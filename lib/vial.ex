defmodule Vial do
  def mix(command, do: block) do
    "mix " <> command <> " " <> block
  end
end
