defmodule Vial.Actions do
  def remove_comments(string) do
    string
    |> String.split("\n")
    |> Enum.reject(& &1 =~ ~r/\A(\s+)?#/)
    |> Enum.join("\n")
  end
end
