defmodule GQLErrorMessage.Logger do
  @moduledoc false
  require Logger

  @doc false
  def debug(prefix, message) do
    prefix
    |> format_message(message)
    |> Logger.debug()
  end

  @doc false
  def error(prefix, message) do
    prefix
    |> format_message(message)
    |> Logger.error()
  end

  defp format_message(prefix, message) do
    "#{prefix}: #{message}"
  end
end
