if Code.ensure_loaded?(Ecto) do
  defmodule GQLErrorMessage.CommonError.ChangesetTranslation do
    @moduledoc """
    Translates `Ecto.Changeset` errors into `GQLErrorMessage.ClientError` structs.

    This API converts validation and constraint errors from changesets
    into `GQLErrorMessage.ClientError` structs.

    > #### Warning {: .warning}
    >
    > This module requires `:ecto` as a dependency.
    """
    alias GQLErrorMessage.{ClientError, Spec}

    @doc """
    Translates an `Ecto.Changeset` into a list of `GQLErrorMessage.ClientError`
    structs.

    Each error in the changeset is converted into a `GQLErrorMessage.ClientError`, with
    the `field` corresponding to the changeset field and the `message` containing the
    validation error text.

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
        ...> GQLErrorMessage.CommonError.ChangesetTranslation.handle_translate(changeset, input, spec)
        [%GQLErrorMessage.ClientError{field: :name, message: "can't be blank"}]
    """
    @spec handle_translate(changeset :: Ecto.Changeset.t(), input :: map(), spec :: Spec.t()) ::
            list(ClientError.t())
    def handle_translate(%Ecto.Changeset{} = changeset, _input, _spec) do
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
  defmodule GQLErrorMessage.CommonError.ChangesetTranslation do
    @moduledoc """
    This is a stub module that is compiled when the `:ecto` dependency
    is not available. All functions in this module will raise an error
    when called.

    To fix this, add `:ecto` to your `mix.exs` deps:

        defp deps do
          [
            {:ecto, "~> 3.0"}
          ]
        end
    """

    @doc_missing_dependency """
    The adapter `GQLErrorMessage.CommonError.ChangesetTranslation`
    requires the `:ecto` dependency.

    You are trying to use this adapter, but `:ecto` could not be found.

    To fix this, add `:ecto` to your `mix.exs` deps:

        defp deps do
          [
            {:ecto, "~> 3.0"}
          ]
        end

    Then run:

        mix deps.get
    """

    @doc false
    def handle_translate(_changeset, _input, _spec) do
      raise @doc_missing_dependency
    end
  end
end
