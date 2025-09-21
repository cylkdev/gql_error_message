defmodule GQLErrorMessage do
  @moduledoc """
  Documentation for `GQLErrorMessage`.
  """
  alias GQLErrorMessage.{
    Bridge,
    ClientError,
    Config,
    Dict,
    Spec,
    ServerError
  }

  @operations [:mutation, :query]

  @doc """
  Translates an error map into a list of `ClientError` or `ServerError` structs.

  ## Options

    * `dict` - The dictionary to use for looking up error specs.
      Defaults to `GQLErrorMessage.Dict.Default`.

    * `fallback_error_message` - The fallback `GQLErrorMessage.ServerError`
      struct to use when no spec is found.

  ## Examples

      iex> operation = :query
      ...> error = %ErrorMessage{code: :bad_request, message: "invalid request", details: %{params: %{id: 1}}}
      ...> bridge = GQLErrorMessage.Bridges.ErrorMessageBridge
      ...> input = %{id: 1}
      ...> dict = GQLErrorMessage.Dict.Default
      ...> GQLErrorMessage.translate_error(operation, error, bridge, input, dict: dict)
      [%GQLErrorMessage.ClientError{field: [:id], message: "invalid request"}]

      iex> operation = :query
      ...> error = %ErrorMessage{code: :internal_server_error, message: "internal server error", details: %{params: %{users: %{id: [1, 2, 3]}}}}
      ...> bridge = GQLErrorMessage.Bridges.ErrorMessageBridge
      ...> input = %{name: "alice", users: %{id: [1, 2, 3]}}
      ...> dict = GQLErrorMessage.Dict.Default
      ...> GQLErrorMessage.translate_error(operation, error, bridge, input, dict: dict)
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
  def translate_error(op, %{code: code} = error, bridge, input, opts \\ [])
      when op in @operations do
    dict = dict(opts)

    case Dict.get(dict, op, code) do
      nil -> [fallback_error_message(opts)]
      %Spec{} = spec -> handle_translate(error, bridge, input, spec)
      term -> raise "expected a `GQLErrorMessage.Spec` struct, got: #{inspect(term)}"
    end
  end

  defp handle_translate(error, bridge, input, %Spec{kind: :client_error} = spec) do
    bridge
    |> Bridge.translate_error(error, input, spec)
    |> List.wrap()
    |> Enum.map(fn
      %ClientError{} = ce -> ce
      term -> raise "Expected a `GQLErrorMessage.ClientError` struct, got: #{inspect(term)}"
    end)
  end

  defp handle_translate(error, bridge, input, %Spec{kind: :server_error} = spec) do
    bridge
    |> Bridge.translate_error(error, input, spec)
    |> List.wrap()
    |> Enum.map(fn
      %ServerError{} = se -> se
      term -> raise "Expected a `GQLErrorMessage.ServerError` struct, got: #{inspect(term)}"
    end)
  end

  defp fallback_error_message(opts) do
    case opts[:fallback_error_message] || Config.fallback_error_message() do
      nil -> %ServerError{message: "an unknown error occurred"}
      %ServerError{} = se -> se
      term -> raise "expected a `GQLErrorMessage.ServerError` struct, got: #{inspect(term)}"
    end
  end

  defp dict(opts) do
    opts[:dict] || Dict.Default
  end
end
