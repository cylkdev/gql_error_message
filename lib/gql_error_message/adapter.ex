defmodule GQLErrorMessage.Adapter do
  @moduledoc """
  A behaviour for translating errors into GraphQL-compatible formats.

  This module defines the contract for adapters, which are responsible for two main tasks:

    1.  Retrieving an error specification (`GQLErrorMessage.Spec`) from a repository.
    2.  Translating an error term into a `GQLErrorMessage.ClientError` or `GQLErrorMessage.ServerError`.

  The library includes a default adapter, `GQLErrorMessage.Translation`.
  """
  alias GQLErrorMessage.{
    ClientError,
    Spec,
    ServerError
  }

  @doc """
  The callback for retrieving an error specification.

  Implementations should inspect the `error` term to determine which `Spec` to
  retrieve from the `repo`.
  """
  @callback get(repo :: module(), op :: atom(), error :: term()) :: Spec.t() | nil

  @doc """
  The callback for translating an error into a standard error struct.

  Implementations should use the `error` term and the retrieved `spec` to
  construct one or more `GQLErrorMessage.ClientError` or `GQLErrorMessage.ServerError` structs.
  """
  @callback translate_error(error :: term(), input :: map(), spec :: Spec.t()) ::
              ClientError.t() | ServerError.t() | list(ClientError.t() | ServerError.t())

  @doc """
  Delegates `get` to the specified adapter module.
  """
  def get(module, repo, op, error) do
    module.get(repo, op, error)
  end

  @doc """
  Delegates `translate_error` to the specified adapter module.
  """
  def translate_error(module, error, input, spec) do
    module.translate_error(error, input, spec)
  end
end
