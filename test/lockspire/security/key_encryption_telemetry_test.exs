defmodule Lockspire.Security.KeyEncryptionTelemetryTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Lockspire.Admin.Keys
  alias Lockspire.KeyEncryptionHelpers, as: Helpers
  alias Lockspire.Protocol.PrivateJwk
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

    Helpers.reset_decode_warnings()
    on_exit(&Helpers.reset_decode_warnings/0)
    configure(:allow)

    TelemetryCapture.attach_many([
      [:lockspire, :key, :legacy_read],
      [:lockspire, :key, :decode_failed],
      [:lockspire, :audit, :key, :legacy_read],
      [:lockspire, :audit, :key, :decode_failed]
    ])

    :ok
  end

  defp configure(mode) do
    Helpers.put_key_encryption(
      keys: Helpers.config_keys(),
      current: "test-1",
      legacy_plaintext: mode
    )
  end

  defp audit_count, do: Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

  defp quietly(fun), do: capture_log(fn -> fun.() end)

  describe "legacy_read event" do
    test "fires on every legacy read with exact metadata" do
      row = Helpers.legacy_json_row("kid-legacy")

      quietly(fn ->
        assert {:ok, _} = PrivateJwk.decode(row)
        assert {:ok, _} = PrivateJwk.decode(row)
      end)

      for _ <- 1..2 do
        assert_received {:telemetry_event, [:lockspire, :key, :legacy_read], %{count: 1},
                         metadata}

        assert metadata == %{kid: "kid-legacy", legacy_plaintext: :allow}
      end

      refute_received {:telemetry_event, _, _, _}
    end

    test "an envelope read emits nothing" do
      sealed = Helpers.seal_private_jwk("kid-env", %{"kty" => "RSA", "kid" => "kid-env"})
      assert {:ok, _} = PrivateJwk.decode(%{kid: "kid-env", private_jwk_encrypted: sealed})
      refute_received {:telemetry_event, _, _, _}
    end

    test "writes no audit record and no audit-prefixed mirror" do
      before = audit_count()
      legacy = Helpers.legacy_json_row("kid-legacy")
      unreadable = Helpers.unreadable_legacy_row("kid-bad")

      quietly(fn ->
        PrivateJwk.decode(legacy)
        configure(:reject)
        PrivateJwk.decode(legacy)
        PrivateJwk.decode(unreadable)
      end)

      assert audit_count() == before
      refute_received {:telemetry_event, [:lockspire, :audit | _], _, _}
    end
  end

  describe "log lines" do
    test "one warning per kid naming the re-encryption task, silent with no KEK" do
      row = Helpers.legacy_json_row("kid-warn")

      log =
        capture_log(fn ->
          for _ <- 1..3, do: PrivateJwk.decode(row)
        end)

      assert length(String.split(log, "is stored as legacy plaintext")) == 2
      assert log =~ "kid-warn"
      assert log =~ "mix lockspire.keys.reencrypt"

      Helpers.reset_decode_warnings()
      Helpers.put_key_encryption(nil)
      assert capture_log(fn -> PrivateJwk.decode(row) end) == ""
      assert_received {:telemetry_event, [:lockspire, :key, :legacy_read], %{count: 1}, _}
    end

    test "one error per kid and reason, again after a reset" do
      configure(:reject)
      row = Helpers.legacy_json_row("kid-refused")

      log = capture_log(fn -> for _ <- 1..3, do: PrivateJwk.decode(row) end)
      assert length(String.split(log, "could not be read")) == 2
      assert log =~ "kid-refused"
      assert log =~ "plaintext_key_refused"
      refute log =~ "LSK"
      refute log =~ ~s("d")

      # a different reason for the same kid is its own line
      configure(:allow)
      other = %{row | private_jwk_encrypted: <<0xFF, 0x00, "not json">>}
      log = capture_log(fn -> PrivateJwk.decode(other) end)
      assert log =~ "reason: invalid_signing_key"

      Helpers.reset_decode_warnings()
      configure(:reject)
      assert capture_log(fn -> PrivateJwk.decode(row) end) =~ "plaintext_key_refused"
    end
  end

  describe "recovery" do
    test "a refused legacy row is converted by reencrypt/1 without a config change" do
      stored =
        Helpers.insert_signing_key_row!(Helpers.legacy_json_row("kid-recover", status: :active))

      configure(:reject)
      quietly(fn -> assert {:error, :invalid_signing_key} = PrivateJwk.decode(stored) end)

      assert {:ok, report} = Keys.reencrypt()
      assert report.encrypted >= 1

      {:ok, fresh} = Repository.fetch_signing_key_by_id(stored.id)
      assert {:ok, %{"kid" => "kid-recover"}} = PrivateJwk.decode(fresh)
    end
  end
end
