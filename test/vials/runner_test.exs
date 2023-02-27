defmodule Vials.RunnerTest do
  use ExUnit.Case

  @subject Vials.Runner

  describe "function action" do
    test "calls the function" do
      context = %Vials.Context{base_path: "/"}

      context = @subject.run(context, fn v -> %{v | base_path: "/foo"} end)

      assert context.base_path == "/foo"
    end
  end

  describe "create action" do
    @tag :tmp_dir
    test "creates a file", %{tmp_dir: tmp_dir} do
      context = %Vials.Context{base_path: tmp_dir}

      %Vials.Context{} = @subject.run(context, {:create, "hello.txt", "Hi there"})

      assert File.read!(Path.join(tmp_dir, "hello.txt")) == "Hi there"
    end
  end

  describe "edit action" do
    @tag :tmp_dir
    test "changes a file", %{tmp_dir: tmp_dir} do
      context = %Vials.Context{base_path: tmp_dir}

      path = Path.join(tmp_dir, "foo.txt")
      File.write(path, "I'm the first line\n")

      %Vials.Context{} =
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
      context = %Vials.Context{base_path: tmp_dir}

      [file_1, file_2] =
        ~w[20200823000000_some_file.txt 20200823000001_some_file.txt]
        |> Enum.map(&Path.join(tmp_dir, &1))
        |> Enum.map(fn filename ->
          File.write!(filename, "")
          filename
        end)

      %Vials.Context{} = @subject.run(context, {:edit, "*_some_file.txt", fn _ -> "edited" end})

      assert File.read!(file_1) == "edited"
      assert File.read!(file_2) == "edited"
    end

    @tag :tmp_dir
    test "accepts a list", %{tmp_dir: tmp_dir} do
      context = %Vials.Context{base_path: tmp_dir}

      [file_1, file_2] =
        ~w[file_1.txt file_1.txt]
        |> Enum.map(&Path.join(tmp_dir, &1))
        |> Enum.map(fn filename ->
          File.write!(filename, "")
          filename
        end)

      %Vials.Context{} = @subject.run(context, {:edit, ~w[file_1.txt file_2.txt], fn _ -> "edited" end})

      assert File.read!(file_1) == "edited"
      assert File.read!(file_2) == "edited"
    end

    test "returns errors" do
      context = %Vials.Context{base_path: "./"}

      context = @subject.run(context, {:edit, "non-existent-file.txt", &Function.identity/1})

      assert ["No matches for glob \"non-existent-file.txt\""] = context.errors
    end
  end

  describe "remove action" do
    @tag :tmp_dir
    test "removes a file", %{tmp_dir: tmp_dir} do
      context = %Vials.Context{base_path: tmp_dir}
      path = Path.join(tmp_dir, "foo.txt")
      :ok = File.touch(path)

      @subject.run(context, {:remove, "foo.txt"})

      assert {:error, :enoent} = File.read(path)
    end

    @tag :tmp_dir
    test "accepts a glob", %{tmp_dir: tmp_dir} do
      context = %Vials.Context{base_path: tmp_dir}
      file_1 = Path.join(tmp_dir, "foo_1.txt")
      file_2 = Path.join(tmp_dir, "foo_2.txt")
      :ok = File.touch(file_1)
      :ok = File.touch(file_2)

      @subject.run(context, {:remove, "foo_*.txt"})

      assert {:error, _} = File.read(file_1)
      assert {:error, _} = File.read(file_1)
    end
  end
end
