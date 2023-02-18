defmodule Vial.DSLTest do
  use ExUnit.Case

  @subject Vial.DSL

  setup do
    start_supervised(Vial.DSL)
    :ok
  end

  describe "base_path/1" do
    test "returns vial struct with new cwd" do
      vial = %Vial{cwd: "/"}

      func = @subject.base_path("/some/other/dir")
      vial = func.(vial)

      assert vial.cwd == "/some/other/dir"
    end
  end

  describe "create_file/2" do
    @tag :tmp_dir
    test "creates a file", %{tmp_dir: tmp_dir} do
      vial = %Vial{cwd: tmp_dir}

      func = @subject.create_file("hello.txt", "Hi there")
      func.(vial)

      assert File.read!(Path.join(tmp_dir, "hello.txt")) == "Hi there"
    end
  end

  describe "edit_file/2" do
    @tag :tmp_dir
    test "changes a file", %{tmp_dir: tmp_dir} do
      vial = %Vial{cwd: tmp_dir}

      path = Path.join(tmp_dir, "foo.txt")
      File.write(path, "I'm the first line\n")

      func =
        @subject.edit_file("foo.txt", fn contents ->
          contents <> "I'm the second line\n"
        end)

      {:ok, edits} = func.(vial)

      contents = File.read!(path)

      assert contents == """
      I'm the first line
      I'm the second line
      """

      assert contents == edits
    end
  end
end
