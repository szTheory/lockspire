defmodule Lockspire.Integration.SigningKeyUpgradeJourneyTest do
  @moduledoc """
  PROOF-01: legacy plaintext rows become envelopes, stay usable under `:reject`, and survive a
  KEK rotation, with every signing consumer reading its key back from the database.
  """

  use ExUnit.Case, async: false

  import Ecto.Query
  import ExUnit.CaptureIO

  alias Lockspire.KeyEncryptionHelpers, as: Helpers
  alias Lockspire.Security.KeyEncryption
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.SigningKeyRecord
  alias Lockspire.TestSupport.SigningConsumers

  @moduletag :integration

  @task "lockspire.keys.reencrypt"
  @prefix_root "upg-journey-"

  setup do
    refute Process.whereis(Lockspire.TestRepo),
           "the task must start the repo itself, so this test must begin with it stopped"

    foreign =
      with_repo(fn ->
        Lockspire.TestRepo.aggregate(
          from(k in SigningKeyRecord, where: not like(k.kid, ^(@prefix_root <> "%"))),
          :count
        )
      end)

    assert foreign == 0,
           "the committed test database holds #{foreign} signing keys that this test did not " <>
             "create; reset the committed test database before running it"

    on_exit(&cleanup/0)
    Mix.Task.reenable(@task)
    on_exit(fn -> Mix.Task.reenable(@task) end)

    %{prefix: @prefix_root <> Base.url_encode64(:crypto.strong_rand_bytes(6), padding: false)}
  end

  test "a legacy key becomes an envelope and still signs", %{prefix: prefix} do
    Helpers.put_key_encryption(
      keys: Helpers.config_keys(),
      current: "test-1",
      legacy_plaintext: :allow
    )

    kid = prefix <> "-sig-json"
    legacy = Helpers.legacy_json_row(kid, status: :active)
    original = Jason.decode!(legacy.private_jwk_encrypted)
    verify = verify_key(original)
    [seeded] = seed([legacy])
    assert seeded.kid == kid

    assert {:ok, jwt} = id_token_from_storage(kid)
    assert SigningConsumers.verify_jwt(jwt, verify)

    assert {_output, {:error, _}} = run_task(["--check"])
    assert {_output, :ok} = run_task([])
    assert {_output, :ok} = run_task(["--check"])

    [row] = stored(prefix)
    assert_sealed(row.private_jwk_encrypted, original, "test-1")

    assert :ok = SigningConsumers.id_token(read_back(kid), verify)
    assert read_back(kid).kid == kid
  end

  test "legacy JSON and ETF rows for sig and enc survive migration, :reject and a KEK rotation",
       %{prefix: prefix} do
    Helpers.put_key_encryption(
      keys: Helpers.config_keys(),
      current: "test-1",
      legacy_plaintext: :allow
    )

    kids = %{
      sig_json: prefix <> "-sig-json",
      sig_etf: prefix <> "-sig-etf",
      enc_json: prefix <> "-enc-json",
      enc_etf: prefix <> "-enc-etf"
    }

    rows = [
      Helpers.legacy_json_row(kids.sig_json, use: :sig, status: :active),
      Helpers.legacy_etf_row(kids.sig_etf, use: :sig),
      Helpers.legacy_json_row(kids.enc_json, use: :enc),
      Helpers.legacy_etf_row(kids.enc_etf, use: :enc)
    ]

    original = rows |> hd() |> Map.fetch!(:private_jwk_encrypted) |> Jason.decode!()
    verify = verify_key(original)
    seeded = seed(rows)
    assert length(seeded) == 4

    # Step 2: every consumer works from the legacy bytes under :allow.
    assert_all_consumers(kids, verify)

    # Step 3: migrate.
    assert {_output, {:error, _}} = run_task(["--check"])
    assert {_output, :ok} = run_task([])
    assert {_output, :ok} = run_task(["--check"])

    # Step 4: only current-KEK envelopes with no private members on disk.
    stored_rows = stored(prefix)
    assert length(stored_rows) == 4

    for row <- stored_rows do
      assert_sealed(row.private_jwk_encrypted, original, "test-1")
    end

    # Step 5: strict mode.
    Helpers.put_key_encryption(
      keys: Helpers.config_keys(),
      current: "test-1",
      legacy_plaintext: :reject
    )

    assert_all_consumers(kids, verify)

    # Step 6: rotate to test-2 (add non-current, switch current, re-encrypt, check).
    Helpers.put_key_encryption(
      keys: Helpers.config_keys(["test-1", "test-2"]),
      current: "test-1",
      legacy_plaintext: :reject
    )

    Helpers.put_key_encryption(
      keys: Helpers.config_keys(["test-1", "test-2"]),
      current: "test-2",
      legacy_plaintext: :reject
    )

    assert {_output, :ok} = run_task([])
    assert {_output, :ok} = run_task(["--check"])

    rotated = stored(prefix)
    assert length(rotated) == 4
    kek_ids = Enum.map(rotated, &KeyEncryption.envelope_kek_id(&1.private_jwk_encrypted))
    assert Enum.all?(kek_ids, &(&1 == {:ok, "test-2"}))
    assert Enum.count(kek_ids, &(&1 == {:ok, "test-1"})) == 0

    for row <- rotated do
      assert_sealed(row.private_jwk_encrypted, original, "test-2")
    end

    # The old key is removed; only test-2 remains.
    Helpers.put_key_encryption(
      keys: Helpers.config_keys(["test-2"]),
      current: "test-2",
      legacy_plaintext: :reject
    )

    # Step 7: same kids, still working.
    assert_all_consumers(kids, verify)
  end

  # Reads every row back from the database, then drives all six consumers over each sig/enc pair.
  defp assert_all_consumers(kids, verify) do
    for sig_kid <- [kids.sig_json, kids.sig_etf], enc_kid <- [kids.enc_json, kids.enc_etf] do
      sig = read_back(sig_kid)
      enc = read_back(enc_kid)
      assert sig.kid == sig_kid
      assert enc.kid == enc_kid

      results = SigningConsumers.sign_all(%{sig: sig, enc: enc, verify: verify})

      assert results == %{
               id_token: :ok,
               logout_token: :ok,
               jarm: :ok,
               introspection_jwt: :ok,
               access_token: :ok,
               jar_decrypt: :ok
             }
    end
  end

  defp id_token_from_storage(kid) do
    key = read_back(kid)

    params = %{
      client_id: "client-123",
      issuer: "https://example.test/lockspire",
      host_claims: %Lockspire.Host.Claims{subject: "sub-1", id_token: %{}, userinfo: %{}},
      interaction_nonce: "nonce-123",
      access_token: "access-token-123",
      issued_at: ~U[2026-04-28 15:00:00Z],
      signing_key: key
    }

    Lockspire.Protocol.IdToken.sign(params)
  end

  defp verify_key(private_map) do
    {_, public_map} = private_map |> JOSE.JWK.from_map() |> JOSE.JWK.to_public_map()
    JOSE.JWK.from_map(public_map)
  end

  # The stored bytes must be a version-1 LSK envelope under `kek_id` and hold no private member.
  defp assert_sealed(bytes, original, kek_id) do
    assert {:ok, ^kek_id} = KeyEncryption.envelope_kek_id(bytes)
    assert binary_part(bytes, 0, 4) == "LSK" <> <<1>>
    refute bytes =~ ~s("d")
    refute bytes =~ ~s("k")

    for member <- ["d", "p", "q", "dp", "dq", "qi"], is_binary(original[member]) do
      refute bytes =~ original[member]
    end
  end

  defp read_back(kid) do
    with_repo(fn ->
      {:ok, rows} = Repository.list_signing_keys()
      Enum.find(rows, &(&1.kid == kid))
    end)
  end

  defp run_task(args) do
    Mix.Task.reenable(@task)
    test_pid = self()

    output =
      capture_io(fn ->
        result =
          try do
            Mix.Task.run(@task, args)
            :ok
          rescue
            error in Mix.Error -> {:error, error.message}
          end

        send(test_pid, {:task_result, result})
      end)

    assert_received {:task_result, result}
    {output, result}
  end

  defp seed(rows), do: with_repo(fn -> Enum.map(rows, &Helpers.insert_signing_key_row!/1) end)

  defp stored(prefix) do
    with_repo(fn ->
      {:ok, rows} = Repository.list_signing_keys()
      rows |> Enum.filter(&String.starts_with?(&1.kid, prefix)) |> Enum.sort_by(& &1.id)
    end)
  end

  defp with_repo(fun) do
    {:ok, result, _apps} =
      Ecto.Migrator.with_repo(Lockspire.TestRepo, fn _ -> fun.() end, mode: :temporary)

    result
  end

  defp cleanup do
    with_repo(fn ->
      ids =
        Lockspire.TestRepo.all(
          from(k in SigningKeyRecord, where: like(k.kid, ^(@prefix_root <> "%")), select: k.id)
        )

      string_ids = Enum.map(ids, &to_string/1)

      Lockspire.TestRepo.delete_all(
        from(a in AuditEventRecord,
          where: a.resource_type == "signing_key" and a.resource_id in ^string_ids
        )
      )

      Lockspire.TestRepo.delete_all(from(k in SigningKeyRecord, where: k.id in ^ids))
    end)
  end
end
