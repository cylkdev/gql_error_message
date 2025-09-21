if Code.ensure_loaded?(ErrorMessage) do
  defmodule GQLErrorMessage.Bridges.ErrorMessageBridge do
    alias GQLErrorMessage.{ClientError, Spec, ServerError}

    @behaviour GQLErrorMessage.Bridge

    @impl true
    @doc """
    Translates an error message into a list of GraphQL error structs.

    ## Examples

        iex> error = %ErrorMessage{code: :internal_server_error, message: "internal server error", details: %{params: %{users: %{id: [1, 2, 3]}}}}
        ...> input = %{name: "alice", users: %{id: [1, 2, 3]}}
        ...> spec = %GQLErrorMessage.Spec{
        ...>   operation: :query,
        ...>   kind: :server_error,
        ...>   code: :internal_server_error,
        ...>   message: "internal server error",
        ...>   extensions: %{}
        ...> }
        ...> GQLErrorMessage.Bridges.ErrorMessageBridge.translate_error(error, input, spec)
        [%GQLErrorMessage.ServerError{message: "internal server error", extensions: %{}}]
    """
    @spec translate_error(error :: ErrorMessage.t(), input :: map(), spec :: Spec.t()) ::
            list(ClientError.t() | ServerError.t())
    def translate_error(%ErrorMessage{} = e, input, %Spec{kind: :server_error} = spec) do
      details = e.details || %{}
      msg = details[:gql][:message] || e.message || spec.message
      error_params = details[:gql][:input] || details[:params] || %{}
      extensions = Map.merge(spec.extensions || %{}, details[:gql][:extensions] || %{})

      input
      |> intersect_paths(error_params)
      |> Enum.map(fn {field, value} ->
        key = List.last(field)
        final_msg = replace_kv_template(msg, key, value)
        %ServerError{message: final_msg, extensions: extensions}
      end)
    end

    def translate_error(%ErrorMessage{} = e, input, %Spec{kind: :client_error} = spec) do
      details = e.details || %{}
      msg = details[:gql][:message] || e.message || spec.message
      error_params = details[:gql][:input] || details[:params] || %{}

      input
      |> intersect_paths(error_params)
      |> Enum.map(fn {field, value} ->
        key = List.last(field)
        final_msg = replace_kv_template(msg, key, value)
        %ClientError{field: field, message: final_msg}
      end)
    end

    defp replace_kv_template(str, key, value) do
      str
      |> replace_key_template(key)
      |> replace_value_template(value)
    end

    defp replace_key_template(str, key) do
      String.replace(str, "%{key}", to_string(key))
    end

    defp replace_value_template(str, value) do
      String.replace(str, "%{value}", to_string(value))
    end

    # The `intersect_paths` function walks a pair of nested data structures
    # and collects the paths of fields they have in common. A “path” is just
    # the sequence of keys or indexes you’d follow to reach a value.
    #
    # For example, the path [:profile, :name] means “go into the :profile map,
    # then into the :name field.”. The function always starts from the first
    # structure and only continues down a branch if the second structure also
    # has that branch. At the end, it returns a list of all the overlapping
    # paths where both sides share the same keys or indexes.
    #
    # This is used when we want to know exactly which parts of some user
    # input line up with an error map, so we can point to the fields that are
    # actually invalid.

    @doc false
    @spec intersect_paths(input :: map(), error_params :: map()) ::
            list({path :: list(), value :: term()})
    def intersect_paths(input, error_params) do
      input
      |> collect_int_paths(error_params, [], [])
      |> Enum.reverse()
    end

    defp collect_int_paths(inputs, error_value, path, acc) when is_list(inputs) do
      if Keyword.keyword?(inputs) do
        Enum.reduce(inputs, acc, fn input, acc ->
          collect_int_paths(input, error_value, path, acc)
        end)
      else
        if inputs === error_value do
          [{Enum.reverse(path), inputs} | acc]
        else
          acc
        end
      end
    end

    defp collect_int_paths(input, errors, path, acc) when is_list(errors) do
      Enum.reduce(errors, acc, fn error, acc ->
        collect_int_paths(input, error, path, acc)
      end)
    end

    defp collect_int_paths({input_key, input_val}, error_params, path, acc) do
      if Map.has_key?(error_params, input_key) do
        next_error_params = Map.fetch!(error_params, input_key)
        next_path = [input_key | path]
        collect_int_paths(input_val, next_error_params, next_path, acc)
      else
        acc
      end
    end

    defp collect_int_paths(input, error_params, path, acc) when is_map(input) do
      input
      |> Map.to_list()
      |> collect_int_paths(error_params, path, acc)
    end

    defp collect_int_paths(user_leaf, error_leaf, path, acc) do
      if user_leaf === error_leaf do
        [{Enum.reverse(path), user_leaf} | acc]
      else
        acc
      end
    end
  end
end
