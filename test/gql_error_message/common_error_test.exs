defmodule GQLErrorMessage.CommonErrorTest do
  use ExUnit.Case, async: true

  doctest GQLErrorMessage.CommonError

  alias GQLErrorMessage.{ClientError, ServerError}
  alias GQLErrorMessage.Support.Schemas.User
  alias GQLErrorMessage.CommonError

  describe "translate/3 with ErrorMessage structs" do
    test "delegates client ErrorMessage to ErrorMessageTranslator" do
      error = ErrorMessage.bad_request("is invalid")

      assert [%ClientError{field: [], message: "is invalid"}] ===
               CommonError.translate(error, %{}, [])
    end

    test "delegates server ErrorMessage to ErrorMessageTranslator" do
      error = ErrorMessage.internal_server_error("db down")

      assert [%ServerError{message: "db down"}] =
               CommonError.translate(error, %{}, [])
    end

    test "passes args through for field inference" do
      error = ErrorMessage.bad_request("is invalid", %{input: %{email: nil}})
      args = %{email: "bad@"}

      assert [%ClientError{field: [:email], message: "is invalid"}] ===
               CommonError.translate(error, args, [])
    end
  end

  describe "translate/3 passthrough clauses" do
    test "returns a ClientError unchanged" do
      error = %ClientError{field: [:email], message: "taken"}

      assert [^error] = CommonError.translate(error, %{}, [])
    end

    test "returns a ServerError unchanged" do
      error = %ServerError{message: "db down", extensions: %{code: "INTERNAL_SERVER_ERROR"}}

      assert [^error] = CommonError.translate(error, %{}, [])
    end
  end

  describe "translate/3 with Absinthe-normalized plain maps" do
    test "translates a ServerError-shaped map to a ServerError" do
      error = %{message: "not authorized", extensions: %{}}

      assert [%ServerError{message: "not authorized", extensions: %{}}] ===
               CommonError.translate(error, %{}, [])
    end

    test "translates a ClientError-shaped map to a ClientError" do
      error = %{message: "is invalid", field: [:email]}

      assert [%ClientError{field: [:email], message: "is invalid"}] ===
               CommonError.translate(error, %{}, [])
    end

    test "translates a bare message map to a ServerError" do
      error = %{message: "something went wrong"}

      assert [%ServerError{message: "something went wrong", extensions: %{}}] ===
               CommonError.translate(error, %{}, [])
    end
  end

  describe "translate/3 with Ecto.Changeset structs" do
    test "delegates changeset errors to ChangesetTranslator" do
      changeset = User.changeset(%User{}, %{})

      assert [%ClientError{field: [:name], message: "can't be blank"}] ===
               CommonError.translate(changeset, %{}, [])
    end
  end
end
