defmodule GQLErrorMessage.Translation.ErrorMessageTranslationTest do
  use ExUnit.Case, async: true
  doctest GQLErrorMessage.Translation.ErrorMessageTranslation

  alias GQLErrorMessage.Translation.ErrorMessageTranslation
  alias GQLErrorMessage.{Spec, ClientError, ServerError}

  test "intersect_paths/2 finds common paths in nested structures" do
    # Simple shallow match
    input = %{id: 1, other: 2}
    params = %{id: 1, extra: 3}
    assert [{[:id], 1}] = ErrorMessageTranslation.intersect_paths(input, params)

    # Nested map match
    # Only `:user -> :age` overlaps, `:user -> :name` and `:active` have no counterpart in params
    input = %{user: %{name: "alice", age: 30}, active: true}
    params = %{user: %{age: 30}}
    assert [{[:user, :age], 30}] = ErrorMessageTranslation.intersect_paths(input, params)

    # Multiple matches at same depth
    # Order is not guaranteed, so compare as sets
    input = %{a: 1, b: 2, c: 3}
    params = %{a: 1, b: 2}
    paths = ErrorMessageTranslation.intersect_paths(input, params)
    assert MapSet.new(paths) == MapSet.new([{[:a], 1}, {[:b], 2}])

    # Lists: exact list match
    input = %{values: [1, 2, 3]}
    params = %{values: [1, 2, 3]}
    assert [{[:values], [1, 2, 3]}] = ErrorMessageTranslation.intersect_paths(input, params)

    # Lists: no match if values differ
    input = %{values: [1, 2, 3]}
    params = %{values: [1, 2, 4]}
    assert [] = ErrorMessageTranslation.intersect_paths(input, params)
  end

  test "translate_error/3 builds ClientError structs for client_error specs" do
    error =
      %ErrorMessage{
        code: :bad_request,
        message: "invalid request",
        details: %{params: %{id: 1}}
      }

    input = %{id: 1}

    spec = %Spec{
      operation: :query,
      kind: :client_error,
      code: :bad_request,
      message: "invalid request",
      extensions: %{}
    }

    # Should produce a list with one ClientError pointing to the :id field
    assert [%ClientError{field: [:id], message: "invalid request"}] =
             ErrorMessageTranslation.translate_error(error, input, spec)
  end

  test "translate_error/3 builds ServerError structs for server_error specs" do
    error = %ErrorMessage{
      code: :internal_server_error,
      message: "internal server error",
      details: %{
        gql: %{
          input: %{
            user: %{id: 42}
          }
        }
      }
    }

    input = %{user: %{id: 42}}

    spec = %Spec{
      operation: :query,
      kind: :server_error,
      code: :internal_server_error,
      message: "internal server error",
      extensions: %{}
    }

    assert [
             %ServerError{
               message: "internal server error",
               extensions: extensions
             }
           ] = ErrorMessageTranslation.translate_error(error, input, spec)

    assert %{} === extensions
  end

  test "translate_error/3 replaces %{key} and %{value} placeholders in error messages" do
    # Error message includes placeholders; details.params provides the data
    error = %ErrorMessage{
      code: :bad_request,
      message: "Invalid %{key}: %{value}",
      details: %{params: %{age: 17}}
    }

    input = %{age: 17}

    spec = %Spec{
      operation: :query,
      kind: :client_error,
      code: :bad_request,
      message: "unused message",
      extensions: %{}
    }

    assert [
             %ClientError{
               field: [:age],
               message: "Invalid age: 17"
             }
           ] = ErrorMessageTranslation.translate_error(error, input, spec)
  end

  test "translate_error/3 prioritizes details[:gql] overrides for message and input" do
    # It should use the gql.message and gql.input (not the original message or params)
    spec = %Spec{
      operation: :query,
      kind: :client_error,
      code: :unauthorized,
      message: "default msg",
      extensions: %{}
    }

    error = %ErrorMessage{
      code: :unauthorized,
      message: "Original message",
      details: %{
        gql: %{
          message: "Override %{key} error",
          input: %{field1: "foo"}
        },
        # params has a different value, should be ignored
        params: %{field1: "bar"}
      }
    }

    input = %{field1: "foo"}

    assert [
             %ClientError{
               field: [:field1],
               message: "Override field1 error"
             }
           ] = ErrorMessageTranslation.translate_error(error, input, spec)
  end

  test "translate_error/3 merges spec.extensions with details[:gql][:extensions] for server errors" do
    # Should produce one ServerError with merged extensions and placeholder replaced in message
    spec = %Spec{
      operation: :mutation,
      kind: :server_error,
      code: :bad_gateway,
      message: "bad gateway error at %{key}",
      extensions: %{code: 502, note: "spec"}
    }

    error = %ErrorMessage{
      code: :bad_gateway,
      message: nil,
      details: %{
        gql: %{
          input: %{
            service: "database"
          },
          extensions: %{
            note: "override",
            new_info: "xyz"
          }
        },
        params: %{}
      }
    }

    input = %{service: "database"}

    assert [
             %ServerError{
               message: "bad gateway error at service",
               extensions: %{code: 502, note: "override", new_info: "xyz"}
             }
           ] = ErrorMessageTranslation.translate_error(error, input, spec)
  end

  test "translate_error/3 returns an empty list if no input fields intersect error details" do
    spec = %Spec{
      operation: :query,
      kind: :client_error,
      code: :bad_request,
      message: "doesn't matter",
      extensions: %{}
    }

    error = %ErrorMessage{
      code: :bad_request,
      message: "No match",
      details: %{
        params: %{
          field: "mismatch"
        }
      }
    }

    input = %{field: "different"}

    # No overlapping values, no errors produced
    assert [] = ErrorMessageTranslation.translate_error(error, input, spec)
  end
end
