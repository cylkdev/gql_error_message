defmodule GQLErrorMessage.Absinthe do
  @moduledoc """
  Provides integration with the Absinthe GraphQL library.

  This api is split into the following components:

    * `GQLErrorMessage.Absinthe.Middleware` - A middleware that automatically
      translates resolver errors into GraphQL-compliant error responses.

    * `GQLErrorMessage.Absinthe.Type` - Defines a standard `user_error` object
      and a `user_error_payload_fields` macro for use in your schema.

  ## Installation

  To use Absinthe in your project, add the dependency to your `mix.exs` file:

      def deps do
        [
          {:absinthe, "~> 1.7"}
        ]
      end

  Then fetch the dependencies:

      mix deps.get
  """
end
