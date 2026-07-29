defmodule Lockspire.Mix.Tasks.LockspireClientCreateTest do
  @moduledoc """
  Proves ADOPT-D08 is closed: `mix lockspire.client.create` reaches a started
  repo from an `app.config`-only task -- exactly the shape a stock adopter CLI
  invocation uses -- instead of exiting 1 with a repo-not-started runtime
  error.

  This test deliberately does not start `Lockspire.TestRepo` itself (no
  `start_supervised!`, no `Ecto.Migrator.with_repo` in `setup`). Doing so would
  mask the defect this file exists to catch: if the task under test does not
  start the repo on its own, every assertion here would still fail with
  "could not lookup Ecto repo Lockspire.TestRepo because it was not started or
  it does not exist" -- confirmed empirically against the pre-fix task.

  Because the repo is started transiently by the task itself (not owned by
  this test's process), inserted rows are real commits, not sandboxed --
  `Ecto.Migrator.with_repo/2` starts an independent connection pool that this
  test's `Ecto.Adapters.SQL.Sandbox` ownership never touches. Every test that
  registers a client explicitly deletes its own row via `on_exit` so this file
  does not leak durable state into the rest of the shared test database used
  by `mix test.integration`.
  """

  use ExUnit.Case, async: false

  import Ecto.Query
  import ExUnit.CaptureIO

  @moduletag :integration

  alias Lockspire.Admin.Clients, as: AdminClients
  alias Lockspire.Storage.Ecto.ClientRecord

  setup do
    Mix.Task.reenable("lockspire.client.create")
    :ok
  end

  defp cleanup_client_on_exit(client_id) do
    on_exit(fn ->
      Ecto.Migrator.with_repo(Lockspire.Config.repo!(), fn repo ->
        repo.delete_all(from(c in ClientRecord, where: c.client_id == ^client_id))
      end)
    end)
  end

  test "registers a public client against a started repo and reaches app.config only" do
    client_id = "walk-client-create-#{System.unique_integer([:positive])}"
    cleanup_client_on_exit(client_id)

    output =
      capture_io(fn ->
        Mix.Tasks.Lockspire.Client.Create.run([
          "--client-type",
          "public",
          "--client-id",
          client_id,
          "--redirect-uri",
          "https://client.example.com/callback",
          "--scope",
          "profile",
          "--grant-type",
          "authorization_code"
        ])
      end)

    assert output =~ "client_id=#{client_id}"
    assert output =~ "client_type=public"
    assert output =~ "redirect_uris=https://client.example.com/callback"
    assert output =~ "allowed_scopes=profile"
    assert output =~ "allowed_grant_types=authorization_code"
    assert output =~ "token_endpoint_auth_method=none"
    refute output =~ "client_secret="

    {:ok, {:ok, persisted}, _started_apps} =
      Ecto.Migrator.with_repo(Lockspire.Config.repo!(), fn _repo ->
        AdminClients.get_client(client_id)
      end)

    assert persisted.client_id == client_id
    assert persisted.client_type == :public
  end

  test "registers a confidential client and prints exactly one secret line, writing no file" do
    client_id = "walk-client-create-confidential-#{System.unique_integer([:positive])}"
    cleanup_client_on_exit(client_id)
    tmp_dir = System.tmp_dir!()
    before_entries = File.ls!(tmp_dir)

    output =
      capture_io(fn ->
        Mix.Tasks.Lockspire.Client.Create.run([
          "--client-type",
          "confidential",
          "--client-id",
          client_id,
          "--redirect-uri",
          "https://client.example.com/callback",
          "--scope",
          "profile",
          "--grant-type",
          "authorization_code"
        ])
      end)

    secret_lines =
      output
      |> String.split("\n")
      |> Enum.filter(&String.starts_with?(&1, "client_secret="))

    assert length(secret_lines) == 1

    # Only entries attributable to this task count as evidence. The system temp
    # directory is shared with every other process on the machine, so diffing it
    # wholesale makes this assertion fail whenever anything else happens to write
    # there during the run -- a race, not a defect in the task under test.
    attributable_entries =
      (File.ls!(tmp_dir) -- before_entries)
      |> Enum.filter(fn entry ->
        String.contains?(entry, client_id) or
          String.contains?(String.downcase(entry), "lockspire")
      end)

    assert attributable_entries == []
  end

  test "raises a Mix.Error carrying the field:reason(detail) summary when registration fails" do
    assert_raise Mix.Error, ~r/client_type:invalid_client_type/, fn ->
      capture_io(fn ->
        Mix.Tasks.Lockspire.Client.Create.run([
          "--client-type",
          "not-a-real-type",
          "--redirect-uri",
          "https://client.example.com/callback",
          "--scope",
          "profile",
          "--grant-type",
          "authorization_code"
        ])
      end)
    end
  end

  test "raises on unknown switches before any repo work begins" do
    assert_raise Mix.Error, ~r/Unknown options: --bogus-switch/, fn ->
      Mix.Tasks.Lockspire.Client.Create.run(["--bogus-switch", "value"])
    end
  end
end
