defmodule Vial.DSLTest do
  use ExUnit.Case

  require Vial.DSL

  @subject Vial.DSL

  setup do
    start_supervised(Vial.DSL)
    :ok
  end

  describe "base_path/1" do
    test "returns vial struct with new base_path" do
      context = %Vial.Context{base_path: "/"}

      func = @subject.base_path("/some/other/dir")
      context = func.(context)

      assert context.base_path == "/some/other/dir"
    end
  end

  describe "create/2" do
    test "return a create message" do
      assert {:create, "hello.txt", "Hi there"} = @subject.create("hello.txt", "Hi there")
    end

    test "transforms a block to an ast" do
      {:create, _, contents} =
        @subject.create "mod.ex" do
          defmodule F do
            def hi do
              "hi"
            end
          end
        end

      assert contents == """
             defmodule F do
               def hi do
                 "hi"
               end
             end\
             """
    end
  end

  describe "edit/2" do
    test "return an edit message" do
      assert {:edit, "foo.txt", func} = @subject.edit("foo.txt", &(&1 <> "!"))

      assert func.("hi") == "hi!"
    end
  end

  describe "remove/1" do
    test "returns a remove message" do
      assert {:remove, "foo.txt"} = @subject.remove("foo.txt")
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

  describe "remove_comments/0" do
    test "returns and edit message with a recursive glob" do
      assert @subject.remove_comments() == {:edit, "**/*.{ex,exs}", &Vial.Actions.remove_comments/1}
    end
  end
end
