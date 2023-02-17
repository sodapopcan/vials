defmodule Vial do
  defstruct [:module, :cwd, :task, :task_args, :options]

  def load(args) do
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
      cwd: File.cwd!(),
      task: task,
      task_args: task_args,
      options: options
    }
  end

#   def run_actions(vial) do
#     do_run_actions(vial, vial.module.actions())
#   end

#   def do_run_actions(vial, []), do: vial

#   def do_run_actions(vial, [action | actions]) do
#     vial = run_action(vial, action)
#     do_run_actions(vial, actions)
#   end

#   def run_action(vial, {:create_file, [filename, contents]}) do
#     # File.write!(Path.join(vial.cwd, ))
#   end
end
