defmodule Vial.DSL do
  use Agent

  defmacro __using__(_) do
    quote do
      @before_compile Vial.DSL

      Vial.DSL.start_link([])

      import Vial.DSL
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def actions do
        Agent.get(Vial.DSL, & &1) |> Enum.reverse()
      end
    end
  end

  def start_link(_) do
    Agent.start_link(fn -> [] end, name: Vial.DSL)
  end

  defp add(func) do
    Agent.update(__MODULE__, &[func | &1])
    func
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
