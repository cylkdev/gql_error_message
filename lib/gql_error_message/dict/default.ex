defmodule GQLErrorMessage.Dict.Default do
  alias GQLErrorMessage.{Config, Spec}

  @behaviour GQLErrorMessage.Dict

  @query_specs [
    %Spec{
      operation: :query,
      kind: :client_error,
      code: :bad_request,
      message: "invalid request",
      extensions: Config.extensions()
    },
    %Spec{
      operation: :query,
      kind: :client_error,
      code: :unauthorized,
      message: "unauthorized",
      extensions: Config.extensions()
    },
    %Spec{
      operation: :query,
      kind: :client_error,
      code: :forbidden,
      message: "forbidden",
      extensions: Config.extensions()
    },
    %Spec{
      operation: :query,
      kind: :server_error,
      code: :internal_server_error,
      message: "internal server error",
      extensions: Config.extensions()
    },
    %Spec{
      operation: :query,
      kind: :server_error,
      code: :bad_gateway,
      message: "bad gateway",
      extensions: Config.extensions()
    },
    %Spec{
      operation: :query,
      kind: :server_error,
      code: :service_unavailable,
      message: "service unavailable",
      extensions: Config.extensions()
    },
    %Spec{
      operation: :query,
      kind: :server_error,
      code: :gateway_timeout,
      message: "gateway timeout",
      extensions: Config.extensions()
    }
  ]

  @mutation_specs [
    %Spec{
      operation: :mutation,
      kind: :client_error,
      code: :unauthorized,
      message: "unauthorized",
      extensions: Config.extensions()
    },
    %Spec{
      operation: :mutation,
      kind: :client_error,
      code: :forbidden,
      message: "forbidden",
      extensions: Config.extensions()
    },
    %Spec{
      operation: :mutation,
      kind: :client_error,
      code: :conflict,
      message: "conflict",
      extensions: Config.extensions()
    },
    %Spec{
      operation: :mutation,
      kind: :client_error,
      code: :unprocessable_entity,
      message: "unprocessable entity",
      extensions: Config.extensions()
    },
    %Spec{
      operation: :mutation,
      kind: :server_error,
      code: :internal_server_error,
      message: "internal server error",
      extensions: Config.extensions()
    },
    %Spec{
      operation: :mutation,
      kind: :server_error,
      code: :bad_gateway,
      message: "bad gateway",
      extensions: Config.extensions()
    },
    %Spec{
      operation: :mutation,
      kind: :server_error,
      code: :service_unavailable,
      message: "service unavailable",
      extensions: Config.extensions()
    },
    %Spec{
      operation: :mutation,
      kind: :server_error,
      code: :gateway_timeout,
      message: "gateway timeout",
      extensions: Config.extensions()
    }
  ]

  @specs @query_specs ++ @mutation_specs
  @spec_mappings Map.new(@specs, fn d -> {{d.operation, d.code}, d} end)

  @impl true
  def list, do: @specs

  @impl true
  def get(op, code), do: Map.get(@spec_mappings, {op, code})
end
