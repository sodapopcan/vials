defmodule Vial.DSL do
  use Agent

  def start_link, do: start_link(nil)

  def start_link(_) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def run_actions(vial) do
    for action <- Agent.get(__MODULE__, & &1) do
      action.(vial)
    end
  end

  defp add(func) do
    Agent.update(__MODULE__, &[func | &1])
    func
  end

  def base_path(path) do
    add(fn vial ->
      path = Path.join(vial.cwd, path)
      Map.put(vial, :cwd, path)
    end)
  end

  def create_file(filename, contents) do
    add(fn vial ->
      path = Path.join(vial.cwd, filename)
      File.write!(path, contents)
    end)
  end

  def edit_file(filename, func) do
    add(fn vial ->
      path = Path.join(vial.cwd, filename)

      with [filename] <- Path.wildcard(path),
           {:ok, contents} <- File.read(filename),
           edits <- func.(contents),
           :ok <- File.write(path, edits) do
        {:ok, edits}
      end
    end)
  end
end
