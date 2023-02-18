defmodule Vial.DSLTest do
  use ExUnit.Case

  @subject Vial.DSL

  setup do
    start_supervised(Vial.DSL)
    :ok
  end

  describe "cd/1" do
    test "returns vial struct with new cwd" do
      vial = %Vial{cwd: "/"}

      func = @subject.cd("/some/other/dir")
      vial = func.(vial)

      assert vial.cwd == "/some/other/dir"
    end
  end

  describe "create_file/1" do
    @tag :tmp_dir
    test "creates a function called create_file_1/2", %{tmp_dir: tmp_dir} do
      vial = %Vial{cwd: tmp_dir}

      func = @subject.create_file("hello.txt", "Hi there")
      func.(vial)

      assert File.read!(Path.join(tmp_dir, "hello.txt")) == "Hi there"
    end
  end
end
