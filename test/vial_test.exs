defmodule VialTest do
  use ExUnit.Case

  @subject Vial

  describe "load_module/1" do
    @tag :tmp_dir
    test "loads module by task name", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "phx.new.ex")

      File.write!(path, """
      defmodule Foo do
        def test, do: "test"
      end
      """)

      mod = @subject.load_module("phx.new", tmp_dir)

      assert mod.test() == "test"
    end
  end

  describe "options" do
    test "adds options" do
      defmodule Elixir.Vials.Phx.New do
        use Vial

        @options ~w[--binary-id]
      end

      assert Vials.Phx.New.command() == "mix phx.new --binary-id"
    end
  end
end
