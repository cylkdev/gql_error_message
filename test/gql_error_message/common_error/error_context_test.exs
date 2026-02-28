defmodule GQLErrorMessage.CommonError.ErrorContextTest do
  use ExUnit.Case, async: true

  alias GQLErrorMessage.CommonError.ErrorContext

  describe "struct" do
    test "creates struct with required fields" do
      assert %ErrorContext{value: "some error", hook_module: SomeModule} =
               %ErrorContext{value: "some error", hook_module: SomeModule}
    end

    test "enforces :value key" do
      assert_raise ArgumentError, ~r/:value/, fn ->
        struct!(ErrorContext, %{hook_module: SomeModule})
      end
    end

    test "enforces :hook_module key" do
      assert_raise ArgumentError, ~r/:hook_module/, fn ->
        struct!(ErrorContext, %{value: "err"})
      end
    end
  end
end
