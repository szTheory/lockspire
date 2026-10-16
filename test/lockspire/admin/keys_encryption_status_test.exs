defmodule Lockspire.Admin.KeysEncryptionStatusTest do
  use ExUnit.Case, async: false

  alias Lockspire.Admin
  alias Lockspire.Admin.Keys
  alias Lockspire.Admin.Keys.EncryptionStatus
  alias Lockspire.KeyEncryptionHelpers, as: Helpers

  @sentinel "SENTINEL-KEK-MATERIAL"

  describe "build/2" do
    test "an empty table is ready when a key set is configured" do
      status = EncryptionStatus.build(Helpers.config_keyset(), [])

      assert status.total == 0
      assert status.stranded_retired == %{count: 0, kids: []}
      assert status.pending == []
      assert status.configured
      assert status.current_kek_id == "test-1"
      assert status.configured_kek_ids == ["test-1", "test-2"]
      assert status.ready?
    end

    test "without a key set every envelope counts as unknown and nothing is ready" do
      rows = [Helpers.legacy_json_row("a-legacy"), Helpers.sealed_row("b-env", "test-1")]
      status = EncryptionStatus.build(nil, rows)

      refute status.configured
      assert status.current_kek_id == nil
      assert status.configured_kek_ids == []
      assert status.legacy_plaintext == :allow
      assert status.legacy == 1
      assert status.unknown_kek == %{"test-1" => 1}
      refute status.ready?
    end

    test "every pending and broken class is counted, including same-id wrong material" do
      rows = [
        Helpers.sealed_row("a-current", "test-1"),
        Helpers.sealed_row("b-other", "test-2"),
        Helpers.legacy_json_row("c-legacy"),
        Helpers.nil_material_row("d-nil"),
        Helpers.sealed_row("e-gone", "gone-1"),
        Helpers.sealed_row("f-wrong", "test-1", salt: "different"),
        tampered("g-tampered"),
        Helpers.sealed_row("h-swapped", "test-1", seal_kid: "someone-else")
      ]

      status = EncryptionStatus.build(Helpers.config_keyset(), rows)

      assert status.total == 8
      assert status.by_kek_id == %{"test-1" => 1, "test-2" => 1}
      assert status.legacy == 1
      assert status.no_private_key == 1
      assert status.unknown_kek == %{"gone-1" => 1}
      assert status.undecryptable == 3

      assert status.pending == [
               %{kid: "b-other", state: :other_kek},
               %{kid: "c-legacy", state: :legacy},
               %{kid: "e-gone", state: :unknown_kek},
               %{kid: "f-wrong", state: :undecryptable},
               %{kid: "g-tampered", state: :undecryptable},
               %{kid: "h-swapped", state: :undecryptable}
             ]

      refute status.ready?
    end

    test "only rows on the current id are ready" do
      rows = [Helpers.sealed_row("a", "test-1"), Helpers.sealed_row("b", "test-1")]
      status = EncryptionStatus.build(Helpers.config_keyset(), rows)

      assert status.by_kek_id == %{"test-1" => 2}
      assert status.ready?
    end

    test "retired rows the engine cannot seal are stranded and never block readiness" do
      rows = [
        Helpers.sealed_row("a-ok", "test-1"),
        Helpers.unreadable_legacy_row("b-bytes", status: :retired),
        Helpers.legacy_json_row("c-no-kid", status: :retired, kid_in_jwk: false),
        Helpers.sealed_row("d-gone", "gone-1", status: :retired),
        Helpers.sealed_row("e-wrong", "test-2", status: :retired, salt: "different")
      ]

      status = EncryptionStatus.build(Helpers.config_keyset(), rows)

      assert status.stranded_retired == %{
               count: 4,
               kids: ["b-bytes", "c-no-kid", "d-gone", "e-wrong"]
             }

      assert status.legacy == 0
      assert status.unknown_kek == %{}
      assert status.undecryptable == 0
      assert status.pending == []
      assert status.ready?
    end

    test "the same unsealable rows block readiness in every other status" do
      for status_name <- [:active, :retiring, :upcoming] do
        rows = [
          Helpers.unreadable_legacy_row("b-bytes", status: status_name),
          Helpers.sealed_row("d-gone", "gone-1", status: status_name),
          Helpers.sealed_row("e-wrong", "test-2", status: status_name, salt: "different")
        ]

        status = EncryptionStatus.build(Helpers.config_keyset(), rows)

        assert status.stranded_retired == %{count: 0, kids: []}
        assert status.legacy == 1
        assert status.unknown_kek == %{"gone-1" => 1}
        assert status.undecryptable == 1

        assert status.pending == [
                 %{kid: "b-bytes", state: :unsealable_legacy},
                 %{kid: "d-gone", state: :unknown_kek},
                 %{kid: "e-wrong", state: :undecryptable}
               ]

        refute status.ready?
      end
    end

    test "a retired row the engine can seal still blocks until it is sealed" do
      legacy = Helpers.legacy_json_row("a-legacy", status: :retired)
      other = Helpers.sealed_row("b-other", "test-2", status: :retired)

      legacy_status = EncryptionStatus.build(Helpers.config_keyset(), [legacy])
      assert legacy_status.legacy == 1
      assert legacy_status.pending == [%{kid: "a-legacy", state: :legacy}]
      refute legacy_status.ready?

      other_status = EncryptionStatus.build(Helpers.config_keyset(), [other])
      assert other_status.pending == [%{kid: "b-other", state: :other_kek}]
      refute other_status.ready?
    end

    test "with no key set a retired envelope is unknown, not stranded" do
      status =
        EncryptionStatus.build(nil, [Helpers.sealed_row("a", "test-1", status: :retired)])

      assert status.unknown_kek == %{"test-1" => 1}
      assert status.stranded_retired == %{count: 0, kids: []}
      refute status.ready?
    end
  end

  describe "encryption_status/0" do
    setup do
      Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
      start_supervised!(Lockspire.TestRepo)
      Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

      owner = Ecto.Adapters.SQL.Sandbox.start_owner!(Lockspire.TestRepo, shared: true)
      on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(owner) end)

      Helpers.put_key_encryption(
        keys: Helpers.config_keys(),
        current: "test-1",
        legacy_plaintext: :allow
      )

      :ok
    end

    test "matches the pure builder on a fixture row set" do
      rows =
        Enum.map(
          [
            Helpers.sealed_row("a-current", "test-1"),
            Helpers.sealed_row("b-other", "test-2"),
            Helpers.legacy_json_row("c-legacy"),
            Helpers.sealed_row("e-gone", "gone-1")
          ],
          &Helpers.insert_signing_key_row!/1
        )

      assert {:ok, status} = Keys.encryption_status()
      assert status == EncryptionStatus.build(Helpers.config_keyset(), rows)
      assert {:ok, ^status} = Admin.encryption_status()
    end

    test "an unreadable active row is recovered by activating a replacement and retiring it" do
      row =
        Helpers.insert_signing_key_row!(
          Helpers.unreadable_legacy_row("a-unreadable", status: :active)
        )

      assert {:ok, status} = Keys.encryption_status()
      refute status.ready?
      assert status.pending == [%{kid: "a-unreadable", state: :unsealable_legacy}]

      assert {:ok, generated} = Admin.generate_key(:sig)
      replacement_id = generated.key.id
      assert {:ok, _} = Admin.publish_key(replacement_id)
      assert {:ok, _} = Admin.activate_key(replacement_id)

      assert {:ok, still_blocked} = Keys.encryption_status()
      refute still_blocked.ready?
      assert %{kid: "a-unreadable", state: :unsealable_legacy} in still_blocked.pending

      assert {:ok, _} = Admin.retire_key(row.id)

      assert {:ok, recovered} = Keys.encryption_status()
      assert recovered.ready?
      assert recovered.stranded_retired == %{count: 1, kids: ["a-unreadable"]}
    end

    test "invalid config returns a name-only error without key material" do
      Application.put_env(:lockspire, :key_encryption, keys: [{"bad", @sentinel}], current: "bad")

      assert {:error, {:invalid_config, message}} = Keys.encryption_status()
      assert is_binary(message)
      refute message =~ @sentinel
    end

    test "the status holds no long binary that could be stored bytes or key material" do
      Helpers.insert_signing_key_row!(Helpers.legacy_json_row("a-legacy"))
      Helpers.insert_signing_key_row!(Helpers.sealed_row("b-other", "test-2"))

      assert {:ok, status} = Keys.encryption_status()
      assert Enum.all?(binaries(status), &(byte_size(&1) <= 16))
    end
  end

  defp tampered(kid) do
    row = Helpers.sealed_row(kid, "test-1")
    size = byte_size(row.private_jwk_encrypted) - 1
    <<head::binary-size(size), last>> = row.private_jwk_encrypted
    %{row | private_jwk_encrypted: <<head::binary, Bitwise.bxor(last, 1)>>}
  end

  defp binaries(value) when is_binary(value), do: [value]
  defp binaries(value) when is_map(value), do: value |> Enum.flat_map(&binaries/1)
  defp binaries({key, value}), do: binaries(key) ++ binaries(value)
  defp binaries(value) when is_list(value), do: Enum.flat_map(value, &binaries/1)
  defp binaries(_value), do: []
end
