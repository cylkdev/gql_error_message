defmodule Mix.Tasks.GqlErrorMessage.Gen.Types do
  @moduledoc """
  Generates a `UserError` module containing the `:user_error` Absinthe
  object type used by `GQLErrorMessage.Absinthe.Middleware`.

  The generated module uses `Absinthe.Schema.Notation` and defines a
  `:user_error` object with two fields: `field` (`list_of(:string)`) and
  `message` (`:string`). Import the generated module into your Absinthe
  schema with `import_types`.

  ## Usage

      mix gql_error_message.gen.types

  By default the module name is inferred from your application name. For
  an app named `:my_app`, the generated module is `MyAppWeb.Schema.Types.UserError`
  and the file is written to `lib/my_app_web/schema/user_error_types.ex`.

  ### Options

    * `--module` — override the generated module name. For example:

          mix gql_error_message.gen.types --module MyAppWeb.GraphQL.Types.UserError

    * `--path` — override the output file path. For example:

          mix gql_error_message.gen.types --path lib/my_app_web/graphql/types/user_error.ex

    * `--schema` — path to your Absinthe schema file. When provided,
      the generator automatically adds `import_types` to the schema:

          mix gql_error_message.gen.types --schema lib/my_app_web/schema.ex

  """
  @shortdoc "Generates the :user_error Absinthe object type module"

  use Mix.Task

  alias GQLErrorMessage.Generator
  alias Mix.Project

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args, strict: [module: :string, path: :string, schema: :string])

    app = Project.config()[:app]
    result = Generator.generate_types(app, opts)

    print_file_result(result.file)
    print_injection_result(result.injection, result.module_name)
  end

  defp print_file_result({:ok, path}) do
    Mix.shell().info([:green, "* creating ", :reset, path])
  end

  defp print_file_result({:error, :already_exists, path}) do
    Mix.shell().info([:yellow, "* already exists ", :reset, path])
  end

  defp print_injection_result({:ok, :injected}, module_name) do
    Mix.shell().info([:green, "* injecting ", :reset, "import_types #{module_name}"])
  end

  defp print_injection_result({:ok, :already_present}, module_name) do
    Mix.shell().info([:yellow, "* already imported ", :reset, "import_types #{module_name}"])
  end

  defp print_injection_result({:error, :anchor_not_found}, module_name) do
    Mix.shell().info([:red, "* could not inject ", :reset, "import_types #{module_name}"])

    Mix.shell().info(
      "  Could not find an insertion point. Add the following to your schema manually:\n\n" <>
        "      import_types #{module_name}\n"
    )
  end

  defp print_injection_result(nil, module_name) do
    Mix.shell().info("")

    Mix.shell().info(
      "Import the generated module into your Absinthe schema:\n\n" <>
        "    import_types #{module_name}\n"
    )
  end
end
