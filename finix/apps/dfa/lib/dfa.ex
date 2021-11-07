defmodule Dfa do
  @moduledoc """
  Behaviour of deterministic finite automaton.
  """
  @type option() :: String.t() | integer() | nil

  @callback initialize!(String.t(), integer(), String.t(), [option()]) :: Redix.Protocol.redis_value()
  @callback initialize!(String.t(), String.t(), integer(), String.t(), [option()]) :: Redix.Protocol.redis_value()

  @callback on!(String.t(), integer(), String.t(), String.t(), String.t(), [option()]) :: Redix.Protocol.redis_value()

  @callback rm!(String.t(), integer(), String.t(), [option()]) :: Redix.Protocol.redis_value()

  @callback state!(String.t(), integer(), [option()]) :: Redix.Protocol.redis_value()

  @callback trigger!(String.t(), integer(), String.t(), [option()]) :: {:ok, String.t()} | {:error, String.t()}

  @optional_callbacks initialize!: 5, initialize!: 4
end
