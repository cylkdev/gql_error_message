defmodule GQLErrorMessage.Translation do
  @moduledoc """
  The default adapter for translating common Elixir errors
  into GraphQL errors.

  This module inspects the error type and delegates the
  translation to a specialized module.

  ## Supported Error Types

    * `ErrorMessage` structs
    * `Ecto.Changeset` structs

  Any other term is translated into a fallback `GQLErrorMessage.ServerError`.
  """
  alias GQLErrorMessage.{
    Config,
    Repo,
    ServerError
  }

  alias GQLErrorMessage.Translation.{
    ChangesetTranslation,
    ErrorMessageTranslation
  }

  @behaviour GQLErrorMessage.Adapter

  @logger_prefix "GQLErrorMessage.Translation"

  @impl true
  @doc """
  Retrieves an error specification from a repository.

  This function determines the error `:code` to look up based on the type of
  the error term:

    * `%{code: code}` - Uses the `:code` value directly.
    * `Ecto.Changeset` - Defaults to `:unprocessable_entity`.
    * Any other term - Defaults to `:internal_server_error`.
  """
  def get(repo, op, %{code: code}) do
    Repo.get(repo, op, code)
  end

  def get(repo, op, changeset) when is_struct(changeset, Ecto.Changeset) do
    Repo.get(repo, op, :unprocessable_entity)
  end

  def get(repo, op, _term) do
    Repo.get(repo, op, :internal_server_error)
  end

  @impl true
  @doc """
  Translates an error into a list of GraphQL error structs.

  This function delegates the translation to a specialized module based on the
  error's type:

    * `ErrorMessage`: `GQLErrorMessage.Translation.ErrorMessageTranslation`
    * `Ecto.Changeset`: `GQLErrorMessage.Translation.ChangesetTranslation`
    * Any other term: Returns a fallback `ServerError`
  """
  def translate_error(%{code: _} = error, input, spec) do
    ErrorMessageTranslation.translate_error(error, input, spec)
  end

  def translate_error(changeset, input, spec) when is_struct(changeset, Ecto.Changeset) do
    ChangesetTranslation.translate_error(changeset, input, spec)
  end

  def translate_error(term, _, _) do
    GQLErrorMessage.Logger.error(@logger_prefix, "unknown error: #{inspect(term)}")

    [fallback_error()]
  end

  defp fallback_error do
    case Config.fallback_error() do
      nil -> %ServerError{message: "undefined error", extensions: %{}}
      %ServerError{} = server_error -> server_error
      params -> ServerError.new(params)
    end
  end
end
