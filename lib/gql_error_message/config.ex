defmodule GQLErrorMessage.Config do
  @moduledoc """
  Runtime configuration for `GQLErrorMessage`.

  Reads application environment values at runtime so that configuration
  can be changed without recompiling.
  """

  @default_translator GQLErrorMessage.CommonError

  @doc """
  Returns the configured translator adapter module.

  Reads `:translator` from the `:gql_error_message` application
  environment at runtime. Falls back to
  `GQLErrorMessage.CommonError` when no value is set.

  ## Examples

      iex> GQLErrorMessage.Config.translator()
      GQLErrorMessage.CommonError

  """
  @spec translator() :: module()
  def translator do
    Application.get_env(:gql_error_message, :translator, @default_translator)
  end

  @doc """
  Returns the configured error message hook module, or `nil` if none is set.

  Reads `:error_message_hook` from the `:gql_error_message` application
  environment at runtime.

  ## Examples

      iex> GQLErrorMessage.Config.error_message_hook()
      nil

  """
  @spec error_message_hook() :: module() | nil
  def error_message_hook do
    Application.get_env(:gql_error_message, :error_message_hook)
  end
end
