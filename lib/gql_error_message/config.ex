defmodule GQLErrorMessage.Config do
  @moduledoc false
  @app :gql_error_message

  def adapter do
    Application.get_env(@app, :adapter)
  end

  def fallback_error do
    Application.get_env(@app, :fallback_error)
  end
end
