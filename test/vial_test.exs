defmodule VialTest do
  use ExUnit.Case

  test "does a thing" do
    result = Vial.mix(fn -> "hi" end)

    assert result == "hi"
  end
end
