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

  defmodule Context do
    defstruct [
      base_path: File.cwd!(),
      errors: [],
      log: []
    ]

    def new(opts) do
      Map.merge(%Context{}, opts)
    end
  end

  def run(args) do
    {vial_opts, rest} = parse_vial_opts(args)
    context = Context.new(vial_opts)

    [task_name | raw_task_args] = rest
    task_args = parse_task_args(rest)

    vial_module = load_vial(vial_opts, task_args)

    validate!(vial_module)

    Mix.Task.run(task_name, raw_task_args)

    run_actions(vial_module)

    ######
    vial = Vial.parse(args)

    Mix.Task.run(vial.task, vial.raw_task_args)

    vial = load(vial)

    run_actions(vial, Vial.DSL.get())
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

  def load(vial) do
    path = Path.join(vial.module_location, "#{vial.task}.ex")
    {:ok, ast} = Code.string_to_quoted(File.read!(path))
    args = Macro.escape(vial.args)
    module_attr_ast = quote(do: (@args unquote(args)))

    ast = Vial.Util.inject_into_module_body(ast, module_attr_ast)

    [{module, _}] = Code.compile_quoted(ast)

    %{vial | module: module}
  end

  defp run_actions(vial, []), do: vial

  defp run_actions(vial, [action | actions]) do
    vial = Vial.Runner.run(vial, action)

    run_actions(vial, actions)
  end

  defmacro __using__(_) do
    quote do
      Vial.DSL.start_link([])
      import Vial.DSL, except: [start_link: 2]
    end
  end
end
