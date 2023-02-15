defmodule VialTest do
  use ExUnit.Case

  test "converts the module name into the mix task" do
    defmodule Vials.Phx.New do
      use Vial
    end

    assert Vials.Phx.New.command() == "mix phx.new"
  end

  describe "options" do
    test "adds options" do
      defmodule Vials.Phx.New do
        use Vial

        @options ~w[--binary-id]
      end

      assert Vials.Phx.New.command() == "mix phx.new --binary-id"
    end
  end
end
