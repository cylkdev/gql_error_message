defmodule GQLErrorMessage.Support.Hooks.MessageOnlyHook do
  @behaviour GQLErrorMessage.CommonError.ErrorMessageHook

  @impl GQLErrorMessage.CommonError.ErrorMessageHook
  def build_message(_message, :conflict, %{entity: entity}, _args) do
    "A #{entity} with that value already exists"
  end

  def build_message(message, _code, _details, _args), do: message
end
