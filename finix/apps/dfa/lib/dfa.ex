defmodule Dfa do
  @moduledoc """
  Behaviour of deterministic finite automaton.
  """
  @type option() :: String.t() | integer() | nil

  @callback initialize!(String.t(), integer(), String.t()) :: Redix.Protocol.redis_value()
  @callback initialize!(String.t(), String.t(), integer(), String.t()) :: Redix.Protocol.redis_value()

  @doc """
  Defines a state change event.
  """
  @callback on!(String.t(), integer(), String.t(), String.t(), String.t()) :: Redix.Protocol.redis_value()

  @doc """
  Removes a state change event.
  """
  @callback rm!(String.t(), integer(), String.t()) :: Redix.Protocol.redis_value()

  @doc """
  Load a state.
  """
  @callback state!(String.t(), integer()) :: Redix.Protocol.redis_value()

  @doc """
  Triggers an event.
  """
  @callback trigger!(String.t(), integer(), String.t()) :: {:ok, String.t()} | {:error, String.t()}

  @optional_callbacks initialize!: 3, initialize!: 4
end
