defmodule Dfa.Predefined do
  @moduledoc """
  Dfa.Predefined only predefines a behavior of state machine.
  The state machine here consists of `machine `and `instance`.
  """
  @behaviour Dfa

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
    host = Application.get_env(:dfa, :redis_host) || @redis_host
    port = Application.get_env(:dfa, :redis_port) || @redis_port

    with {:ok, conn} <- Redix.start_link(host: host, port: port) do
      conn
    else
      error -> raise "Failed to connect to #{host}:#{port} #{error}"
    end
  end

  @doc """
  Generate an instance of a state machine.
  """
  @impl Dfa
  def initialize!(instance_name, machine_name, db_index, initial_state) do
    conn = conn()

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
  Deletes an instance.
  """
  @spec deinitialize!(String.t(), integer()) :: Redix.Protocol.redis_value() | nil
  def deinitialize!(instance_name, db_index) do
    if __MODULE__.instance_exists?(instance_name, db_index) do
      conn = conn()

      Redix.command!(conn, ["SELECT", db_index])
      Redix.command!(conn, ["SPOP", instance_set_key(instance_name), 1])
      Redix.command!(conn, ["DEL", instance_string_key(instance_name)])
    else
      nil
    end
  end

  @doc """
  Defines a state change event.
  """
  @impl Dfa
  def on!(machine_name, db_index, event, current_state, next_state) do
    conn = conn()

    Redix.command!(conn, ["SELECT", db_index])
    Redix.command!(conn, ["HSET", machine_event_key(machine_name, event), current_state, next_state])
  end

  @doc """
  Removes a state change event.
  """
  @impl Dfa
  def rm!(machine_name, db_index, event) do
    conn = conn()

    Redix.command!(conn, ["SELECT", db_index])
    Redix.command!(conn, ["HDEL", machine_event_key(machine_name, event)])
  end

  @doc """
  Load a state.
  """
  @impl Dfa
  def state!(instance_name, db_index) do
    conn = conn()

    Redix.command!(conn, ["SELECT", db_index])
    Redix.command!(conn, ["GET", instance_string_key(instance_name)])
  end

  @spec send_event!(String.t(), integer(), String.t()) :: Redix.Protocol.redis_value()
  defp send_event!(instance_name, db_index, event) do
    conn = conn()

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
  @impl Dfa
  def trigger!(instance_name, db_index, event) do
    [state, result] = send_event!(instance_name, db_index, event)
    do_trigger(state, result)
  end

  defp do_trigger(state, nil), do: {:error, state}
  defp do_trigger(state, _), do: {:ok, state}

  @doc """
  Check if a given machine name exists.
  """
  @spec exists?(String.t(), integer()) :: boolean()
  def exists?(machine_name, db_index) do
    conn = conn()

    with {:ok, _}    <- Redix.command(conn, ["SELECT", db_index]),
         {:ok, keys} <- Redix.command(conn, ["KEYS", "#{machine_name}*"]) do
      keys != []
    else
      _ -> false
    end
  end

  @doc """
  Check if given instance name exists.
  """
  def instance_exists?(instance_name, db_index) do
    conn = conn()

    with {:ok, _}   <- Redix.command(conn, ["SELECT", db_index]),
         {:ok, val} <- Redix.command(conn, ["GET", instance_string_key(instance_name)]) do
      !is_nil(val)
    else
      _ -> false
    end
  end
end
