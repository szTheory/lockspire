defmodule Lockspire.Admin.KeysReencryptTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Lockspire.Admin
  alias Lockspire.KeyEncryptionHelpers, as: Helpers
  alias Lockspire.Protocol.PrivateJwk
  alias Lockspire.Security.KeyEncryption
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository

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
