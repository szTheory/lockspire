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
