defmodule Dfm do
  @moduledoc """
  Documentation for `Dfm`.
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

  @redis_host "localhost"
  @redis_port 6379

  defp conn() do
    with {:ok, conn} <- Redix.start_link(host: @redis_host, port: @redis_port) do
      conn
    else
      error -> raise "Failed to connect to #{@redis_host}:#{@redis_port} #{error}"
    end
  end

  def flushall() do
    conn = conn()
    Redix.command(conn, ["FLUSHALL"])

    Logger.info("Flushed all")
  end

  @doc """
  Initializes state of automaton.
  """
  @spec initialize(String.t(), integer(), String.t()) :: Redix.Protocol.redis_value()
  def initialize(key_name, db_index, initial_state) do
    conn = conn()
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
  @spec on(String.t(), integer(), String.t(), String.t(), String.t()) :: Redix.Protocol.redis_value()
  def on(key_name, db_index, event, current_state, next_state) do
    conn = conn()

    Redix.command!(conn, ["SELECT", db_index])
    Redix.command!(conn, ["HSET", event_key(key_name, event), current_state, next_state])
  end

  @doc """
  Removes a pattern of state change.
  """
  @spec rm(String.t(), integer(), String.t()) :: Redix.Protocol.redis_value()
  def rm(key_name, db_index, event) do
    conn = conn()

    Redix.command!(conn, ["SELECT", db_index])
    Redix.command!(conn, ["HDEL", event_key(key_name, event)])
  end

  @doc """
  Return current state.
  """
  @spec state(String.t(), integer()) :: Redix.Protocol.redis_value()
  def state(key_name, db_index) do
    conn = conn()

    Redix.command!(conn, ["SELECT", db_index])
    Redix.command!(conn, ["GET", name(key_name)])
  end

  @spec send_event(String.t(), integer(), String.t()) :: Redix.Protocol.redis_value()
  defp send_event(key_name, db_index, event) do
    conn = conn()

    Redix.command!(conn, ["SELECT", db_index])
    Redix.command!(conn, ["EVAL", @script, 2, name(key_name), event_key(key_name, event)])
  end

  @doc """
  Triggers state change.
  """
  @spec trigger(String.t(), integer(), String.t()) :: Redix.Protocol.redis_value()
  def trigger(key_name, db_index, event) do
    result = send_event(key_name, db_index, event)
    IO.inspect(result)
  end
end
