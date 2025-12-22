defmodule GQLErrorMessage.ErrorMessageDefinition do
  @mutation_specs [
    %{
      operation: :mutation,
      kind: :server_error,
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
      code: :not_found,
      message: "not found",
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
      kind: :client_error,
      code: :not_found,
      message: "not found",
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
      kind: :client_error,
      code: :not_found,
      message: "not found",
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

  @specs @query_specs ++ @mutation_specs ++ @subscription_specs
  @spec_index @specs
              |> Enum.with_index()
              |> Map.new(fn {spec, index} -> {{spec.operation, spec.code}, index} end)

  def list, do: @specs

  def fetch_spec!(op, code) do
    case Map.get(@spec_index, {op, code}) do
      nil -> raise "ErrorMessageDefinition not found for operation: #{op} and code: #{code}"
      index -> get_in(@specs, [Access.at!(index)])
    end
  end
end
