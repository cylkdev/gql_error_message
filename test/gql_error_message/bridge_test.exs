defmodule GQLErrorMessage.BridgeTest do
  use ExUnit.Case, async: true
  doctest GQLErrorMessage.Bridge

  defmodule DummyBridgeImpl do
    def translate_error(error, input, spec) do
      {:called, error, input, spec}
    end
  end

  test "translate_error/4 delegates to the adapter's translate_error/3" do
    dummy_error = %{some: "error"}
    dummy_input = %{"field" => 123}

    dummy_spec = %GQLErrorMessage.Spec{
      operation: :query,
      kind: :client_error,
      code: :dummy,
      message: "msg",
      extensions: %{}
    }

    assert {:called, ^dummy_error, ^dummy_input, ^dummy_spec} =
             GQLErrorMessage.Bridge.translate_error(
               DummyBridgeImpl,
               dummy_error,
               dummy_input,
               dummy_spec
             )
  end
end
