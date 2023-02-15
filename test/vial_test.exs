defmodule VialTest do
  use ExUnit.Case

  test "converts the module name into the mix task" do
    defmodule Vials.Phx.New do
      use Vial
    end

    assert Vials.Phx.New.command() == "mix phx.new"
  end
end
