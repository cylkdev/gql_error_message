defmodule GQLErrorMessage.CommonError.ErrorMessageTranslator do
  @moduledoc """
  Built-in translator for `ErrorMessage` structs.

  This module converts `ErrorMessage` structs (from the
  [`:error_message`](https://hex.pm/packages/error_message) hex package) into
  `GQLErrorMessage.ClientError` or `GQLErrorMessage.ServerError` structs.
  The `ErrorMessage` library models HTTP-style errors with a status code
  atom (such as `:bad_request` or `:internal_server_error`), a message
  string, and an optional details map.

  ## Client vs. Server Classification

  The translator classifies errors based on the HTTP status code in
  `error.code`:

    * **Client codes** — `:bad_request`, `:unauthorized`, `:forbidden`,
      `:not_found`, `:conflict`, and `:unprocessable_entity` produce
      `GQLErrorMessage.ClientError` structs. These represent problems
      with the user's input that the user can fix.

    * **Server codes** — all other codes (such as
      `:internal_server_error`, `:service_unavailable`, or
      `:gateway_timeout`) produce `GQLErrorMessage.ServerError` structs.
      The uppercased code string (for example, `"INTERNAL_SERVER_ERROR"`)
      is included in the error's `extensions` map under the `:code` key.

  ## Field Inference

  When the `ErrorMessage` struct has a `details` map containing an
  `:input` key whose value is also a map, the translator uses that map
  to figure out which input fields caused the error. It does this by
  collecting the leaf paths from `details.input` and checking whether
  each path exists in the resolver arguments.

  For example, if the error has `details: %{input: %{email: nil}}` and
  the resolver arguments are `%{input: %{email: "bad@", name: "Alice"}}`,
  the translator finds that `:email` exists in both maps. It then
  produces a `ClientError` with `field: [:email]` instead of the
  default `field: []`.

  The resolver arguments are automatically unwrapped: if the top-level
  key is `:input` (as is typical for mutations), the translator looks
  inside `args.input` for the field intersection. For queries, where
  arguments are flat, it uses `args` directly.

  When no paths intersect — or when `details` has no `:input` key — the
  translator produces a single error with `field: []`, meaning the error
  applies to the input as a whole.

  Nested input fields are supported. If `details.input` is
  `%{address: %{zip_code: nil}}` and the resolver arguments contain
  `%{input: %{address: %{zip_code: "000"}}}`, the resulting error will
  have `field: [:address, :zip_code]`.

  ## Message Templates

  The error message may contain `%{key}` and `%{value}` placeholder
  tokens. When field inference finds matching paths, these placeholders
  are replaced:

    * `%{key}` is replaced with the leaf field name as a string (for
      example, `"email"`).

    * `%{value}` is replaced with the string representation of the
      actual input value from the resolver arguments (for example,
      `"bad@"`).

  For example, an error with message `"%{key} is invalid"` and a
  matching field `:email` produces the final message `"email is invalid"`.

  If the message does not contain any `%{` placeholder, it is returned
  unchanged.

  ## Examples

      iex> alias GQLErrorMessage.CommonError.ErrorMessageTranslator
      ...> error = ErrorMessage.bad_request("is invalid")
      ...> ErrorMessageTranslator.translate(error, %{}, [])
      [%GQLErrorMessage.ClientError{field: [], message: "is invalid"}]

      iex> alias GQLErrorMessage.CommonError.ErrorMessageTranslator
      ...> error = ErrorMessage.bad_request("is invalid", %{input: %{email: nil}})
      ...> ErrorMessageTranslator.translate(error, %{input: %{email: "bad@"}}, [])
      [%GQLErrorMessage.ClientError{field: [:email], message: "is invalid"}]

      iex> alias GQLErrorMessage.CommonError.ErrorMessageTranslator
      ...> error = ErrorMessage.internal_server_error("db down")
      ...> ErrorMessageTranslator.translate(error, %{}, [])
      [%GQLErrorMessage.ServerError{message: "db down", extensions: %{code: "INTERNAL_SERVER_ERROR"}}]

  """

  alias GQLErrorMessage.{ClientError, Config, ServerError}

  @client_codes [
    :bad_request,
    :unauthorized,
    :forbidden,
    :not_found,
    :conflict,
    :unprocessable_entity
  ]

  @doc """
  Returns `:client` or `:server` for the given HTTP status code atom.

  This is the built-in classification logic. Hook modules can call this
  function as a fallback in their `classify/2` implementation.

  ## Examples

      iex> GQLErrorMessage.CommonError.ErrorMessageTranslator.classify(:bad_request)
      :client

      iex> GQLErrorMessage.CommonError.ErrorMessageTranslator.classify(:internal_server_error)
      :server

  """
  @spec classify(atom()) :: :client | :server
  def classify(code) when code in @client_codes, do: :client
  def classify(_code), do: :server

  @doc """
  Translates an `ErrorMessage` struct into a list of GraphQL error structs.

  This function performs the full translation pipeline: classification,
  field inference, message template expansion, and error struct
  construction. See the module documentation for details on each step.

  The `error` argument is an `ErrorMessage` struct from the
  [`:error_message`](https://hex.pm/packages/error_message) hex package.

  The `args` argument is the resolver arguments map from the Absinthe
  resolution struct (`resolution.arguments`). For mutations, this map
  typically has the shape `%{input: %{email: "...", name: "..."}}`.
  For queries, the keys are the field arguments directly (for example,
  `%{id: "123"}`). The translator uses this map for field inference —
  it compares the paths in `error.details.input` against the paths in
  `args` to determine which input fields caused the error.

  The `opts` argument is a keyword list that supports:

    * `:error_message_hook` — a module implementing
      `GQLErrorMessage.CommonError.ErrorMessageHook` whose
      callbacks override classification, message building, and field
      inference. Defaults to the value of
      `config :gql_error_message, :error_message_hook` (nil if not set).

  Returns a list of `GQLErrorMessage.ClientError` and/or
  `GQLErrorMessage.ServerError` structs.

  Raises `FunctionClauseError` if `error` is not an `ErrorMessage` struct.

  ## Examples

  Translating a client error without field inference:

      iex> alias GQLErrorMessage.CommonError.ErrorMessageTranslator
      ...> error = ErrorMessage.bad_request("is invalid")
      ...> ErrorMessageTranslator.translate(error, %{}, [])
      [%GQLErrorMessage.ClientError{field: [], message: "is invalid"}]

  Translating a client error with field inference from details and
  arguments:

      iex> alias GQLErrorMessage.CommonError.ErrorMessageTranslator
      ...> error = ErrorMessage.bad_request("is invalid", %{input: %{email: nil}})
      ...> ErrorMessageTranslator.translate(error, %{input: %{email: "bad@"}}, [])
      [%GQLErrorMessage.ClientError{field: [:email], message: "is invalid"}]

  Translating a server error:

      iex> alias GQLErrorMessage.CommonError.ErrorMessageTranslator
      ...> error = ErrorMessage.internal_server_error("db down")
      ...> ErrorMessageTranslator.translate(error, %{}, [])
      [%GQLErrorMessage.ServerError{message: "db down", extensions: %{code: "INTERNAL_SERVER_ERROR"}}]

  """
  @spec translate(ErrorMessage.t(), map(), keyword()) :: [ClientError.t() | ServerError.t()]
  def translate(%ErrorMessage{code: code, message: message, details: details}, args, opts) do
    hook = Keyword.get(opts, :error_message_hook, Config.error_message_hook())

    details = details || %{}

    classification = classify_with_hook(hook, code, details)
    fields = infer_fields_with_hook(hook, details, args)
    final_message = build_message_with_hook(hook, message, code, details, args)

    case classification do
      :client -> build_client_errors(final_message, fields)
      :server -> build_server_errors(final_message, fields, code, details)
    end
  end

  defp build_client_errors(message, []) do
    [%ClientError{field: [], message: message}]
  end

  defp build_client_errors(message, paths) do
    Enum.map(paths, fn {field, value} ->
      %ClientError{
        field: field,
        message: apply_template(message, field, value)
      }
    end)
  end

  defp build_server_errors(message, [], code, details) do
    [%ServerError{message: message, extensions: build_extensions(code, details)}]
  end

  defp build_server_errors(message, paths, code, details) do
    extensions = build_extensions(code, details)

    Enum.map(paths, fn {field, value} ->
      %ServerError{
        message: apply_template(message, field, value),
        extensions: extensions
      }
    end)
  end

  defp get_resolution_input(%{input: input}) when is_map(input), do: input
  defp get_resolution_input(args) when is_map(args), do: args
  defp get_resolution_input(_), do: %{}

  defp get_user_params(details) do
    details[:input] || details[:params] || %{}
  end

  defp build_extensions(code, details) do
    Map.merge(details, %{
      code: code |> to_string() |> String.upcase()
    })
  end

  defp apply_template(message, field, value) do
    if contains_template?(message) do
      message
      |> String.replace("%{key}", field |> List.last() |> to_string())
      |> String.replace("%{value}", to_string(value))
    else
      message
    end
  end

  defp contains_template?(message) when is_binary(message) do
    String.contains?(message, "%{")
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

      if is_map(v) and map_size(v) > 0 do
        collect_paths(v, next_path, acc)
      else
        [next_path | acc]
      end
    end)
  end

  defp collect_paths(_other, _path, acc), do: acc

  defp get_in_path(data, path) when is_list(path) do
    Enum.reduce_while(path, {:ok, data}, fn key, {:ok, current} ->
      if is_map(current) and Map.has_key?(current, key) do
        {:cont, {:ok, Map.fetch!(current, key)}}
      else
        {:halt, :error}
      end
    end)
  end

  defp classify_with_hook(nil, code, _details), do: classify(code)

  defp classify_with_hook(hook, code, details) do
    if Code.ensure_loaded?(hook) and function_exported?(hook, :classify, 2) do
      hook.classify(code, details)
    else
      classify(code)
    end
  end

  defp build_message_with_hook(nil, message, _code, _details, _args), do: message

  defp build_message_with_hook(hook, message, code, details, args) do
    if Code.ensure_loaded?(hook) and function_exported?(hook, :build_message, 4) do
      hook.build_message(message, code, details, args)
    else
      message
    end
  end

  defp infer_fields_with_hook(nil, details, args) do
    default_infer_fields(details, args)
  end

  defp infer_fields_with_hook(hook, details, args) do
    if Code.ensure_loaded?(hook) and function_exported?(hook, :infer_fields, 2) do
      hook.infer_fields(details, args)
    else
      default_infer_fields(details, args)
    end
  end

  defp default_infer_fields(details, args) do
    user_params = get_user_params(details)
    input = get_resolution_input(args)
    intersecting_paths(input, user_params)
  end
end
