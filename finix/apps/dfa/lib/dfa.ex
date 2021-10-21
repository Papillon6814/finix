defmodule Dfa do
  @moduledoc """
  Documentation for `Dfa`.
  Dfa module helps you define your original deterministic finite automaton.

  ## Usage
  ```elixir
  Dfa.initialize!(key_name, db_index, state1)
  Dfa.on!(key_name, db_index, trigger1, state1, state2)
  Dfa.on!(key_name, db_index, trigger1, state2, state3)
  Dfa.on!(key_name, db_index, trigger1, state3, state1)
  Dfa.on!(key_name, db_index, trigger2, state1, state3)

  assert Dfa.state!(key_name, db_index) == state1
  assert {:ok, state3} = Dfa.trigger!(key_name, db_index, trigger1)
  assert Dfa.state!(key_name, db_index) == state2
  ```
  """

  require Logger

  @script """
  local curr = redis.call("GET", KEYS[1])
  local next = redis.call("HGET", KEYS[2], curr)
  if next then
    redis.call("SET", KEYS[1], next)
    return { next, true }
  else
    return { curr, false }
  end
  """

  @type option() :: String.t() | integer()

  @redis_host "localhost"
  @redis_port 6379

  defp conn(opts) do
    host = Keyword.get(opts, :redis_host, @redis_host)
    port = Keyword.get(opts, :redis_port, @redis_port)

    with {:ok, conn} <- Redix.start_link(host: host, port: port) do
      conn
    else
      error -> raise "Failed to connect to #{host}:#{port} #{error}"
    end
  end

  @doc """
  Flush all data.
  """
  @spec flushall([option()]) :: :ok
  def flushall(opts \\ []) do
    conn = conn(opts)
    Redix.command(conn, ["FLUSHALL"])

    Logger.info("Flushed all")
  end

  @doc """
  Initializes state of automaton.
  """
  @spec initialize!(String.t(), integer(), String.t(), [option()]) :: Redix.Protocol.redis_value()
  def initialize!(key_name, db_index, initial_state, opts \\ []) do
    conn = conn(opts)
    name = name(key_name)

    Redix.command!(conn, ["SELECT", db_index])
    Redix.command!(conn, ["SET", name, initial_state, "NX"])
  end

  @spec name(String.t()) :: String.t()
  defp name(key_name), do: "finite:#{key_name}"

  @spec event_key(String.t(), String.t()) :: String.t()
  defp event_key(key_name, event), do: "#{key_name}:#{event}"

  @doc """
  Defines how automaton changes the state.
  """
  @spec on!(String.t(), integer(), String.t(), String.t(), String.t(), [option()]) :: Redix.Protocol.redis_value()
  def on!(key_name, db_index, event, current_state, next_state, opts \\ []) do
    conn = conn(opts)

    Redix.command!(conn, ["SELECT", db_index])
    Redix.command!(conn, ["HSET", event_key(key_name, event), current_state, next_state])
  end

  @doc """
  Removes a pattern of state change.
  """
  @spec rm!(String.t(), integer(), String.t(), [option()]) :: Redix.Protocol.redis_value()
  def rm!(key_name, db_index, event, opts \\ []) do
    conn = conn(opts)

    Redix.command!(conn, ["SELECT", db_index])
    Redix.command!(conn, ["HDEL", event_key(key_name, event)])
  end

  @doc """
  Return current state.
  """
  @spec state!(String.t(), integer(), [option()]) :: Redix.Protocol.redis_value()
  def state!(key_name, db_index, opts \\ []) do
    conn = conn(opts)

    Redix.command!(conn, ["SELECT", db_index])
    Redix.command!(conn, ["GET", name(key_name)])
  end

  @spec send_event!(String.t(), integer(), String.t(), [option()]) :: Redix.Protocol.redis_value()
  defp send_event!(key_name, db_index, event, opts) do
    conn = conn(opts)

    Redix.command!(conn, ["SELECT", db_index])
    Redix.command!(conn, ["EVAL", @script, 2, name(key_name), event_key(key_name, event)])
  end

  @doc """
  Triggers state change.
  """
  @spec trigger!(String.t(), integer(), String.t(), [option()]) :: {:ok, String.t()} | {:error, String.t()}
  def trigger!(key_name, db_index, event, opts \\ []) do
    [state, result] = send_event!(key_name, db_index, event, opts)
    do_trigger(state, result)
  end

  defp do_trigger(state, nil), do: {:error, state}
  defp do_trigger(state, _), do: {:ok, state}
end
