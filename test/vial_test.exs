defmodule VialTest do
  use ExUnit.Case

  import Vial

  test "does a thing" do
    result =
      mix "phx.new" do
        options "--binary-id"
      end

    assert result == "mix phx.new --binary-id"
  end
end
