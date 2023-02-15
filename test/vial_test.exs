defmodule VialTest do
  use ExUnit.Case

  test "does a thing" do
    result =
      Vial.mix "phx.new" do
        "--binary"
      end

    assert result == "mix phx.new --binary"
  end
end
