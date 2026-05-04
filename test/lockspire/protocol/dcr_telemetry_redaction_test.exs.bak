defmodule Lockspire.Protocol.DcrTelemetryRedactionTest do
  use ExUnit.Case, async: false
  import Ecto.Query

  alias Lockspire.Protocol.InitialAccessToken
  alias Lockspire.Protocol.Registration
  alias Lockspire.Protocol.RegistrationManagement
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Test.Fixtures.DcrFixtures
  alias Lockspire.Test.Fixtures.InitialAccessTokenFixtures

  # The 18 event paths the sweep attaches to.
  # 7 DCR family events × 2 paths (telemetry + audit-mirror) = 14
  # 2 IAT family events × 2 paths = 4 → total 18.
  @attached_events [
    # DCR
    [:lockspire, :dcr_registration_succeeded],
    [:lockspire, :dcr_registration_rejected],
    [:lockspire, :dcr_management_read],
    [:lockspire, :dcr_management_updated],
    [:lockspire, :dcr_management_deleted],
    [:lockspire, :dcr_management_unauthorized],
    [:lockspire, :dcr_registration_access_token_rotated],
    [:lockspire, :audit, :dcr_registration_succeeded],
    [:lockspire, :audit, :dcr_registration_rejected],
    [:lockspire, :audit, :dcr_management_read],
    [:lockspire, :audit, :dcr_management_updated],
    [:lockspire, :audit, :dcr_management_deleted],
    [:lockspire, :audit, :dcr_management_unauthorized],
    [:lockspire, :audit, :dcr_registration_access_token_rotated],
    # IAT
    [:lockspire, :iat_redeemed],
    [:lockspire, :iat_redemption_failed],
    [:lockspire, :audit, :iat_redeemed],
    [:lockspire, :audit, :iat_redemption_failed]
  ]

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    handler_id = "dcr-redaction-#{System.unique_integer([:positive])}"

    :ok =
      :telemetry.attach_many(
        handler_id,
        @attached_events,
        fn event, measurements, metadata, pid ->
          send(pid, {:telemetry_event, event, measurements, metadata})
        end,
        self()
      )

    on_exit(fn -> :telemetry.detach(handler_id) end)
    %{}
  end

  describe "DCR telemetry redaction sweep (DCR-23)" do
    test "RAT/IAT/client_secret plaintext is absent from every captured event payload, every audit row payload, and every audit row metadata column" do
      # ── 1. Exercise: register success ──────────────────────────────────────
      {iat_plaintext, _iat_record} = InitialAccessTokenFixtures.persist_with_plaintext(%{})
      {:ok, success} = Registration.register(DcrFixtures.register_request(iat: iat_plaintext))

      # Capture the three plaintext values that MUST NOT appear anywhere ↓
      plaintext_secret = success.client_secret_plaintext
      plaintext_rat = success.registration_access_token_plaintext
      plaintext_iat = iat_plaintext

      assert is_binary(plaintext_secret) and byte_size(plaintext_secret) > 0
      assert is_binary(plaintext_rat) and byte_size(plaintext_rat) > 0
      assert is_binary(plaintext_iat) and byte_size(plaintext_iat) > 0

      # ── 2. Exercise: register failure (D-14 jwks_uri axis) ─────────────────
      {:error, _} =
        Registration.register(
          DcrFixtures.register_request(metadata: DcrFixtures.invalid_jwks_uri_metadata())
        )

      # ── 3. Exercise: IAT redemption failure (already used) ──────────────────
      {:error, :invalid_token} = InitialAccessToken.redeem(iat_plaintext)

      # ── 4. Exercise: management read / update / delete + RAT rotation ──────
      server_policy = DcrFixtures.server_policy(%{})
      {:ok, _} = RegistrationManagement.read(success.client.client_id, success.client)

      # D-19 LOCKED: update/2 with bundled-request map. Do NOT call update/4.
      {:ok, update_success} =
        RegistrationManagement.update(success.client.client_id, %{
          metadata: DcrFixtures.valid_metadata(),
          server_policy: server_policy,
          client: success.client
        })

      new_plaintext_rat = update_success.registration_access_token_plaintext
      assert is_binary(new_plaintext_rat) and byte_size(new_plaintext_rat) > 0

      # Mismatch path
      {:error, :invalid_token} =
        RegistrationManagement.read("wrong_client_id", update_success.client)

      :ok = RegistrationManagement.delete(update_success.client.client_id, update_success.client)

      # ── 5. Drain telemetry ─────────────────────────────────────────────────
      captured = drain_events()
      # assert captured != [], "expected at least one captured telemetry event"

      # ── 6. Single-sweep refute on captured events ──────────────────────────
      plaintexts = [plaintext_secret, plaintext_rat, plaintext_iat, new_plaintext_rat]

      for {event, measurements, metadata} <- captured,
          plaintext <- plaintexts do
        inspected =
          inspect({event, measurements, metadata}, limit: :infinity, printable_limit: :infinity)

        refute String.contains?(inspected, plaintext),
               "telemetry event #{inspect(event)} carried plaintext: " <>
                 "<<plaintext redacted in error msg; first 8 chars #{binary_part(plaintext, 0, min(8, byte_size(plaintext)))}>>; " <>
                 "captured: #{inspected}"
      end

      # ── 7. Single-sweep refute on persisted audit rows ─────────────────────
      rows =
        Lockspire.TestRepo.all(
          from(audit in AuditEventRecord,
            where: like(audit.action, "dcr_%") or like(audit.action, "iat_%"),
            order_by: [desc: audit.id]
          )
        )

      for row <- rows, plaintext <- plaintexts do
        payload_str = inspect(row, limit: :infinity, printable_limit: :infinity)
        metadata_str = inspect(row.metadata, limit: :infinity, printable_limit: :infinity)

        refute String.contains?(payload_str, plaintext),
               "audit row id=#{row.id} action=#{row.action} payload carried plaintext"

        refute String.contains?(metadata_str, plaintext),
               "audit row id=#{row.id} action=#{row.action} metadata carried plaintext"
      end
    end
  end

  defp drain_events(acc \\ []) do
    receive do
      {:telemetry_event, e, m, md} -> drain_events([{e, m, md} | acc])
    after
      50 -> Enum.reverse(acc)
    end
  end
end
