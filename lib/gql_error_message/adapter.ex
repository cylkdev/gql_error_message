defmodule GQLErrorMessage.Adapter do
  @moduledoc """
  A behaviour for translating errors into GraphQL-compatible formats.

  This module defines the contract for adapters, which are responsible for two main tasks:

    1.  Retrieving an error specification (`GQLErrorMessage.Spec`)
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
  retrieve from the `codex`.
  """
  @callback get_spec(codex :: module(), op :: atom(), error :: term()) :: Spec.t() | nil

  @doc """
  The callback for translating an error into a standard error struct.

  Implementations should use the `error` term and the retrieved `spec` to
  construct one or more `GQLErrorMessage.ClientError` or `GQLErrorMessage.ServerError` structs.
  """
  @callback handle_translate(error :: term(), input :: map(), spec :: Spec.t()) ::
              ClientError.t() | ServerError.t() | list(ClientError.t() | ServerError.t())

  @doc """
  Delegates `get_spec` to the specified adapter module.
  """
  def get_spec(module, codex, op, error) do
    case module.get_spec(codex, op, error) do
      %Spec{} = spec -> spec
      term ->
        raise """
        Adapter #{inspect(module)} did not return a spec,

        module: #{inspect(module)}
        codex: #{inspect(codex)}
        operation: #{inspect(op)}
        error: #{inspect(error)}

        got: #{inspect(term)}
        """
    end
  end

  @doc """
  Delegates `handle_translate` to the specified adapter module.
  """
  def handle_translate(module, error, input, spec) do
    error
    |> module.handle_translate(input, spec)
    |> List.wrap()
  end
end
