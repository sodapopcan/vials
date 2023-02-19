defmodule Vial.UtilTest do
  use ExUnit.Case

  @subject Vial.Util

  describe "dep_to_string/1" do
    test "converts a dependency tuple to a string" do
      dep = {:dep, "~> 0.0.1"}

      string = @subject.dep_to_string(dep)

      assert string == "{:dep, \"~> 0.0.1\"}"
    end
  end

  describe "inject_into_module_body" do
    test "injects code into a module's body" do
      ast =
        Code.string_to_quoted!("""
        defmodule Vial.UtilTest.Inject do
        end
        """)

      quoted =
        quote do
          def hi do
            "hi"
          end
        end

      [{mod, _}] =
        ast
        |> @subject.inject_into_module_body(quoted)
        |> Code.compile_quoted()

      assert mod.hi() == "hi"
    end

    test "injects at the top of the module's body" do
      ast =
        Code.string_to_quoted!("""
        defmodule Vial.UtilTest.InjectTop do
          def hi do
            @hi
          end
        end
        """)

      quoted =
        quote do
          @hi "hi"
        end

      [{mod, _}] =
        ast
        |> @subject.inject_into_module_body(quoted)
        |> Code.compile_quoted()

      assert mod.hi() == "hi"
    end
  end
end
