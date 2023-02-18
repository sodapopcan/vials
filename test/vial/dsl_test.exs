defmodule Vial.DSLTest do
  use ExUnit.Case

  describe "cd/1" do
    vial = %Vial{cwd: "/"}

    defmodule CD do
      use Vial.DSL

      cd "/some/other/dir"
    end

    [func] = CD.actions()
    vial = func.(vial)

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
      func.(vial)

      assert File.read!(Path.join(tmp_dir, "hello.txt")) == "Hi there"
    end
  end
end
