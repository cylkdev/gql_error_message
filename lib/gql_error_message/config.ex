defmodule GQLErrorMessage.Config do
  @app :gql_error_message

  def extensions do
    Application.get_env(@app, :extensions) || %{}
  end

  def fallback_error_message do
    Application.get_env(@app, :fallback_error_message)
  end
end
