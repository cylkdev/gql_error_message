defmodule GQLErrorMessage.CommonBridge do
  @moduledoc """
  A bridge adapter that provides a common interface for translating errors
  into GraphQL errors.

  This adapter supports the following error types:

    * `ErrorMessage` struct
    * `Ecto.Changeset` struct

  Any other terms are translated into a fallback error.
  """
  alias GQLErrorMessage.{
    Config,
    SpecStore,
    ServerError
  }

  alias GQLErrorMessage.CommonBridge.{
    ChangesetBridge,
    ErrorMessageBridge
  }

  @behaviour GQLErrorMessage.Bridge

  @logger_prefix "GQLErrorMessage.CommonBridge"

  @impl true
  def get_spec(spec_store, op, %{code: code}) do
    SpecStore.get_spec(spec_store, op, code)
  end

  def get_spec(spec_store, op, changeset) when is_struct(changeset, Ecto.Changeset) do
    SpecStore.get_spec(spec_store, op, :unprocessable_entity)
  end

  def get_spec(spec_store, op, _term) do
    SpecStore.get_spec(spec_store, op, :internal_server_error)
  end

  @impl true
  @doc """
  Translates an error message into a list of GraphQL error structs.
  """
  def translate_error(%{code: _} = error, input, spec) do
    ErrorMessageBridge.translate_error(error, input, spec)
  end

  def translate_error(changeset, input, spec) when is_struct(changeset, Ecto.Changeset) do
    ChangesetBridge.translate_error(changeset, input, spec)
  end

  def translate_error(term, _, _) do
    GQLErrorMessage.Logger.error(@logger_prefix, "unknown error: #{inspect(term)}")

    [fallback_error()]
  end

  defp fallback_error do
    case Config.fallback_error() do
      nil -> %ServerError{message: "undefined error", extensions: %{}}
      %ServerError{} = server_error -> server_error
      term -> raise "expected a `GQLErrorMessage.ServerError` struct, got: #{inspect(term)}"
    end
  end
end
