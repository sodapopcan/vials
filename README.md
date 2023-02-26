# Vials

Vials of whathaveyou to add to the mix

## About

Vials is a mix task that wraps other mix tasks to alter or enhance their
behaviour.

For example, here is a vial around `phx.new`:

```elixir
# ~/.vials/phx.new.ex
defmodule Phx.New do
  use Vials

  cd @arg[:_1]

  remove_file "priv/static/favicon.ico"
end
``` 

Run it with:

```bash
$ mix vial phx.new my_project
```

This will run `mix phx.new my_project` as normal, then `cd my_project` and
remove the favicon.

Vials files are named after their mix task name and saved in `~/.vials`,
`~/vials`, or `$VIAL_PATH` (see [options](#options) for more).

Positional arguments passed to the wrapped task are available as `@1`, `@2`, and
so on whereas options are available as `@option_name`.

For example:

```elixir
# ~/.vials/phx.new.ex
defmodule Phx.New do
  use Vials

  cd if @args[:module], do: underscore(@args.module), else: @args._1


end
```


```elixir
# ~/.vials/phx.new.ex
defmodule Phx.New do
  use Vials

  @options [binary_id: true]

  cd "{$1}"

  create_file "#{@_1}/context.ex" do
  """
  defmodule {camelize(@1)}.Schema do
    defmacro __using__(_) do
      use Ecto.Schema

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
    end
  end
  """
  end
end
```

Heres are some vials around 


For example, in phx:


```bash
$ mix vial -p /some/other/location/alternate-phx-new.ex mix phx.new
```


```bash
$ mix vial ~/path/to/some/template/ phx.new 
```

a .vial file:

```elixir
defmodule {module}Web.Live do
  use {}Web, :live_view

  def render(assigns) do
    ~H"""
    Welcome to {snake}.
    """
  end
end
```

```elixir
# template.vial
include "/path/to/fs/templates"

deps do
  add 
end
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `vial` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:vial, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/vial>.

