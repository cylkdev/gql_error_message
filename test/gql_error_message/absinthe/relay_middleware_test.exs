defmodule GQLErrorMessage.Absinthe.RelayMiddlewareTest do
  use ExUnit.Case, async: true

  alias GQLErrorMessage.Support.Absinthe.RelaySchema

  @user_query """
  query GetUser($name: String!) {
    user(name: $name) {
      name
      email
    }
  }
  """

  @create_user_mutation """
  mutation CreateUser($input: CreateUserInput!) {
    createUser(input: $input) {
      user {
        name
        email
      }
      userErrors {
        field
        message
      }
    }
  }
  """

  describe "relay query success" do
    test "returns data with no errors" do
      assert {:ok, result} = Absinthe.run(@user_query, RelaySchema, variables: %{"name" => "valid"})

      assert %{data: %{"user" => %{"name" => "valid", "email" => "valid@test.com"}}} = result
      refute Map.has_key?(result, :errors)
    end
  end

  describe "relay query client error" do
    test "promotes client error to server error in top-level errors" do
      assert {:ok, result} = Absinthe.run(@user_query, RelaySchema, variables: %{"name" => "not_found"})

      assert %{
               data: %{"user" => nil},
               errors: [%{message: "user not found"}]
             } = result
    end
  end

  describe "relay query server error" do
    test "returns server error in top-level errors" do
      assert {:ok, result} = Absinthe.run(@user_query, RelaySchema, variables: %{"name" => "server_error"})

      assert %{
               data: %{"user" => nil},
               errors: [%{message: "db down"}]
             } = result
    end
  end

  describe "relay query unhandled error" do
    test "raises RuntimeError for unrecognized error types" do
      assert_raise RuntimeError, ~r/Unsupported error type/, fn ->
        Absinthe.run(@user_query, RelaySchema, variables: %{"name" => "unhandled"})
      end
    end
  end

  describe "relay mutation success" do
    test "returns data with empty user_errors" do
      input = %{"name" => "valid", "email" => "valid@test.com"}

      assert {:ok, result} =
               Absinthe.run(@create_user_mutation, RelaySchema, variables: %{"input" => input})

      assert %{
               data: %{
                 "createUser" => %{
                   "user" => %{"name" => "valid", "email" => "valid@test.com"},
                   "userErrors" => nil
                 }
               }
             } = result

      refute Map.has_key?(result, :errors)
    end
  end

  describe "relay mutation client error" do
    test "returns user_errors in payload with no top-level errors" do
      input = %{"name" => "client_error", "email" => "test@test.com"}

      assert {:ok, result} =
               Absinthe.run(@create_user_mutation, RelaySchema, variables: %{"input" => input})

      assert %{
               data: %{
                 "createUser" => %{
                   "userErrors" => [%{"field" => [], "message" => "is invalid"}]
                 }
               }
             } = result

      refute Map.has_key?(result, :errors)
    end
  end

  describe "relay mutation client error with field inference" do
    test "infers field path from details[:input] intersecting with relay args" do
      input = %{"name" => "field_error", "email" => "bad@test.com"}

      assert {:ok, result} =
               Absinthe.run(@create_user_mutation, RelaySchema, variables: %{"input" => input})

      assert %{
               data: %{
                 "createUser" => %{
                   "userErrors" => [%{"field" => ["email"], "message" => "is invalid"}]
                 }
               }
             } = result

      refute Map.has_key?(result, :errors)
    end
  end

  describe "relay mutation client error with message template" do
    test "interpolates %{key} in the message" do
      input = %{"name" => "template_error", "email" => "bad@test.com"}

      assert {:ok, result} =
               Absinthe.run(@create_user_mutation, RelaySchema, variables: %{"input" => input})

      assert %{
               data: %{
                 "createUser" => %{
                   "userErrors" => [%{"field" => ["email"], "message" => "email is invalid"}]
                 }
               }
             } = result
    end
  end

  describe "relay mutation server error" do
    test "returns top-level errors and nil data" do
      input = %{"name" => "server_error", "email" => "test@test.com"}

      assert {:ok, result} =
               Absinthe.run(@create_user_mutation, RelaySchema, variables: %{"input" => input})

      assert %{
               data: %{"createUser" => nil},
               errors: [%{message: "db down"}]
             } = result
    end
  end

  describe "relay mutation unhandled error" do
    test "raises RuntimeError for unrecognized error types" do
      input = %{"name" => "unhandled", "email" => "test@test.com"}

      assert_raise RuntimeError, ~r/Unsupported error type/, fn ->
        Absinthe.run(@create_user_mutation, RelaySchema, variables: %{"input" => input})
      end
    end
  end

  describe "relay mutation changeset error" do
    test "returns changeset errors in user_errors" do
      input = %{"name" => "changeset", "email" => "test@test.com"}

      assert {:ok, result} =
               Absinthe.run(@create_user_mutation, RelaySchema, variables: %{"input" => input})

      assert %{
               data: %{
                 "createUser" => %{
                   "userErrors" => [%{"message" => "can't be blank"}]
                 }
               }
             } = result

      refute Map.has_key?(result, :errors)
    end
  end
end
