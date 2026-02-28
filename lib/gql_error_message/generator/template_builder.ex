defmodule GQLErrorMessage.Generator.TemplateBuilder do
  @moduledoc """
  Renders EEx templates shipped in the `:gql_error_message` `priv/`
  directory.

  This module owns the mapping from a template name to its location
  on disk and evaluates the template with caller-supplied assigns.
  It also provides helpers for deriving a default module name and
  converting a module name to a file path.
  """

  @doc """
  Renders the EEx template at the given `template_path` relative to
  the `:gql_error_message` `priv/templates` directory.

  `assigns` is a keyword list of bindings available in the template
  as module attributes (e.g. `@module_name`).

  Returns the rendered string.
  """
  @spec render(String.t(), keyword()) :: String.t()
  def render(template_path, assigns) do
    template_dir = Application.app_dir(:gql_error_message, "priv/templates")
    full_path = Path.join(template_dir, template_path)
    EEx.eval_file(full_path, assigns: assigns)
  end

  @doc """
  Derives the default module name from the given application atom.

  For an app named `:my_app`, the result is
  `"MyAppWeb.Schema.Types.UserError"`.
  """
  @spec default_module_name(atom()) :: String.t()
  def default_module_name(app) do
    camelized =
      app
      |> Atom.to_string()
      |> Macro.camelize()

    "#{camelized}Web.Schema.Types.UserError"
  end

  @doc """
  Converts a module name string to a relative file path under `lib/`.

  For example, `"MyAppWeb.Schema.Types.UserError"` becomes
  `"lib/my_app_web/schema/user_error_types.ex"`.
  """
  @spec module_to_path(String.t()) :: String.t()
  def module_to_path(module_name) do
    relative =
      module_name
      |> String.replace("Elixir.", "")
      |> Macro.underscore()

    Path.join("lib", "#{relative}.ex")
  end
end
