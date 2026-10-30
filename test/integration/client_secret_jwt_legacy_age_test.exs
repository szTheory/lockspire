defmodule Lockspire.Integration.ClientSecretJwtLegacyAgeTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.TestSupport.ClientSecretVerifierFixtures, as: Fixtures

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

  test "LEG175-FRESH persists and authenticates through repository-backed ClientAuth" do
    %{client: client, plaintext_secret: secret} = Fixtures.persisted_client()
    assert {:ok, %Client{client_id: id}} = Repository.fetch_client_by_id(client.client_id)
    assert id == client.client_id
    assert Fixtures.secret_hash_matches?(client.client_secret_hash, secret)
    {result, _jti, _issued_at} = Fixtures.authenticate(client, secret)
    assert {:ok, %Client{client_id: ^id}} = result
    assert Fixtures.effects_snapshot(id) == %{used_jtis: 1, tokens: 0, grants: 0, audits: 0}
  end

  test "LEG175-FORMS sends each historical authenticated shape through the persisted caller" do
    now = System.os_time(:second)

    for shape <- [:tuple3, :tuple2, :map] do
      %{client: client, plaintext_secret: secret} =
        Fixtures.persisted_client(legacy_shape: shape, signed_at: now, max_age: 60)

      {result, jti, _issued_at} = Fixtures.authenticate(client, secret)
      assert {:ok, %Client{client_id: client_id}} = result
      assert client_id == client.client_id
      assert is_binary(jti) and jti != ""

      assert Fixtures.effects_snapshot(client_id) == %{
               used_jtis: 1,
               tokens: 0,
               grants: 0,
               audits: 0
             }
    end
  end

  test "LEG175-AGED-23H and LEG175-AGED-2D expose Plug's native storage age" do
    now = System.os_time(:second)

    %{client: aged_client, plaintext_secret: aged_secret} =
      Fixtures.persisted_client(signed_at: now - 23 * 60 * 60)

    {aged_result, aged_jti, _} = Fixtures.authenticate(aged_client, aged_secret)
    assert {:ok, %Client{client_id: aged_id}} = aged_result
    assert aged_jti
    assert Fixtures.effects_snapshot(aged_id).used_jtis == 1

    %{client: old_client, plaintext_secret: old_secret} =
      Fixtures.persisted_client(signed_at: now - 2 * 86_400)

    {old_result, old_jti, _} = Fixtures.authenticate(old_client, old_secret)
    assert_invalid_client(old_result, :client_secret_verifier_unavailable)
    refute is_nil(old_jti)

    assert Fixtures.effects_snapshot(old_client.client_id) == %{
             used_jtis: 0,
             tokens: 0,
             grants: 0,
             audits: 0
           }
  end

  test "LEG175-FUTURE rejects an authenticated verifier timestamp ahead of Plug wall clock" do
    now = System.os_time(:second)
    %{client: client, plaintext_secret: secret} = Fixtures.persisted_client(signed_at: now + 60)

    {result, jti, _} = Fixtures.authenticate(client, secret)
    assert_invalid_client(result, :client_secret_verifier_unavailable)
    refute is_nil(jti)

    assert Fixtures.effects_snapshot(client.client_id) == %{
             used_jtis: 0,
             tokens: 0,
             grants: 0,
             audits: 0
           }
  end

  test "LEG175-MALFORMED, LEG175-WRONG-KEY and LEG175-MISSING fail before replay persistence" do
    wrong_key =
      Plug.Crypto.encrypt(
        String.duplicate("b", 64),
        "lockspire client_secret_jwt verifier",
        "test-secret"
      )

    for {case_id, verifier, expected_reason} <- [
          {"LEG175-MALFORMED", "not-a-plug-ciphertext", :client_secret_verifier_unavailable},
          {"LEG175-WRONG-KEY", wrong_key, :client_secret_verifier_unavailable},
          {"LEG175-MISSING", nil, :client_secret_verifier_missing}
        ] do
      %{client: client, plaintext_secret: secret} = Fixtures.persisted_client(verifier: verifier)
      {result, jti, _} = Fixtures.authenticate(client, secret)
      assert_invalid_client(result, expected_reason)
      assert is_binary(jti) and jti != "", "#{case_id} must use a fresh assertion JTI"

      assert Fixtures.effects_snapshot(client.client_id) == %{
               used_jtis: 0,
               tokens: 0,
               grants: 0,
               audits: 0
             }
    end
  end

  test "LEG175-INACTIVE rejects a disabled client after assertion validation and replay consumption" do
    %{client: client, plaintext_secret: secret} = Fixtures.persisted_client(active: false)
    {result, jti, _} = Fixtures.authenticate(client, secret)
    assert_invalid_client(result, :client_app_disabled)
    refute is_nil(jti)

    assert Fixtures.effects_snapshot(client.client_id) == %{
             used_jtis: 1,
             tokens: 0,
             grants: 0,
             audits: 0
           }
  end

  test "LEG175-APP-BEFORE, APP-EQUAL and APP-AFTER use configured equality semantics" do
    decision_now = DateTime.utc_now() |> DateTime.truncate(:second)

    for {case_id, deadline, expected} <- [
          {"LEG175-APP-BEFORE", DateTime.add(decision_now, 1, :second), :success},
          {"LEG175-APP-EQUAL", decision_now, :client_app_expired},
          {"LEG175-APP-AFTER", DateTime.add(decision_now, -1, :second), :client_app_expired}
        ] do
      %{client: client, plaintext_secret: secret} =
        Fixtures.persisted_client(lifetime_version: 1, client_expires_at: deadline)

      {result, _jti, issued_at} =
        Fixtures.authenticate(client, secret,
          issued_at: decision_now,
          now: fn -> decision_now end
        )

      assert DateTime.compare(issued_at, decision_now) == :eq, case_id
      assert_case_result(result, expected, case_id)
      assert lifecycle_effects(client.client_id, expected)
    end
  end

  test "LEG175-SECRET-BEFORE, SECRET-EQUAL and SECRET-AFTER use configured equality semantics" do
    decision_now = DateTime.utc_now() |> DateTime.truncate(:second)

    for {case_id, deadline, expected} <- [
          {"LEG175-SECRET-BEFORE", DateTime.add(decision_now, 1, :second), :success},
          {"LEG175-SECRET-EQUAL", decision_now, :client_secret_expired},
          {"LEG175-SECRET-AFTER", DateTime.add(decision_now, -1, :second), :client_secret_expired}
        ] do
      %{client: client, plaintext_secret: secret} =
        Fixtures.persisted_client(lifetime_version: 1, client_secret_expires_at: deadline)

      {result, _jti, issued_at} =
        Fixtures.authenticate(client, secret,
          issued_at: decision_now,
          now: fn -> decision_now end
        )

      assert DateTime.compare(issued_at, decision_now) == :eq, case_id
      assert_case_result(result, expected, case_id)
      assert lifecycle_effects(client.client_id, expected)
    end
  end

  test "LEG175-V0-UNLIMITED keeps the legacy lifetime row usable" do
    %{client: client, plaintext_secret: secret} = Fixtures.persisted_client(lifetime_version: 0)
    {result, _jti, _} = Fixtures.authenticate(client, secret)
    assert {:ok, %Client{client_id: id}} = result
    assert Fixtures.effects_snapshot(id).used_jtis == 1
  end

  test "LEG175-HASH-MISMATCH is persisted and explicitly non-ready for migration" do
    %{client: divergent, plaintext_secret: secret} =
      Fixtures.persisted_client(hash: "sha256:synthetic:divergent")

    assert {:ok, stored} = Repository.fetch_client_by_id(divergent.client_id)

    assert stored.client_secret_jwt_verifier_encrypted ==
             divergent.client_secret_jwt_verifier_encrypted

    refute Fixtures.secret_hash_matches?(stored.client_secret_hash, secret)

    %{client: missing_hash, plaintext_secret: missing_secret} =
      Fixtures.persisted_client(hash: nil)

    assert {:ok, stored_missing} = Repository.fetch_client_by_id(missing_hash.client_id)
    assert is_nil(stored_missing.client_secret_hash)
    refute Fixtures.secret_hash_matches?(stored_missing.client_secret_hash, missing_secret)
  end

  defp assert_case_result({:ok, %Client{}}, :success, _case_id), do: :ok

  defp assert_case_result({:error, %{reason_code: expected}}, expected, _case_id), do: :ok

  defp assert_case_result(actual, expected, case_id) do
    flunk("#{case_id} expected #{inspect(expected)}, got #{inspect(redact_result(actual))}")
  end

  defp assert_invalid_client(
         {:error, %{status: 401, error: "invalid_client", reason_code: reason}},
         reason
       ),
       do: :ok

  defp assert_invalid_client(actual, expected) do
    flunk("expected invalid_client #{expected}, got #{inspect(redact_result(actual))}")
  end

  defp lifecycle_effects(client_id, :success) do
    assert Fixtures.effects_snapshot(client_id) == %{
             used_jtis: 1,
             tokens: 0,
             grants: 0,
             audits: 0
           }
  end

  defp lifecycle_effects(client_id, _error) do
    assert Fixtures.effects_snapshot(client_id) == %{
             used_jtis: 1,
             tokens: 0,
             grants: 0,
             audits: 0
           }
  end

  defp redact_result({:error, error}),
    do: %{status: error.status, error: error.error, reason_code: error.reason_code}

  defp redact_result(other), do: other
end
