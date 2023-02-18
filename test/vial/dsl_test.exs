defmodule Vial.DSLTest do
  use ExUnit.Case

  describe "actions/0" do
    test "returns all functions in order" do
      defmodule Actions do
        use Vial.DSL

        create_file "hello.txt", "Hi there"
        create_file "bye.txt", "Bye there"
      end

      [int_1, int_2] =
        Actions.actions()
        |> Enum.map(&Atom.to_string/1)
        |> Enum.map(&(Regex.run(~r/[[:digit:]]+\z/, &1)))
        |> List.flatten()
        |> Enum.map(&String.to_integer/1)

      assert int_1 < int_2
    end
  end

  describe "cd/1" do
    vial = %Vial{cwd: "/"}

    defmodule CD do
      use Vial.DSL

      cd "/some/other/dir"
    end

    [func] = CD.actions()
    vial = apply(CD, func, [vial])

    assert vial.cwd == "/some/other/dir"
  end

  describe "create_file/1" do
    @tag :tmp_dir
    test "creates a function called create_file_1/2", %{tmp_dir: tmp_dir} do
      vial = %Vial{cwd: tmp_dir}

      defmodule CreateFile do
        use Vial.DSL

        create_file "hello.txt", "Hi there"
      end

      [func] = CreateFile.actions()
      apply(CreateFile, func, [vial])

      assert File.read!(Path.join(tmp_dir, "hello.txt")) == "Hi there"
    end

    @tag :tmp_dir
    test "sets args", %{tmp_dir: tmp_dir} do
      vial = %Vial{cwd: tmp_dir}

      defmodule CreateFileVariables do
        use Vial.DSL, %{_1: "some_project"}

        create_file "#{@args[:_1]}_file.txt", "Hi there"
      end

      [func] = CreateFileVariables.actions()
      apply(CreateFileVariables, func, [vial])

      assert File.read!(Path.join(tmp_dir, "some_project_file.txt")) == "Hi there"
    end
  end
end
