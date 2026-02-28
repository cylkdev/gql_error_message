defmodule GQLErrorMessage.CommonError.HandleErrorTest do
  use ExUnit.Case, async: true

  alias GQLErrorMessage.{ClientError, ServerError}
  alias GQLErrorMessage.CommonError
  alias GQLErrorMessage.CommonError.ErrorContext
  alias GQLErrorMessage.Support.Hooks.ClassifyOnlyHook
  alias GQLErrorMessage.Support.Hooks.FullHook

  describe "handle_error/2" do
    test "passes through {:ok, value} unchanged" do
      result = CommonError.handle_error(ClassifyOnlyHook, fn -> {:ok, %{user: "alice"}} end)

      assert {:ok, %{user: "alice"}} === result
    end

    test "wraps {:error, reason} in ErrorContext" do
      error = ErrorMessage.bad_request("is invalid")

      result = CommonError.handle_error(ClassifyOnlyHook, fn -> {:error, error} end)

      assert {:error, %ErrorContext{value: ^error, hook_module: ClassifyOnlyHook}} = result
    end

    test "sets the hook module on the struct" do
      result = CommonError.handle_error(FullHook, fn -> {:error, "some reason"} end)

      assert {:error, %ErrorContext{hook_module: FullHook}} = result
    end
  end

  describe "handle_error/2 integration with translate/3" do
    test "hook classify callback is used when translating a wrapped error" do
      error = ErrorMessage.bad_request("critical failure", %{severity: :critical})

      {:error, wrapped} = CommonError.handle_error(ClassifyOnlyHook, fn -> {:error, error} end)

      result = CommonError.translate(wrapped, %{}, [])

      assert [%ServerError{message: "critical failure"}] = result
    end

    test "hook classify falls back to default when not overridden" do
      error = ErrorMessage.bad_request("is invalid")

      {:error, wrapped} = CommonError.handle_error(ClassifyOnlyHook, fn -> {:error, error} end)

      result = CommonError.translate(wrapped, %{}, [])

      assert [%ClientError{field: [], message: "is invalid"}] === result
    end

    test "full hook callbacks are used when translating a wrapped error" do
      error = ErrorMessage.conflict("dup", %{entity: "user"})

      {:error, wrapped} = CommonError.handle_error(FullHook, fn -> {:error, error} end)

      result = CommonError.translate(wrapped, %{}, [])

      assert [%ClientError{field: [], message: "A user with that value already exists"}] ===
               result
    end

    test "full hook field inference is used with wrapped error" do
      error = ErrorMessage.bad_request("is invalid", %{fields: [:email]})
      args = %{email: "bad@"}

      {:error, wrapped} = CommonError.handle_error(FullHook, fn -> {:error, error} end)

      result = CommonError.translate(wrapped, args, [])

      assert [%ClientError{field: [:email], message: "is invalid"}] === result
    end

    test "flows through top-level GQLErrorMessage.translate/3" do
      error = ErrorMessage.bad_request("critical", %{severity: :critical})

      {:error, wrapped} =
        CommonError.handle_error(ClassifyOnlyHook, fn -> {:error, error} end)

      result = GQLErrorMessage.translate(wrapped, %{})

      assert [%ServerError{message: "critical"}] = result
    end
  end
end
