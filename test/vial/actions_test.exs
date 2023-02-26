defmodule Vial.ActionsTest do
  use ExUnit.Case

  @subject Vial.Actions

  describe "remove comments" do
    test "it removes comments from the given string" do
      string = """
      # I'm a comment
      # and I continue on
      # with commenting
      def some_code(a_fn_with_args) do
        # I'm commenting again why not
        do_the_thing_to(a_fn_with_args)
      end
      """

      result = @subject.remove_comments(string)

      assert result == """
      def some_code(a_fn_with_args) do
        do_the_thing_to(a_fn_with_args)
      end
      """
    end
  end
end
