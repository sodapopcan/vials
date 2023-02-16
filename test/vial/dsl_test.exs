defmodule Vial.DSLTest do
  use ExUnit.Case

  describe ".create_file/1" do
    @tag :tmp_dir
    test "creates a function called create_file_1/2", %{tmp_dir: tmp_dir} do
      vial = %Vial{cwd: tmp_dir}

      defmodule CreateFile do
        use Vial.DSL

        create_file "hello.txt", "Hi there"
      end

      CreateFile.create_file_0(vial)

      assert File.read!(Path.join(tmp_dir, "hello.txt")) == "Hi there"
    end
  end
end
