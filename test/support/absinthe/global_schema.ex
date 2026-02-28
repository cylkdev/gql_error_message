defmodule GQLErrorMessage.Support.Absinthe.GlobalSchema do
  @moduledoc false
  use Absinthe.Schema

  alias GQLErrorMessage.Support.Absinthe.Resolvers

  query do
    field :user, :user do
      arg :name, non_null(:string)

      resolve &Resolvers.get_user/3
    end

    field :post, :post do
      arg :id, non_null(:id)

      resolve &Resolvers.get_post/3
    end
  end

  mutation do
    field :create_user, :create_user_payload do
      arg :input, non_null(:create_user_input)

      resolve &Resolvers.create_user/3
    end
  end

  object :user do
    field :name, :string
    field :email, :string

    field :post, :post do
      resolve &Resolvers.get_user_post/3
    end
  end

  object :post do
    field :title, :string

    field :comments, list_of(:comment) do
      resolve &Resolvers.get_comments/3
    end
  end

  object :comment do
    field :body, :string
  end

  input_object :create_user_input do
    field :name, non_null(:string)
    field :email, non_null(:string)
  end

  object :user_error do
    field :field, list_of(:string)
    field :message, :string
  end

  object :create_user_payload do
    field :user, :user
    field :user_errors, list_of(:user_error)
  end

  def middleware(middleware, _field, _object) do
    middleware ++ [GQLErrorMessage.Absinthe.Middleware]
  end
end
