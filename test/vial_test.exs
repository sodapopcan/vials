defmodule VialTest do
  use ExUnit.Case

  @subject Vial

  describe "load/1" do
    @tag :tmp_dir
    test "loads vial module from args and returns a %Vial{} struct", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "phx.new.ex")

      File.write!(path, """
      defmodule Elixir.Phx.New do
        def test, do: "test"
      end
      """)

      vial = @subject.load(~w[-l #{tmp_dir} phx.new --binary-id --database sqlite])

      assert vial.module == Phx.New
      assert vial.task == "phx.new"
      assert vial.options == [binary_id: true, database: "sqlite"]
    end

    test "works with a default module location" do
      File.write!("tmp/phx.new.ex", """
      defmodule Elixir.Phx.New do
      end
      """)

      vial = @subject.load(~w[phx.new])

      assert vial.module == Phx.New

      File.rm("tmp/phx.new.ex")
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
