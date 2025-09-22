defmodule GQLErrorMessage do
  @moduledoc """
  Documentation for `GQLErrorMessage`.
  """
  alias GQLErrorMessage.{
    Bridge,
    ClientError,
    Spec,
    ServerError
  }

  @logger_prefix "GQLErrorMessage"

  @operations [:mutation, :query, :subscription]

  @doc """
  Translates an error map into a list of `ClientError` or `ServerError` structs.

  ## Options

    * `spec_store` - The spec_storeionary to use for looking up error specs. Defaults to `GQLErrorMessage.Lexicon`.

    * `fallback_error` - The fallback `GQLErrorMessage.ServerError` struct to use when no spec is found.

  ## Examples

      iex> operation = :query
      ...> error = %ErrorMessage{code: :bad_request, message: "invalid request", details: %{params: %{id: 1}}}
      ...> bridge = GQLErrorMessage.CommonBridge
      ...> input = %{id: 1}
      ...> GQLErrorMessage.translate_error(operation, error, bridge, input)
      [%GQLErrorMessage.ClientError{field: [:id], message: "invalid request"}]

      iex> operation = :query
      ...> error = %ErrorMessage{code: :internal_server_error, message: "internal server error", details: %{params: %{users: %{id: [1, 2, 3]}}}}
      ...> bridge = GQLErrorMessage.CommonBridge
      ...> input = %{name: "alice", users: %{id: [1, 2, 3]}}
      ...> GQLErrorMessage.translate_error(operation, error, bridge, input)
      [%GQLErrorMessage.ServerError{message: "internal server error", extensions: %{}}]
  """
  @spec translate_error(
          op :: atom(),
          error :: map(),
          bridge :: module(),
          input :: map()
        ) :: list()
  @spec translate_error(
          op :: atom(),
          error :: map(),
          bridge :: module(),
          input :: map(),
          opts :: keyword()
        ) :: list()
  def translate_error(op, error, bridge, input, opts \\ []) when op in @operations do
    spec_store = opts[:spec_store] || GQLErrorMessage.Lexicon

    case Bridge.get_spec(bridge, spec_store, op, error) do
      %Spec{} = spec ->
        translate(error, bridge, input, spec)

      term ->
        raise "Bridge #{inspect(bridge)} did not return a spec, got: #{inspect(term)}"
    end
  end

  defp translate(error, bridge, input, %Spec{kind: :client_error} = spec) do
    bridge
    |> Bridge.translate_error(error, input, spec)
    |> List.wrap()
    |> Enum.map(fn
      %ClientError{} = client_error -> client_error
      term -> raise "Expected a `GQLErrorMessage.ClientError` struct, got: #{inspect(term)}"
    end)
    |> then(fn
      [] ->
        GQLErrorMessage.Logger.debug(
          @logger_prefix,
          """
          Bridge #{inspect(bridge)} did not return any errors.

          error:
          #{inspect(error)}

          input:
          #{inspect(input)}

          spec:
          #{inspect(spec)}
          """
        )

        []

      results ->
        results
    end)
  end

  defp translate(error, bridge, input, %Spec{kind: :server_error} = spec) do
    bridge
    |> Bridge.translate_error(error, input, spec)
    |> List.wrap()
    |> Enum.map(fn
      %ServerError{} = server_error -> server_error
      term -> raise "Expected a `GQLErrorMessage.ServerError` struct, got: #{inspect(term)}"
    end)
    |> then(fn
      [] ->
        GQLErrorMessage.Logger.debug(
          @logger_prefix,
          """
          Bridge #{inspect(bridge)} did not return any errors.

          error:
          #{inspect(error)}

          input:
          #{inspect(input)}

          spec:
          #{inspect(spec)}
          """
        )

        []

      results ->
        results
    end)
  end
end
