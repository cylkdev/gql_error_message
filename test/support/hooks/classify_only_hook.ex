defmodule GQLErrorMessage.Support.Hooks.ClassifyOnlyHook do
  @behaviour GQLErrorMessage.CommonError.ErrorMessageHook

  alias GQLErrorMessage.CommonError.ErrorMessageTranslator

  @impl GQLErrorMessage.CommonError.ErrorMessageHook
  def classify(:bad_request, %{severity: :critical}), do: :server

  def classify(code, _details) do
    ErrorMessageTranslator.classify(code)
  end
end
