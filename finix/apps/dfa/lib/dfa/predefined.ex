defmodule Dfa.Predefined do
  @moduledoc """
  Dfa.Predefined only predefines a behavior of state machine.
  The state machine here consists of `machine `and `instance`.
  """

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
  Generate an instance of a state machine.
  """
  @spec initialize!(String.t(), String.t(), integer(), String.t(), [option()]) :: Redix.Protocol.redis_value()
  def initialize!(instance_name, machine_name, db_index, initial_state, opts \\ []) do
    conn = conn(opts)

    Redix.command!(conn, ["SELECT", db_index])
    Redix.command!(conn, ["SADD", instance_set_key(instance_name), machine_name])
    Redix.command!(conn, ["SET", instance_string_key(instance_name), initial_state, "NX"])
  end

  @spec instance_set_key(String.t()) :: String.t()
  defp instance_set_key(instance_name), do: "finite_predefined_set:#{instance_name}"

  @spec instance_string_key(String.t()) :: String.t()
  defp instance_string_key(instance_name), do: "finite_predefined_string:#{instance_name}"

  @spec machine_event_key(String.t(), String.t()) :: String.t()
  defp machine_event_key(machine_name, event), do: "#{machine_name}:#{event}"

  @doc """
  Defines a state change event.
  """
  @spec on!(String.t(), integer(), String.t(), String.t(), String.t(), [option()]) :: Redix.Protocol.redis_value()
  def on!(machine_name, db_index, event, current_state, next_state, opts \\ []) do
    conn = conn(opts)

    Redix.command!(conn, ["SELECT", db_index])
    Redix.command!(conn, ["HSET", machine_event_key(machine_name, event), current_state, next_state])
  end

  @doc """
  Removes a state change event.
  """
  @spec rm!(String.t(), integer(), String.t(), [option()]) :: Redix.Protocol.redis_value()
  def rm!(machine_name, db_index, event, opts \\ []) do
    conn = conn(opts)

    Redix.command!(conn, ["SELECT", db_index])
    Redix.command!(conn, ["HDEL", machine_event_key(machine_name, event)])
  end

  @doc """
  Load a state.
  """
  @spec state!(String.t(), integer(), [option()]) :: Redix.Protocol.redis_value()
  def state!(instance_name, db_index, opts \\ []) do
    conn = conn(opts)

    Redix.command!(conn, ["SELECT", db_index])
    Redix.command!(conn, ["GET", instance_string_key(instance_name)])
  end

  @spec send_event!(String.t(), integer(), String.t(), [option()]) :: Redix.Protocol.redis_value()
  defp send_event!(instance_name, db_index, event, opts) do
    conn = conn(opts)

    Redix.command!(conn, ["SELECT", db_index])

    machine_name = conn
      |> Redix.command!(["SMEMBERS", instance_set_key(instance_name)])
      |> hd()
      |> machine_event_key(event)

    Redix.command!(conn, ["EVAL", @script, 2, instance_string_key(instance_name), machine_name])
  end

  @doc """
  Triggers an event.
  """
  @spec trigger!(String.t(), integer(), String.t(), [option()]) :: {:ok, String.t()} | {:error, String.t()}
  def trigger!(instance_name, db_index, event, opts \\ []) do
    [state, result] = send_event!(instance_name, db_index, event, opts)
    do_trigger(state, result)
  end

  defp do_trigger(state, nil), do: {:error, state}
  defp do_trigger(state, _), do: {:ok, state}

  @doc """
  Check if a given machine name exists.
  """
  @spec exists?(String.t(), integer(), [option()]) :: boolean()
  def exists?(machine_name, db_index, opts \\ []) do
    conn = conn(opts)

    with {:ok, _} <- Redix.command(conn, ["SELECT", db_index]),
         {:ok, keys} <- Redix.command(conn, ["KEYS", "#{machine_name}*"]) do
      keys != []
    else
      _ -> false
    end
  end
end
