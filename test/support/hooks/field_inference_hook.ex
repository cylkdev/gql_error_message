defmodule GQLErrorMessage.Support.Hooks.FieldInferenceHook do
  @behaviour GQLErrorMessage.CommonError.ErrorMessageHook

  @impl GQLErrorMessage.CommonError.ErrorMessageHook
  def infer_fields(%{fields: fields}, args) when is_list(fields) do
    Enum.map(fields, fn field ->
      {[field], Map.get(args, field)}
    end)
  end

  def infer_fields(_details, _args), do: []
end
