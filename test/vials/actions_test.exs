defmodule Vials.ActionsTest do
  use ExUnit.Case

  @subject Vials.Actions

  describe "remove comments" do
    test "it removes comments from the given string" do
      string = ~S'''
      # I'm a comment
      # and I continue on
      # with commenting
      @doc """
      ## Examples
      # Comment in docstring
      """
      def some_code(a_fn_with_args) do
        # I'm commenting again why not
        do_the_thing_to(a_fn_with_args)
      end
      '''

      result = @subject.remove_comments(string)

      assert result == ~S'''
            @doc """
            ## Examples
            # Comment in docstring
            """
            def some_code(a_fn_with_args) do
              do_the_thing_to(a_fn_with_args)
            end
            '''
    end
  end

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

    result = @subject.add_dep(mix_exs, {:four, "~> 0.0.1"})

    assert result == """
           defp deps do
             [
               {:one, "~> 0.0.3"},
               {:two, "~> 1.1.1"},
               {:three, "~> 1.1.1"},
               {:four, "~> 0.0.1"}
             ]
           end
           """
  end
end
