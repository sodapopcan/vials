defmodule Vial do
  defstruct [
    :module_location,
    :module,
    :cwd,
    :task,
    :task_args,
    :raw_task_args,
    :options,
    :args,
    :variables,
    errors: []
  ]

  defmodule Args do
    use Agent

    def start_link(args) do
      Agent.start_link(fn -> args end, name: __MODULE__)
    end

    def get do
      Agent.get(__MODULE__, & &1)
    end
  end

  def run(args) do
    vial = Vial.parse(args)

    Vial.Args.start_link(vial.args)

    path = Path.join(vial.module_location, "#{vial.task}.ex")
    {:ok, ast} = Code.string_to_quoted(File.read!(path))
    {:defmodule, line, [aliases | [[do: {:__block__, [], body}]]]} = ast
    args = Macro.escape(vial.args)
    new = quote(do: (@args unquote(args)))
    body = [new | body]
    ast = {:defmodule, line, [aliases | [[do: {:__block__, [], body}]]]}

    [{module, _}] = Code.compile_quoted(ast)

    vial = %{vial | module: module}

    Mix.Task.run(vial.task, vial.raw_task_args)

    run_actions(vial, Vial.DSL.get())
  end

  defp run_actions(vial, []), do: vial

  defp run_actions(vial, [action | actions]) do
    vial = Vial.Runner.run(vial, action)

    run_actions(vial, actions)
  end

  def parse(args) do
    {vial_options, rest} =
      OptionParser.parse_head!(args,
        switches: [location: :string],
        aliases: [l: :location]
      )

    [_ | raw_task_args] = rest

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
        if Mix.env() == :test do
          "tmp"
        else
          Path.join(System.user_home(), "vials")
        end
      end

    args =
      task_args
      |> Enum.with_index()
      |> Enum.map(fn {arg, index} -> {:"_#{index + 1}", arg} end)
      |> Enum.into(%{})
      |> Map.merge(Enum.into(options, %{}))

    %Vial{
      module: nil,
      module_location: module_location,
      cwd: if(Mix.env() == :test, do: "tmp", else: File.cwd!()),
      task: task,
      task_args: task_args,
      raw_task_args: raw_task_args,
      options: options,
      args: args
    }
  end

  defmacro __using__(_) do
    quote do
      # @args Args.get()
      Vial.DSL.start_link()
      import Vial.DSL, except: [start_link: 1, start_link: 2]
    end
  end
end
