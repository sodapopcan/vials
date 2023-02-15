defmodule Vial do
  defmacro __using__(_) do
    quote do
      dbg __MODULE__

      @before_compile Vial
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

      def task do
        @task
      end
    end
  end
end
