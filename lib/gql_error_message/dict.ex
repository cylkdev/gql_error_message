defmodule GQLErrorMessage.Dict do
  @callback list() :: list()
  @callback get(op :: atom(), code :: atom()) :: map()

  def list(adapter), do: adapter.list()
  def get(adapter, op, code), do: adapter.get(op, code)
end
