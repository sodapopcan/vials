defmodule Vial do
  defmacro __using__(_) do
    quote do
      @before_compile Vial

      @options []

      import Vial
    end
  end

  defmacro __before_compile__(_) do
    quote do
      module_parts = __MODULE__ |> Atom.to_string() |> String.split(".")

      @task \
        Enum.reduce(module_parts, [], fn
          "VialTest", acc -> acc
          "Elixir", acc -> acc
          "Vials", acc -> acc
          other, acc -> acc ++ [String.downcase(other)]
        end)
        |> Enum.join(".")

      def command do
        [
          "mix",
          @task,
          Enum.join(@options, " ")
        ]
        |> Enum.reject(& &1 == "")
        |> Enum.join(" ")
      end
    end
  end
end
