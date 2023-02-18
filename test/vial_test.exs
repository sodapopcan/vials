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

      vial =
        %Vial{module_location: "tmp", task: "mod.two"}
        |> @subject.load()

      assert vial.module == Mod.Two

      File.rm("tmp/mod.two.ex")
    end
  end

  describe "run/1" do
    test "runs the associated task" do
      defmodule Elixir.Mix.Tasks.Run1 do
        def run(_) do
          File.write!(Path.join("tmp", "example.txt"), "test output")
        end
      end

      path = Path.join("tmp", "run1.ex")
      File.write!(path, """
      defmodule Vials.Run1 do
        use Vial
      end
      """)

      Vial.run(["run1"])

      path = Path.join("tmp", "example.txt")

      assert File.read!(path) == "test output"

      File.rm(path)
    end

    test "create_file" do
      defmodule Elixir.Mix.Tasks.Create.File do
        def run(_), do: nil
      end

      path = Path.join("tmp", "create.file.ex")
      File.write!(path, """
      defmodule Vials.Create.File do
        use Vial

        create_file @args[:_1] <> "_file.txt", "I'm some content"
      end
      """)

      Vial.run(["create.file", "file_prefix"])

      created_file = "file_prefix_file.txt"
      assert File.read!(created_file) == "I'm some content"

      File.rm(created_file)
    end
  end
end
