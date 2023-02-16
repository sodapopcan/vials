defmodule VialTest do
  use ExUnit.Case

  @subject Vial

  describe "load/1" do
    @tag :tmp_dir
    test "loads vial module from args and returns a %Vial{} struct", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "mod.one.ex")

      File.write!(path, """
      defmodule Elixir.Mod.One do
        def test, do: "test"
      end
      """)

      vial = @subject.load(~w[-l #{tmp_dir} mod.one --binary-id --database sqlite])

      assert vial.module == Mod.One
      assert vial.task == "mod.one"
      assert vial.options == [binary_id: true, database: "sqlite"]
    end

    test "works with a default module location" do
      File.write!("tmp/mod.two.ex", """
      defmodule Elixir.Mod.Two do
      end
      """)

      vial = @subject.load(~w[mod.two])

      assert vial.module == Mod.Two

      File.rm("tmp/mod.two.ex")
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
