defmodule VialTest do
  use ExUnit.Case

  @subject Vial

  describe "parse_vial_opts" do
    test "parses vial args from the arg list" do
      args = ["-l", "some/path", "some.task", "--some", "option"]

      {vial_opts, _} = @subject.parse_vial_opts(args)

      assert vial_opts == [location: "some/path"]
    end
  end

  describe "parse_task_args" do
    test "parses task args" do
      args = ["some.task", "arg", "--some", "option", "--bool"]

      {task_opts, task_args} = @subject.parse_task_args(args)

      assert task_args == ["some.task", "arg"]
      assert task_opts == [some: "option", bool: true]
    end
  end

  describe "get_path" do
    setup do
      home = Application.get_env(:vial, :user_home).()

      remove_test_dirs = fn ->
        [
          Path.join(home, ".vials"),
          Path.join(home, "vials"),
          Path.join([home, "some", "path"]),
          Path.join(home, "some")
        ]
        |> Enum.each(fn dir ->
          File.exists?(dir)
          if File.exists?(dir), do: File.rmdir(dir)
        end)
      end

      # Ensure test dirs are removed before each test
      remove_test_dirs.()

      on_exit(remove_test_dirs)

      %{home: home}
    end

    test "returns `:home/vials` by default", %{home: home} do
      File.mkdir(Path.join(home, "vials"))

      {:ok, module_path} = @subject.get_path()

      assert module_path == Path.join(home, "vials")
    end

    test "returns `:home/.vials` if it exists", %{home: home} do
      File.mkdir(Path.join(home, "vials"))
      File.mkdir(Path.join(home, ".vials"))

      {:ok, module_path} = @subject.get_path()

      assert module_path == Path.join(home, ".vials")
    end

    test "returns $VIALS_PATH if VIALS_PATH exists", %{home: home} do
      File.mkdir(Path.join(home, "vials"))
      File.mkdir(Path.join(home, ".vials"))
      File.mkdir_p(Path.join(~w[tmp some path]))
      System.put_env("VIALS_PATH", Path.join(~w[tmp some path]))

      {:ok, module_path} = @subject.get_path()

      assert module_path == Path.join(~w[tmp some path])
    end

    test "raises if none of the options exist" do
      {:error, message} = @subject.get_path()

      assert message ==
               "No path found.  Please create one of `~/vials` or `~/.vials` or set VIALS_PATH."
    end
  end

  # describe "compile_vial_module" do
  #   @tag :tmp_dir
  #   test "compiles the user's vial", %{tmp_dir: tmp_dir} do
  #     vial_opts = []
  #     File.write!(Path.join(tmp_dir, "mod.two"), """
  #     defmodule Elixir.Mod.Two do
  #     end
  #     """)

  #     @subject.load_vial_module()
  #   end
  # end

  describe "parse/1" do
    @tag :tmp_dir
    test "parses mix args and returns a %Vial{} struct", %{tmp_dir: tmp_dir} do
      vial =
        @subject.parse(
          ~w[-l #{tmp_dir} mod.one some-arg some-other-arg --binary-id --database sqlite]
        )

      assert vial.module_location == tmp_dir
      assert vial.cwd == "tmp"
      assert vial.task == "mod.one"
      assert vial.task_args == ["some-arg", "some-other-arg"]
      assert vial.raw_task_args == ~w[some-arg some-other-arg --binary-id --database sqlite]
      assert vial.options == [binary_id: true, database: "sqlite"]

      assert vial.args == %{
               :_1 => "some-arg",
               :_2 => "some-other-arg",
               binary_id: true,
               database: "sqlite"
             }
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

        create_file "#\{@args[:_1]}_file.txt", "I'm some content"
      end
      """)

      Vial.run(["create.file", "file_prefix"])

      created_file = Path.join("tmp", "file_prefix_file.txt")
      assert File.read!(created_file) == "I'm some content"

      File.rm(created_file)
    end

    test "conditional create_file" do
      defmodule Elixir.Mix.Tasks.Conditional.Create.File do
        def run(_), do: nil
      end

      path = Path.join("tmp", "conditional.create.file.ex")

      File.write!(path, """
      defmodule Vials.Conditional.Create.File do
        use Vial

        if @args[:arg_not_passed] do
          create_file "file.txt", "I'm some content"
        end
      end
      """)

      Vial.run(["conditional.create.file"])

      refute File.exists?("tmp/file.txt")
    end
  end
end
