# Vial

Vials of whathaveyou to add to the mix

## About

Vial is a mix task that wraps other mix tasks to alter or enhance their
behaviour.

For example, here is a vial to add to `phx.new`:

```elixir
defmodule Vials.Phx.New do
  use Vial

  cd "{$1}"

  remove_file "priv/static/favicon.ico"

  change_file "lib/{$1}_web/layouts/root.html.heex", fn contents ->
    remove_lines(contents, 10..30)
  end
end
```

By default, Vial searches for vials in `~/.vials` then `~/vials`.   You can set
you own path with `export VIAL_LOOKUP_PATH=path/to/your/vial/directory`

```elixir
# ~/.vials/phx.new.ex
defmodule Vials.Phx.New do
  use Vial

  @options [binary_id: true]

  cd "{$1}"

  create_file "{$1/context.ex}" do
  """
  defmodule {$1|camelize}.Schema do
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
$ mix vial phx.new --vial ~/path/to/some/template/
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

