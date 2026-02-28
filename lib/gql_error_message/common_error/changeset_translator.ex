defmodule GQLErrorMessage.CommonError.ChangesetTranslator do
  @moduledoc """
  Built-in translator for `Ecto.Changeset` structs.

  This module converts invalid `Ecto.Changeset` structs into a list of
  `GQLErrorMessage.ClientError` structs, one per field/message pair.
  Ecto changesets are the standard way to validate data in Elixir
  applications that use the [`:ecto`](https://hex.pm/packages/ecto) hex
  package. When a changeset fails validation, it accumulates errors as a
  keyword list on `changeset.errors`, where each key is a field name and
  each value is a `{message, opts}` tuple.

  This translator uses `Ecto.Changeset.traverse_errors/2` to walk the
  error structure and interpolate any `%{placeholder}` tokens in the
  message (such as `%{count}` in `"should be at least %{count} characters"`).
  Each resulting field/message pair becomes a separate `ClientError` with
  `field: [field_atom]`.

  The default translator (`GQLErrorMessage.CommonError`) delegates
  `Ecto.Changeset` errors to this module automatically. If you write a
  custom translator, you can call this module directly for changeset
  errors:

      def translate(%Ecto.Changeset{} = changeset, args) do
        GQLErrorMessage.CommonError.ChangesetTranslator.translate(changeset, args)
      end

  The resolver arguments (the second argument to `translate/2`) are
  not used by this module. The changeset already contains all the
  information needed to produce the error list.

  > #### Note {: .info}
  >
  > This module requires `:ecto` as a dependency.

  ## Examples

      iex> alias GQLErrorMessage.CommonError.ChangesetTranslator
      ...> changeset = Ecto.Changeset.change({%{}, %{email: :string}}, %{})
      ...> changeset = Ecto.Changeset.add_error(changeset, :email, "is invalid")
      ...> ChangesetTranslator.translate(changeset, %{})
      [%GQLErrorMessage.ClientError{field: [:email], message: "is invalid"}]

  """

  alias Ecto.Changeset
  alias GQLErrorMessage.ClientError

  @doc """
  Translates an `Ecto.Changeset` into a list of `ClientError` structs.

  This function uses `Ecto.Changeset.traverse_errors/2` to walk the
  changeset's error structure. Each field/message pair in the changeset
  errors becomes a separate `GQLErrorMessage.ClientError` struct with
  `field: [field_atom]` and the interpolated message string. Any
  `%{placeholder}` tokens in the message (such as `%{count}` in
  `"should be at least %{count} characters"`) are replaced with their
  corresponding values from the error options.

  The `changeset` argument is an `Ecto.Changeset` struct. It can be valid
  or invalid. If the changeset has no errors, an empty list is returned.

  The `args` argument is the resolver arguments map. This module does not
  use the resolver arguments — the changeset already contains all the
  information needed to produce the error list. The argument is accepted
  to match the translator function signature used by
  `GQLErrorMessage.CommonError`.

  Returns a list of `GQLErrorMessage.ClientError` structs, one per
  field/message pair. Returns an empty list if the changeset has no errors.

  Raises `FunctionClauseError` if `changeset` is not an `Ecto.Changeset`
  struct.

  ## Examples

  Translating a changeset with a single validation error:

      iex> alias GQLErrorMessage.CommonError.ChangesetTranslator
      ...> changeset = Ecto.Changeset.change({%{}, %{email: :string}}, %{})
      ...> changeset = Ecto.Changeset.add_error(changeset, :email, "is invalid")
      ...> ChangesetTranslator.translate(changeset, %{})
      [%GQLErrorMessage.ClientError{field: [:email], message: "is invalid"}]

  Translating a valid changeset returns an empty list:

      iex> alias GQLErrorMessage.CommonError.ChangesetTranslator
      ...> changeset = Ecto.Changeset.change({%{}, %{name: :string}}, %{})
      ...> ChangesetTranslator.translate(changeset, %{})
      []

  """
  @spec translate(Ecto.Changeset.t(), map()) :: [ClientError.t()]
  def translate(%Changeset{} = changeset, _args) do
    changeset
    |> Changeset.traverse_errors(&format_error/1)
    |> flatten_errors([])
  end

  defp flatten_errors(errors, path) when is_map(errors) do
    Enum.flat_map(errors, fn {field, value} ->
      flatten_errors(value, path ++ [field])
    end)
  end

  defp flatten_errors(errors, path) when is_list(errors) do
    Enum.flat_map(errors, &flatten_errors(&1, path))
  end

  defp flatten_errors(message, path) when is_binary(message) do
    [%ClientError{field: path, message: message}]
  end

  defp format_error({message, opts}) do
    Regex.replace(~r"%{(\w+)}", message, fn _, key ->
      atom_key = String.to_existing_atom(key)
      opts |> Keyword.get(atom_key, key) |> to_string()
    end)
  end
end
