defmodule DfmTest do
  use ExUnit.Case
  doctest Dfm

  describe "dfm" do
    test "simple automaton" do
      Dfm.flushall()

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
        Dfm.initialize(key_name, db_index, state1)
        Dfm.on(key_name, db_index, trigger1, state1, state2)
        Dfm.on(key_name, db_index, trigger1, state2, state3)
        Dfm.on(key_name, db_index, trigger1, state3, state1)
        Dfm.on(key_name, db_index, trigger2, state1, state3)

        assert Dfm.state(key_name, db_index) == state1
        assert {:ok, state3} = Dfm.trigger(key_name, db_index, trigger1)
        assert Dfm.state(key_name, db_index) == state2
        assert {:ok, state3} = Dfm.trigger(key_name, db_index, trigger1)
        assert Dfm.state(key_name, db_index) == state3
        assert {:ok, state3} = Dfm.trigger(key_name, db_index, trigger1)
        assert Dfm.state(key_name, db_index) == state1
        assert {:ok, state3} = Dfm.trigger(key_name, db_index, trigger2)
        assert Dfm.state(key_name, db_index) == state3

        # NOTE: Invalid patterns
        assert {:error, state3} = Dfm.trigger(key_name, db_index, trigger2)
        assert {:error, state3} = Dfm.trigger(key_name, db_index, invalid_trigger)
      end)
    end
  end
end
