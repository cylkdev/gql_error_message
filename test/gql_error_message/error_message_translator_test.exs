defmodule GQLErrorMessage.ErrorMessageTranslatorTest do
  use ExUnit.Case, async: true

  test "mutation client error uses details.input for deep paths and builds ClientError" do
    input = %{user: %{profile: %{age: 17}}}

    error = %ErrorMessage{
      code: :bad_request,
      message: "Invalid %{key}: %{value}",
      details: %{input: %{user: %{profile: %{age: true}}}}
    }

    errors = GQLErrorMessage.translate_error(:mutation, input, error)

    assert length(errors) === 1

    e0 = Enum.at(errors, 0)
    assert is_struct(e0, GQLErrorMessage.ClientError) === true
    assert Map.get(e0, :field) === [:user, :profile, :age]
    assert Map.get(e0, :message) === "Invalid age: 17"
  end

  test "query client error is translated into ServerError" do
    input = %{user: %{profile: %{age: 17}}}

    error = %ErrorMessage{
      code: :bad_request,
      message: "Invalid %{key}: %{value}",
      details: %{input: %{user: %{profile: %{age: true}}}}
    }

    errors = GQLErrorMessage.translate_error(:query, input, error)

    assert length(errors) === 1

    e0 = Enum.at(errors, 0)
    assert is_struct(e0, GQLErrorMessage.ServerError) === true
    assert Map.get(e0, :message) === "Invalid age: 17"
    assert Map.get(e0, :extensions) === %{}
  end

  test "mutation server error uses details.extensions and returns ServerError" do
    input = %{user: %{id: 1}}

    error = %ErrorMessage{
      code: :internal_server_error,
      message: nil,
      details: %{message: "oops", extensions: %{code: 500}}
    }

    errors = GQLErrorMessage.translate_error(:mutation, input, error)

    assert length(errors) === 1

    e0 = Enum.at(errors, 0)
    assert is_struct(e0, GQLErrorMessage.ServerError) === true
    assert Map.get(e0, :message) === "oops"
    assert Map.get(e0, :extensions) === %{:code => 500}
  end

  test "mutation client error with nil details returns unknown field" do
    input = %{id: 1}

    error = %ErrorMessage{
      code: :unauthorized,
      message: "unauthorized",
      details: nil
    }

    errors = GQLErrorMessage.translate_error(:mutation, input, error)

    assert length(errors) === 1

    e0 = Enum.at(errors, 0)
    assert is_struct(e0, GQLErrorMessage.ClientError) === true
    assert Map.get(e0, :field) === ["unknown"]
    assert Map.get(e0, :message) === "unauthorized"
  end

  test "changeset errors always produce ClientError with a one-segment field path" do
    types = %{name: :string}
    data = {%{}, types}

    changeset =
      data
      |> Ecto.Changeset.cast(%{}, [:name])
      |> Ecto.Changeset.validate_required([:name])

    errors = GQLErrorMessage.translate_error(:mutation, %{}, changeset)

    assert length(errors) === 1

    e0 = Enum.at(errors, 0)
    assert is_struct(e0, GQLErrorMessage.ClientError) === true
    assert Map.get(e0, :field) === [:name]
    assert Map.get(e0, :message) === "can't be blank"
  end
end
