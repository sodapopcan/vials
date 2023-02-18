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
    add({:create, filename, contents})
  end

  def edit_file(filename, func) do
    add({:edit, filename, func})
  end

  def delete_file(filename) do
    {:delete, filename}
  end

  def add_dep(dep) do
    last_dep_regex = ~r/defp deps do.*\n(\s+)(\{:.*?})\n/s

    func = fn contents ->
      [indent, last_dep] = Regex.run(last_dep_regex, contents, capture: :all_but_first)

      replacement = last_dep <> ",\n#{indent}" <> Vial.Util.dep_to_string(dep)
      String.replace(contents, last_dep, replacement)
    end

    add({:edit, "mix.exs", func})
  end
end
