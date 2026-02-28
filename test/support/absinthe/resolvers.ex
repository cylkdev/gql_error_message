defmodule GQLErrorMessage.Support.Absinthe.Resolvers do
  @moduledoc false

  alias GQLErrorMessage.Support.Schemas.Rfq
  alias GQLErrorMessage.Support.Schemas.User

  def get_user(_parent, %{name: name}, _resolution) do
    case name do
      "valid" ->
        {:ok, %{name: "valid", email: "valid@test.com"}}

      "not_found" ->
        {:error, ErrorMessage.not_found("user not found")}

      "server_error" ->
        {:error, ErrorMessage.internal_server_error("db down")}

      "unhandled" ->
        {:error, "something unexpected"}

      "changeset" ->
        {:error, User.changeset(%User{}, %{})}

      "has_post" ->
        {:ok, %{name: "has_post", email: "post@test.com"}}

      "post_error" ->
        {:ok, %{name: "post_error", email: "error@test.com"}}
    end
  end

  def get_user_post(%{name: "post_error"}, _args, _resolution) do
    {:error, ErrorMessage.internal_server_error("post fetch failed")}
  end

  def get_user_post(_parent, _args, _resolution) do
    {:ok, %{title: "User's Post"}}
  end

  def get_post(_parent, %{id: id}, _resolution) do
    case id do
      "error_post" ->
        {:ok, %{title: "error_post"}}

      _ ->
        {:ok, %{title: "Test Post"}}
    end
  end

  def get_comments(%{title: "error_post"}, _args, _resolution) do
    {:error, ErrorMessage.internal_server_error("comments failed")}
  end

  def get_comments(_parent, _args, _resolution) do
    {:ok, [%{body: "a comment"}]}
  end

  def create_user(_parent, %{input: input}, _resolution) do
    case input.name do
      "valid" ->
        {:ok, %{user: %{name: "valid", email: input.email}}}

      "client_error" ->
        {:error, ErrorMessage.bad_request("is invalid")}

      "field_error" ->
        {:error, ErrorMessage.bad_request("is invalid", %{input: %{email: nil}})}

      "template_error" ->
        {:error, ErrorMessage.bad_request("%{key} is invalid", %{input: %{email: nil}})}

      "server_error" ->
        {:error, ErrorMessage.internal_server_error("db down")}

      "unhandled" ->
        {:error, "unknown"}

      "changeset" ->
        {:error, User.changeset(%User{}, %{})}

      "nested_changeset" ->
        {:error, Rfq.changeset(%Rfq{}, %{commercial_responses: [%{}]})}
    end
  end

  def create_user_relay(%{name: name, email: email}, _resolution) do
    case name do
      "valid" ->
        {:ok, %{user: %{name: "valid", email: email}}}

      "client_error" ->
        {:error, ErrorMessage.bad_request("is invalid")}

      "field_error" ->
        {:error, ErrorMessage.bad_request("is invalid", %{input: %{email: nil}})}

      "template_error" ->
        {:error, ErrorMessage.bad_request("%{key} is invalid", %{input: %{email: nil}})}

      "server_error" ->
        {:error, ErrorMessage.internal_server_error("db down")}

      "unhandled" ->
        {:error, "unknown"}

      "changeset" ->
        {:error, User.changeset(%User{}, %{})}
    end
  end
end
