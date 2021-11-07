defmodule Dfa.Instant do
  @moduledoc """
  Documentation for `Dfa`.
  Dfa.Instant module helps you define your original deterministic finite automaton by building it on redis by a given name.

  ## Usage
  ```elixir
  Dfa.Instant.initialize!(key_name, db_index, state1)
  Dfa.Instant.on!(key_name, db_index, trigger1, state1, state2)
  Dfa.Instant.on!(key_name, db_index, trigger1, state2, state3)
  Dfa.Instant.on!(key_name, db_index, trigger1, state3, state1)
  Dfa.Instant.on!(key_name, db_index, trigger2, state1, state3)

  assert Dfa.Instant.state!(key_name, db_index) == state1
  assert {:ok, state3} = Dfa.Instant.trigger!(key_name, db_index, trigger1)
  assert Dfa.Instant.state!(key_name, db_index) == state2
  ```
  """
  @behaviour Dfa

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
  defp name(key_name), do: "finite_instant:#{key_name}"

  @spec event_key(String.t(), String.t()) :: String.t()
  defp event_key(key_name, event), do: "#{key_name}:#{event}"

  @doc """
  Defines how automaton changes the state.
  """
  @impl Dfa
  def on!(key_name, db_index, event, current_state, next_state, opts \\ []) do
    conn = conn(opts)

    Redix.command!(conn, ["SELECT", db_index])
    Redix.command!(conn, ["HSET", event_key(key_name, event), current_state, next_state])
  end

  @doc """
  Removes a pattern of state change.
  """
  @impl Dfa
  def rm!(key_name, db_index, event, opts \\ []) do
    conn = conn(opts)

    Redix.command!(conn, ["SELECT", db_index])
    Redix.command!(conn, ["HDEL", event_key(key_name, event)])
  end

  @doc """
  Return current state.
  """
  @impl Dfa
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
  @impl Dfa
  def trigger!(key_name, db_index, event, opts \\ []) do
    [state, result] = send_event!(key_name, db_index, event, opts)
    do_trigger(state, result)
  end

  defp do_trigger(state, nil), do: {:error, state}
  defp do_trigger(state, _), do: {:ok, state}
end
