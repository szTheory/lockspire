defmodule Lockspire.Admin.KeysReencryptTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Lockspire.Admin
  alias Lockspire.KeyEncryptionHelpers, as: Helpers
  alias Lockspire.Protocol.PrivateJwk
  alias Lockspire.Security.KeyEncryption
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.TestSupport.TelemetryCapture

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    owner = Ecto.Adapters.SQL.Sandbox.start_owner!(Lockspire.TestRepo, shared: true)
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(owner) end)

    Helpers.put_key_encryption(
      keys: Helpers.config_keys(),
      current: "test-1",
      legacy_plaintext: :allow
    )

    :ok
  end

  describe "tracer: one legacy row becomes an envelope" do
    test "converts a retired legacy JSON row and records one audit entry" do
      row =
        Helpers.insert_signing_key_row!(Helpers.legacy_json_row("kid-legacy", status: :retired))

      original_jwk = Jason.decode!(row.private_jwk_encrypted)

      assert {:ok, report} = Admin.reencrypt()

      assert report.dry_run == false
      assert report.current_kek_id == "test-1"
      assert report.scanned == 1
      assert report.encrypted == 1
      assert report.rewrapped == 0
      assert report.already_current == 0
      assert report.failed == []

      stored = fetch!(row.id)
      assert String.starts_with?(stored.private_jwk_encrypted, "LSK")
      assert {:ok, "test-1"} = KeyEncryption.envelope_kek_id(stored.private_jwk_encrypted)
      assert {:ok, ^original_jwk} = PrivateJwk.decode(stored)

      assert stored.status == :retired
      assert stored.use == :sig
      assert stored.published_at == row.published_at
      assert stored.activated_at == row.activated_at
      assert stored.retired_at == row.retired_at

      audit = audit_for!(row.id)
      assert audit.action == "key_encrypted"
      assert audit.outcome == "succeeded"
      assert Enum.sort(Map.keys(audit.metadata)) == ~w(kek_id key_id kid status use)
    end

    test "a second run is a no-op" do
      row = Helpers.insert_signing_key_row!(Helpers.legacy_json_row("kid-twice"))

      assert {:ok, %{encrypted: 1}} = Admin.reencrypt()
      first_bytes = fetch!(row.id).private_jwk_encrypted
      audit_count = audit_count()

      assert {:ok, report} = Admin.reencrypt()
      assert report.already_current == 1
      assert report.encrypted == 0
      assert fetch!(row.id).private_jwk_encrypted == first_bytes
      assert audit_count() == audit_count
    end

    test "rows without private material are counted and untouched" do
      row = Helpers.insert_signing_key_row!(Helpers.nil_material_row("kid-nil"))

      assert {:ok, report} = Admin.reencrypt()
      assert report.scanned == 1
      assert report.no_private_key == 1
      assert fetch!(row.id).private_jwk_encrypted == nil
      assert audit_count() == 0
    end
  end

  describe "rotation matrix" do
    setup do
      rows = %{
        legacy_json: Helpers.insert_signing_key_row!(Helpers.legacy_json_row("kid-json")),
        legacy_etf: Helpers.insert_signing_key_row!(Helpers.legacy_etf_row("kid-etf")),
        on_test_1: Helpers.insert_signing_key_row!(Helpers.sealed_row("kid-on-1", "test-1")),
        on_test_2: Helpers.insert_signing_key_row!(Helpers.sealed_row("kid-on-2", "test-2"))
      }

      %{rows: rows}
    end

    test "every material row ends on the current KEK with the same kid", %{rows: rows} do
      assert {:ok, first} = Admin.reencrypt()
      assert first.encrypted == 2
      assert first.rewrapped == 1
      assert first.already_current == 1
      assert first.by_source_kek == %{"legacy" => 2, "test-1" => 1, "test-2" => 1}
      assert_all_on(rows, "test-1")

      use_current("test-2")
      assert {:ok, second} = Admin.reencrypt()
      assert second.rewrapped == 4
      assert second.encrypted == 0
      assert second.already_current == 0
      assert_all_on(rows, "test-2")

      assert {:ok, third} = Admin.reencrypt()
      assert third.already_current == 4
      assert third.rewrapped == 0
    end

    test "rows still sign after the old KEK is removed", %{rows: rows} do
      assert {:ok, _report} = Admin.reencrypt()
      use_current("test-2")
      assert {:ok, _report} = Admin.reencrypt()

      Helpers.put_key_encryption(
        keys: [{"test-2", Helpers.config_material("test-2")}],
        current: "test-2"
      )

      for {_name, row} <- rows do
        stored = fetch!(row.id)
        assert {:ok, jwk} = PrivateJwk.decode(stored)
        assert jwk["kid"] == row.kid

        private = JOSE.JWK.from_map(jwk)

        {_, compact} =
          private |> JOSE.JWS.sign("payload", %{"alg" => "RS256"}) |> JOSE.JWS.compact()

        assert {true, "payload", _jws} = JOSE.JWS.verify(JOSE.JWK.to_public(private), compact)
      end
    end

    test "a term-encoded row is stored as JSON inside the envelope", %{rows: rows} do
      assert {:ok, _report} = Admin.reencrypt()
      stored = fetch!(rows.legacy_etf.id)

      assert {:ok, plaintext} =
               KeyEncryption.open(
                 Helpers.config_keyset(),
                 stored.kid,
                 stored.private_jwk_encrypted
               )

      assert {:ok, %{"kid" => "kid-etf"}} = Jason.decode(plaintext)
    end

    test "re-wrapped rows write a key_rewrapped audit entry with the previous KEK", %{rows: rows} do
      assert {:ok, _report} = Admin.reencrypt()

      audit = audit_for!(rows.on_test_2.id)
      assert audit.action == "key_rewrapped"

      assert Enum.sort(Map.keys(audit.metadata)) ==
               ~w(kek_id key_id kid previous_kek_id status use)

      assert audit.metadata["previous_kek_id"] == "test-2"
      assert audit.metadata["kek_id"] == "test-1"
      assert audit_count() == 3
    end
  end

  describe "scope" do
    test "every status and both uses are converted without touching lifecycle columns" do
      rows =
        for {kid, status, use} <- [
              {"s-upcoming", :upcoming, :sig},
              {"s-active", :active, :sig},
              {"s-retiring", :retiring, :enc},
              {"s-retired-sig", :retired, :sig},
              {"s-retired-enc", :retired, :enc},
              {"s-active-enc", :active, :enc}
            ] do
          Helpers.insert_signing_key_row!(Helpers.legacy_json_row(kid, status: status, use: use))
        end

      assert {:ok, report} = Admin.reencrypt()
      assert report.encrypted == 6
      assert report.failed == []

      for row <- rows do
        stored = fetch!(row.id)
        assert String.starts_with?(stored.private_jwk_encrypted, "LSK")
        assert stored.status == row.status
        assert stored.use == row.use
        assert stored.published_at == row.published_at
        assert stored.activated_at == row.activated_at
        assert stored.retiring_at == row.retiring_at
        assert stored.retired_at == row.retired_at
      end
    end

    test "legacy rows are converted even when plaintext is rejected" do
      row = Helpers.insert_signing_key_row!(Helpers.legacy_json_row("kid-reject"))

      Helpers.put_key_encryption(
        keys: Helpers.config_keys(),
        current: "test-1",
        legacy_plaintext: :reject
      )

      assert {:ok, %{encrypted: 1}} = Admin.reencrypt()
      assert String.starts_with?(fetch!(row.id).private_jwk_encrypted, "LSK")
    end

    test "pages visit every row exactly once" do
      for n <- 1..5, do: Helpers.insert_signing_key_row!(Helpers.legacy_json_row("kid-page-#{n}"))

      assert {:ok, report} = Admin.reencrypt(page_size: 2)
      assert report.scanned == 5
      assert report.encrypted == 5
    end
  end

  describe "failures" do
    setup do
      rows = [
        Helpers.insert_signing_key_row!(Helpers.legacy_json_row("f-no-kid", kid_in_jwk: false)),
        Helpers.insert_signing_key_row!(
          Helpers.legacy_json_row("f-other-kid", jwk_kid: "elsewhere")
        ),
        Helpers.insert_signing_key_row!(Helpers.legacy_etf_row("f-atoms", atom_keys: true)),
        Helpers.insert_signing_key_row!(Helpers.unreadable_legacy_row("f-unreadable")),
        Helpers.insert_signing_key_row!(Helpers.sealed_row("f-gone", "gone-1")),
        Helpers.insert_signing_key_row!(
          Helpers.sealed_row("f-wrong-material", "test-2", salt: "x")
        ),
        Helpers.insert_signing_key_row!(
          Helpers.sealed_row("f-swapped", "test-2", seal_kid: "someone-else")
        )
      ]

      %{rows: rows, before: Map.new(rows, &{&1.id, &1.private_jwk_encrypted})}
    end

    test "each failure is reported by kid and reason and the row is untouched", ctx do
      assert {:ok, report} = Admin.reencrypt()

      assert report.scanned == 7
      assert report.encrypted == 0
      assert report.rewrapped == 0

      assert Enum.map(report.failed, &{&1.kid, &1.reason, &1.kek_id}) == [
               {"f-no-kid", :kid_mismatch, nil},
               {"f-other-kid", :kid_mismatch, nil},
               {"f-atoms", :kid_mismatch, nil},
               {"f-unreadable", :unreadable_legacy, nil},
               {"f-gone", :unknown_kek, "gone-1"},
               {"f-wrong-material", :decryption_failed, "test-2"},
               {"f-swapped", :decryption_failed, "test-2"}
             ]

      for row <- ctx.rows, do: assert(fetch!(row.id).private_jwk_encrypted == ctx.before[row.id])
      assert audit_count() == 0
    end

    test "dry-run reports the same outcome and writes nothing", ctx do
      good = Helpers.insert_signing_key_row!(Helpers.legacy_json_row("f-good"))
      stale = Helpers.insert_signing_key_row!(Helpers.sealed_row("f-stale", "test-2"))

      assert {:ok, dry} = Admin.reencrypt(dry_run: true)
      assert dry.dry_run == true
      assert audit_count() == 0
      assert fetch!(good.id).private_jwk_encrypted == good.private_jwk_encrypted
      assert fetch!(stale.id).private_jwk_encrypted == stale.private_jwk_encrypted
      for row <- ctx.rows, do: assert(fetch!(row.id).private_jwk_encrypted == ctx.before[row.id])

      assert {:ok, real} = Admin.reencrypt()
      assert real.dry_run == false
      assert %{real | dry_run: true} == dry
      assert dry.encrypted == 1
      assert dry.rewrapped == 1
      assert length(dry.failed) == 7
    end
  end

  describe "retired rows" do
    test "are converted or reported like any other status" do
      ok = Helpers.insert_signing_key_row!(Helpers.legacy_json_row("r-ok", status: :retired))

      bad =
        Helpers.insert_signing_key_row!(Helpers.unreadable_legacy_row("r-bad", status: :retired))

      gone =
        Helpers.insert_signing_key_row!(Helpers.sealed_row("r-gone", "gone-1", status: :retired))

      assert {:ok, report} = Admin.reencrypt()
      assert report.encrypted == 1
      assert String.starts_with?(fetch!(ok.id).private_jwk_encrypted, "LSK")

      assert Enum.map(report.failed, &{&1.kid, &1.reason, &1.status}) == [
               {"r-bad", :unreadable_legacy, :retired},
               {"r-gone", :unknown_kek, :retired}
             ]

      assert fetch!(bad.id).private_jwk_encrypted == bad.private_jwk_encrypted
      assert fetch!(gone.id).private_jwk_encrypted == gone.private_jwk_encrypted
    end
  end

  describe "configuration errors" do
    test "absent key encryption touches nothing" do
      row = Helpers.insert_signing_key_row!(Helpers.legacy_json_row("kid-absent"))
      Helpers.put_key_encryption(nil)

      assert {:error, :key_encryption_not_configured} = Admin.reencrypt()
      assert fetch!(row.id).private_jwk_encrypted == row.private_jwk_encrypted
    end

    test "invalid key encryption reports a message without key material" do
      row = Helpers.insert_signing_key_row!(Helpers.legacy_json_row("kid-invalid"))

      Application.put_env(:lockspire, :key_encryption,
        keys: [{"a", "SECRETMATERIAL"}],
        current: "a"
      )

      assert {:error, {:invalid_config, message}} = Admin.reencrypt()
      refute message =~ "SECRETMATERIAL"
      assert fetch!(row.id).private_jwk_encrypted == row.private_jwk_encrypted
    end
  end

  describe "ordering and empty tables" do
    test "an empty table yields an all-zero report and no audit entry" do
      assert {:ok, report} = Admin.reencrypt()
      assert report.scanned == 0
      assert report.failed == []
      assert report.changes == []
      assert audit_count() == 0
    end

    test "changes follow ascending key id and repeat identically" do
      for n <- 1..3, do: Helpers.insert_signing_key_row!(Helpers.legacy_json_row("o-#{n}"))
      assert {:ok, report} = Admin.reencrypt(dry_run: true)
      assert Enum.map(report.changes, & &1.kid) == ["o-1", "o-2", "o-3"]
      assert Enum.map(report.changes, & &1.action) == [:encrypted, :encrypted, :encrypted]
      assert {:ok, ^report} = Admin.reencrypt(dry_run: true)
    end
  end

  describe "operator telemetry" do
    @actions [:encrypted, :rewrapped, :reencrypt_failed, :reencrypt_completed]
    @measurement_schema ~w(already_current conflicted count duration encrypted failed
                           no_private_key pending rewrapped scanned stranded_retired)a

    setup do
      events =
        Enum.flat_map(@actions, fn action ->
          [[:lockspire, :key, action], [:lockspire, :audit, :key, action]]
        end)

      TelemetryCapture.attach_many(events)

      Helpers.insert_signing_key_row!(Helpers.legacy_json_row("t-legacy"))
      Helpers.insert_signing_key_row!(Helpers.sealed_row("t-stale", "test-2"))
      Helpers.insert_signing_key_row!(Helpers.sealed_row("t-gone", "gone-1"))
      :ok
    end

    test "apply mode emits exact allowlisted metadata for each event" do
      actor = %{type: :operator, id: "test-operator"}
      assert {:ok, _report} = Admin.reencrypt(actor: actor)

      events = drain_events()

      assert [encrypted] = events_named(events, [:lockspire, :key, :encrypted])
      assert metadata_keys(encrypted) == [:actor_id, :actor_type, :kek_id, :key_id, :kid, :status]

      assert [rewrapped] = events_named(events, [:lockspire, :key, :rewrapped])

      assert metadata_keys(rewrapped) ==
               [:actor_id, :actor_type, :kek_id, :key_id, :kid, :previous_kek_id, :status]

      assert [failed] = events_named(events, [:lockspire, :key, :reencrypt_failed])
      assert metadata_keys(failed) == [:key_id, :kid, :reason]
      assert elem(failed, 2) |> Map.fetch!(:reason) == :unknown_kek

      assert [completed] = events_named(events, [:lockspire, :key, :reencrypt_completed])
      assert metadata_keys(completed) == [:actor_id, :actor_type, :current_kek_id, :mode]
      assert Enum.sort(Map.keys(elem(completed, 1))) == @measurement_schema
      assert elem(completed, 1).scanned == 3
      assert elem(completed, 1).failed == 1
      assert elem(completed, 2).mode == :apply

      for action <- @actions do
        assert length(events_named(events, [:lockspire, :audit, :key, action])) ==
                 length(events_named(events, [:lockspire, :key, action]))
      end

      refute_sensitive(events)
    end

    test "dry-run emits only the completed event with the same measurement schema" do
      actor = %{type: :operator, id: "test-operator"}
      assert {:ok, _report} = Admin.reencrypt(dry_run: true, actor: actor)

      events = drain_events()
      assert events_named(events, [:lockspire, :key, :encrypted]) == []
      assert events_named(events, [:lockspire, :key, :rewrapped]) == []
      assert events_named(events, [:lockspire, :key, :reencrypt_failed]) == []

      assert [completed] = events_named(events, [:lockspire, :key, :reencrypt_completed])
      assert Enum.sort(Map.keys(elem(completed, 1))) == @measurement_schema
      assert elem(completed, 1).encrypted == 1
      assert elem(completed, 1).rewrapped == 1
      assert elem(completed, 2).mode == :dry_run
    end
  end

  describe "assess/2" do
    alias Lockspire.Admin.Keys.Reencrypt

    setup do
      %{keyset: Helpers.config_keyset()}
    end

    test "classifies each stored shape", %{keyset: keyset} do
      assert Reencrypt.assess(Helpers.nil_material_row("a"), keyset) == :no_private_key
      assert Reencrypt.assess(Helpers.legacy_json_row("a"), keyset) == :sealable_legacy

      assert Reencrypt.assess(Helpers.legacy_json_row("a", kid_in_jwk: false), keyset) ==
               {:unsealable, :kid_mismatch, nil}

      assert Reencrypt.assess(Helpers.unreadable_legacy_row("a"), keyset) ==
               {:unsealable, :unreadable_legacy, nil}

      assert Reencrypt.assess(Helpers.sealed_row("a", "test-2"), keyset) == {:envelope, "test-2"}

      assert Reencrypt.assess(Helpers.sealed_row("a", "gone-1"), keyset) ==
               {:unsealable, :unknown_kek, "gone-1"}

      assert Reencrypt.assess(Helpers.sealed_row("a", "test-2", salt: "x"), keyset) ==
               {:unsealable, :decryption_failed, "test-2"}
    end

    test "a nil key set cannot open any envelope" do
      assert Reencrypt.assess(Helpers.sealed_row("a", "test-2"), nil) ==
               {:unsealable, :unknown_kek, "test-2"}
    end
  end

  defp drain_events(acc \\ []) do
    receive do
      {:telemetry_event, event, measurements, metadata} ->
        drain_events([{event, measurements, metadata} | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  defp events_named(events, name), do: Enum.filter(events, fn {event, _, _} -> event == name end)

  defp metadata_keys({_event, _measurements, metadata}), do: metadata |> Map.keys() |> Enum.sort()

  defp refute_sensitive(events) do
    for {_event, _measurements, metadata} <- events, {_key, value} <- metadata do
      refute is_binary(value) and String.contains?(value, "LSK")
      refute is_binary(value) and byte_size(value) > 64
    end
  end

  defp use_current(id) do
    Helpers.put_key_encryption(keys: Helpers.config_keys(), current: id)
  end

  defp assert_all_on(rows, kek_id) do
    for {_name, row} <- rows do
      stored = fetch!(row.id)
      assert {:ok, ^kek_id} = KeyEncryption.envelope_kek_id(stored.private_jwk_encrypted)
      assert {:ok, jwk} = PrivateJwk.decode(stored)
      assert jwk["kid"] == row.kid
    end
  end

  defp fetch!(id) do
    {:ok, key} = Repository.fetch_signing_key_by_id(id)
    key
  end

  defp audit_for!(id) do
    Lockspire.TestRepo.one!(
      from(a in AuditEventRecord,
        where: a.resource_type == "signing_key" and a.resource_id == ^to_string(id),
        order_by: [desc: a.id],
        limit: 1
      )
    )
  end

  defp audit_count do
    Lockspire.TestRepo.aggregate(
      from(a in AuditEventRecord, where: a.action in ["key_encrypted", "key_rewrapped"]),
      :count
    )
  end
end
