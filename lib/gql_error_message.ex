defmodule GQLErrorMessage do
  alias GQLErrorMessage.{
    ChangesetTranslator,
    ErrorMessageTranslator,
    ServerError
  }

  def translate_error(op, input, %ErrorMessage{} = error) do
    with [] <- ErrorMessageTranslator.translate_error(op, input, error) do
      [fallback_error()]
    end
  end

  def translate_error(op, input, %Ecto.Changeset{} = changeset) do
    with [] <- ChangesetTranslator.translate_error(op, input, changeset) do
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
