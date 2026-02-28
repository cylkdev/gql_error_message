defmodule GQLErrorMessage.ClientErrorTest do
  use ExUnit.Case, async: true

  doctest GQLErrorMessage.ClientError

  alias GQLErrorMessage.ClientError

  describe "new/2" do
    test "creates a ClientError with field and message" do
      error = ClientError.new([:email], "is invalid")

      assert %ClientError{field: [:email], message: "is invalid"} === error
    end

    test "creates a ClientError with a nested field path" do
      error = ClientError.new([:address, :zip_code], "is required")

      assert %ClientError{field: [:address, :zip_code], message: "is required"} === error
    end

    test "creates a ClientError with an empty field path" do
      error = ClientError.new([], "general error")

      assert %ClientError{field: [], message: "general error"} === error
    end
  end

  describe "to_map/1" do
    test "converts to a plain map" do
      error = %ClientError{field: [:name], message: "can't be blank"}

      assert %{field: [:name], message: "can't be blank"} === ClientError.to_map(error)
    end
  end
end
