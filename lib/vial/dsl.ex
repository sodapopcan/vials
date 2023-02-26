defmodule Vial.DSL do
  use Agent

  def start_link([]) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def get do
    Agent.get(__MODULE__, & &1) |> Enum.reverse()
  end

  def add(message) do
    Agent.update(__MODULE__, &[message | &1])

    message
  end

  defmacro create(filename, do: ast) do
    contents = Sourceror.to_string(ast)

    quote do
      Vial.DSL.add({:create, unquote(filename), unquote(contents)})
    end
  end

  defmacro create(filename, contents) when is_binary(contents) do
    quote do
      Vial.DSL.add({:create, unquote(filename), unquote(contents)})
    end
  end

  def edit(filename, func) do
    add({:edit, filename, func})
  end

  def remove(filename) do
    add({:remove, filename})
  end

  def base_path(path) do
    add(fn context ->
      path = Path.join(context.base_path, path)
      Map.put(context, :base_path, path)
    end)
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

  def remove_comments do
    add({:edit, "**/*.{ex,exs}", &Vial.Actions.remove_comments/1})
  end

  def remove_comments(filename_or_filenames)
      when is_binary(filename_or_filenames) or is_list(filename_or_filenames) do
    add({:edit, filename_or_filenames, &Vial.Actions.remove_comments/1})
  end
end
