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
    test "return a create message" do
      assert {:create, "hello.txt", "Hi there"} = @subject.create_file("hello.txt", "Hi there")
    end
  end

  describe "edit_file/2" do
    test "return an edit message" do
      assert {:edit, "foo.txt", func} = @subject.edit_file("foo.txt", &(&1 <> "!"))

      assert func.("hi") == "hi!"
    end
  end

  describe "delete_file/1" do
    test "returns a delete message" do
      assert {:delete, "foo.txt"} = @subject.delete_file("foo.txt")
    end
  end

  describe "add_dep/1" do
    test "adds deps to deps list in mix.exs" do
      mix_exs = """
      defp deps do
        [
          {:one, "~> 0.0.3"},
          {:two, "~> 1.1.1"},
          {:three, "~> 1.1.1"}
        ]
      end
      """

      {:edit, "mix.exs", func} = @subject.add_dep({:four, "~> 0.0.1"})

      expected = """
      defp deps do
        [
          {:one, "~> 0.0.3"},
          {:two, "~> 1.1.1"},
          {:three, "~> 1.1.1"},
          {:four, "~> 0.0.1"}
        ]
      end
      """

      assert func.(mix_exs) == expected
    end
  end
end
