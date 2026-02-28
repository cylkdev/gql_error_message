defmodule GQLErrorMessage.Support.Absinthe.RelaySchema do
  @moduledoc false
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  alias GQLErrorMessage.Support.Absinthe.Resolvers

  query do
    field :user, :user do
      arg :name, non_null(:string)

      resolve &Resolvers.get_user/3
    end
  end

  mutation do
    payload field :create_user do
      input do
        field :name, non_null(:string)
        field :email, non_null(:string)
      end

      output do
        field :user, :user
        field :user_errors, list_of(:user_error)
      end

      resolve &Resolvers.create_user_relay/2
    end
  end

  object :user do
    field :name, :string
    field :email, :string
  end

  object :user_error do
    field :field, list_of(:string)
    field :message, :string
  end

  def middleware(middleware, _field, _object) do
    middleware ++ [GQLErrorMessage.Absinthe.Middleware]
  end
end
