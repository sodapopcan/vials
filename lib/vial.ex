defmodule Vial do
  def load_module(task, path) do
    path = Path.join(path, "#{task}.ex")

    [{mod, _}] = Code.compile_file(path)

    mod
  end

  defmacro __using__(_) do
    quote do
      @before_compile Vial

      @options []

      import Vial
    end
  end

  defmacro __before_compile__(_) do
    quote do
      @task \
        __MODULE__
        |> Atom.to_string()
        |> String.replace(~r/\AElixir\.Vials\./, "")
        |> String.split(".")
        |> Enum.map(&String.downcase/1)
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
