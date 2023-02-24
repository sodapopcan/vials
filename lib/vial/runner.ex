defmodule Vial.Runner do
  def run(context, func) when is_function(func) do
    func.(context)
  end

  def run(context, {:create, filename, contents}) do
    path = Path.join(context.base_path, filename)

    File.write!(path, contents)

    context
  end

  def run(context, {:edit, filename, func}) when is_binary(filename) and is_function(func, 1) do
    glob = Path.join(context.base_path, filename)

    with [filename] <- Path.wildcard(glob),
         {:ok, contents} <- File.read(filename),
         edited <- func.(contents),
         :ok <- File.write(filename, edited) do
      context
    else
      [] ->
        %{context | errors: ["File not found: #{filename}" | context.errors]}

      [_ | _] ->
        %{context | errors: ["Globs must match exactly one file" | context.errors]}

      {:error, error} ->
        %{context | errors: [error | context.errors]}
    end
  end

  def run(context, {:delete, filename}) do
    path = Path.join(context.base_path, filename)

    File.rm(path)
  end
end
