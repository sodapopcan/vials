defmodule Vial.Variables do
  def interpolate(variables, string) do
    matches = Regex.scan(~r/\{\$([[:word:]]+)\|?([[:word:]]+)?\}/, string)
    replace(variables, string, matches)
  end

  defp replace(_variables, string, []), do: string

  defp replace(variables, string, [[match, key]]) do
    variable = variables[String.to_atom(key)]
    String.replace(string, match, variable)
  end

  defp replace(variables, string, [[match, key, filter]]) do
    variable = variables[String.to_atom(key)]
    variable = apply_filter(filter, variable)

    String.replace(string, match, variable)
  end

  defp apply_filter("camelize", variable) do
    Macro.camelize(variable)
  end
end
