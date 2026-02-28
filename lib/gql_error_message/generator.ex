defmodule GQLErrorMessage.Generator do
  @moduledoc """
  Orchestrates code generation for `GQLErrorMessage`.

  This module coordinates template rendering and file writing to
  generate Absinthe type modules. It is the single entry point for
  generation logic — callers (such as Mix tasks) supply options and
  act on the result.
  """

  alias GQLErrorMessage.Generator.FileWriter
  alias GQLErrorMessage.Generator.SchemaInjector
  alias GQLErrorMessage.Generator.TemplateBuilder

  @template "schema/types/user_error.ex.eex"

  @doc """
  Generates the `:user_error` Absinthe type module.

  `app` is the OTP application atom used to derive the default module
  name. `opts` is a keyword list that may include:

    * `:module` — override the generated module name (string).
    * `:path` — override the output file path (string).
    * `:schema` — path to the Absinthe schema file where
      `import_types` should be injected.

  Returns a map with the following keys:

    * `:file` — `{:ok, path}` or `{:error, :already_exists, path}`.
    * `:module_name` — the resolved module name string.
    * `:injection` — `{:ok, :injected}`, `{:ok, :already_present}`,
      `{:error, :anchor_not_found}`, or `nil` when `:schema` is not set.
  """
  @spec generate_types(atom(), keyword()) :: map()
  def generate_types(app, opts \\ []) do
    module_name = opts[:module] || TemplateBuilder.default_module_name(app)
    file_path = opts[:path] || TemplateBuilder.module_to_path(module_name)
    contents = TemplateBuilder.render(@template, module_name: module_name)

    file_result =
      case FileWriter.write(file_path, contents) do
        {:ok, path} -> {:ok, path}
        {:error, :already_exists} -> {:error, :already_exists, file_path}
      end

    injection_result =
      case opts[:schema] do
        nil -> nil
        schema_path -> SchemaInjector.inject_import(schema_path, module_name)
      end

    %{
      file: file_result,
      module_name: module_name,
      injection: injection_result
    }
  end
end
