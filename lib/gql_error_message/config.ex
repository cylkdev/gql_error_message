defmodule GQLErrorMessage.Config do
  @moduledoc false
  @app :gql_error_message

  def fallback_error do
    Application.get_env(@app, :fallback_error)
  end

  def specs do
    Application.get_env(@app, :specs)
  end
end
