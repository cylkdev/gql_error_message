defmodule GQLErrorMessage.DefaultRepo do
  @moduledoc """
  The default repository for error specifications.

  This module provides a pre-defined set of standard error
  specifications for common HTTP status codes, categorized by
  operation (`:mutation`, `:query`, `:subscription`).

  ## Customization

  You can override or extend the default specifications by providing
  a `specs` list in your application's configuration:

      config :gql_error_message, specs: [
        %{operation: :query, kind: :client_error, code: :custom_error, ...}
      ]

  > Note: The `specs` configuration is only used at compile time.
  """
  alias GQLErrorMessage.Spec

  @behaviour GQLErrorMessage.Repo

  @mutation_specs [
    %{
      operation: :mutation,
      kind: :client_error,
      code: :unauthorized,
      message: "unauthorized",
      extensions: %{}
    },
    %{
      operation: :mutation,
      kind: :client_error,
      code: :forbidden,
      message: "forbidden",
      extensions: %{}
    },
    %{
      operation: :mutation,
      kind: :client_error,
      code: :conflict,
      message: "conflict",
      extensions: %{}
    },
    %{
      operation: :mutation,
      kind: :client_error,
      code: :unprocessable_entity,
      message: "unprocessable entity",
      extensions: %{}
    },
    %{
      operation: :mutation,
      kind: :server_error,
      code: :internal_server_error,
      message: "internal server error",
      extensions: %{}
    },
    %{
      operation: :mutation,
      kind: :server_error,
      code: :bad_gateway,
      message: "bad gateway",
      extensions: %{}
    },
    %{
      operation: :mutation,
      kind: :server_error,
      code: :service_unavailable,
      message: "service unavailable",
      extensions: %{}
    },
    %{
      operation: :mutation,
      kind: :server_error,
      code: :gateway_timeout,
      message: "gateway timeout",
      extensions: %{}
    }
  ]

  @query_specs [
    %{
      operation: :query,
      kind: :client_error,
      code: :bad_request,
      message: "invalid request",
      extensions: %{}
    },
    %{
      operation: :query,
      kind: :client_error,
      code: :unauthorized,
      message: "unauthorized",
      extensions: %{}
    },
    %{
      operation: :query,
      kind: :client_error,
      code: :forbidden,
      message: "forbidden",
      extensions: %{}
    },
    %{
      operation: :query,
      kind: :server_error,
      code: :internal_server_error,
      message: "internal server error",
      extensions: %{}
    },
    %{
      operation: :query,
      kind: :server_error,
      code: :bad_gateway,
      message: "bad gateway",
      extensions: %{}
    },
    %{
      operation: :query,
      kind: :server_error,
      code: :service_unavailable,
      message: "service unavailable",
      extensions: %{}
    },
    %{
      operation: :query,
      kind: :server_error,
      code: :gateway_timeout,
      message: "gateway timeout",
      extensions: %{}
    }
  ]

  @subscription_specs [
    %{
      operation: :subscription,
      kind: :client_error,
      code: :bad_request,
      message: "invalid request",
      extensions: %{}
    },
    %{
      operation: :subscription,
      kind: :client_error,
      code: :unauthorized,
      message: "unauthorized",
      extensions: %{}
    },
    %{
      operation: :subscription,
      kind: :client_error,
      code: :forbidden,
      message: "forbidden",
      extensions: %{}
    },
    %{
      operation: :subscription,
      kind: :server_error,
      code: :internal_server_error,
      message: "internal server error",
      extensions: %{}
    },
    %{
      operation: :subscription,
      kind: :server_error,
      code: :bad_gateway,
      message: "bad gateway",
      extensions: %{}
    },
    %{
      operation: :subscription,
      kind: :server_error,
      code: :service_unavailable,
      message: "service unavailable",
      extensions: %{}
    },
    %{
      operation: :subscription,
      kind: :server_error,
      code: :gateway_timeout,
      message: "gateway timeout",
      extensions: %{}
    }
  ]

  @specs Enum.map(@mutation_specs ++ @query_specs ++ @subscription_specs, &Spec.new/1)
  @spec_mappings Map.new(@specs, fn spec -> {{spec.operation, spec.code}, spec} end)

  @impl true
  @doc """
  Returns the list of all error specifications.
  """
  def list, do: @specs

  @impl true
  @doc """
  Retrieves an error specification by operation and code.
  """
  def get(op, code) do
    case @spec_mappings do
      %{{^op, ^code} => value} -> value
      _ -> nil
    end
  end
end
