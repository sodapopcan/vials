defmodule Vial.Variables do
  def interpolate(variables, string) do
    matches = Regex.scan(~r/\{\$([[:word:]]+)\}/, string)
    replace(variables, string, matches)
  end

  defp replace(_variables, string, []), do: string

  defp replace(variables, string, [[match, key] | _]) do
    variable = variables[String.to_atom(key)]
    String.replace(string, match, variable)
  end
end
