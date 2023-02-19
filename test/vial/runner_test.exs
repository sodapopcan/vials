defmodule Vial.RunnerTest do
  use ExUnit.Case

  @subject Vial.Runner

  describe "function action" do
    test "calls the function" do
      vial = %Vial{cwd: "/"}

      vial = @subject.run(vial, fn v -> %{v | cwd: "/foo"} end)

      assert vial.cwd == "/foo"
    end
  end

  describe "create action" do
    @tag :tmp_dir
    test "creates a file", %{tmp_dir: tmp_dir} do
      vial = %Vial{cwd: tmp_dir}

      %Vial{} = @subject.run(vial, {:create, "hello.txt", "Hi there"})

      assert File.read!(Path.join(tmp_dir, "hello.txt")) == "Hi there"
    end
  end

  describe "edit action" do
    @tag :tmp_dir
    test "changes a file", %{tmp_dir: tmp_dir} do
      vial = %Vial{cwd: tmp_dir}

      path = Path.join(tmp_dir, "foo.txt")
      File.write(path, "I'm the first line\n")

      %Vial{} =
        @subject.run(
          vial,
          {:edit, "foo.txt",
           fn contents ->
             contents <> "I'm the second line\n"
           end}
        )

      contents = File.read!(path)

      assert contents == """
             I'm the first line
             I'm the second line
             """
    end

    @tag :tmp_dir
    test "accepts globs", %{tmp_dir: tmp_dir} do
      vial = %Vial{cwd: tmp_dir}
      path = Path.join(tmp_dir, "20200823000000_some_file.txt")
      File.write!(path, "")

      %Vial{} = @subject.run(vial, {:edit, "*_some_file.txt", fn _ -> "edited" end})

      assert File.read!(path) == "edited"
    end

    @tag :tmp_dir
    test "errors on multiple glob matches", %{tmp_dir: tmp_dir} do
      vial = %Vial{cwd: tmp_dir}
      path_1 = Path.join(tmp_dir, "apples_and_organes.txt")
      path_2 = Path.join(tmp_dir, "apples_and_bananas.txt")
      File.write!(path_1, "")
      File.write!(path_2, "")

      vial = @subject.run(vial, {:edit, "apples_and_*.txt", &Function.identity/1})

      assert "Globs must match exactly one file" in vial.errors
    end

    test "returns errors" do
      vial = %Vial{cwd: "./"}

      vial = @subject.run(vial, {:edit, "non-existent-file.txt", &Function.identity/1})

      assert ["File not found: " <> _] = vial.errors
    end
  end

  describe "delete action" do
    @tag :tmp_dir
    test "deletes a file", %{tmp_dir: tmp_dir} do
      vial = %Vial{cwd: tmp_dir}
      path = Path.join(tmp_dir, "foo.txt")
      File.write!(path, "")

      @subject.run(vial, {:delete, "foo.txt"})

      assert {:error, _} = File.read(path)
    end
  end
end
