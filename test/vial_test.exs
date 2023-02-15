defmodule VialTest do
  use ExUnit.Case
  doctest Vial

  test "does a thing" do
    result = Vial.mix(fn -> "hi" end)

    assert result == "hi"
  end
end
