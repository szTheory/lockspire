defmodule Lockspire.Protocol.DcrAuditAttributionTest do
  use ExUnit.Case, async: false
  import Ecto.Query

  alias Lockspire.Protocol.InitialAccessToken
  alias Lockspire.Protocol.Registration
  alias Lockspire.Protocol.RegistrationManagement
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Test.Fixtures.DcrFixtures
  alias Lockspire.Test.Fixtures.InitialAccessTokenFixtures

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    :ok
  end

  describe "DCR audit attribution (DCR-22)" do
    test "no DCR audit row is attributed to :operator across the full DCR write surface" do
      # ── 1. Intake success (registers via IAT) ───────────────────────────────
      {iat_plaintext, _iat_record} = InitialAccessTokenFixtures.persist_with_plaintext(%{})

      {:ok, success} =
        Registration.register(DcrFixtures.register_request(iat: iat_plaintext))

      # ── 2. Intake failures (every D-14/D-15 axis) ───────────────────────────
      {:error, _} =
        Registration.register(
          DcrFixtures.register_request(metadata: DcrFixtures.invalid_jwks_uri_metadata())
        )

      {:error, _} =
        Registration.register(
          DcrFixtures.register_request(metadata: DcrFixtures.mutual_jwks_metadata())
        )

      {:error, _} =
        Registration.register(
          DcrFixtures.register_request(metadata: DcrFixtures.incoherent_grant_response_metadata())
        )

      {:error, _} =
        Registration.register(
          DcrFixtures.register_request(metadata: DcrFixtures.invalid_redirect_uri_metadata())
        )

      {:error, _} =
        Registration.register(
          DcrFixtures.register_request(metadata: DcrFixtures.pkce_required_false_metadata())
        )

      # ── 3. IAT redemption failures ──────────────────────────────────────────
      # Already-used path: re-using the IAT consumed in step 1
      {:error, _} = InitialAccessToken.redeem(iat_plaintext)
      # Not-found path
      {:error, _} = InitialAccessToken.redeem("nonexistent_iat_for_test")

      # ── 4. Management read / update / delete + RAT rotation ─────────────────
      _rat = success.registration_access_token_plaintext
      client = success.client
      server_policy = DcrFixtures.server_policy(%{})

      {:ok, _} = RegistrationManagement.read(client.client_id, client)

      {:error, :invalid_token} =
        RegistrationManagement.read("wrong_client_id", client)

      # D-19 LOCKED: update/2 with bundled-request map. Do NOT call update/4.
      {:ok, update_success} =
        RegistrationManagement.update(client.client_id, %{
          metadata: DcrFixtures.valid_metadata(),
          server_policy: server_policy,
          client: client
        })

      {:error, %Registration.Error{}} =
        RegistrationManagement.update(update_success.client.client_id, %{
          metadata: DcrFixtures.invalid_jwks_uri_metadata(),
          server_policy: server_policy,
          client: update_success.client
        })

      {:error, :invalid_token} =
        RegistrationManagement.update("wrong_client_id", %{
          metadata: DcrFixtures.valid_metadata(),
          server_policy: server_policy,
          client: update_success.client
        })

      :ok = RegistrationManagement.delete(update_success.client.client_id, update_success.client)

      # ── 5. Sweep audit rows ─────────────────────────────────────────────────
      rows =
        Lockspire.TestRepo.all(
          from(audit in AuditEventRecord,
            where: like(audit.action, "dcr_%"),
            order_by: [desc: audit.id]
          )
        )

      assert rows != [], "expected DCR audit rows to be present from the exercise"

      offenders = Enum.filter(rows, &(&1.actor_type == "operator"))

      assert offenders == [],
             "DCR audit rows attributed to :operator: " <>
               inspect(Enum.map(offenders, &Map.take(&1, [:id, :action, :actor_type, :actor_id])))

      # And every DCR row must be either "dcr" or "self_registered_client"
      allowed_actor_types = ["dcr", "self_registered_client"]

      unknown =
        Enum.filter(rows, fn row -> row.actor_type not in allowed_actor_types end)

      assert unknown == [],
             "DCR audit rows with unexpected actor_type: " <>
               inspect(Enum.map(unknown, &Map.take(&1, [:id, :action, :actor_type])))
    end
  end
end
