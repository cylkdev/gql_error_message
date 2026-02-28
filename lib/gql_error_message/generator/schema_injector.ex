defmodule GQLErrorMessage.Generator.SchemaInjector do
  @moduledoc """
  Injects `import_types` calls into an existing Absinthe schema file.

  This module reads a schema file as text, finds an appropriate
  insertion point, and splices in the `import_types` line. It uses
  two anchors in priority order:

    1. After the last existing `import_types` line.
    2. After `use Absinthe.Schema`.

  The injection is idempotent — if the import already exists in the
  file, no changes are made.
  """

  @doc """
  Injects `import_types <module_name>` into the schema file at
  `schema_path`.

  Returns `{:ok, :injected}` when the line is successfully added,
  `{:ok, :already_present}` when the import already exists in the
  file, or `{:error, :anchor_not_found}` when neither an existing
  `import_types` call nor `use Absinthe.Schema` can be found.
  """
  @spec inject_import(String.t(), String.t()) ::
          {:ok, :injected} | {:ok, :already_present} | {:error, :anchor_not_found}
  def inject_import(schema_path, module_name) do
    contents = File.read!(schema_path)
    import_line = "import_types #{module_name}"

    if String.contains?(contents, import_line) do
      {:ok, :already_present}
    else
      case find_anchor(contents) do
        {:ok, anchor} ->
          updated = String.replace(contents, anchor, "#{anchor}\n  #{import_line}", global: false)
          File.write!(schema_path, updated)
          {:ok, :injected}

        :error ->
          {:error, :anchor_not_found}
      end
    end
  end

  defp find_anchor(contents) do
    cond do
      anchor = last_import_types_line(contents) -> {:ok, anchor}
      anchor = use_absinthe_schema_line(contents) -> {:ok, anchor}
      true -> :error
    end
  end

  defp last_import_types_line(contents) do
    contents
    |> String.split("\n")
    |> Enum.filter(&String.match?(&1, ~r/^\s*import_types\s+/))
    |> List.last()
  end

  defp use_absinthe_schema_line(contents) do
    contents
    |> String.split("\n")
    |> Enum.find(&String.match?(&1, ~r/^\s*use Absinthe\.Schema\b/))
  end
end
