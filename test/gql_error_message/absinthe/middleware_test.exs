defmodule GQLErrorMessage.MiddlewareTest do
  use ExUnit.Case, async: true
  doctest GQLErrorMessage.Middleware

  defmodule MockSchema do
    use Absinthe.Schema

    object :user_error do
      field :message, :string
      field :field, list_of(:string)
    end

    object :query_bad_request_payload do
      field :message, :string
    end

    object :query_internal_server_error_payload do
      field :message, :string
    end

    object :mutation_validation_error_payload do
      field :message, :string
      field :user_errors, list_of(:user_error)
    end

    query do
      field :query_success, :string do
        resolve fn _parent_entity, _field_args, _resolution ->
          {:ok, "hello world"}
        end

        middleware GQLErrorMessage.Middleware
      end

      field :query_bad_request, :query_bad_request_payload do
        arg :id, :id

        resolve fn _parent_entity, field_args, _resolution ->
          {:error,
           %ErrorMessage{
             code: :bad_request,
             message: "invalid request",
             details: %{params: field_args}
           }}
        end

        middleware GQLErrorMessage.Middleware
      end

      field :query_internal_server_error, :query_internal_server_error_payload do
        arg :id, :id

        resolve fn _parent_entity, field_args, _resolution ->
          {:error,
           %ErrorMessage{
             code: :internal_server_error,
             message: "unexpected error",
             details: %{params: field_args}
           }}
        end

        middleware GQLErrorMessage.Middleware
      end
    end

    mutation do
      field :mutation_nudge, :string do
        resolve fn _parent_entity, _field_args, _resolution ->
          {:ok, "hi"}
        end

        middleware GQLErrorMessage.Middleware
      end

      field :mutation_validation_error, :mutation_validation_error_payload do
        arg :id, :id

        resolve fn _parent_entity, _field_args, _resolution ->
          {:error,
           GQLErrorMessage.Support.Schemas.User.changeset(
             %GQLErrorMessage.Support.Schemas.User{},
             %{}
           )}
        end

        middleware GQLErrorMessage.Middleware
      end

      # field :query_internal_server_error, :query_internal_server_error_payload do
      #   arg :id, :id

      #   resolve fn _parent_entity, field_args, _resolution ->
      #     {:error,
      #      %ErrorMessage{
      #        code: :internal_server_error,
      #        message: "unexpected error",
      #        details: %{params: field_args}
      #      }}
      #   end

      #   middleware GQLErrorMessage.Middleware
      # end
    end
  end

  describe "call/2" do
    test "operation query: returns successful response" do
      query =
        """
        query {
          querySuccess
        }
        """

      assert {:ok, %{data: %{"querySuccess" => "hello world"}}} =
               Absinthe.run(query, MockSchema)
    end

    test "operation query: returns client errors" do
      query =
        """
        query {
          queryBadRequest(id: "123") {
            message
          }
        }
        """

      assert {
               :ok,
               %{
                 data: %{"queryBadRequest" => nil},
                 errors: [
                   %{
                     message: "invalid request",
                     path: ["queryBadRequest"],
                     field: ["id"]
                   }
                 ]
               }
             } = Absinthe.run(query, MockSchema)
    end

    test "operation query: returns server errors" do
      query =
        """
        query {
          queryInternalServerError(id: "123") {
            message
          }
        }
        """

      assert {
               :ok,
               %{
                 data: %{"queryInternalServerError" => nil},
                 errors: [
                   %{
                     message: "unexpected error",
                     path: ["queryInternalServerError"],
                     extensions: %{}
                   }
                 ]
               }
             } = Absinthe.run(query, MockSchema)
    end

    test "operation mutation: returns successful response" do
      query =
        """
        mutation {
          mutationNudge
        }
        """

      assert {:ok, %{data: %{"mutationNudge" => "hi"}}} =
               Absinthe.run(query, MockSchema)
    end

    test "operation mutation: returns validation errors" do
      query =
        """
        mutation {
          mutationValidationError(id: "123") {
            message
            userErrors {
              message
              field
            }
          }
        }
        """

      assert {:ok,
              %{
                data: %{
                  "mutationValidationError" => %{
                    "message" => nil,
                    "userErrors" => [%{"field" => ["name"], "message" => "can't be blank"}]
                  }
                }
              }} =
               Absinthe.run(query, MockSchema)
    end
  end
end
