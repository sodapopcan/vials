defmodule Vials.Runner do
  @moduledoc false

  def run(context, func) when is_function(func, 1) do
    func.(context)
  end

  def run(context, {:create, filename, contents}) do
    path = Path.join(context.base_path, filename)

    File.write!(path, contents)

    context
  end

  def run(context, {:edit, globs, func}) when is_list(globs) do
    edit(context, globs, func)
  end

  def run(context, {:edit, glob, func}) when is_binary(glob) and is_function(func, 1) do
    edit(context, glob, func)
  end

  def run(context, {:remove, glob_or_list}) do
    remove(context, glob_or_list)
  end

  defp edit(context, globs, func) when is_list(globs) do
    globs = Enum.map(globs, &Path.join(context.base_path, &1))

    do_edit(context, globs, func)
  end

  defp edit(context, glob, func) do
    case context.base_path |> Path.join(glob) |> Path.wildcard() do
      [] -> %{context | errors: ["No matches for glob \"" <> glob <> "\""]}
      filenames -> do_edit(context, filenames, func)
    end
  end

  defp do_edit(context, [], _func), do: context

  defp do_edit(context, [filename | filenames], func) do
    context =
      with {:ok, contents} <- File.read(filename),
           edited <- func.(contents),
           :ok <- File.write(filename, edited) do
        context
      else
        {:error, error} ->
          %{context | errors: [error | context.errors]}
      end

    do_edit(context, filenames, func)
  end

  defp remove(context, list) when is_list(list) do
    Enum.each(list, &remove(context, &1))
  end

  defp remove(context, glob) do
    files =
      context.base_path
      |> Path.join(glob)
      |> Path.wildcard()

    for file <- files, do: :ok = File.rm(file)
  end
end
