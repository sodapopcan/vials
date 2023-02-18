defmodule Vial.DSL do
  defmodule Counter do
    use Agent

    def start_link do
      Agent.start_link(fn -> 0 end, name: __MODULE__)
    end

    def next do
      Agent.update(__MODULE__, & &1 + 1)
      Agent.get(__MODULE__, & &1)
    end
  end

  defmacro __using__(args) do
    Counter.start_link()

    quote do
      @before_compile Vial.DSL

      @counter 0
      @actions []

      @args unquote(args)

      import Vial.DSL
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def actions do
        Enum.reverse(@actions)
      end
    end
  end

  defmacro cd(path) do
    func_name = :"cd_#{Counter.next()}"

    quote do
      @actions [unquote(func_name) | @actions]
      def unquote(func_name)(vial) do
        path = Path.join(vial.cwd, unquote(path))
        Map.put(vial, :cwd, path)
      end
    end
  end

  defmacro create_file(filename, contents) do
    func_name = :"create_file_#{Counter.next()}"

    quote do
      @actions [unquote(func_name) | @actions]
      def unquote(func_name)(vial) do
        path = Path.join(vial.cwd, unquote(filename))
        File.write!(path, unquote(contents))
      end
    end
  end
end
