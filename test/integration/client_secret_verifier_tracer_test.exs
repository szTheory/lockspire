defmodule Lockspire.Integration.ClientSecretVerifierTracerTest do
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

  test "persists a native dedicated verifier and authenticates it against the final client ID" do
    capability_ready? =
      Code.ensure_loaded?(Context) and Code.ensure_loaded?(ClientSecretVerifier) and
        function_exported?(Context, :resolve, 2) and
        function_exported?(Context, :validate, 1) and
        function_exported?(ClientSecretVerifier, :seal, 3)

    assert capability_ready?, "dedicated verifier context and sealing capability are required"

    key = :crypto.strong_rand_bytes(32)
    context = context(key)
    {hash, secret} = Clients.rotate_secret_hash()
    client_id = unique_id()

    assert {:ok, verifier} = ClientSecretVerifier.seal(context, client_id, secret)
    assert String.starts_with?(verifier, "LSCV1.")

    client = %Client{
      client_id: client_id,
      client_secret_hash: hash,
      client_secret_jwt_verifier_encrypted: verifier,
      client_type: :confidential,
      name: "Dedicated verifier tracer",
      redirect_uris: [],
      allowed_scopes: [],
      allowed_grant_types: [],
      allowed_response_types: [],
      token_endpoint_auth_method: :client_secret_jwt,
      pkce_required: true,
      subject_type: :public,
      active: true,
      provenance: :operator,
      lifetime_version: 0
    }

    assert {:ok, persisted} = Repository.register_client(client)
    assert {:ok, stored} = Repository.fetch_client_by_id(client_id)
    assert stored.client_secret_jwt_verifier_encrypted == verifier
    assert Fixtures.secret_hash_matches?(stored.client_secret_hash, secret)

    {params, jti, _issued_at} = Fixtures.assertion(stored, secret)
    result = ClientAuth.authenticate(params, nil, auth_options(context))

    assert result_kind(result) == :ok

    assert Fixtures.effects_snapshot(client_id) == %{
             used_jtis: 1,
             tokens: 0,
             grants: 0,
             audits: 0
           }

    assert persisted.client_id == client_id
    assert inspect(context) =~ "ClientSecretVerifier.Context"
    refute inspect(context) =~ Base.encode64(key)
    assert is_binary(jti) and byte_size(jti) > 0
  end

  test "a verifier sealed for a different identity fails before replay insertion" do
    assert Code.ensure_loaded?(Context) and Code.ensure_loaded?(ClientSecretVerifier) and
             function_exported?(ClientSecretVerifier, :seal, 3),
           "dedicated verifier sealing capability is required"

    context = context(:crypto.strong_rand_bytes(32))
    {hash, secret} = Clients.rotate_secret_hash()
    client_id = unique_id()
    {:ok, verifier} = ClientSecretVerifier.seal(context, unique_id(), secret)

    client = %Client{
      client_id: client_id,
      client_secret_hash: hash,
      client_secret_jwt_verifier_encrypted: verifier,
      client_type: :confidential,
      name: "Dedicated verifier identity binding",
      redirect_uris: [],
      allowed_scopes: [],
      allowed_grant_types: [],
      allowed_response_types: [],
      token_endpoint_auth_method: :client_secret_jwt,
      pkce_required: true,
      subject_type: :public,
      active: true,
      provenance: :operator,
      lifetime_version: 0
    }

    {:ok, _persisted} = Repository.register_client(client)
    {:ok, stored} = Repository.fetch_client_by_id(client_id)
    {params, _jti, _issued_at} = Fixtures.assertion(stored, secret)

    result = ClientAuth.authenticate(params, nil, auth_options(context))

    assert result_kind(result) == {:error, :client_secret_verifier_unavailable}

    assert Fixtures.effects_snapshot(client_id) == %{
             used_jtis: 0,
             tokens: 0,
             grants: 0,
             audits: 0
           }
  end

  test "absent dedicated context keeps the existing legacy authentication path" do
    %{client: client, plaintext_secret: secret} = Fixtures.persisted_client()
    {result, _jti, _issued_at} = Fixtures.authenticate(client, secret)

    assert result_kind(result) == :ok

    assert Fixtures.effects_snapshot(client.client_id) == %{
             used_jtis: 1,
             tokens: 0,
             grants: 0,
             audits: 0
           }
  end

  defp context(key) do
    encoded_key = Base.url_encode64(key, padding: false)

    {:ok, context} =
      Context.resolve(
        {:present,
         [
           keys: [{"tracer-primary", encoded_key}],
           current: "tracer-primary",
           write_mode: :dedicated,
           legacy_read: :allow
         ]},
        []
      )

    {:ok, validated} = Context.validate(context)
    validated
  end

  defp auth_options(context) do
    [
      client_store: Repository,
      jti_store: Repository,
      server_policy_store: Repository,
      supported_jwt_auth_methods: [:client_secret_jwt],
      client_secret_verifier_context: context
    ]
  end

  defp result_kind({:ok, %Client{}}), do: :ok
  defp result_kind({:error, %{reason_code: reason}}), do: {:error, reason}
  defp result_kind(_other), do: :unexpected

  defp unique_id,
    do: "phase176-" <> Base.url_encode64(:crypto.strong_rand_bytes(18), padding: false)
end
