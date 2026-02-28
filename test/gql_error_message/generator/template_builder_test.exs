defmodule GQLErrorMessage.Generator.TemplateBuilderTest do
  use ExUnit.Case, async: true

  alias GQLErrorMessage.Generator.TemplateBuilder

  describe "render/2" do
    test "renders the user_error template with the given module name" do
      result =
        TemplateBuilder.render("schema/types/user_error.ex.eex",
          module_name: "MyAppWeb.Schema.Types.UserError"
        )

      assert result =~ "defmodule MyAppWeb.Schema.Types.UserError do"
      assert result =~ "use Absinthe.Schema.Notation"
      assert result =~ "object :user_error do"
    end
  end

  describe "default_module_name/1" do
    test "derives module name from app atom" do
      assert "MyAppWeb.Schema.Types.UserError" === TemplateBuilder.default_module_name(:my_app)
    end

    test "camelizes underscored app names" do
      assert "CoolApiWeb.Schema.Types.UserError" === TemplateBuilder.default_module_name(:cool_api)
    end
  end

  describe "module_to_path/1" do
    test "converts a module name to a lib path" do
      assert "lib/my_app_web/schema/types/user_error.ex" ===
               TemplateBuilder.module_to_path("MyAppWeb.Schema.Types.UserError")
    end

    test "strips Elixir. prefix if present" do
      assert "lib/my_app_web/schema/types/user_error.ex" ===
               TemplateBuilder.module_to_path("Elixir.MyAppWeb.Schema.Types.UserError")
    end
  end
end
