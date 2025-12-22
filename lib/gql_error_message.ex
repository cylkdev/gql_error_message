defmodule GQLErrorMessage do
  alias GQLErrorMessage.{
    ChangesetTranslator,
    ErrorMessageTranslator,
    ServerError
  }

  def translate_error(op, input, %ErrorMessage{} = error) do
    IO.inspect("A-1")

    with [] <- ErrorMessageTranslator.translate_error(op, input, error) do
      IO.inspect("A-2")
      [fallback_error()]
    end
  end

  def translate_error(op, input, %Ecto.Changeset{} = changeset) do
    IO.inspect("B-1")

    with [] <- ChangesetTranslator.translate_error(op, input, changeset) do
      IO.inspect("B-2")
      [fallback_error()]
    end
  end

  defp fallback_error do
    %ServerError{
      message: "Service currently unavailable, please try again later",
      extensions: %{}
    }
  end
end
