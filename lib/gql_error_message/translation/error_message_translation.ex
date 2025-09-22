if Code.ensure_loaded?(ErrorMessage) do
  defmodule GQLErrorMessage.Translation.ErrorMessageTranslation do
    @moduledoc """
    Translates `ErrorMessage` structs into GraphQL-compatible errors.

    This module converts `ErrorMessage` structs into `GQLErrorMessage.ClientError` or
    `GQLErrorMessage.ServerError` structs. It intelligently finds the source of an
    error by intersecting the GraphQL input with the error's parameters.

    > #### Warning {: .warning}
    >
    > This module requires `:error_message` as a dependency.
    """
    alias GQLErrorMessage.{ClientError, Spec, ServerError}

    @doc """
    Translates an `ErrorMessage` struct into a list of error structs.

    Based on the spec `kind`, this function generates either `GQLErrorMessage.ClientError` or
    `GQLErrorMessage.ServerError` structs.

    It identifies the source field(s) of the error by finding the intersection
    between the `input` map and the parameters in the details map.

    ## Message Templating

    The error message supports `%{key}` and `%{value}` placeholders, which will be
    replaced with the field name and value from the input that caused the error.

    ## Overrides

    The `details` map can contain a `:gql` key to customize the output:

      * `details.gql.message` - Overrides the error message.
      * `details.gql.input` - Overrides the `details.params` used for path intersection.
      * `details.gql.extensions` - Merged into the extensions for `ServerError`s.

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
        ...> GQLErrorMessage.Translation.ErrorMessageTranslation.translate_error(error, input, spec)
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
else
  defmodule GQLErrorMessage.Translation.ErrorMessageTranslation do
    @moduledoc """
    This is a stub module that is compiled when the `:error_message` dependency
    is not available. All functions in this module will raise an error
    when called.

    To fix this, add `:error_message` to your `mix.exs` deps:

        defp deps do
          [
            {:error_message, "~> 0.3.0"}
          ]
        end
    """

    @doc_missing_dependency """
    The adapter `GQLErrorMessage.Translation.ErrorMessageTranslation`
    requires the `:error_message` dependency.

    You are trying to use this adapter, but `:error_message` could not be found.

    To fix this, add `:error_message` to your mix.exs deps:

        defp deps do
          [
            {:error_message, "~> 0.3.0"}
          ]
        end

    Then run:

        mix deps.get
    """

    @doc false
    def translate_error(_e, _input, _spec) do
      raise @doc_missing_dependency
    end
  end
end
