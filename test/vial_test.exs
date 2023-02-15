defmodule VialTest do
  use ExUnit.Case
  doctest Vial

  test "greets the world" do
    assert Vial.hello() == :world
  end
end
