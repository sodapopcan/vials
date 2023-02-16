defmodule Vial.DSL do
  @counter 0

  defmacro __using__(_) do
    quote do
      @counter unquote(@counter)
      @actions []

      import Vial.DSL
    end
  end

  defmacro create_file(filename, contents) do
    func_name = :"create_file_#{@counter}"

    quote do
      @actions [unquote(func_name) | @actions]

      def unquote(func_name)(vial) do
        path = Path.join(vial.cwd, unquote(filename))

        File.write!(path, unquote(contents))
      end
    end
  end
end
