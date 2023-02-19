defmodule Vial.Util do
  def dep_to_string(dep) do
    dep
    |> Tuple.to_list()
    |> then(fn [d, v] -> ["{:#{d},", "\"#{v}\"}"] end)
    |> Enum.join(" ")
  end

  def inject_into_module_body(ast, quoted) do
    {ast, _} =
      Macro.prewalk(ast, false, fn
        [do: block], false ->
          {[do: [quoted | List.wrap(block)]], true}

        other, acc ->
          {other, acc}
      end)

    ast
  end
end
