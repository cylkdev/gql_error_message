defmodule GQLErrorMessage.Serializer do
  @moduledoc """
  Converts Elixir terms into JSON-serializable values.

  This module is used internally by `GQLErrorMessage.ServerError.to_map/1`
  to ensure that the `extensions` map on a server error can be safely
  encoded as JSON. It recursively traverses data structures and converts
  each element into a type that JSON encoders (such as `Jason`) can
  handle.

  The conversion rules are:

    * `Date`, `Time`, `DateTime`, and `NaiveDateTime` structs are
      converted to ISO 8601 strings (for example,
      `~D[2025-01-15]` becomes `"2025-01-15"`).

    * Other structs are converted to a map with two keys: `:struct`
      (the module name as a string, without the `"Elixir."` prefix) and
      `:data` (the struct fields recursively converted).

    * Maps are converted by recursively converting each value. Keys are
      left unchanged.

    * Lists are converted by recursively converting each element.

    * Tuples are converted to lists (each element recursively converted).

    * Atoms are converted to strings (without the `"Elixir."` prefix for
      module atoms).

    * All other values (numbers, binaries, etc.) are converted to strings
      via `to_string/1`.

  ## Examples

      iex> GQLErrorMessage.Serializer.to_jsonable_map(~D[2025-01-15])
      "2025-01-15"

      iex> GQLErrorMessage.Serializer.to_jsonable_map(%{code: :internal_server_error})
      %{code: "internal_server_error"}

      iex> GQLErrorMessage.Serializer.to_jsonable_map({:error, :timeout})
      ["error", "timeout"]

  """

  @doc """
  Recursively converts a term into a JSON-serializable value.

  This function accepts any Elixir term and returns a value that can be
  safely encoded as JSON. See the module documentation for the complete
  list of conversion rules.

  ## Examples

      iex> GQLErrorMessage.Serializer.to_jsonable_map(:hello)
      "hello"

      iex> GQLErrorMessage.Serializer.to_jsonable_map([:a, :b])
      ["a", "b"]

      iex> GQLErrorMessage.Serializer.to_jsonable_map(%{name: :alice, age: 30})
      %{name: "alice", age: "30"}

  """
  def to_jsonable_map(term)

  def to_jsonable_map(%Date{} = date), do: Date.to_iso8601(date)

  def to_jsonable_map(%Time{} = time), do: Time.to_iso8601(time)

  def to_jsonable_map(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)

  def to_jsonable_map(%NaiveDateTime{} = datetime), do: NaiveDateTime.to_iso8601(datetime)

  def to_jsonable_map(%module{} = struct) do
    %{
      struct: module |> to_string() |> drop_elixir_prefix(),
      data: struct |> Map.from_struct() |> to_jsonable_map()
    }
  end

  def to_jsonable_map(data) when is_map(data) do
    Map.new(data, fn {k, v} -> {k, to_jsonable_map(v)} end)
  end

  def to_jsonable_map(data) when is_list(data) do
    Enum.map(data, &to_jsonable_map/1)
  end

  def to_jsonable_map(data) when is_tuple(data) do
    data |> Tuple.to_list() |> to_jsonable_map()
  end

  def to_jsonable_map(atom) when is_atom(atom) do
    atom |> Atom.to_string() |> drop_elixir_prefix()
  end

  def to_jsonable_map(value), do: to_string(value)

  defp drop_elixir_prefix(string), do: String.replace(string, "Elixir.", "")
end
