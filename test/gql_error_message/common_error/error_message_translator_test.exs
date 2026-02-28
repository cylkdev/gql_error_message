defmodule GQLErrorMessage.CommonError.ErrorMessageTranslatorTest do
  use ExUnit.Case, async: true

  doctest GQLErrorMessage.CommonError.ErrorMessageTranslator

  alias GQLErrorMessage.{ClientError, ServerError}
  alias GQLErrorMessage.CommonError.ErrorMessageTranslator

  describe "translate/3 client codes" do
    test "translates :bad_request to a ClientError" do
      error = ErrorMessage.bad_request("invalid input")

      assert [%ClientError{field: [], message: "invalid input"}] ===
               ErrorMessageTranslator.translate(error, %{}, [])
    end

    test "translates :unauthorized to a ClientError" do
      error = ErrorMessage.unauthorized("must log in")

      assert [%ClientError{field: [], message: "must log in"}] ===
               ErrorMessageTranslator.translate(error, %{}, [])
    end

    test "translates :forbidden to a ClientError" do
      error = ErrorMessage.forbidden("not allowed")

      assert [%ClientError{field: [], message: "not allowed"}] ===
               ErrorMessageTranslator.translate(error, %{}, [])
    end

    test "translates :not_found to a ClientError" do
      error = ErrorMessage.not_found("resource missing")

      assert [%ClientError{field: [], message: "resource missing"}] ===
               ErrorMessageTranslator.translate(error, %{}, [])
    end

    test "translates :conflict to a ClientError" do
      error = ErrorMessage.conflict("already exists")

      assert [%ClientError{field: [], message: "already exists"}] ===
               ErrorMessageTranslator.translate(error, %{}, [])
    end

    test "translates :unprocessable_entity to a ClientError" do
      error = ErrorMessage.unprocessable_entity("cannot process")

      assert [%ClientError{field: [], message: "cannot process"}] ===
               ErrorMessageTranslator.translate(error, %{}, [])
    end
  end

  describe "translate/3 server codes" do
    test "translates :internal_server_error to a ServerError" do
      error = ErrorMessage.internal_server_error("something broke")

      assert [%ServerError{message: "something broke"}] =
               ErrorMessageTranslator.translate(error, %{}, [])
    end

    test "translates :service_unavailable to a ServerError" do
      error = ErrorMessage.service_unavailable("down for maintenance")

      assert [%ServerError{message: "down for maintenance"}] =
               ErrorMessageTranslator.translate(error, %{}, [])
    end

    test "translates :bad_gateway to a ServerError" do
      error = ErrorMessage.bad_gateway("upstream failed")

      assert [%ServerError{message: "upstream failed"}] =
               ErrorMessageTranslator.translate(error, %{}, [])
    end

    test "translates :gateway_timeout to a ServerError" do
      error = ErrorMessage.gateway_timeout("timed out")

      assert [%ServerError{message: "timed out"}] =
               ErrorMessageTranslator.translate(error, %{}, [])
    end

    test "includes uppercased code in extensions" do
      error = ErrorMessage.internal_server_error("fail")

      assert [%ServerError{message: "fail", extensions: %{code: "INTERNAL_SERVER_ERROR"}}] =
               ErrorMessageTranslator.translate(error, %{}, [])
    end
  end

  describe "translate/3 field inference for client errors" do
    test "infers field path from details[:input] intersecting with args" do
      error = ErrorMessage.unprocessable_entity("is invalid", %{input: %{email: nil}})
      args = %{email: "bad@"}

      assert [%ClientError{field: [:email], message: "is invalid"}] ===
               ErrorMessageTranslator.translate(error, args, [])
    end

    test "infers nested field paths" do
      error =
        ErrorMessage.unprocessable_entity("is invalid", %{
          input: %{address: %{zip_code: nil}}
        })

      args = %{address: %{zip_code: "000"}}

      assert [%ClientError{field: [:address, :zip_code], message: "is invalid"}] ===
               ErrorMessageTranslator.translate(error, args, [])
    end

    test "produces multiple errors when multiple paths intersect" do
      error =
        ErrorMessage.bad_request("is required", %{input: %{name: nil, email: nil}})

      args = %{name: "", email: ""}

      result = ErrorMessageTranslator.translate(error, args, [])

      assert [
               %ClientError{field: [:email], message: "is required"},
               %ClientError{field: [:name], message: "is required"}
             ] = Enum.sort_by(result, & &1.field)
    end

    test "falls back to field: [] when details[:input] does not intersect args" do
      error = ErrorMessage.bad_request("oops", %{input: %{foo: nil}})
      args = %{bar: "baz"}

      assert [%ClientError{field: [], message: "oops"}] ===
               ErrorMessageTranslator.translate(error, args, [])
    end

    test "falls back to field: [] when args is empty" do
      error = ErrorMessage.bad_request("oops", %{input: %{email: nil}})

      assert [%ClientError{field: [], message: "oops"}] ===
               ErrorMessageTranslator.translate(error, %{}, [])
    end

    test "falls back to field: [] when details has no :input key" do
      error = ErrorMessage.bad_request("oops", %{some: "data"})
      args = %{email: "test"}

      assert [%ClientError{field: [], message: "oops"}] ===
               ErrorMessageTranslator.translate(error, args, [])
    end

    test "extracts input from mutation-style args with :input key" do
      error = ErrorMessage.bad_request("is invalid", %{input: %{email: nil}})
      args = %{input: %{email: "bad@", name: "Alice"}}

      assert [%ClientError{field: [:email], message: "is invalid"}] ===
               ErrorMessageTranslator.translate(error, args, [])
    end

    test "infers nested fields from mutation-style args" do
      error =
        ErrorMessage.unprocessable_entity("is invalid", %{
          input: %{address: %{zip_code: nil}}
        })

      args = %{input: %{address: %{zip_code: "000", city: "NYC"}}}

      assert [%ClientError{field: [:address, :zip_code], message: "is invalid"}] ===
               ErrorMessageTranslator.translate(error, args, [])
    end
  end

  describe "translate/3 field inference for server errors" do
    test "produces per-field server errors when paths intersect" do
      error =
        ErrorMessage.internal_server_error("failed on %{key}", %{
          input: %{email: nil}
        })

      args = %{email: "test@test.com"}

      assert [%ServerError{message: "failed on email"}] =
               ErrorMessageTranslator.translate(error, args, [])
    end
  end

  describe "translate/3 message templates" do
    test "replaces %{key} with the field name" do
      error = ErrorMessage.bad_request("%{key} is invalid", %{input: %{email: nil}})
      args = %{email: "bad"}

      assert [%ClientError{field: [:email], message: "email is invalid"}] ===
               ErrorMessageTranslator.translate(error, args, [])
    end

    test "replaces %{value} with the input value" do
      error =
        ErrorMessage.bad_request("%{value} is not allowed", %{input: %{role: nil}})

      args = %{role: "admin"}

      assert [%ClientError{field: [:role], message: "admin is not allowed"}] ===
               ErrorMessageTranslator.translate(error, args, [])
    end

    test "replaces both %{key} and %{value}" do
      error =
        ErrorMessage.bad_request("%{key} cannot be %{value}", %{input: %{age: nil}})

      args = %{age: -1}

      assert [%ClientError{field: [:age], message: "age cannot be -1"}] ===
               ErrorMessageTranslator.translate(error, args, [])
    end

    test "leaves message unchanged when no template placeholders" do
      error = ErrorMessage.bad_request("plain message", %{input: %{email: nil}})
      args = %{email: "test"}

      assert [%ClientError{field: [:email], message: "plain message"}] ===
               ErrorMessageTranslator.translate(error, args, [])
    end

    test "leaves message unchanged when no paths intersect" do
      error = ErrorMessage.bad_request("%{key} is bad", %{input: %{foo: nil}})
      args = %{bar: "baz"}

      assert [%ClientError{field: [], message: "%{key} is bad"}] ===
               ErrorMessageTranslator.translate(error, args, [])
    end
  end

  describe "translate/3 edge cases" do
    test "handles nil args gracefully" do
      error = ErrorMessage.bad_request("oops", %{input: %{email: nil}})

      assert [%ClientError{field: [], message: "oops"}] ===
               ErrorMessageTranslator.translate(error, nil, [])
    end

    test "handles nil details gracefully" do
      error = %ErrorMessage{code: :bad_request, message: "oops", details: nil}

      assert [%ClientError{field: [], message: "oops"}] ===
               ErrorMessageTranslator.translate(error, %{}, [])
    end
  end

  describe "intersecting_paths/2" do
    test "returns matching paths with their values" do
      input = %{email: "test@test.com", name: "Alice"}
      error_input = %{email: nil}

      assert [{[:email], "test@test.com"}] ===
               ErrorMessageTranslator.intersecting_paths(input, error_input)
    end

    test "returns empty list when no paths match" do
      assert [] === ErrorMessageTranslator.intersecting_paths(%{a: 1}, %{b: nil})
    end

    test "handles nested maps" do
      input = %{address: %{city: "NYC", zip: "10001"}}
      error_input = %{address: %{zip: nil}}

      assert [{[:address, :zip], "10001"}] ===
               ErrorMessageTranslator.intersecting_paths(input, error_input)
    end

    test "returns empty list for non-map inputs" do
      assert [] === ErrorMessageTranslator.intersecting_paths("not a map", %{a: 1})
      assert [] === ErrorMessageTranslator.intersecting_paths(%{a: 1}, "not a map")
    end
  end
end
