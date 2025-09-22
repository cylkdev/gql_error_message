defmodule GQLErrorMessage.Logger do
  require Logger

  def debug(prefix, message) do
    prefix
    |> format_message(message)
    |> Logger.debug()
  end

  def error(prefix, message) do
    prefix
    |> format_message(message)
    |> Logger.error()
  end

  defp format_message(prefix, message) do
    "#{prefix}: #{message}"
  end
end
