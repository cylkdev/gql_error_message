defmodule GQLErrorMessage.CommonError.ChangesetTranslatorTest do
  use ExUnit.Case, async: true

  doctest GQLErrorMessage.CommonError.ChangesetTranslator

  alias GQLErrorMessage.ClientError
  alias GQLErrorMessage.Support.Schemas.Rfq
  alias GQLErrorMessage.Support.Schemas.User
  alias GQLErrorMessage.CommonError.ChangesetTranslator

  describe "translate/2" do
    test "translates a changeset with a required field error" do
      changeset = User.changeset(%User{}, %{})

      errors = ChangesetTranslator.translate(changeset, %{})
      assert [%ClientError{field: [:name], message: "can't be blank"}] = errors
    end

    test "translates a changeset with a validation error" do
      changeset = User.changeset(%User{}, %{name: "Alice", age: -1})

      assert [%ClientError{field: [:age], message: "must be greater than or equal to 0"}] =
               ChangesetTranslator.translate(changeset, %{})
    end

    test "translates a changeset with multiple field errors" do
      changeset = User.changeset(%User{}, %{age: -1})

      result = ChangesetTranslator.translate(changeset, %{})

      assert [
               %ClientError{field: [:age], message: "must be greater than or equal to 0"},
               %ClientError{field: [:name], message: "can't be blank"}
             ] = Enum.sort_by(result, & &1.field)
    end

    test "returns an empty list for a valid changeset" do
      changeset = User.changeset(%User{}, %{name: "Alice", age: 25})

      assert [] === ChangesetTranslator.translate(changeset, %{})
    end

    test "flattens nested embedded changeset errors into string messages" do
      changeset = Rfq.changeset(%Rfq{}, %{commercial_responses: [%{}]})

      assert [
               %ClientError{
                 field: [:commercial_responses, :body],
                 message: "can't be blank"
               }
             ] = ChangesetTranslator.translate(changeset, %{})
    end
  end
end
