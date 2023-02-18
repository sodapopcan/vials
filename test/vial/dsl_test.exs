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

    @tag :tmp_dir
    test "accepts globs", %{tmp_dir: tmp_dir} do
      vial = %Vial{cwd: tmp_dir}
      path = Path.join(tmp_dir, "20200823000000_some_file.txt")
      File.write(path, "")

      func = @subject.edit_file("*_some_file.txt", fn _ -> "edited" end)
      {:ok, edits} = func.(vial)

      assert edits == "edited"
    end

    @tag :tmp_dir
    test "errors on multiple glob matches", %{tmp_dir: tmp_dir} do
      vial = %Vial{cwd: tmp_dir}
      path_1 = Path.join(tmp_dir, "apples_and_organes.txt")
      path_2 = Path.join(tmp_dir, "apples_and_bananas.txt")
      File.write!(path_1, "")
      File.write!(path_2, "")

      func = @subject.edit_file("apples_and_*.txt", &Function.identity/1)

      assert {:error, "Globs must match exactly one file"} = func.(vial)
    end

    test "returns errors" do
      vial = %Vial{cwd: "./"}

      func = @subject.edit_file("non-existent-file.txt", &Function.identity/1)

      assert {:error, _} = func.(vial)
    end
  end
end
