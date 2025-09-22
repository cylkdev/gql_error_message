defmodule GQLErrorMessage.Repo do
  @moduledoc """
  A behaviour for a repository of error specifications.

  This module defines the contract for storing and retrieving
  `GQLErrorMessage.Spec` structs.
  """

  @doc """
  The callback for retrieving a list of all error specifications.

  Implementations of this behaviour must provide this callback
  to retrieve a list of all error specifications.
  """
  @callback list :: list(GQLErrorMessage.Spec.t())

  @doc """
  The callback for retrieving an error specification.

  Implementations of this behaviour must provide this callback
  to retrieve an error specification for a given operation and
  code.
  """
  @callback get(op :: atom(), code :: atom()) :: GQLErrorMessage.Spec.t() | nil

  @doc """
  Retrieves a list of all error specifications from a repository.

  This function delegates to the `list/1` callback
  implemented by the repository.
  """
  def list(repo) do
    repo.list()
  end

  @doc """
  Retrieves an error specification from a repository.

  This function delegates to the `get/2` callback
  implemented by the repository.
  """
  def get(repo, op, code) do
    repo.get(op, code)
  end
end
