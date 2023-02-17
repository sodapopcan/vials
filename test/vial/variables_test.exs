defmodule Vial.VariablesTest do
  use ExUnit.Case

  @subject Vial.Variables

  describe "run/2" do
    test "interpolates {$1}" do
      variables = %{:"1" => "what"}
      string = "That's {$1} they say"

      result = @subject.interpolate(variables, string)

      assert result == "That's what they say"
    end

    test "interolates {$binary_id}" do
      variables = %{binary_id: "some-binary-id"}
      string = "My id: {$binary_id}"

      result = @subject.interpolate(variables, string)

      assert result == "My id: some-binary-id"
    end
  end
end
