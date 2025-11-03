if Code.ensure_loaded?(Absinthe) do
  defmodule GQLErrorMessage.Absinthe.Middleware do
    @moduledoc """
    A post-resolution Absinthe middleware for translating errors.

    This middleware converts resolver errors into a standard GraphQL
    error format (as defined by the specification) and places them
    into the errors array of the response alongside any partial data.

    ## Usage

    Apply this middleware to a field in your Absinthe schema. It **must** be placed
    *after* the `resolve` function.

        field :create_user, :user_payload do
          arg :input, non_null(:user_input)

          resolve &Accounts.create_user/3

          middleware GQLErrorMessage.Absinthe.Middleware
        end

    ## Error Handling

      * **Client Errors**: For mutations, client errors are added to
        a `user_errors` field in the response payload. For queries
        and subscriptions, they are added to the top-level `errors`
        list, and the data is set to `nil`.

      * **Server Errors**: Server errors are always added to the
        top-level `errors` list, and the data is set to `nil`.

    ## Options

      * `:input_path` - The path to the input arguments for mutations. Defaults to `[:input]`.
      * All options accepted by `GQLErrorMessage.translate_error/4` are also supported.

    > #### Warning {: .warning}
    >
    > This module requires `:absinthe` as a dependency.
    """
    alias GQLErrorMessage.{ClientError, ServerError}

    @doc """
    The main entry point for the middleware.

    It is called by Absinthe with the resolution struct and middleware options.
    """
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
      adapter = Keyword.get(opts, :adapter, GQLErrorMessage.Translation)
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

      case Enum.flat_map(errors, &GQLErrorMessage.translate_error(adapter, op, &1, input, opts)) do
        [%ClientError{} | _] = gql_errors ->
          if op === :mutation do
            current_value = value || %{}
            final_value = Map.put(current_value, :user_errors, to_jsonable_map(gql_errors, opts))
            %{resolution | errors: [], value: final_value}
          else
            %{resolution | errors: to_jsonable_map(gql_errors, opts), value: nil}
          end

        [%ServerError{} | _] = gql_errors ->
          %{resolution | errors: to_jsonable_map(gql_errors, opts), value: nil}

        [] ->
          raise "Adapter #{inspect(adapter)} failed to translate errors\n\nerrors: #{inspect(errors)}"
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
