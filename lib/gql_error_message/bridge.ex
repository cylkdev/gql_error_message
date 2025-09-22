defmodule GQLErrorMessage.Bridge do
  alias GQLErrorMessage.{
    ClientError,
    Spec,
    ServerError
  }

  @callback get_spec(spec_store :: module(), op :: atom(), code :: atom()) :: Spec.t() | nil

  @callback translate_error(error :: term(), input :: map(), spec :: Spec.t()) ::
              ClientError.t() | ServerError.t() | list(ClientError.t() | ServerError.t())

  def get_spec(bridge, spec_store, op, code) do
    bridge.get_spec(spec_store, op, code)
  end

  def translate_error(bridge, error, input, spec) do
    bridge.translate_error(error, input, spec)
  end
end
