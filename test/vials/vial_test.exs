defmodule Vials.VialTest do
  use ExUnit.Case

  require Vials.Vial

  @subject Vials.Vial

  setup do
    start_supervised(Vials.Vial)
    :ok
  end

  describe "base_path/1" do
    test "returns vial struct with new base_path" do
      context = %Vials.Context{base_path: "/"}

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
    test "returns an edit messages" do
      assert {:edit, "mix.exs", func} = @subject.add_dep({:some_dep, "~> 0.0.0"})
      assert is_function(func, 1)
    end
  end

  describe "remove_comments/0" do
    test "returns an edit message with a recursive glob" do
      assert @subject.remove_comments() ==
               {:edit, "**/*.{ex,exs}", &Vials.Actions.remove_comments/1}
    end
  end

  describe "remove_comments/1" do
    test "returns an edit message with a filename" do
      assert @subject.remove_comments("foo.txt") ==
               {:edit, "foo.txt", &Vials.Actions.remove_comments/1}
    end

    test "returns and edit message when given a list" do
      assert @subject.remove_comments(~w[foo.txt bar.txt]) ==
               {:edit, ~w[foo.txt bar.txt], &Vials.Actions.remove_comments/1}
    end
  end
end
