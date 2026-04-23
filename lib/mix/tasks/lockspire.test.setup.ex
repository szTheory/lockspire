defmodule Mix.Tasks.Lockspire.Test.Setup do
  @moduledoc """
  Create and migrate the Lockspire test database used by automated checks.
  """

  @shortdoc "Creates and migrates the Lockspire test database"

  use Mix.Task

  @requirements ["app.config"]

  alias Lockspire.TestRepo

  @impl Mix.Task
  def run(_args) do
    ensure_storage!(TestRepo)
    migrate!(TestRepo)
  end

  defp ensure_storage!(repo) do
    case repo.__adapter__().storage_up(repo.config()) do
      :ok ->
        Mix.shell().info("Created #{inspect(repo)} storage")

      {:error, :already_up} ->
        Mix.shell().info("#{inspect(repo)} storage already exists")

      {:error, reason} ->
        Mix.raise("Could not create #{inspect(repo)} storage: #{inspect(reason)}")
    end
  end

  defp migrate!(repo) do
    migrations_path = Application.app_dir(:lockspire, "priv/repo/migrations")

    {:ok, _, _} =
      Ecto.Migrator.with_repo(repo, fn started_repo ->
        Ecto.Migrator.run(started_repo, migrations_path, :up, all: true)
      end)

    Mix.shell().info("Migrated #{inspect(repo)}")
  end
end
