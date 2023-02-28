defmodule Vials.Actions do
  @moduledoc false

  @doc_start ~r/@.*"""\z/
  @doc_end ~r/"""\z/
  @comment ~r/\A(\s+)?#/

  def remove_comments(string) do
    string
    |> String.split("\n")
    |> Enum.reduce({[], false}, fn line, {lines, in_doc?} ->
      cond do
        line =~ @doc_start -> {[line | lines], true}
        line =~ @doc_end -> {[line | lines], false}
        line =~ @comment and not in_doc? -> {lines, in_doc?}
        true -> {[line | lines], in_doc?}
      end
    end)
    |> elem(0)
    |> Enum.reverse()
    |> Enum.join("\n")
  end

  def add_dep(file_contents, dep) do
    last_dep_regex = ~r/defp deps do.*\n(\s+)(\{:.*?})\n/s

    [indent, last_dep] = Regex.run(last_dep_regex, file_contents, capture: :all_but_first)

    replacement = last_dep <> ",\n#{indent}" <> Vials.Util.dep_to_string(dep)
    String.replace(file_contents, last_dep, replacement)
  end
end
