defmodule GQLErrorMessage.Absinthe.MiddlewareTest do
  use ExUnit.Case, async: true

  alias GQLErrorMessage.Absinthe.Middleware

  describe "call/2" do
    test "raises when resolution is not yet resolved" do
      resolution = %Absinthe.Resolution{state: :unresolved}

      assert_raise RuntimeError, ~r/can only be used \*after\* the resolve function/, fn ->
        Middleware.call(resolution, [])
      end
    end
  end
end
