defmodule GQLErrorMessage.Lexicon do
  alias GQLErrorMessage.Spec

  @behaviour GQLErrorMessage.SpecStore

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

  @specs @mutation_specs ++ @query_specs ++ @subscription_specs
  @spec_mappings (GQLErrorMessage.Config.specs() || @specs)
                 |> Enum.map(&Spec.new/1)
                 |> Map.new(fn spec -> {{spec.operation, spec.code}, spec} end)

  @impl GQLErrorMessage.SpecStore
  def get_spec(op, code) do
    Map.get(@spec_mappings, {op, code})
  end
end
