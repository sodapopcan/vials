defmodule Vial do
  defstruct [:module_location, :module, :cwd, :task, :task_args, :options, :args, :variables]

  defmodule Args do
    use Agent

    def start_link(args) do
      Agent.start_link(fn -> args end, name: __MODULE__)
    end

    def get do
      Agent.get(__MODULE__, & &1)
    end
  end

  defdelegate start_link(args), to: Args

  def parse(args) do
    {vial_options, rest} =
      OptionParser.parse_head!(args,
        switches: [location: :string],
        aliases: [l: :location]
      )

    {options, task_data, _} =
      OptionParser.parse(rest,
        switches: [],
        allow_nonexistent_atoms: true
      )

    [task | task_args] = task_data

    module_location =
      if vial_options[:location] do
        vial_options[:location]
      else
        if Mix.env() == :test, do: "tmp", else: "tmp"
      end

    args =
      task_args
      |> Enum.with_index()
      |> Enum.map(fn {arg, index} -> {:"#{index + 1}", arg} end)
      |> Enum.into(%{})
      |> Map.merge(Enum.into(options, %{}))

    %Vial{
      module: nil,
      module_location: module_location,
      cwd: File.cwd!(),
      task: task,
      task_args: task_args,
      options: options,
      args: args
    }
  end

  def load(vial) do
    path = Path.join(vial.module_location, "#{vial.task}.ex")
    [{module, _}] = Code.compile_file(path)

    %{vial | module: module}
  end

  def run(args) do
    vial = Vial.parse(args)

    Vial.start_link(vial.args)

    vial = Vial.load(vial)

    Mix.Task.run(vial.task)

    for action <- vial.module.actions() do
      apply(vial.module, action, [vial])
    end
  end

  defmacro __using__(_) do
    quote do
      use Vial.DSL, Args.get()
    end
  end
end
