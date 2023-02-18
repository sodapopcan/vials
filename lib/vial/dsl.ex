defmodule Vial.DSL do
  defmacro __using__(args) do
    quote do
      @before_compile Vial.DSL

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
    func_name = :"cd_#{System.unique_integer([:positive])}"

    quote do
      @actions [unquote(func_name) | @actions]
      def unquote(func_name)(vial) do
        path = Path.join(vial.cwd, unquote(path))
        Map.put(vial, :cwd, path)
      end
    end
  end

  defmacro create_file(filename, contents) do
    func_name = :"create_file_#{System.unique_integer([:positive])}"

    quote do
      @actions [unquote(func_name) | @actions]
      def unquote(func_name)(vial) do
        path = Path.join(vial.cwd, unquote(filename))
        File.write!(path, unquote(contents))
      end
    end
  end
end
