defmodule GQLErrorMessage.ChangesetTranslator do
  alias GQLErrorMessage.ClientError

  def translate_error(_op, _input, %Ecto.Changeset{} = changeset) do
    changeset
    |> errors_on()
    |> Enum.reduce([], fn {field, msgs}, acc ->
      Enum.reduce(msgs, acc, fn msg, acc ->
        [%ClientError{field: [field], message: msg} | acc]
      end)
    end)
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        atom_key = String.to_existing_atom(key)
        opts |> Keyword.get(atom_key, key) |> to_string()
      end)
    end)
  end
end
