defmodule Vial.DSLTest do
  use ExUnit.Case

  describe "actions/0" do
    test "returns all functions in order" do
      defmodule Actions do
        use Vial.DSL

        create_file "hello.txt", "Hi there"
        create_file "bye.txt", "Bye there"
      end

      actions = Actions.actions()

      assert actions == [:create_file_1, :create_file_2]
      assert function_exported?(Actions, :create_file_1, 1)
      assert function_exported?(Actions, :create_file_2, 1)
    end
  end

  describe "cd/1" do
    vial = %Vial{cwd: "/"}

    defmodule CD do
      use Vial.DSL

      cd "/some/other/dir"
    end

    vial = CD.cd_1(vial)

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

      CreateFile.create_file_1(vial)

      assert File.read!(Path.join(tmp_dir, "hello.txt")) == "Hi there"
    end

    @tag :tmp_dir
    test "interpolates variables in filename", %{tmp_dir: tmp_dir} do
      vial = %Vial{cwd: tmp_dir, variables: %{:"1" => "some_project"}}

      defmodule CreateFileVariables do
        use Vial.DSL

        create_file "{$1}_file.txt", "Hi there"
      end

      CreateFileVariables.create_file_1(vial)

      assert File.read!(Path.join(tmp_dir, "some_project_file.txt")) == "Hi there"
    end
  end
end
