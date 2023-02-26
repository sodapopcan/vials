defmodule Vial.Env do
  @env Mix.env()

  def prod?, do: @env == :prod
  def dev?, do: @env == :dev
  def test?, do: @env == :test
end
