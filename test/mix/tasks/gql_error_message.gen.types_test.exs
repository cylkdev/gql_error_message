defmodule Mix.Tasks.GqlErrorMessage.Gen.TypesTest do
  use ExUnit.Case, async: true

  describe "run/1" do
    @tag :tmp_dir
    test "creates the generated file and prints creation message", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "lib/test_app_web/schema/types/user_error.ex")

      Mix.shell(Mix.Shell.Process)

      Mix.Tasks.GqlErrorMessage.Gen.Types.run([
        "--path",
        path,
        "--module",
        "TestAppWeb.Schema.Types.UserError"
      ])

      assert File.exists?(path)
      assert File.read!(path) =~ "defmodule TestAppWeb.Schema.Types.UserError do"

      assert_received {:mix_shell, :info, [creating_msg]}
      assert creating_msg =~ "* creating"
      assert creating_msg =~ path
    after
      Mix.shell(Mix.Shell.IO)
    end

    @tag :tmp_dir
    test "prints already exists when file is present", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "lib/existing.ex")
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, "original")

      Mix.shell(Mix.Shell.Process)

      Mix.Tasks.GqlErrorMessage.Gen.Types.run([
        "--path",
        path,
        "--module",
        "TestAppWeb.Schema.Types.UserError"
      ])

      assert_received {:mix_shell, :info, [exists_msg]}
      assert exists_msg =~ "* already exists"
      assert exists_msg =~ path
    after
      Mix.shell(Mix.Shell.IO)
    end

    @tag :tmp_dir
    test "prints injection message when --schema is provided", %{tmp_dir: tmp_dir} do
      schema_path = Path.join(tmp_dir, "schema.ex")
      output_path = Path.join(tmp_dir, "lib/user_error.ex")

      File.write!(schema_path, """
      defmodule MyApp.Schema do
        use Absinthe.Schema
      end
      """)

      Mix.shell(Mix.Shell.Process)

      Mix.Tasks.GqlErrorMessage.Gen.Types.run([
        "--path",
        output_path,
        "--module",
        "TestAppWeb.Schema.Types.UserError",
        "--schema",
        schema_path
      ])

      assert_received {:mix_shell, :info, [creating_msg]}
      assert creating_msg =~ "* creating"

      assert_received {:mix_shell, :info, [inject_msg]}
      assert inject_msg =~ "* injecting"
      assert inject_msg =~ "import_types TestAppWeb.Schema.Types.UserError"
    after
      Mix.shell(Mix.Shell.IO)
    end

    @tag :tmp_dir
    test "prints already imported when import_types already present", %{tmp_dir: tmp_dir} do
      schema_path = Path.join(tmp_dir, "schema.ex")
      output_path = Path.join(tmp_dir, "lib/user_error.ex")

      File.write!(schema_path, """
      defmodule MyApp.Schema do
        use Absinthe.Schema

        import_types TestAppWeb.Schema.Types.UserError
      end
      """)

      Mix.shell(Mix.Shell.Process)

      Mix.Tasks.GqlErrorMessage.Gen.Types.run([
        "--path",
        output_path,
        "--module",
        "TestAppWeb.Schema.Types.UserError",
        "--schema",
        schema_path
      ])

      assert_received {:mix_shell, :info, [_creating_msg]}

      assert_received {:mix_shell, :info, [already_msg]}
      assert already_msg =~ "* already imported"
      assert already_msg =~ "import_types TestAppWeb.Schema.Types.UserError"
    after
      Mix.shell(Mix.Shell.IO)
    end

    @tag :tmp_dir
    test "prints could not inject when no anchor found in schema", %{tmp_dir: tmp_dir} do
      schema_path = Path.join(tmp_dir, "schema.ex")
      output_path = Path.join(tmp_dir, "lib/user_error.ex")

      File.write!(schema_path, """
      defmodule MyApp.SomeModule do
        def hello, do: :world
      end
      """)

      Mix.shell(Mix.Shell.Process)

      Mix.Tasks.GqlErrorMessage.Gen.Types.run([
        "--path",
        output_path,
        "--module",
        "TestAppWeb.Schema.Types.UserError",
        "--schema",
        schema_path
      ])

      assert_received {:mix_shell, :info, [_creating_msg]}

      assert_received {:mix_shell, :info, [could_not_msg]}
      assert could_not_msg =~ "* could not inject"

      assert_received {:mix_shell, :info, [fallback_msg]}
      assert fallback_msg =~ "Could not find an insertion point"
    after
      Mix.shell(Mix.Shell.IO)
    end
  end
end
