defmodule Vials.Actions do
  @moduledoc false

  @doc_start ~r/@.*"""\z/
  @doc_end ~r/"""\z/
  @comment ~r/\A(\s+)?#/

  def remove_comments(string) do
    {ast, _comments} =
      string
      |> Sourceror.parse_string!()
      |> Sourceror.Comments.extract_comments()

    Sourceror.to_string(ast) <> "\n"
  end

  def add_dep(file_contents, dep) do
    last_dep_regex = ~r/defp deps do.*\n(\s+)(\{:.*?})\n/s

    [indent, last_dep] = Regex.run(last_dep_regex, file_contents, capture: :all_but_first)

    replacement = last_dep <> ",\n#{indent}" <> Vials.Util.dep_to_string(dep)
    String.replace(file_contents, last_dep, replacement)
  end
end
