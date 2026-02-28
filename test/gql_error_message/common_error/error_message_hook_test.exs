defmodule GQLErrorMessage.CommonError.ErrorMessageHookTest do
  use ExUnit.Case, async: true

  alias GQLErrorMessage.{ClientError, ServerError}
  alias GQLErrorMessage.CommonError.ErrorMessageTranslator
  alias GQLErrorMessage.Support.Hooks.ClassifyOnlyHook
  alias GQLErrorMessage.Support.Hooks.MessageOnlyHook
  alias GQLErrorMessage.Support.Hooks.FieldInferenceHook
  alias GQLErrorMessage.Support.Hooks.FullHook

  describe "classify hook" do
    test "overrides classification from client to server" do
      error = ErrorMessage.bad_request("critical failure", %{severity: :critical})

      result =
        ErrorMessageTranslator.translate(error, %{}, error_message_hook: ClassifyOnlyHook)

      assert [%ServerError{message: "critical failure"}] = result
    end

    test "falls back to default classification when hook does not override" do
      error = ErrorMessage.bad_request("is invalid")

      result =
        ErrorMessageTranslator.translate(error, %{}, error_message_hook: ClassifyOnlyHook)

      assert [%ClientError{field: [], message: "is invalid"}] === result
    end

    test "server codes remain server with classify hook" do
      error = ErrorMessage.internal_server_error("db down")

      result =
        ErrorMessageTranslator.translate(error, %{}, error_message_hook: ClassifyOnlyHook)

      assert [%ServerError{message: "db down"}] = result
    end
  end

  describe "build_message hook" do
    test "customizes message based on code and details" do
      error = ErrorMessage.conflict("duplicate", %{entity: "user"})

      result =
        ErrorMessageTranslator.translate(error, %{}, error_message_hook: MessageOnlyHook)

      assert [%ClientError{field: [], message: "A user with that value already exists"}] ===
               result
    end

    test "falls back to original message when hook does not override" do
      error = ErrorMessage.bad_request("is invalid")

      result =
        ErrorMessageTranslator.translate(error, %{}, error_message_hook: MessageOnlyHook)

      assert [%ClientError{field: [], message: "is invalid"}] === result
    end
  end

  describe "infer_fields hook" do
    test "overrides field inference with custom logic" do
      error = ErrorMessage.bad_request("is invalid", %{fields: [:email]})
      args = %{email: "bad@"}

      result =
        ErrorMessageTranslator.translate(error, args, error_message_hook: FieldInferenceHook)

      assert [%ClientError{field: [:email], message: "is invalid"}] === result
    end

    test "returns empty fields when hook details do not match" do
      error = ErrorMessage.bad_request("is invalid")

      result =
        ErrorMessageTranslator.translate(error, %{}, error_message_hook: FieldInferenceHook)

      assert [%ClientError{field: [], message: "is invalid"}] === result
    end
  end

  describe "full hook (all callbacks)" do
    test "classify override works with full hook" do
      error = ErrorMessage.bad_request("critical", %{severity: :critical})

      result = ErrorMessageTranslator.translate(error, %{}, error_message_hook: FullHook)

      assert [%ServerError{message: "critical"}] = result
    end

    test "message override works with full hook" do
      error = ErrorMessage.conflict("dup", %{entity: "account"})

      result = ErrorMessageTranslator.translate(error, %{}, error_message_hook: FullHook)

      assert [%ClientError{field: [], message: "A account with that value already exists"}] ===
               result
    end

    test "field inference override works with full hook" do
      error = ErrorMessage.bad_request("is invalid", %{fields: [:name]})
      args = %{name: ""}

      result = ErrorMessageTranslator.translate(error, args, error_message_hook: FullHook)

      assert [%ClientError{field: [:name], message: "is invalid"}] === result
    end
  end

  describe "no hook (nil)" do
    test "uses default behavior when no hook is configured" do
      error = ErrorMessage.bad_request("is invalid")

      result = ErrorMessageTranslator.translate(error, %{}, [])

      assert [%ClientError{field: [], message: "is invalid"}] === result
    end

    test "default field inference still works" do
      error = ErrorMessage.bad_request("is invalid", %{input: %{email: nil}})
      args = %{input: %{email: "bad@"}}

      result = ErrorMessageTranslator.translate(error, args, [])

      assert [%ClientError{field: [:email], message: "is invalid"}] === result
    end
  end

  describe "hook via top-level translate/3" do
    test "opts flow through to ErrorMessageTranslator" do
      error = ErrorMessage.bad_request("critical", %{severity: :critical})

      result =
        GQLErrorMessage.translate(error, %{}, error_message_hook: ClassifyOnlyHook)

      assert [%ServerError{message: "critical"}] = result
    end

    test "message hook flows through top-level" do
      error = ErrorMessage.conflict("dup", %{entity: "order"})

      result =
        GQLErrorMessage.translate(error, %{}, error_message_hook: MessageOnlyHook)

      assert [%ClientError{field: [], message: "A order with that value already exists"}] ===
               result
    end
  end
end
