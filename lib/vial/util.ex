defmodule Vial.Util do
  def user_home do
    if Mix.env() == :test do
      "tmp"
    else
      System.user_home()
    end
  end

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

    {:ok, ast}
  end
end
