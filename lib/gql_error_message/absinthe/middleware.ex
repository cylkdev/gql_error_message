defmodule GQLErrorMessage.Absinthe.Middleware do
  @moduledoc """
  Absinthe middleware that translates resolver errors into GraphQL-compliant error structures.

  When an Absinthe resolver returns `{:error, reason}`, the error term is
  placed into the resolution's `errors` list. This middleware intercepts
  those errors after resolution, passes each one through
  `GQLErrorMessage.translate/3`, and places the resulting
  `GQLErrorMessage.ClientError` and `GQLErrorMessage.ServerError` structs
  into the correct location in the GraphQL response.

  This middleware must be placed **after** the `resolve` function in the
  field definition. If it runs before resolution completes, it raises an
  error explaining the correct placement.

  ## Applying the Middleware

  There are two ways to apply this middleware to your schema:

  ### Per-field (explicit)

  Add the middleware directly after `resolve` on individual fields:

      field :create_user, :create_user_payload do
        arg :input, non_null(:create_user_input)

        resolve &Accounts.create_user/3

        middleware GQLErrorMessage.Absinthe.Middleware
      end

  ### Global (via `middleware/3` callback)

  Apply the middleware to all fields by defining the `middleware/3`
  callback in your schema module. This callback receives the current
  middleware list, the field definition, and the parent object type.
  Append this middleware to the end of the list so it runs after
  resolution:

      def middleware(middleware, _field, _object) do
        middleware ++ [GQLErrorMessage.Absinthe.Middleware]
      end

  ## How Errors Are Placed

  The middleware determines the root operation type (query, mutation, or
  subscription) by inspecting the resolution path. The placement of
  errors depends on the operation type:

  ### Mutations

  For mutation fields, errors are split into two groups:

    * **Client errors** (`GQLErrorMessage.ClientError` structs) are
      placed into a `user_errors` key on the resolution value. This
      means your mutation payload type must include a `user_errors`
      field of type `list_of(:user_error)`. Generate the `:user_error`
      type by running `mix gql_error_message.gen.types`.

    * **Server errors** (`GQLErrorMessage.ServerError` structs) are
      placed into the top-level `errors` array of the GraphQL response,
      and the `data` for the mutation field is set to `nil`.

  If both client and server errors are present, server errors take
  priority — the entire mutation field data is set to `nil` and only
  server errors appear in the top-level `errors` array.

  ### Queries and Subscriptions

  For query and subscription fields, all errors are promoted to server
  errors and placed in the top-level `errors` array. Client errors are
  promoted because queries do not have a payload object with a
  `user_errors` field. The `data` for the field is set to `nil`.
  """

  alias GQLErrorMessage.{ClientError, ServerError}

  @doc """
  Called by Absinthe after resolution to translate and place errors.

  This function is invoked automatically by the Absinthe middleware
  pipeline. You do not call it directly. It receives the
  `%Absinthe.Resolution{}` struct and any middleware options (which
  are currently unused).

  There are three clauses:

    1. If the resolution has no errors (`errors: []`), the resolution
       is returned unchanged. No translation occurs.

    2. If the resolution has errors and is in the `:resolved` state,
       each error is translated via `GQLErrorMessage.translate/3` and
       the results are placed according to the operation type (see
       the module documentation for placement rules).

    3. If the resolution is not yet resolved (for example, because
       this middleware was placed before `resolve`), an error is
       raised explaining the correct placement.
  """
  def call(%Absinthe.Resolution{state: :resolved, errors: []} = resolution, _opts) do
    resolution
  end

  def call(
        %Absinthe.Resolution{
          state: :resolved,
          arguments: args,
          errors: errors
        } = resolution,
        opts
      ) do
    op = operation_type(resolution)

    translated =
      errors
      |> List.wrap()
      |> Enum.flat_map(fn error ->
        GQLErrorMessage.translate(error, args, opts)
      end)

    place_errors(resolution, op, translated)
  end

  def call(%Absinthe.Resolution{} = _resolution, _opts) do
    raise """
    ** (GQLErrorMessage.Middleware.PostResolutionOnlyError)
    GQLErrorMessage.Middleware can only be used *after* the resolve function.
    Place it after `resolve/1` in your schema field definition.
    """
  end

  @doc false
  def operation_type(%Absinthe.Resolution{path: path}) do
    path
    |> Enum.at(-1)
    |> Map.fetch!(:schema_node)
    |> Map.fetch!(:identifier)
  end

  defp place_errors(resolution, :mutation, errors) do
    {client_errors, server_errors} = split_by_type(errors)

    if server_errors !== [] do
      %{resolution | errors: Enum.map(server_errors, &ServerError.to_map/1), value: nil}
    else
      value = Map.put(resolution.value || %{}, :user_errors, Enum.map(client_errors, &ClientError.to_map/1))
      %{resolution | errors: [], value: value}
    end
  end

  defp place_errors(resolution, _op, errors) do
    server_errors = Enum.map(errors, &promote_to_server_error/1)
    %{resolution | errors: Enum.map(server_errors, &ServerError.to_map/1), value: nil}
  end

  defp split_by_type(errors) do
    Enum.split_with(errors, &match?(%ClientError{}, &1))
  end

  defp promote_to_server_error(%ServerError{} = error), do: error

  defp promote_to_server_error(%ClientError{message: message}) do
    %ServerError{message: message, extensions: %{}}
  end
end
