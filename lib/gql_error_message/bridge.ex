defmodule GQLErrorMessage.Bridge do
  alias GQLErrorMessage.{ClientError, Spec}

  @callback translate_error(error :: term(), input :: map(), spec :: Spec.t()) ::
              ClientError.t()

  def translate_error(adapter, error, input, spec) do
    adapter.translate_error(error, input, spec)
  end
end
