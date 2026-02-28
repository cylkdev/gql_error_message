defmodule GQLErrorMessage.Generator.FileWriterTest do
  use ExUnit.Case, async: true

  alias GQLErrorMessage.Generator.FileWriter

  @tag :tmp_dir
  describe "write/2" do
    @tag :tmp_dir
    test "creates parent directories and writes the file", %{tmp_dir: tmp_dir} do
      path = Path.join([tmp_dir, "nested", "dir", "file.ex"])

      assert {:ok, ^path} = FileWriter.write(path, "contents")
      assert File.read!(path) === "contents"
    end

    @tag :tmp_dir
    test "returns error when the file already exists", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "existing.ex")
      File.write!(path, "original")

      assert {:error, :already_exists} === FileWriter.write(path, "new contents")
      assert File.read!(path) === "original"
    end
  end
end
