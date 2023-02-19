defmodule Vial.Runner do
  defstruct [
    :base_path,
    errors: []
  ]

  def run(runner, func) when is_function(func) do
    func.(runner)
  end

  def run(runner, {:create, filename, contents}) do
    path = Path.join(runner.cwd, filename)

    File.write!(path, contents)

    runner
  end

  def run(runner, {:edit, filename, func}) when is_binary(filename) and is_function(func, 1) do
    glob = Path.join(runner.cwd, filename)

    with [filename] <- Path.wildcard(glob),
         {:ok, contents} <- File.read(filename),
         edited <- func.(contents),
         :ok <- File.write(filename, edited) do
      runner
    else
      [] ->
        %{runner | errors: ["File not found: #{filename}" | runner.errors]}

      [_ | _] ->
        %{runner | errors: ["Globs must match exactly one file" | runner.errors]}

      {:error, error} ->
        %{runner | errors: [error | runner.errors]}
    end
  end

  def run(runner, {:delete, filename}) do
    path = Path.join(runner.cwd, filename)

    File.rm(path)
  end
end
