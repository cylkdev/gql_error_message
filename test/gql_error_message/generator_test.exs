defmodule GQLErrorMessage.GeneratorTest do
  use ExUnit.Case, async: true

  alias GQLErrorMessage.Generator

  describe "generate_types/2" do
    @tag :tmp_dir
    test "generates a file with default module name and path", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "lib/test_app_web/schema/types/user_error.ex")

      result = Generator.generate_types(:test_app, path: path)

      assert {:ok, ^path} = result.file
      assert result.module_name === "TestAppWeb.Schema.Types.UserError"
      assert is_nil(result.injection)
      assert File.exists?(path)

      contents = File.read!(path)
      assert contents =~ "defmodule TestAppWeb.Schema.Types.UserError do"
    end

    @tag :tmp_dir
    test "uses the provided module name override", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "lib/custom.ex")

      result = Generator.generate_types(:test_app, module: "Custom.Types.UserError", path: path)

      assert result.module_name === "Custom.Types.UserError"

      contents = File.read!(path)
      assert contents =~ "defmodule Custom.Types.UserError do"
    end

    @tag :tmp_dir
    test "returns already_exists when file is present", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "lib/existing.ex")
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, "original")

      result = Generator.generate_types(:test_app, path: path)

      assert {:error, :already_exists, ^path} = result.file
      assert File.read!(path) === "original"
    end

    @tag :tmp_dir
    test "injects import_types into schema when schema option is given", %{tmp_dir: tmp_dir} do
      schema_path = Path.join(tmp_dir, "schema.ex")
      output_path = Path.join(tmp_dir, "lib/user_error.ex")

      File.write!(schema_path, """
      defmodule MyApp.Schema do
        use Absinthe.Schema
      end
      """)

      result = Generator.generate_types(:test_app, path: output_path, schema: schema_path)

      assert {:ok, :injected} = result.injection
      assert File.read!(schema_path) =~ "import_types #{result.module_name}"
    end

    @tag :tmp_dir
    test "returns nil injection when no schema option given", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "lib/user_error.ex")

      result = Generator.generate_types(:test_app, path: path)

      assert is_nil(result.injection)
    end
  end
end
