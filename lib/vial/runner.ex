defmodule Vial.Runner do
  def run(context, func) when is_function(func) do
    func.(context)
  end

  def run(context, {:create, filename, contents}) do
    path = Path.join(context.base_path, filename)

    File.write!(path, contents)

    context
  end

  def run(context, {:edit, filenames, func}) when is_list(filenames) do
    filenames = Enum.map(filenames, &Path.join(context.base_path, &1))

    edit(context, filenames, func)
  end

  def run(context, {:edit, glob, func}) when is_binary(glob) and is_function(func, 1) do
    case context.base_path |> Path.join(glob) |> Path.wildcard() do
      [] -> %{context | errors: ["No matches for glob \"" <> glob <> "\""]}
      filenames -> edit(context, filenames, func)
    end
  end

  def run(context, {:remove, filename}) do
    path = Path.join(context.base_path, filename)

    File.rm(path)
  end

  defp edit(context, [], _func), do: context

  defp edit(context, [filename | filenames], func) do
    context =
      with {:ok, contents} <- File.read(filename),
           edited <- func.(contents),
           :ok <- File.write(filename, edited) do
        context
      else
        {:error, error} ->
          %{context | errors: [error | context.errors]}
      end

    edit(context, filenames, func)
  end
end
