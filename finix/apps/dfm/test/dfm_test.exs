defmodule DfmTest do
  use ExUnit.Case
  doctest Dfm

  describe "dfm" do
    test "just works" do
      Dfm.flushall()

      key_name = "user1"
      db_index = 15

      state1 = "a"
      state2 = "b"
      state3 = "c"
      trigger1 = "x"
      trigger2 = "y"

      Dfm.initialize(key_name, db_index, state1)
      Dfm.on(key_name, db_index, trigger1, state1, state2)
      Dfm.on(key_name, db_index, trigger1, state2, state3)
      Dfm.on(key_name, db_index, trigger1, state3, state1)
      Dfm.on(key_name, db_index, trigger2, state1, state3)

      assert Dfm.state(key_name, db_index) == state1
      Dfm.trigger(key_name, db_index, trigger1)
      assert Dfm.state(key_name, db_index) == state2
      Dfm.trigger(key_name, db_index, "t")
    end
  end
end
