defmodule GQLErrorMessage.Generator.FileWriter do
  @moduledoc """
  Writes generated file contents to disk.

  This module handles the file-system concerns of code generation:
  creating parent directories and writing content to a target path.
  It refuses to overwrite an existing file, returning
  `{:error, :already_exists}` instead.
  """

  @doc """
  Writes `contents` to `path`, creating parent directories as needed.

  Returns `{:ok, path}` on success. Returns `{:error, :already_exists}`
  when `path` already exists on disk.
  """
  @spec write(String.t(), String.t()) :: {:ok, String.t()} | {:error, :already_exists}
  def write(path, contents) do
    if File.exists?(path) do
      {:error, :already_exists}
    else
      path |> Path.dirname() |> File.mkdir_p!()
      File.write!(path, contents)
      {:ok, path}
    end
  end
end
