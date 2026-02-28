# GQLErrorMessage

An Elixir library that provides a standardized API for translating Elixir error terms into GraphQL-compliant error messages. It translates `ErrorMessage` structs and `Ecto.Changeset` errors out of the box and integrates with Absinthe via middleware. Custom error types are supported through a translator behaviour.

## Tech Stack

### Core Dependencies

- **Name:** ErrorMessage
  **Dependency:** `{:error_message, ">= 0.1.0"}`
  **Purpose:** Standardized error message structs for HTTP errors

- **Name:** Absinthe
  **Dependency:** `{:absinthe, ">= 1.0.0", optional: true}`
  **Purpose:** GraphQL implementation for Elixir

- **Name:** Absinthe Relay
  **Dependency:** `{:absinthe_relay, "~> 1.5", optional: true}`
  **Purpose:** Relay-style GraphQL support for Absinthe

- **Name:** Ecto
  **Dependency:** `{:ecto, ">= 1.0.0", optional: true}`
  **Purpose:** Database wrapper and language integrated query for Elixir

### Documentation

- **Name:** ExDoc
  **Dependency:** `{:ex_doc, ">= 0.0.0", only: :dev, runtime: false}`
  **Purpose:** Documentation generation for HexDocs

### Code Quality and Static Analysis

- **Name:** Credo
  **Dependency:** `{:credo, "~> 1.4", only: [:dev, :test], runtime: false}`
  **Purpose:** Static analysis and code quality checking

- **Name:** Blitz Credo Checks
  **Dependency:** `{:blitz_credo_checks, "~> 0.1.5", only: [:dev, :test], runtime: false}`
  **Purpose:** Additional Credo checks

- **Name:** Dialyzer
  **Dependency:** `{:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}`
  **Purpose:** Static analysis for type checking

### Testing and Coverage

- **Name:** ExCoveralls
  **Dependency:** `{:excoveralls, "~> 0.13", only: :test}`
  **Purpose:** Test coverage reporting

### Debugging and Runtime Introspection

- **Name:** Rexbug
  **Dependency:** `{:rexbug, "~> 1.0", only: :dev}`
  **Purpose:** Tracing and debugging tool

- **Name:** Observer CLI
  **Dependency:** `{:observer_cli, "~> 1.8", only: :dev}`
  **Purpose:** Terminal-based BEAM observer

- **Name:** Etop
  **Dependency:** `{:etop, "~> 0.7", only: :dev}`
  **Purpose:** Erlang top-like process viewer
