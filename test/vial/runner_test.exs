defmodule Vial.RunnerTest do
  use ExUnit.Case

  @subject Vial.Runner

  describe "function action" do
    test "calls the function" do
      context = %Vial.Context{base_path: "/"}

      context = @subject.run(context, fn v -> %{v | base_path: "/foo"} end)

      assert context.base_path == "/foo"
    end
  end

  describe "create action" do
    @tag :tmp_dir
    test "creates a file", %{tmp_dir: tmp_dir} do
      context = %Vial.Context{base_path: tmp_dir}

      %Vial.Context{} = @subject.run(context, {:create, "hello.txt", "Hi there"})

      assert File.read!(Path.join(tmp_dir, "hello.txt")) == "Hi there"
    end
  end

  describe "edit action" do
    @tag :tmp_dir
    test "changes a file", %{tmp_dir: tmp_dir} do
      context = %Vial.Context{base_path: tmp_dir}

      path = Path.join(tmp_dir, "foo.txt")
      File.write(path, "I'm the first line\n")

      %Vial.Context{} =
        @subject.run(
          context,
          {:edit, "foo.txt", &(&1 <> "I'm the second line\n")}
        )

      contents = File.read!(path)

      assert contents == """
             I'm the first line
             I'm the second line
             """
    end

    @tag :tmp_dir
    test "accepts globs", %{tmp_dir: tmp_dir} do
      context = %Vial.Context{base_path: tmp_dir}
      path = Path.join(tmp_dir, "20200823000000_some_file.txt")
      File.write!(path, "")

      %Vial.Context{} = @subject.run(context, {:edit, "*_some_file.txt", fn _ -> "edited" end})

      assert File.read!(path) == "edited"
    end

    @tag :tmp_dir
    test "errors on multiple glob matches", %{tmp_dir: tmp_dir} do
      context = %Vial.Context{base_path: tmp_dir}
      path_1 = Path.join(tmp_dir, "apples_and_organes.txt")
      path_2 = Path.join(tmp_dir, "apples_and_bananas.txt")
      File.write!(path_1, "")
      File.write!(path_2, "")

      context = @subject.run(context, {:edit, "apples_and_*.txt", &Function.identity/1})

      assert "Globs must match exactly one file" in context.errors
    end

    test "returns errors" do
      context = %Vial.Context{base_path: "./"}

      context = @subject.run(context, {:edit, "non-existent-file.txt", &Function.identity/1})

      assert ["File not found: " <> _] = context.errors
    end
  end

  describe "delete action" do
    @tag :tmp_dir
    test "deletes a file", %{tmp_dir: tmp_dir} do
      context = %Vial.Context{base_path: tmp_dir}
      path = Path.join(tmp_dir, "foo.txt")
      File.write!(path, "")

      @subject.run(context, {:delete, "foo.txt"})

      assert {:error, _} = File.read(path)
    end
  end
end
