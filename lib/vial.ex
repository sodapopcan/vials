defmodule Vial do
  defmodule VialException do
    defexception [:message]
  end

  defmodule Context do
    defstruct base_path: File.cwd!(),
              errors: [],
              log: []

    def new(opts) do
      Map.merge(%Context{}, Enum.into(opts, %{}))
    end
  end

  def run(args) do
    {vial_opts, raw_task_args} = parse_vial_opts(args)
    context = Context.new(vial_opts)

    task_args = parse_task_args(raw_task_args)
    escaped_args = Macro.escape(task_args)
    module_attr_ast = quote(do: (@args unquote(escaped_args)))

     with {:ok, path} <- get_path(vial_opts),
          {:ok, file} <- read_file(path, "#{task_args._0}.ex"),
          {:ok, ast} <- Code.string_to_quoted(file),
          {:ok, ast} <- Vial.Util.inject_into_module_body(ast, module_attr_ast),
          {:ok, _module} <- compile(ast) do
       case raw_task_args do
         [task_name | raw_task_args] -> Mix.Task.run(task_name, raw_task_args)
         [task_name] -> Mix.Task.run(task_name)
       end
       run_actions(context, Vial.DSL.get())
     else
       {:error, message} ->
         raise VialException, message: message
     end
  end

  def parse_vial_opts(args) do
    OptionParser.parse_head!(args,
      switches: [location: :string],
      aliases: [l: :location]
    )
  end

  def parse_task_args(args) do
    {opts, args, _} =
      OptionParser.parse(args,
        switches: [],
        allow_nonexistent_atoms: true
      )

    target =
      case args do
        [_, target | _] -> target
        [_] -> nil
      end

    args
    |> Enum.with_index()
    |> Enum.map(fn {arg, index} -> {:"_#{index}", arg} end)
    |> Enum.into(%{target: target})
    |> Map.merge(Enum.into(opts, %{}))
  end

  def get_path(_vial_opts \\ []) do
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

  def read_file(path, filename) do
    path
    |> Path.join(filename)
    |> File.read()
  end

  def compile(ast) do
    [{module, _}] = Code.compile_quoted(ast)

    {:ok, module}
  rescue
    e ->
      {:error, e.description}
  end

  defp run_actions(vial, []), do: vial

  defp run_actions(vial, [action | actions]) do
    vial = Vial.Runner.run(vial, action)

    run_actions(vial, actions)
  end

  defmacro __using__(_) do
    quote do
      Vial.DSL.start_link([])
      import Vial.DSL, except: [start_link: 1]
    end
  end
end
