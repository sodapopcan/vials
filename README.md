# Vial

Add it to the mix!

## About

Vial is a wrapper around mix to do stuff and whatnot.


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

