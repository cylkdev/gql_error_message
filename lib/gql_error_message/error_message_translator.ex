defmodule GQLErrorMessage.ErrorMessageTranslator do
  alias GQLErrorMessage.{ClientError, ServerError}

  @type operation :: :mutation | :query | :subscription

  @doc """
  Translates an `%ErrorMessage{}` into GraphQL-safe error structs.

  ## Details schema

  The translator supports a simple, explicit schema under `error.details`:

    * `:input` - a map describing the input fields related to the error.
      This is used to build deep field paths. The *shape* (keys and nesting)
      is what matters.
    * `:message` - optional override message template.
    * `:extensions` - optional server error extensions.

  Message templates may include `%{key}` and `%{value}` placeholders.
  """
  @spec translate_error(operation(), map(), ErrorMessage.t()) :: [
          ClientError.t() | ServerError.t()
        ]
  def translate_error(op, input, %ErrorMessage{code: code} = e) do
    kind = kind_for_code(code)
    translate_error(op, input, e, kind)
  end

  defp translate_error(:mutation, input, %ErrorMessage{} = e, :server) do
    {msg, details_input, extensions} = normalize_details(e)

    input
    |> intersecting_paths(details_input)
    |> case do
      [] ->
        [%ServerError{message: msg, extensions: extensions}]

      paths ->
        Enum.map(paths, fn {field, value} ->
          key = List.last(field)
          msg2 = replace_template(msg, key, value)
          %ServerError{message: msg2, extensions: extensions}
        end)
    end
  end

  defp translate_error(:mutation, input, %ErrorMessage{} = e, :client) do
    {msg, details_input, _extensions} = normalize_details(e)

    input
    |> intersecting_paths(details_input)
    |> case do
      [] ->
        [%ClientError{field: ["unknown"], message: msg}]

      paths ->
        Enum.map(paths, fn {field, value} ->
          key = List.last(field)
          msg2 = replace_template(msg, key, value)
          %ClientError{field: field, message: msg2}
        end)
    end
  end

  defp translate_error(op, _input, %ErrorMessage{} = e, :server)
       when op in [:query, :subscription] do
    {msg, _details_input, extensions} = normalize_details(e)
    [%ServerError{message: msg, extensions: extensions}]
  end

  defp translate_error(op, input, %ErrorMessage{} = e, :client)
       when op in [:query, :subscription] do
    {msg, details_input, extensions} = normalize_details(e)

    # Queries/subscriptions cannot return client errors. We translate them into
    # server errors. If we can build per-field messages, we emit one server error
    # per field; otherwise we emit a single server error.
    input
    |> intersecting_paths(details_input)
    |> case do
      [] ->
        [%ServerError{message: msg, extensions: extensions}]

      paths ->
        Enum.map(paths, fn {field, value} ->
          key = List.last(field)
          msg2 = replace_template(msg, key, value)
          %ServerError{message: msg2, extensions: extensions}
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
  @spec intersecting_paths(input :: map(), error_input :: map()) ::
          list({path :: list(), value :: term()})
  def intersecting_paths(input, error_input) when is_map(input) and is_map(error_input) do
    error_input
    |> collect_paths([], [])
    |> Enum.reduce([], fn path, acc ->
      case get_in_path(input, path) do
        {:ok, value} -> [{path, value} | acc]
        :error -> acc
      end
    end)
    |> Enum.reverse()
  end

  def intersecting_paths(_input, _error_input), do: []

  defp collect_paths(map, path, acc) when is_map(map) do
    Enum.reduce(map, acc, fn {k, v}, acc ->
      next_path = path ++ [k]

      cond do
        is_map(v) and map_size(v) > 0 ->
          collect_paths(v, next_path, acc)

        true ->
          [next_path | acc]
      end
    end)
  end

  defp collect_paths(_other, _path, acc), do: acc

  defp get_in_path(data, path) when is_list(path) do
    Enum.reduce_while(path, {:ok, data}, fn key, {:ok, current} ->
      cond do
        is_map(current) and Map.has_key?(current, key) ->
          {:cont, {:ok, Map.fetch!(current, key)}}

        true ->
          {:halt, :error}
      end
    end)
  end

  defp normalize_details(%ErrorMessage{} = e) do
    details = e.details || %{}

    msg =
      cond do
        is_map(details) and is_binary(details[:message]) -> details[:message]
        is_binary(e.message) -> e.message
        true -> "unexpected error"
      end

    input =
      if is_map(details) and is_map(details[:input]) do
        details[:input]
      else
        %{}
      end

    extensions =
      if is_map(details) and is_map(details[:extensions]) do
        details[:extensions]
      else
        %{}
      end

    {msg, input, extensions}
  end

  defp kind_for_code(code) when is_atom(code) do
    if code in [
         :forbidden,
         :conflict,
         :not_found,
         :unprocessable_entity,
         :bad_request
       ] do
      :client
    else
      :server
    end
  end

  defp kind_for_code(_), do: :server
end
