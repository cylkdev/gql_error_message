defmodule GQLErrorMessage.ServerErrorTest do
  use ExUnit.Case, async: true

  doctest GQLErrorMessage.ServerError

  alias GQLErrorMessage.ServerError

  describe "new/1" do
    test "creates a ServerError with message and default extensions" do
      error = ServerError.new("something broke")

      assert %ServerError{message: "something broke", extensions: %{}} === error
    end
  end

  describe "new/2" do
    test "creates a ServerError with message and extensions" do
      error = ServerError.new("something broke", %{"code" => "INTERNAL"})

      assert %ServerError{message: "something broke", extensions: %{"code" => "INTERNAL"}} ===
               error
    end
  end

  describe "to_map/1" do
    test "converts to a plain map with serialized extensions" do
      error = %ServerError{message: "fail", extensions: %{"code" => "BAD"}}

      assert %{message: "fail", extensions: %{"code" => "BAD"}} === ServerError.to_map(error)
    end

    test "serializes complex extension values" do
      error = %ServerError{
        message: "fail",
        extensions: %{code: :internal, timestamp: ~D[2025-01-01]}
      }

      assert %{message: "fail", extensions: %{code: "internal", timestamp: "2025-01-01"}} =
               ServerError.to_map(error)
    end
  end
end
