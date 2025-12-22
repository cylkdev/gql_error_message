defmodule GQLErrorMessage.ErrorMessageTranslator do
  alias GQLErrorMessage.{
    ClientError,
    ServerError,
    ErrorMessageDefinition
  }

  def translate_error(op, input, %ErrorMessage{code: code} = e) do
    spec = ErrorMessageDefinition.fetch_spec!(op, code)
    translate_error(op, input, e, spec)
  end

  def translate_error(:mutation, input, %ErrorMessage{} = e, %{kind: :server_error} = spec) do
    case e.details do
      nil ->
        extensions = e.details || %{}
        [%ServerError{message: e.message, extensions: extensions}]

      details ->
        msg = details[:message] || e.message || spec.message
        error_inputs = details[:input] || details[:params] || Map.delete(details, :gql)

        extensions = Map.merge(spec.extensions || %{}, details[:extensions] || %{})

        input
        |> intersecting_paths(error_inputs)
        |> Enum.map(fn {field, value} ->
          key = List.last(field)
          msg2 = replace_template(msg, key, value)
          %ServerError{message: msg2, extensions: extensions}
        end)
    end
  end

  def translate_error(:mutation, _input, %ErrorMessage{code: code} = e, %{kind: :client_error} = _spec) do
    code2 = code |> Atom.to_string() |> String.upcase()
    extensions = Map.put(e.details || %{}, :code, code2)
    [%ServerError{message: e.message, extensions: extensions}]
  end

  def translate_error(:query, _input, %ErrorMessage{} = e, %{kind: :server_error} = _spec) do
    [%ServerError{message: e.message, extensions: e.details || %{}}]
  end

  def translate_error(:query, input, %ErrorMessage{} = e, %{kind: :client_error} = spec) do
    case e.details do
      nil ->
        [%ClientError{field: ["unknown"], message: e.message}]

      details ->
        msg = details[:message] || e.message || spec.message
        error_inputs = details[:input] || details[:params] || Map.delete(details, :gql)

        input
        |> intersecting_paths(error_inputs)
        |> Enum.map(fn {field, value} ->
          key = List.last(field)
          msg2 = replace_template(msg, key, value)
          %ClientError{field: field, message: msg2}
        end)
    end
  end

  defp replace_template(str, key, value) do
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
  @spec intersecting_paths(input :: map(), error_inputs :: map()) ::
          list({path :: list(), value :: term()})
  def intersecting_paths(input, error_inputs) do
    input
    |> collect_intersected_paths(error_inputs, [], [])
    |> Enum.reverse()
  end

  defp collect_intersected_paths(inputs, error_value, path, acc) when is_list(inputs) do
    if Keyword.keyword?(inputs) do
      Enum.reduce(inputs, acc, fn input, acc ->
        collect_intersected_paths(input, error_value, path, acc)
      end)
    else
      if inputs === error_value do
        [{Enum.reverse(path), inputs} | acc]
      else
        acc
      end
    end
  end

  defp collect_intersected_paths(input, errors, path, acc) when is_list(errors) do
    Enum.reduce(errors, acc, fn error, acc ->
      collect_intersected_paths(input, error, path, acc)
    end)
  end

  defp collect_intersected_paths({input_key, input_val}, error_inputs, path, acc) do
    if Map.has_key?(error_inputs, input_key) do
      next_error_inputs = Map.fetch!(error_inputs, input_key)
      next_path = [input_key | path]
      collect_intersected_paths(input_val, next_error_inputs, next_path, acc)
    else
      acc
    end
  end

  defp collect_intersected_paths(input, error_inputs, path, acc) when is_map(input) do
    input
    |> Map.to_list()
    |> collect_intersected_paths(error_inputs, path, acc)
  end

  defp collect_intersected_paths(user_leaf, error_leaf, path, acc) do
    if user_leaf === error_leaf do
      [{Enum.reverse(path), user_leaf} | acc]
    else
      acc
    end
  end
end
