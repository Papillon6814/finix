defmodule Dfa.PredefinedTest do
  use ExUnit.Case
  doctest Dfa.Predefined

  describe "dfa" do
    test "simple automaton" do
      Dfa.Instant.flushall()

      machine_name = "matine"
      instance_name1 = "automatto"
      instance_name2 = "automatty"
      db_index = 15

      state1 = "a"
      state2 = "b"
      state3 = "c"
      trigger1 = "x"
      trigger2 = "y"
      invalid_trigger = "invalid"

      Dfa.Predefined.on!(machine_name, db_index, trigger1, state1, state2)
      Dfa.Predefined.on!(machine_name, db_index, trigger1, state2, state3)
      Dfa.Predefined.on!(machine_name, db_index, trigger1, state3, state1)
      Dfa.Predefined.on!(machine_name, db_index, trigger2, state1, state3)

      Dfa.Predefined.initialize!(instance_name1, machine_name, db_index, state1)
      Dfa.Predefined.initialize!(instance_name2, machine_name, db_index, state1)

      assert Dfa.Predefined.state!(instance_name1, db_index) == state1

      assert {:ok, _} = Dfa.Predefined.trigger!(instance_name1, db_index, trigger1)
      assert Dfa.Predefined.state!(instance_name1, db_index) == state2
      assert {:ok, _} = Dfa.Predefined.trigger!(instance_name1, db_index, trigger1)
      assert {:ok, _} = Dfa.Predefined.trigger!(instance_name2, db_index, trigger1)
      assert Dfa.Predefined.state!(instance_name1, db_index) == state3
      assert Dfa.Predefined.state!(instance_name2, db_index) == state2
      assert {:ok, _} = Dfa.Predefined.trigger!(instance_name1, db_index, trigger1)
      assert {:ok, _} = Dfa.Predefined.trigger!(instance_name1, db_index, trigger2)
      assert Dfa.Predefined.state!(instance_name1, db_index) == state3
      assert {:error, _} = Dfa.Predefined.trigger!(instance_name2, db_index, trigger2)
      assert Dfa.Predefined.state!(instance_name2, db_index) == state2
      assert {:error, _} = Dfa.Predefined.trigger!(instance_name2, db_index, invalid_trigger)
      assert Dfa.Predefined.state!(instance_name2, db_index) == state2
    end
  end
end
