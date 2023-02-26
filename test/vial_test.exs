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
      args = ["some.task", "arg", "another_arg", "--some", "option", "--bool"]

      task_args = @subject.parse_task_args(args)

      assert %{
               args: ["some.task", "arg", "another_arg"],
               task_name: "some.task",
               target: "arg",
               opts: %{some: "option", bool: true}
             } = task_args
    end

    test "sets target to nil if there is none" do
      args = ["some.task"]

      task_args = @subject.parse_task_args(args)

      assert %{args: ["some.task"], target: nil} = task_args
    end
  end

  describe "get_path" do
    setup do
      home = Vial.Util.user_home()

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

  describe "read_file/2" do
    @tag :tmp_dir
    test "it finds a file given its path", %{tmp_dir: path} do
      task_name = "some.task"
      File.write!(Path.join(path, "some.task"), "I'm the file contents.")

      {:ok, contents} = @subject.read_file(path, task_name)

      assert contents == "I'm the file contents."
    end
  end

  describe "inject_task_args" do
    test "injects the task's args into the vial" do
      ast =
        Code.string_to_quoted!("""
        defmodule Vial.UtilTest.Inject do
          def args, do: @args
          def opts, do: @opts
          def task_name, do: @task_name
          def target, do: @target
        end
        """)

      task_args = %{
        args: ["task_name", "target"],
        opts: %{opt1: "opt1", opt2: "opt2"},
        task_name: "task_name",
        target: "target"
      }

      [{mod, _}] =
        ast
        |> @subject.inject_task_args(task_args)
        |> Code.compile_quoted()

      assert mod.args == ["task_name", "target"]
      assert mod.opts == %{opt1: "opt1", opt2: "opt2"}
      assert mod.task_name == "task_name"
      assert mod.target == "target"
    end
  end

  describe "compile" do
    test "it compiles an ast" do
      {:ok, ast} =
        """
        defmodule CompileFile do
          def hi do
            "hi"
          end
        end
        """
        |> Code.string_to_quoted()

      {:ok, module} = @subject.compile(ast)

      assert module.hi() == "hi"
    end

    test "returns an error if invalid" do
      error =
        "invalid quoted expression: {\"invalid\"}\n\nPlease make sure your quoted expressions are made of valid AST nodes. If you would like to introduce a value into the AST, such as a four-element tuple or a map, make sure to call Macro.escape/1 before"

      assert {:error, ^error} = @subject.compile([{"invalid"}])
    end
  end

  describe "main/1" do
    setup do
      vial_dir = Path.join(~w[tmp vials])

      File.mkdir(vial_dir)

      on_exit(fn ->
        Path.wildcard("#{vial_dir}/*")
        |> Enum.each(&File.rm/1)

        File.rmdir(vial_dir)
      end)

      %{vial_dir: vial_dir}
    end

    test "runs the associated task", %{vial_dir: vial_dir} do
      defmodule Elixir.Mix.Tasks.Run1 do
        def run(_) do
          File.write!(Path.join(~w[tmp example.txt]), "example text")
        end
      end

      filename = Path.join(vial_dir, "run1.ex")

      File.write!(filename, """
      defmodule Vials.Run1 do
        use Vial
      end
      """)

      Vial.main(["run1"])

      assert File.read!(Path.join(~w[tmp example.txt])) == "example text"
    end

    test "create", %{vial_dir: vial_dir} do
      defmodule Elixir.Mix.Tasks.Create.File do
        def run(_), do: nil
      end

      path = Path.join(vial_dir, "create.file.ex")

      File.write!(path, """
      defmodule Vials.Create.File do
        use Vial

        base_path "tmp"

        create "#\{@target}_file.txt", "I'm some content"
      end
      """)

      Vial.main(["create.file", "file_prefix"])

      created_file = Path.join("tmp", "file_prefix_file.txt")
      assert File.read!(created_file) == "I'm some content"

      File.rm(created_file)
    end

    test "conditional create", %{vial_dir: vial_dir} do
      defmodule Elixir.Mix.Tasks.Conditional.Create.File do
        def run(_), do: nil
      end

      path = Path.join(~w[#{vial_dir} conditional.create.file.ex])

      File.write!(path, """
      defmodule Vials.Conditional.Create.File do
        use Vial

        if @args[:arg_not_passed] do
          create "file.txt", "I'm some content"
        end
      end
      """)

      Vial.main(["conditional.create.file"])

      refute File.exists?("tmp/file.txt")
    end

    test "remove_comments from all ex and exs file", %{vial_dir: vial_dir} do
      defmodule Elixir.Mix.Tasks.Remove.All.Comments do
        def run(_), do: nil
      end

      ex_file = Path.join(~w[tmp remove_all_comments.ex])
      exs_file = Path.join(~w[tmp remove_all_comments.exs])
      other_file = Path.join(~w[tmp remove_all_comments])

      File.write!(ex_file, "# A comment")
      File.write!(exs_file, "# A comment")
      File.write!(other_file, "# A comment")

      File.write!(Path.join(~w[#{vial_dir} remove.all.comments.ex]), """
      defmodule Vials.Remove.All.Comments do
        use Vial

        base_path "tmp"

        remove_comments()
      end
      """)

      Vial.main(["remove.all.comments"])

      assert File.read!(ex_file) == ""
      assert File.read!(exs_file) == ""
      assert File.read!(other_file) == "# A comment"
    end
  end
end
