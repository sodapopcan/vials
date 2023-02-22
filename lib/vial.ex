defmodule Vial do
  defmodule VialException do
    defexception [:message]
  end

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
    defstruct base_path: File.cwd!(),
              errors: [],
              log: []

    def new(opts) do
      Map.merge(%Context{}, opts)
    end
  end

  def run(args) do
    {vial_opts, rest} = parse_vial_opts(args)
    _context = Context.new(vial_opts)

    [task_name | raw_task_args] = rest
    _task_args = parse_task_args(raw_task_args)

#     with {:ok, path} <- get_path(vial_opts),
#          {:ok, file} <- get_file(path, task_name),
#          {:ok, vial} <- load_module(file),
#          {:ok, vial} <- inject_args(vial, task_args),
#          {:ok, vial} <- compile_module(vial),
#          {:ok, vial} <- validate(vial) do
#       run_task(task_name, raw_task_args)
#       run_actions(context, vial.actions())
#     else
#       {:error, error} ->
#         raise error
#     end
  end

  def parse_vial_opts(args) do
    OptionParser.parse_head!(args,
      switches: [location: :string],
      aliases: [l: :location]
    )
  end

  def parse_task_args(args) do
    {args, opts, _} =
      OptionParser.parse(args,
        switches: [],
        allow_nonexistent_atoms: true
      )

    {args, opts}
  end

  def get_path(vial_opts \\ []) do
    home = Application.get_env(:vial, :user_home).()

    dirs = [
      System.get_env("VIALS_PATH") |> to_string(),
      Path.join([home, ".vials"]),
      Path.join([home, "vials"])
    ]

    case Enum.filter(dirs, &File.exists?/1) do
      [module_path | _] ->
        {:ok, module_path}

      [] ->
        {:error,
         "No path found.  Please create one of `~/vials` or `~/.vials` or set VIALS_PATH."}
    end
  end

  ####################

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
    module_attr_ast = quote(do: @args(unquote(args)))

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
