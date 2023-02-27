defmodule Vials.UtilTest do
  use ExUnit.Case

  @subject Vials.Util

  describe "dep_to_string/1" do
    test "converts a dependency tuple to a string" do
      dep = {:dep, "~> 0.0.1"}

      string = @subject.dep_to_string(dep)

      assert string == "{:dep, \"~> 0.0.1\"}"
    end
  end
end
