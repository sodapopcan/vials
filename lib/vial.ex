defmodule Vial do
  defstruct [:module, :cwd, :task, :options]

  def load(args) do
    {vial_options, rest} =
      OptionParser.parse_head!(args,
        switches: [location: :string],
        aliases: [l: :location]
      )

    {options, [task | _], _} =
      OptionParser.parse(rest,
        switches: [],
        allow_nonexistent_atoms: true
      )

    location =
      if vial_options[:location] do
        vial_options[:location]
      else
        if Mix.env() == :test, do: "tmp", else: "tmp"
      end

    path = Path.join(location, "#{task}.ex")
    [{module, _}] = Code.compile_file(path)

    %Vial{
      module: module,
      cwd: location,
      task: task,
      options: options
    }
  end
end
