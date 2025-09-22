if Code.ensure_loaded?(Ecto) do
  defmodule GQLErrorMessage.CommonBridge.ChangesetBridge do
    alias GQLErrorMessage.{ClientError, Spec}

    @doc """
    Translates an error message into a list of GraphQL error structs.

    ## Examples

        iex> changeset = GQLErrorMessage.Support.Schemas.User.changeset(%GQLErrorMessage.Support.Schemas.User{}, %{})
        ...> input = %{name: "alice"}
        ...> spec = %GQLErrorMessage.Spec{
        ...>   operation: :query,
        ...>   kind: :client_error,
        ...>   code: :internal_server_error,
        ...>   message: "internal server error",
        ...>   extensions: %{}
        ...> }
        ...> GQLErrorMessage.CommonBridge.ChangesetBridge.translate_error(changeset, input, spec)
        [%GQLErrorMessage.ClientError{field: :name, message: "can't be blank"}]
    """
    @spec translate_error(changeset :: Ecto.Changeset.t(), input :: map(), spec :: Spec.t()) ::
            list(ClientError.t())
    def translate_error(%Ecto.Changeset{} = changeset, _input, _spec) do
      changeset
      |> errors_on()
      |> Enum.reduce([], fn {field, msgs}, acc ->
        Enum.reduce(msgs, acc, fn msg, acc ->
          [%ClientError{field: field, message: msg} | acc]
        end)
      end)
    end

    @doc false
    def errors_on(changeset) do
      Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
        Regex.replace(~r"%{(\w+)}", message, fn _, key ->
          atom_key = String.to_existing_atom(key)
          opts |> Keyword.get(atom_key, key) |> to_string()
        end)
      end)
    end
  end
else
  defmodule GQLErrorMessage.CommonBridge.ChangesetBridge do
    @doc_missing_dependency """
    The bridge adapter `GQLErrorMessage.CommonBridge.ChangesetBridge`
    requires the `:ecto` dependency.

    You are trying to use this adapter, but `:ecto` could not be found.

    To fix this, add `:ecto` to your mix.exs deps:

        defp deps do
          [
            {:ecto, "~> 3.0"}
          ]
        end

    Then run:

        mix deps.get
    """

    @doc false
    def translate_error(_changeset, _input, _spec) do
      raise @doc_missing_dependency
    end
  end
end
