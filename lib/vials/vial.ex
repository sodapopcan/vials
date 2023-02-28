defmodule Vials.Vial do
  @moduledoc """
  Defines the DSL available in your vials.

  This module is what is imported into your vials when you `use Vials`.

  These functions don't perform any system IO and instead store a list of
  messages to be processed by the `Runner`.

  They will emit one of the following messages:

  ```elixir
  {:create, glob, func/1}
  {:edit, filename, func/1}
  {:remove, glob}
  {:move, glob, dest}
  func/1
  ```

  When a message is a bare, single-arity function, the `Runner` will invoke it
  passing a `%Context{}`.  See `base_path` for an example.
  """

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

  @doc """
  Add a create file message.

  It takes a filename and the content as a string:

  ## Example

      ```elixir
      defmodule Vial do
        use Vials

        create "tmp/example_file.txt", "Hi there!"
      end
      ```

  The content may also be passed as a block of Elixir code which will be
  converted into a string:

  ## Example

      ```elixir
      defmodule Vial do
        use Vials

        create "foo.ex" do
          defmodule Foo do
            def bar do
              "baz"
            end
          end
        end
      end
      ```
  """
  defmacro create(filename, do: ast) do
    contents = Sourceror.to_string(ast)

    quote do
      Vials.Vial.add({:create, unquote(filename), unquote(contents)})
    end
  end

  defmacro create(filename, contents) when is_binary(contents) do
    quote do
      Vials.Vial.add({:create, unquote(filename), unquote(contents)})
    end
  end

  @doc """
  Add a edit file message.

  It accepts a filename, a glob, or a list of filenames and/or globs and
  a callback that will be passed the contents of each file.

  ## Example

      ```elixir
      defmodule Vial do
        use Vials

        edit "foo.txt", fn contents ->
          String.replace(contents, "def bar", "def baz")
        end
      end
      ```
  """
  def edit(glob, func) do
    add({:edit, glob, func})
  end

  @doc """
  Add a remove file message.

  It accepts a filename, a glob, or a list of filenames and/or globs.

  ## Example

      ```elixir
      defmodule Vial do
        use Vials

        remove "foo.txt"
        remove "*_sufix.ex"
        remove ~w[file1.ex file2.ex file_*.ex]
      end
      ```
  """
  def remove(glob) do
    add({:remove, glob})
  end

  @doc """
  Set the base path to perform all subsequent IO operations against.

  This is useful when creating a vial for something like phx_new where you won't
  be in the directory you want to operate on.  In the case of creating a vial
  for phx_new, you likely always want to set it to `@target` which will be the
  new project's directory.

  It can be called multiple times affecting all calls that come after it.

  ## Example

      ```elixir
      defmodule Vial do
        use Vials

        base_path @target
      end
      ```
  """
  def base_path(path) do
    add(fn context ->
      path = Path.join(context.base_path, path)
      Map.put(context, :base_path, path)
    end)
  end

  @doc """
  Adds an edit message to add a dependency to mix.exs.

  ## Example

      ```elixir
      defmodule Vial do
        use Vials

        add_dep {:some_dep, "~> 1.0.0"}
      end
      ```
  """
  def add_dep(dep) do
    add({:edit, "mix.exs", &Vials.Actions.add_dep(&1, dep)})
  end

  @doc """
  Add a message to remove all comments from all .ex and .exs files.
  """
  def remove_comments do
    add({:edit, "**/*.{ex,exs}", &Vials.Actions.remove_comments/1})
  end

  @doc """
  Add a message to remove comments from the given filenames.

  It accepts a filename, a glob, or a list of filenames and/or globs.
  """
  def remove_comments(glob) when is_binary(glob) or is_list(glob) do
    add({:edit, glob, &Vials.Actions.remove_comments/1})
  end
end
