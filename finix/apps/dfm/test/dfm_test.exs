defmodule DfmTest do
  use ExUnit.Case
  doctest Dfm

  test "greets the world" do
    assert Dfm.hello() == :world
  end
end
