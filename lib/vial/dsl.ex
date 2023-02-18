defmodule Vial.DSL do
  use Agent

  defmacro __using__(_) do
    quote do
      @before_compile unquote(Vial.DSL)

      Agent.start_link(fn -> [] end, name: unquote(Vial.DSL))

      import unquote(Vial.DSL)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def actions do
        Agent.get(Vial.DSL, & &1) |> Enum.reverse()
      end
    end
  end

  defp add(func) do
    Agent.update(__MODULE__, &[func | &1])
  end

  def cd(path) do
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
end
