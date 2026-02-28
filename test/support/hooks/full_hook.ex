defmodule GQLErrorMessage.Support.Hooks.FullHook do
  @behaviour GQLErrorMessage.CommonError.ErrorMessageHook

  alias GQLErrorMessage.CommonError.ErrorMessageTranslator

  @impl GQLErrorMessage.CommonError.ErrorMessageHook
  def classify(:bad_request, %{severity: :critical}), do: :server

  def classify(code, _details) do
    ErrorMessageTranslator.classify(code)
  end

  @impl GQLErrorMessage.CommonError.ErrorMessageHook
  def build_message(_message, :conflict, %{entity: entity}, _args) do
    "A #{entity} with that value already exists"
  end

  def build_message(message, _code, _details, _args), do: message

  @impl GQLErrorMessage.CommonError.ErrorMessageHook
  def infer_fields(%{fields: fields}, args) when is_list(fields) do
    Enum.map(fields, fn field ->
      {[field], Map.get(args, field)}
    end)
  end

  def infer_fields(_details, _args), do: []
end
