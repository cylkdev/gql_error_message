defmodule GQLErrorMessage.Generator.SchemaInjectorTest do
  use ExUnit.Case, async: true

  alias GQLErrorMessage.Generator.SchemaInjector

  describe "inject_import/2" do
    @tag :tmp_dir
    test "injects after the last existing import_types line", %{tmp_dir: tmp_dir} do
      schema_path = Path.join(tmp_dir, "schema.ex")

      File.write!(schema_path, """
      defmodule MyApp.Schema do
        use Absinthe.Schema

        import_types MyApp.Schema.Types.Account
        import_types MyApp.Schema.Types.Post
      end
      """)

      assert {:ok, :injected} === SchemaInjector.inject_import(schema_path, "MyApp.Schema.Types.UserError")

      contents = File.read!(schema_path)
      assert contents =~ "import_types MyApp.Schema.Types.Post\n  import_types MyApp.Schema.Types.UserError"
    end

    @tag :tmp_dir
    test "injects after use Absinthe.Schema when no import_types exist", %{tmp_dir: tmp_dir} do
      schema_path = Path.join(tmp_dir, "schema.ex")

      File.write!(schema_path, """
      defmodule MyApp.Schema do
        use Absinthe.Schema

        query do
        end
      end
      """)

      assert {:ok, :injected} === SchemaInjector.inject_import(schema_path, "MyApp.Schema.Types.UserError")

      contents = File.read!(schema_path)
      assert contents =~ "use Absinthe.Schema\n  import_types MyApp.Schema.Types.UserError"
    end

    @tag :tmp_dir
    test "returns already_present when import already exists", %{tmp_dir: tmp_dir} do
      schema_path = Path.join(tmp_dir, "schema.ex")

      File.write!(schema_path, """
      defmodule MyApp.Schema do
        use Absinthe.Schema

        import_types MyApp.Schema.Types.UserError
      end
      """)

      assert {:ok, :already_present} ===
               SchemaInjector.inject_import(schema_path, "MyApp.Schema.Types.UserError")
    end

    @tag :tmp_dir
    test "returns anchor_not_found when no anchor exists", %{tmp_dir: tmp_dir} do
      schema_path = Path.join(tmp_dir, "schema.ex")

      File.write!(schema_path, """
      defmodule MyApp.SomeModule do
        def hello, do: :world
      end
      """)

      assert {:error, :anchor_not_found} ===
               SchemaInjector.inject_import(schema_path, "MyApp.Schema.Types.UserError")
    end
  end
end
