defmodule Dfa.InstantTest do
  use ExUnit.Case
  doctest Dfa.Instant

  describe "dfa" do
    test "simple automaton" do
      Dfa.Instant.flushall()

      1..5
      |> Enum.to_list()
      |> Enum.each(fn n ->
        key_name = "user#{n}"
        db_index = 15

        state1 = "a"
        state2 = "b"
        state3 = "c"
        trigger1 = "x"
        trigger2 = "y"
        invalid_trigger = "invalid"

        # NOTE: Define state changes
        Dfa.Instant.initialize!(key_name, db_index, state1)
        Dfa.Instant.on!(key_name, db_index, trigger1, state1, state2)
        Dfa.Instant.on!(key_name, db_index, trigger1, state2, state3)
        Dfa.Instant.on!(key_name, db_index, trigger1, state3, state1)
        Dfa.Instant.on!(key_name, db_index, trigger2, state1, state3)

        assert Dfa.Instant.state!(key_name, db_index) == state1
        assert {:ok, ^state2} = Dfa.Instant.trigger!(key_name, db_index, trigger1)
        assert Dfa.Instant.state!(key_name, db_index) == state2
        assert {:ok, ^state3} = Dfa.Instant.trigger!(key_name, db_index, trigger1)
        assert Dfa.Instant.state!(key_name, db_index) == state3
        assert {:ok, ^state1} = Dfa.Instant.trigger!(key_name, db_index, trigger1)
        assert Dfa.Instant.state!(key_name, db_index) == state1
        assert {:ok, ^state3} = Dfa.Instant.trigger!(key_name, db_index, trigger2)
        assert Dfa.Instant.state!(key_name, db_index) == state3

        # NOTE: Invalid patterns
        assert {:error, ^state3} = Dfa.Instant.trigger!(key_name, db_index, trigger2)
        assert {:error, ^state3} = Dfa.Instant.trigger!(key_name, db_index, invalid_trigger)
      end)
    end
  end
end
