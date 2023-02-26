# Vials

**This project is not quite ready for primetime yet.  I'm not accepting PRs at
this time as I'm doing a bunch of refactoring.**

Vials are bits of code that can be seamlessly run after a mix task.

At present, the DSL is geared toward altering the output of generators, but that
could change.

For example, here is a vial around `phx.new`:

```elixir
# ~/vials/phx.new.ex
defmodule Phx.New do
  use Vials

  base_path @target

  remove "priv/static/favicon.ico"
end
``` 

Note: `@target` refers to the first argument passed to the mix task.  More info
below.

Run it with:

```bash
$ vials phx.new my_project
```

Vials will load the module defined in `~/vials/phx.new.ex`, run `mix phx.new
my_project` as normal then remove `my_project/priv/static/favicon.ico`.

Vials are searched for in `~/vials`, `~/.vials`, or `$VIAL_PATH` (arguments for
changing this are coming).

Positional arguments passed to the wrapped task are available in
a integer-indexed map as `@args` (available as `@args._0`, `@args._1`, etc)
whereas the options map is available as `@opts`.  `@target` is set to the first
argument given to the _mix task_ (i.e., `@args._1`) whereas, for completeness,
`@task_name` is set to the mix task's name (i.e., @args._0).

For example, with this command:

```bash
$ vials phx.new my_project --module MyLongerProjectName --binary-id
```

...we can do the following:

```elixir
defmodule Phx.New do
  use Vials
  
  base_path @target
  
  if @opts[:binary_id] do
    create "lib/#{@target}/schema", """
    defmodule #{@opts.module}.Schema do
      defmacro __using__(_) do
        quote do
          use Ecto.Schema, warn: false

          @primary_key {:id, :binary_id, autogenerate: true}
          @foreign_key_type :binary_id
        end
      end
    end
    """
  end
end
```

You could also add a vial for `ecto.gen.migration` do to play nicer with
projects using `--binary-id`:

```elixir
# ~/vials/ecto.gen.migrations.ex
defmodule Ecto.Gen.Migration do
  use Vials
  
  # Don't need to set the base_path here since we run this from within our
  # project.
  
  if Path.wildcard("lib/*/schema.ex") |> Enum.any?() do
    edit "*_{@target}.exs", fn contents ->
      if contents =~ `def create table` do
        String.replace(contents, ~r/def create.*/, """
            def change table(#{@target}, primary_key: false) do
              add :id, :binary_id, primary_key: true

              timestamps()
        """
      else
        contents
      end
    end
  end
end
```

As you can see, editing files is a bit crude right now, but improvements will be
coming soon including being able to get the contents as a Sourceror AST.

## Experimental features

I'm fairly new to AST manipulation so you'll have to bear with me.

At the moment, if you pass a block to `create` you can just write straight,
static Elixir:


```elixir
create "lib/some_file.ex" do
  defmodule SomeFile do
    def hi do
      "hi"
    end
  end
end
```

There is currently no way to inject the variable module attributes but I'm
working on that.

## Current API

`base_path/1`: Sets the base path for where to look for all subsequent
filenames.  You only need this if you are wrapping a task like `mix phx.new`
where you want to run commands relative to the new projects root without
actually `cd`'ing into it.

`create/2`: Creates a file.  Takes a filename and contents as strings.

`edit/2`: Edits a file.  Takes a wildcard and passed the contents of all matches
to an anonymous function.

`remove/1`: Removes a file.

`add_dep/1`: Adds a dependency, eg: `add_dep {:some_dep, "~> 0.0.1"}`

`remove_comments/0`: Removes all comments from `ex` and `exs` files.

`remove_comments/1`: Takes a filename or list of filenames to remove comments
from.

## Coming soon

- More DSL functions for common mix-related operations.
- A plugin system for task-specific operations, like starting a phoenix project
using `utc_timestamp_usec` by default, for example.
- A way of passing an alternate directory or filename as an argument instead of
looking for the default vial.

## Installation

Vials is not yet on hexpm.  You can clone the repo and build it with `mix
escript build` from within the project's root.  This will create a `vials`
executable which you can move to some directory in your `PATH`.
