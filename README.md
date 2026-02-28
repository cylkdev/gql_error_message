# GQLErrorMessage

`GQLErrorMessage` provides a simple, transparent, standardized API for
translating various Elixir error terms (like `Ecto.Changeset` or
`ErrorMessage` structs) into GraphQL-compliant error messages.

## Installation

The package can be installed by adding `gql_error_message` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gql_error_message, "~> 0.1.0"}
  ]
end
```

## Quick Start

### 1. Generate the `:user_error` type

```bash
mix gql_error_message.gen.types
```

### 2. Import the type and add middleware to your schema

```elixir
defmodule MyAppWeb.Schema do
  use Absinthe.Schema

  import_types MyAppWeb.Schema.Types.UserError

  query do
    # ...
  end

  mutation do
    # ...
  end

  def middleware(middleware, _field, _object) do
    middleware ++ [GQLErrorMessage.Absinthe.Middleware]
  end
end
```

### 3. Add `user_errors` to mutation payloads

```elixir
object :create_user_payload do
  field :user, :user
  field :user_errors, list_of(:user_error)
end
```

Now any `{:error, reason}` returned from a resolver is automatically
translated into structured `user_errors` for client errors or top-level
`errors` for server errors.

## Documentation

Full documentation is available on [HexDocs](https://hexdocs.pm/gql_error_message).
