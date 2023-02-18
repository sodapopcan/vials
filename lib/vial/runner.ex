defmodule Vial.Runner do
  def run(vial, func) when is_function(func) do
    func.(vial)
  end

  def run(vial, {:create, filename, contents}) do
    path = Path.join(vial.cwd, filename)

    File.write!(path, contents)

    vial
  end

  def run(vial, {:edit, filename, func}) when is_binary(filename) and is_function(func, 1) do
    glob = Path.join(vial.cwd, filename)

    with [filename] <- Path.wildcard(glob),
         {:ok, contents} <- File.read(filename),
         edited <- func.(contents),
         :ok <- File.write(filename, edited) do
      vial
    else
      [] ->
        %{vial | errors: ["File not found: #{filename}" | vial.errors]}

      [_ | _] ->
        %{vial | errors: ["Globs must match exactly one file" | vial.errors]}

      {:error, error} ->
        %{vial | errors: [error | vial.errors]}
    end
  end

  def run(vial, {:delete, filename}) do
    path = Path.join(vial.cwd, filename)

    File.rm(path)
  end
end
