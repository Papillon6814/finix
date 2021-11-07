defmodule Dfa.PredefinedTest do
  use ExUnit.Case
  doctest Dfa.Predefined

  alias Dfa.Predefined

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

      Predefined.on!(machine_name, db_index, trigger1, state1, state2)
      Predefined.on!(machine_name, db_index, trigger1, state2, state3)
      Predefined.on!(machine_name, db_index, trigger1, state3, state1)
      Predefined.on!(machine_name, db_index, trigger2, state1, state3)

      Predefined.initialize!(instance_name1, machine_name, db_index, state1)
      Predefined.initialize!(instance_name2, machine_name, db_index, state1)

      assert Predefined.state!(instance_name1, db_index) == state1

      assert {:ok, _} = Predefined.trigger!(instance_name1, db_index, trigger1)
      assert Predefined.state!(instance_name1, db_index) == state2
      assert {:ok, _} = Predefined.trigger!(instance_name1, db_index, trigger1)
      assert {:ok, _} = Predefined.trigger!(instance_name2, db_index, trigger1)
      assert Predefined.state!(instance_name1, db_index) == state3
      assert Predefined.state!(instance_name2, db_index) == state2
      assert {:ok, _} = Predefined.trigger!(instance_name1, db_index, trigger1)
      assert {:ok, _} = Predefined.trigger!(instance_name1, db_index, trigger2)
      assert Predefined.state!(instance_name1, db_index) == state3
      assert {:error, _} = Predefined.trigger!(instance_name2, db_index, trigger2)
      assert Predefined.state!(instance_name2, db_index) == state2
      assert {:error, _} = Predefined.trigger!(instance_name2, db_index, invalid_trigger)
      assert Predefined.state!(instance_name2, db_index) == state2

      assert Predefined.exists?(machine_name, db_index)
      refute Predefined.exists?("invalid name", db_index)

      invalid_instance = "invld"
      refute Predefined.instance_exists?(invalid_instance, db_index)
    end
  end
end
