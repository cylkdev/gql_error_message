defmodule GQLErrorMessage.Absinthe.GlobalMiddlewareTest do
  use ExUnit.Case, async: true

  alias GQLErrorMessage.Support.Absinthe.GlobalSchema

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

  @user_with_post_query """
  query GetUserWithPost($name: String!) {
    user(name: $name) {
      name
      post {
        title
      }
    }
  }
  """

  @post_query """
  query GetPost($id: ID!) {
    post(id: $id) {
      title
      comments {
        body
      }
    }
  }
  """

  describe "query success" do
    test "returns data with no errors" do
      assert {:ok, result} = Absinthe.run(@user_query, GlobalSchema, variables: %{"name" => "valid"})

      assert %{data: %{"user" => %{"name" => "valid", "email" => "valid@test.com"}}} = result
      refute Map.has_key?(result, :errors)
    end
  end

  describe "query client error" do
    test "promotes client error to server error in top-level errors" do
      assert {:ok, result} = Absinthe.run(@user_query, GlobalSchema, variables: %{"name" => "not_found"})

      assert %{
               data: %{"user" => nil},
               errors: [%{message: "user not found"}]
             } = result
    end
  end

  describe "query server error" do
    test "returns server error in top-level errors" do
      assert {:ok, result} = Absinthe.run(@user_query, GlobalSchema, variables: %{"name" => "server_error"})

      assert %{
               data: %{"user" => nil},
               errors: [%{message: "db down"}]
             } = result
    end
  end

  describe "query unhandled error" do
    test "raises RuntimeError for unrecognized error types" do
      assert_raise RuntimeError, ~r/Unsupported error type/, fn ->
        Absinthe.run(@user_query, GlobalSchema, variables: %{"name" => "unhandled"})
      end
    end
  end

  describe "query changeset error" do
    test "promotes changeset client error to server error" do
      assert {:ok, result} = Absinthe.run(@user_query, GlobalSchema, variables: %{"name" => "changeset"})

      assert %{
               data: %{"user" => nil},
               errors: [%{message: _}]
             } = result
    end
  end

  describe "mutation success" do
    test "returns data with empty user_errors" do
      input = %{"name" => "valid", "email" => "valid@test.com"}

      assert {:ok, result} =
               Absinthe.run(@create_user_mutation, GlobalSchema, variables: %{"input" => input})

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

  describe "mutation client error" do
    test "returns user_errors in payload with no top-level errors" do
      input = %{"name" => "client_error", "email" => "test@test.com"}

      assert {:ok, result} =
               Absinthe.run(@create_user_mutation, GlobalSchema, variables: %{"input" => input})

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

  describe "mutation client error with field inference" do
    test "infers field path from details[:input] intersecting with args" do
      input = %{"name" => "field_error", "email" => "bad@test.com"}

      assert {:ok, result} =
               Absinthe.run(@create_user_mutation, GlobalSchema, variables: %{"input" => input})

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

  describe "mutation client error with message template" do
    test "interpolates %{key} in the message" do
      input = %{"name" => "template_error", "email" => "bad@test.com"}

      assert {:ok, result} =
               Absinthe.run(@create_user_mutation, GlobalSchema, variables: %{"input" => input})

      assert %{
               data: %{
                 "createUser" => %{
                   "userErrors" => [%{"field" => ["email"], "message" => "email is invalid"}]
                 }
               }
             } = result
    end
  end

  describe "mutation server error" do
    test "returns top-level errors and nil data" do
      input = %{"name" => "server_error", "email" => "test@test.com"}

      assert {:ok, result} =
               Absinthe.run(@create_user_mutation, GlobalSchema, variables: %{"input" => input})

      assert %{
               data: %{"createUser" => nil},
               errors: [%{message: "db down"}]
             } = result
    end
  end

  describe "mutation unhandled error" do
    test "raises RuntimeError for unrecognized error types" do
      input = %{"name" => "unhandled", "email" => "test@test.com"}

      assert_raise RuntimeError, ~r/Unsupported error type/, fn ->
        Absinthe.run(@create_user_mutation, GlobalSchema, variables: %{"input" => input})
      end
    end
  end

  describe "mutation changeset error" do
    test "returns changeset errors in user_errors" do
      input = %{"name" => "changeset", "email" => "test@test.com"}

      assert {:ok, result} =
               Absinthe.run(@create_user_mutation, GlobalSchema, variables: %{"input" => input})

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

  describe "nested field on object" do
    test "child resolver on user object returns data" do
      assert {:ok, result} =
               Absinthe.run(@user_with_post_query, GlobalSchema, variables: %{"name" => "has_post"})

      assert %{
               data: %{
                 "user" => %{
                   "name" => "has_post",
                   "post" => %{"title" => "User's Post"}
                 }
               }
             } = result

      refute Map.has_key?(result, :errors)
    end

    test "child resolver error on user object returns top-level errors" do
      assert {:ok, result} =
               Absinthe.run(@user_with_post_query, GlobalSchema, variables: %{"name" => "post_error"})

      assert %{
               data: %{"user" => %{"name" => "post_error", "post" => nil}},
               errors: [%{message: "post fetch failed"}]
             } = result
    end
  end

  describe "nested field error" do
    test "child resolver error returns top-level errors" do
      assert {:ok, result} =
               Absinthe.run(@post_query, GlobalSchema, variables: %{"id" => "error_post"})

      assert %{
               data: %{"post" => %{"title" => "error_post", "comments" => nil}},
               errors: [%{message: "comments failed"}]
             } = result
    end

    test "child resolver success returns data" do
      assert {:ok, result} =
               Absinthe.run(@post_query, GlobalSchema, variables: %{"id" => "ok"})

      assert %{
               data: %{
                 "post" => %{
                   "title" => "Test Post",
                   "comments" => [%{"body" => "a comment"}]
                 }
               }
             } = result

      refute Map.has_key?(result, :errors)
    end
  end
end
