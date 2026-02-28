defmodule GQLErrorMessageTest do
  use ExUnit.Case, async: true

  doctest GQLErrorMessage

  alias GQLErrorMessage.{ClientError, ServerError}
  alias GQLErrorMessage.Support.Schemas.User

  describe "translate/2" do
    test "translates an ErrorMessage with a client code" do
      error = ErrorMessage.not_found("user not found")

      assert [%ClientError{field: [], message: "user not found"}] ===
               GQLErrorMessage.translate(error, %{})
    end

    test "translates an ErrorMessage with a server code" do
      error = ErrorMessage.internal_server_error("database error")

      assert [%ServerError{message: "database error"}] =
               GQLErrorMessage.translate(error, %{})
    end

    test "translates an Ecto.Changeset" do
      changeset = User.changeset(%User{}, %{})

      assert [%ClientError{field: [:name], message: "can't be blank"}] ===
               GQLErrorMessage.translate(changeset, %{})
    end

    test "raises for unknown error types" do
      assert_raise RuntimeError, ~r/Unsupported error type/, fn ->
        GQLErrorMessage.translate("unknown error", %{})
      end
    end
  end

  describe "translate/3" do
    test "passes args through to translators for field inference" do
      error = ErrorMessage.bad_request("is invalid", %{input: %{email: nil}})
      args = %{email: "bad@"}

      assert [%ClientError{field: [:email], message: "is invalid"}] ===
               GQLErrorMessage.translate(error, args)
    end

    test "works with empty args" do
      error = ErrorMessage.not_found("missing")

      assert [%ClientError{field: [], message: "missing"}] ===
               GQLErrorMessage.translate(error, %{}, [])
    end
  end
end
