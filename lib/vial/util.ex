defmodule Vial.Util do
  def user_home do
    if System.get_env("MIX_ENV") == "test" do
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
end
