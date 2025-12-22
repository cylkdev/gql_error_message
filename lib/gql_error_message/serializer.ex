defmodule GQLErrorMessage.Serializer do
  @moduledoc """
  The default serializer for converting Elixir terms into
  JSON-compatible maps.

  This module recursively traverses data structures and
  converts them into a format that can be safely encoded
  as JSON. It handles common Elixir types, including:

    * `Date`, `Time`, `DateTime`, `NaiveDateTime` (converted to ISO 8601 strings)
    * Structs (converted to a map with `:struct` and `:data` keys)
    * Maps, lists, and tuples
    * Atoms (converted to strings)
  """

  @doc """
  Recursively converts a term into a JSON-serializable map or value.
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
    Map.new(data, fn {k, v} -> {to_string(k), to_jsonable_map(v)} end)
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
