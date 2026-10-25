defmodule Lockspire.Integration.ClientSecretVerifierAgeTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Clients
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context
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

  test "native nil, zero and v0 lifetimes remain usable past one day without rewriting verifier" do
    context = context()
    two_days_later_ms = System.os_time(:millisecond) + 2 * 86_400_000

    for {case_id, lifetime_version} <- [
          {:nil_lifetime, 1},
          {:zero_lifetime, 1},
          {:v0_unlimited, 0}
        ] do
      {client, secret} =
        persist_native(context, lifetime_version: lifetime_version, name: Atom.to_string(case_id))

      before = credential_snapshot(client)

      {result, _jti} =
        authenticate(client, secret, context,
          verifier_now_ms: two_days_later_ms,
          lifecycle_now: DateTime.utc_now() |> DateTime.truncate(:second)
        )

      assert result_kind(result) == :ok, Atom.to_string(case_id)
      assert same_credentials?(before, fetch_credentials(client.client_id))
      assert Fixtures.effects_snapshot(client.client_id).used_jtis == 1
    end
  end

  test "app and secret lifetimes reject at equality after consuming the valid assertion JTI" do
    context = context()
    deadline = DateTime.utc_now() |> DateTime.truncate(:second)
    issued_at = DateTime.add(deadline, -1, :second)

    for {kind, field, expired_reason} <- [
          {:app, :client_expires_at, :client_app_expired},
          {:secret, :client_secret_expires_at, :client_secret_expired}
        ],
        {delta_seconds, expected} <- [
          {1, :ok},
          {0, {:error, expired_reason}},
          {-1, {:error, expired_reason}}
        ] do
      attrs =
        [lifetime_version: 1]
        |> Keyword.put(field, DateTime.add(deadline, delta_seconds, :second))

      {client, secret} = persist_native(context, attrs)
      before = credential_snapshot(client)

      {result, _jti} =
        authenticate(client, secret, context,
          issued_at: issued_at,
          lifecycle_now: deadline,
          verifier_now_ms: System.os_time(:millisecond)
        )

      assert result_kind(result) == expected,
             "#{kind} deadline delta #{delta_seconds}: #{inspect(result_kind(result))}"

      assert same_credentials?(before, fetch_credentials(client.client_id))

      assert Fixtures.effects_snapshot(client.client_id) == %{
               used_jtis: 1,
               tokens: 0,
               grants: 0,
               audits: 0
             }
    end
  end

  test "migrated 23-hour material authenticates at its original deadline and fails one ms later" do
    context = context()
    now_seconds = System.os_time(:second)
    signed_at_seconds = now_seconds - 86_399
    signed_at_ms = signed_at_seconds * 1000
    deadline_ms = signed_at_ms + 86_400_000
    {client, secret} = persist_legacy(context, signed_at: signed_at_seconds, max_age: 86_400)
    legacy = client.client_secret_jwt_verifier_encrypted
    expected_hash = client.client_secret_hash

    assert {:ok, migrated} =
             ClientSecretVerifier.prepare_migrated(
               context,
               client.client_id,
               legacy,
               expected_hash,
               now_ms: System.os_time(:millisecond),
               legacy_secret_key_base: Lockspire.Config.secret_key_base()
             )

    update_result =
      Repository.update_client(client, %{client_secret_jwt_verifier_encrypted: migrated})

    assert elem(update_result, 0) == :ok

    {:ok, stored} = Repository.fetch_client_by_id(client.client_id)
    before = credential_snapshot(stored)
    lifecycle_now = DateTime.from_unix!(now_seconds)

    {at_deadline, _jti} =
      authenticate(stored, secret, context,
        verifier_now_ms: deadline_ms,
        lifecycle_now: lifecycle_now
      )

    assert result_kind(at_deadline) == :ok
    assert same_credentials?(before, fetch_credentials(client.client_id))

    {after_deadline, _jti} =
      authenticate(stored, secret, context,
        verifier_now_ms: deadline_ms + 1,
        lifecycle_now: lifecycle_now
      )

    assert result_kind(after_deadline) == {:error, :client_secret_verifier_unavailable}
    assert same_credentials?(before, fetch_credentials(client.client_id))

    assert Fixtures.effects_snapshot(client.client_id) == %{
             used_jtis: 1,
             tokens: 0,
             grants: 0,
             audits: 0
           }
  end

  test "legacy allow matches the qualified caller, reject fails before replay, and invalid ages stay unchanged" do
    allowed_context = context(legacy_read: :allow)
    rejected_context = context(legacy_read: :reject)
    now_seconds = System.os_time(:second)

    %{client: allowed, plaintext_secret: allowed_secret} =
      Fixtures.persisted_client(signed_at: now_seconds)

    {allowed_result, _jti} = authenticate(allowed, allowed_secret, allowed_context)
    assert result_kind(allowed_result) == :ok

    %{client: rejected, plaintext_secret: rejected_secret} =
      Fixtures.persisted_client(signed_at: now_seconds)

    rejected_before = credential_snapshot(rejected)
    {rejected_result, _jti} = authenticate(rejected, rejected_secret, rejected_context)
    assert result_kind(rejected_result) == {:error, :client_secret_verifier_unavailable}
    assert Fixtures.effects_snapshot(rejected.client_id).used_jtis == 0
    assert same_credentials?(rejected_before, fetch_credentials(rejected.client_id))

    for {signed_at, expected_jtis} <- [{now_seconds - 2 * 86_400, 0}, {now_seconds + 60, 0}] do
      %{client: unusable, plaintext_secret: unusable_secret} =
        Fixtures.persisted_client(signed_at: signed_at)

      before = credential_snapshot(unusable)
      {unusable_result, _jti} = authenticate(unusable, unusable_secret, allowed_context)
      assert result_kind(unusable_result) == {:error, :client_secret_verifier_unavailable}
      assert Fixtures.effects_snapshot(unusable.client_id).used_jtis == expected_jtis
      assert same_credentials?(before, fetch_credentials(unusable.client_id))
    end

    %{client: malformed, plaintext_secret: malformed_secret} =
      Fixtures.persisted_client(verifier: "not-a-qualified-verifier")

    before = credential_snapshot(malformed)
    {malformed_result, _jti} = authenticate(malformed, malformed_secret, allowed_context)
    assert result_kind(malformed_result) == {:error, :client_secret_verifier_unavailable}
    assert Fixtures.effects_snapshot(malformed.client_id).used_jtis == 0
    assert same_credentials?(before, fetch_credentials(malformed.client_id))
  end

  test "dedicated authentication does not add a request-time hash comparison" do
    context = context()
    {client, secret} = persist_native(context, hash: "sha256:synthetic:divergent")
    before = credential_snapshot(client)
    {result, _jti} = authenticate(client, secret, context)

    assert result_kind(result) == :ok
    assert same_credentials?(before, fetch_credentials(client.client_id))
    assert Fixtures.effects_snapshot(client.client_id).used_jtis == 1
  end

  defp persist_native(context, opts) do
    {hash, secret} = Clients.rotate_secret_hash()
    client_id = unique_id()
    {:ok, verifier} = ClientSecretVerifier.seal(context, client_id, secret)

    attrs = %{
      client_id: client_id,
      client_secret_hash: Keyword.get(opts, :hash, hash),
      client_secret_jwt_verifier_encrypted: verifier,
      client_type: :confidential,
      name: Keyword.get(opts, :name, "Age contract integration"),
      redirect_uris: [],
      allowed_scopes: [],
      allowed_grant_types: [],
      allowed_response_types: [],
      token_endpoint_auth_method: :client_secret_jwt,
      pkce_required: true,
      subject_type: :public,
      active: true,
      provenance: :operator,
      lifetime_version: Keyword.get(opts, :lifetime_version, 0),
      client_expires_at: Keyword.get(opts, :client_expires_at),
      client_secret_expires_at: Keyword.get(opts, :client_secret_expires_at)
    }

    {:ok, persisted} = Repository.register_client(struct!(Client, attrs))
    {:ok, stored} = Repository.fetch_client_by_id(persisted.client_id)
    {stored, secret}
  end

  defp persist_legacy(_context, opts) do
    %{client: client, plaintext_secret: secret} =
      Fixtures.persisted_client(
        signed_at: Keyword.fetch!(opts, :signed_at),
        max_age: Keyword.fetch!(opts, :max_age)
      )

    {client, secret}
  end

  defp authenticate(client, secret, context, opts \\ []) do
    assertion_opts =
      if Keyword.has_key?(opts, :issued_at),
        do: [issued_at: Keyword.fetch!(opts, :issued_at)],
        else: []

    {params, jti, _issued_at} = Fixtures.assertion(client, secret, assertion_opts)

    result =
      ClientAuth.authenticate(params, nil,
        client_store: Repository,
        jti_store: Repository,
        server_policy_store: Repository,
        supported_jwt_auth_methods: [:client_secret_jwt],
        client_secret_verifier_context: context,
        verifier_now_ms: Keyword.get(opts, :verifier_now_ms, System.os_time(:millisecond)),
        now: fn -> Keyword.get(opts, :lifecycle_now, DateTime.utc_now()) end
      )

    {result, jti}
  end

  defp context(opts \\ []) do
    key = :crypto.strong_rand_bytes(32)
    key_id = "age-integration-key"

    {:ok, context} =
      Context.resolve(
        {:present,
         [
           keys: [{key_id, Base.url_encode64(key, padding: false)}],
           current: key_id,
           write_mode: :dedicated,
           legacy_read: Keyword.get(opts, :legacy_read, :allow)
         ]},
        Lockspire.Config.client_secret_verifier_forbidden_key_bytes()
      )

    context
  end

  defp credential_snapshot(%Client{} = client),
    do: {client.client_secret_hash, client.client_secret_jwt_verifier_encrypted}

  defp fetch_credentials(client_id) do
    {:ok, stored} = Repository.fetch_client_by_id(client_id)
    credential_snapshot(stored)
  end

  defp same_credentials?(left, right), do: left == right

  defp result_kind({:ok, %Client{}}), do: :ok
  defp result_kind({:error, %{reason_code: reason}}), do: {:error, reason}
  defp result_kind(_other), do: :unexpected

  defp unique_id,
    do: "age-integration-" <> Base.url_encode64(:crypto.strong_rand_bytes(18), padding: false)
end
