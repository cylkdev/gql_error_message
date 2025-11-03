defmodule GQLErrorMessage.AdapterTest do
  use ExUnit.Case, async: true
  doctest GQLErrorMessage.Adapter

  defmodule MockImpl do
    def handle_translate(error, input, spec) do
      {:called, error, input, spec}
    end
  end

  test "handle_translate/4 delegates to the adapter's handle_translate/3" do
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
             GQLErrorMessage.Adapter.handle_translate(
               MockImpl,
               dummy_error,
               dummy_input,
               dummy_spec
             )
  end
end
