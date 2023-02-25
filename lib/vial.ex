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

  def main(args) do
    {vial_opts, raw_task_args} = parse_vial_opts(args)
    context = Context.new(vial_opts)

    task_args = parse_task_args(raw_task_args)

    with {:ok, path} <- get_path(vial_opts),
         {:ok, file} <- read_file(path, "#{task_args.task_name}.ex"),
         {:ok, ast} <- Code.string_to_quoted(file),
         {:ok, ast} <- inject_task_args(ast, task_args),
         {:ok, _module} <- compile(ast) do
      cmd = Enum.join(["mix" | raw_task_args], " ")
      {_output, 0} = System.shell(cmd, close_stdin: true, into: IO.stream())

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

    task_name = List.first(args)
    target = Enum.at(args, 1)

    %{
      opts: Enum.into(opts, %{}),
      args: args,
      task_name: task_name,
      target: target
    }
  end

  def get_path(_vial_opts \\ []) do
    home = Vial.Util.user_home()

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

  def inject_task_args(ast, task_args) do
    args = Macro.escape(task_args.args)
    opts = Macro.escape(task_args.opts)
    task_name = Macro.escape(task_args.task_name)
    target = Macro.escape(task_args.target)

    quoted =
      quote do
        @args unquote(args)
        @opts unquote(opts)
        @task_name unquote(task_name)
        @target unquote(target)
      end

    {ast, _} =
      Macro.prewalk(ast, false, fn
        [do: block], false ->
          {[do: [quoted | List.wrap(block)]], true}

        other, acc ->
          {other, acc}
      end)

    {:ok, ast}
  end

  def compile(ast) do
    [{module, _}] = Code.compile_quoted(ast)

    {:ok, module}
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
