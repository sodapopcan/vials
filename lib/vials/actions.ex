defmodule Vials.Actions do
  @moduledoc false

  def remove_comments(source) do
    {ast, _comments} =
      source
      |> Sourceror.parse_string!()
      |> Sourceror.Comments.extract_comments()

    Sourceror.to_string(ast) <> "\n"
  end

  def add_dep(source, dep) do
    ast =
      source
      |> Sourceror.parse_string!()
      |> Sourceror.postwalk(fn
        {:defp, meta, [{:deps, _, _} = fun, body]}, state ->
          [{{_, _, [:do]}, block_ast}] = body
          {:__block__, block_meta, [deps]} = block_ast

          dep_line =
            case List.last(deps) do
              {_, meta, _} ->
                meta[:line] || block_meta[:line]

              _ ->
                block_meta[:line]
            end + 1

          deps =
            deps ++
              [
                {:__block__, [line: dep_line], [dep]}
              ]

          ast = {:defp, meta, [fun, [do: {:__block__, block_meta, [deps]}]]}
          {ast, state}

        other, state ->
          {other, state}
      end)

    Sourceror.to_string(ast) <> "\n"
  end
end
