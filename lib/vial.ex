defmodule Vial do
  defmacro mix(command, do: block) do
    options = elem(block, 2) |> Enum.join(" ")

    "mix " <> command <> " " <> options
  end
end
