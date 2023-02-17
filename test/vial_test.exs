defmodule VialTest do
  use ExUnit.Case

  @subject Vial

  describe "parse/1" do
    @tag :tmp_dir
    test "parses mix args and returns a %Vial{} struct", %{tmp_dir: tmp_dir} do
      vial =
        @subject.parse(
          ~w[-l #{tmp_dir} mod.one some-arg some-other-arg --binary-id --database sqlite]
        )

      assert vial.module_location == tmp_dir
      assert vial.cwd == File.cwd!()
      assert vial.task == "mod.one"
      assert vial.task_args == ["some-arg", "some-other-arg"]
      assert vial.options == [binary_id: true, database: "sqlite"]

      assert vial.args == %{
               :"1" => "some-arg",
               :"2" => "some-other-arg",
               binary_id: true,
               database: "sqlite"
             }
    end
  end

  describe "load/1" do
    @tag :tmp_dir
    test "loads vial module from args and returns a %Vial{} struct", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "mod.one.ex")

      File.write!(path, """
      defmodule Elixir.Mod.One do
        def test, do: "test"
      end
      """)

      vial = %Vial{module_location: tmp_dir, task: "mod.one"}

      vial = @subject.load(vial)

      assert vial.module == Mod.One
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

  describe "run/1" do
    test "does it" do
      path = Path.join("tmp", "run1.ex")

      File.write!(path, """
      defmodule Elixir.Run1 do
        use Vial
      end
      """)

      Vial.run(["run1", "example"])

      path = Path.join("tmp", "example.txt")

      assert File.read!(path) == "example"

      File.rm path
    end
  end
end
