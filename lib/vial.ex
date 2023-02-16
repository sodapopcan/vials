defmodule Vial do
  defstruct [:module, :task, :options]

  def load(args) do
    {vial_options, rest} =
      OptionParser.parse_head!(args,
        switches: [location: :string],
        aliases: [l: :location]
      )

    {options, [task | _], _} =
      OptionParser.parse(rest,
        allow_nonexistent_atoms: true
      )

    location = vial_options[:location]
    path = Path.join(location, "#{task}.ex")
    [{module, _}] = Code.compile_file(path)

    %Vial{
      module: module,
      task: task,
      options: options
    }
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
      @task __MODULE__
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
        |> Enum.reject(&(&1 == ""))
        |> Enum.join(" ")
      end
    end
  end
end
