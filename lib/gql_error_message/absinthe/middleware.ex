if Code.ensure_loaded?(Absinthe) do
  defmodule GQLErrorMessage.Absinthe.Middleware do
    @moduledoc false
    alias GQLErrorMessage.{ClientError, ServerError}

    def call(%Absinthe.Resolution{state: :resolved, errors: []} = resolution, _opts) do
      resolution
    end

    def call(
          %Absinthe.Resolution{
            state: :resolved,
            arguments: args,
            errors: errors,
            value: value
          } = resolution,
          opts
        ) do
      bridge = Keyword.get(opts, :bridge, GQLErrorMessage.CommonBridge)
      error_key = opts[:error_key] || :user_errors
      op = operation_type(resolution)

      input =
        case op do
          :mutation ->
            case get_in(args, opts[:input_path] || [:input]) do
              nil -> args
              input -> input
            end

          :query ->
            args

          :subscription ->
            args
        end

      case Enum.flat_map(errors, &GQLErrorMessage.translate_error(op, &1, bridge, input, opts)) do
        [%ClientError{} | _] = gql_errors ->
          if op === :mutation do
            current_value = value || %{}
            final_value = Map.put(current_value, error_key, to_jsonable_map(gql_errors, opts))
            %{resolution | errors: [], value: final_value}
          else
            %{resolution | errors: to_jsonable_map(gql_errors, opts), value: nil}
          end

        [%ServerError{} | _] = gql_errors ->
          %{resolution | errors: to_jsonable_map(gql_errors, opts), value: nil}
      end
    end

    def call(%Absinthe.Resolution{} = _resolution, _opts) do
      raise """
      ** (GQLErrorMessage.Absinthe.Middleware.PostResolutionOnlyError)
      GQLErrorMessage.Absinthe.Middleware can only be used *after* the resolve function.
      Place it after `resolve/1` in your schema field definition.
      """
    end

    @doc false
    def operation_type(%Absinthe.Resolution{parent_type: %{identifier: identifier}}) do
      case identifier do
        :query -> :query
        :mutation -> :mutation
        :subscription -> :subscription
      end
    end

    defp to_jsonable_map(errors, opts) when is_list(errors),
      do: Enum.map(errors, &to_jsonable_map(&1, opts))

    defp to_jsonable_map(%ClientError{} = e, opts), do: ClientError.to_jsonable_map(e, opts)
    defp to_jsonable_map(%ServerError{} = e, opts), do: ServerError.to_jsonable_map(e, opts)
  end
end
