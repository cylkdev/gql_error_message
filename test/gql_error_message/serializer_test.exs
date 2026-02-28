defmodule GQLErrorMessage.SerializerTest do
  use ExUnit.Case, async: true

  doctest GQLErrorMessage.Serializer

  alias GQLErrorMessage.Serializer

  describe "to_jsonable_map/1" do
    test "converts a Date to ISO 8601 string" do
      assert "2025-01-15" === Serializer.to_jsonable_map(~D[2025-01-15])
    end

    test "converts a Time to ISO 8601 string" do
      assert "13:45:00" === Serializer.to_jsonable_map(~T[13:45:00])
    end

    test "converts a DateTime to ISO 8601 string" do
      {:ok, dt, _} = DateTime.from_iso8601("2025-01-15T13:45:00Z")

      assert "2025-01-15T13:45:00Z" === Serializer.to_jsonable_map(dt)
    end

    test "converts a NaiveDateTime to ISO 8601 string" do
      assert "2025-01-15T13:45:00" === Serializer.to_jsonable_map(~N[2025-01-15 13:45:00])
    end

    test "converts a struct to a map with :struct and :data keys" do
      assert %{struct: "URI", data: %{host: "example.com"}} =
               Serializer.to_jsonable_map(%URI{host: "example.com", port: 443})
    end

    test "converts a map recursively" do
      input = %{name: :alice, age: 30}
      result = Serializer.to_jsonable_map(input)

      assert result === %{name: "alice", age: "30"}
    end

    test "converts a list recursively" do
      input = [:a, :b, :c]
      result = Serializer.to_jsonable_map(input)

      assert result === ["a", "b", "c"]
    end

    test "converts a tuple to a list" do
      assert ["a", "b"] === Serializer.to_jsonable_map({:a, :b})
    end

    test "converts atoms to strings without Elixir. prefix" do
      assert "hello" === Serializer.to_jsonable_map(:hello)
    end

    test "passes through strings" do
      assert "hello" === Serializer.to_jsonable_map("hello")
    end

    test "converts numbers to strings" do
      assert "42" === Serializer.to_jsonable_map(42)
    end
  end
end
