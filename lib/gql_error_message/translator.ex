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
    Codex,
    ServerError
  }

  alias GQLErrorMessage.Translator.{
    ChangesetTranslation,
    ErrorMessageTranslation
  }

  @behaviour GQLErrorMessage.Adapter

  @logger_prefix "GQLErrorMessage.Translation"

  @impl true
  @doc """
  Retrieves an error specification from a codexsitory.

  This function determines the error `:code` to look up based on the type of
  the error term:

    * `%{code: code}` - Uses the `:code` value directly.
    * `Ecto.Changeset` - Defaults to `:unprocessable_entity`.
    * Any other term - Defaults to `:internal_server_error`.

  ## Examples

      iex> GQLErrorMessage.Translation.get_spec(GQLErrorMessage.DefaultCodex, :mutation, %{code: :unauthorized})
      %GQLErrorMessage.Spec{
        operation: :mutation,
        kind: :client_error,
        code: :unauthorized,
        message: "unauthorized",
        extensions: %{}
      }
  """
  def get_spec(codex, op, %{code: code}) do
    Codex.spec_for(codex, op, code)
  end

  def get_spec(codex, op, changeset) when is_struct(changeset, Ecto.Changeset) do
    Codex.spec_for(codex, op, :unprocessable_entity)
  end

  def get_spec(codex, op, _term) do
    Codex.spec_for(codex, op, :internal_server_error)
  end

  @impl true
  @doc """
  Translates an error into a list of GraphQL error structs.

  This function delegates the translation to a specialized module based on the
  error's type:

    * `ErrorMessage`: `GQLErrorMessage.Translator.ErrorMessageTranslation`
    * `Ecto.Changeset`: `GQLErrorMessage.Translator.ChangesetTranslation`
    * Any other term: Returns a fallback `ServerError`

  ### Examples

      error = %ErrorMessage{code: :unauthorized, message: "authentication required", details: nil}
      input = %{name: "alice", users: %{id: [1, 2, 3]}}
      spec = %GQLErrorMessage.Spec{
        operation: :mutation,
        kind: :client_error,
        code: :unauthorized,
        message: "unauthorized",
        extensions: %{}
      }
      GQLErrorMessage.Translator.handle_translate(error, input, spec)
  """
  def handle_translate(%ErrorMessage{code: _} = error, input, spec) do
    with [] <- ErrorMessageTranslation.handle_translate(error, input, spec) do
      GQLErrorMessage.Logger.warning(
        @logger_prefix,
        """
        ErrorMessage translation failed.

        This could be due to a mismatch between the input and the errors on
        the ErrorMessage. Review the input and the ErrorMessage below to ensure
        they match. If you believe this is a bug, please file an issue at:

        https://github.com/cylkdev/gql_error_message/issues/new

        ---

        error:

        #{inspect(error, pretty: true)}

        input:

        #{inspect(input, pretty: true)}

        spec:

        #{inspect(spec, pretty: true)}
        """
      )

      [fallback_error()]
    end
  end

  def handle_translate(changeset, input, spec) when is_struct(changeset, Ecto.Changeset) do
    with [] <- ChangesetTranslation.handle_translate(changeset, input, spec) do
      GQLErrorMessage.Logger.warning(
        @logger_prefix,
        """
        Changeset translation failed.

        This could be due to a mismatch between the input and the errors on
        the changeset. Review the input and the changeset below to ensure
        they match. If you believe this is a bug, please file an issue at:

        https://github.com/cylkdev/gql_error_message/issues/new

        ---

        changeset:

        #{inspect(changeset, pretty: true)}

        input:

        #{inspect(input, pretty: true)}

        spec:

        #{inspect(spec, pretty: true)}
        """
      )

      [fallback_error()]
    end
  end

  def handle_translate(term, _, _) do
    GQLErrorMessage.Logger.error(@logger_prefix, "Received unknown error: #{inspect(term)}")

    [fallback_error()]
  end

  defp fallback_error do
    case Config.fallback_error() do
      nil ->
        %ServerError{
          message: "Service currently unavailable, please try again later",
          extensions: %{}
        }

      %ServerError{} = server_error ->
        server_error

      params ->
        ServerError.new(params)
    end
  end
end
