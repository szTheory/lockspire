defmodule Lockspire.Integration.ClientSecretVerifierRotationTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  @moduletag :integration

  alias Lockspire.Admin.Clients
  alias Lockspire.Clients, as: ClientRegistration
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.AuditEventRecord
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
    cache_key = Lockspire.Config.client_secret_verifier_cache_key()
    previous_context = :persistent_term.get(cache_key, :missing)
    context = verifier_context(:crypto.strong_rand_bytes(32))
    :persistent_term.put(cache_key, context)

    on_exit(fn ->
      if previous_context == :missing,
        do: :persistent_term.erase(cache_key),
        else: :persistent_term.put(cache_key, previous_context)
    end)

    %{context: context, cache_key: cache_key}
  end

  test "Basic, post, and JWT rotation keeps the client identity and returns one coherent replacement",
       %{
         context: context
       } do
    for method <- [:client_secret_basic, :client_secret_post, :client_secret_jwt] do
      attrs = client_attrs(method)
      assert {:ok, registered} = ClientRegistration.register_client(attrs)
      client_id = registered.client.client_id
      old_secret = registered.client_secret
      assert {:ok, before} = Repository.fetch_client_by_id(client_id)
      before_audits = audit_count(client_id)

      now = ~U[2030-01-02 03:04:05Z]

      assert {:ok, %{client: %Client{} = rotated, client_secret: new_secret}} =
               Clients.rotate_client_secret(client_id,
                 now: now,
                 actor: %{type: :operator, id: "verifier-rotation-test"}
               )

      assert is_binary(new_secret) and new_secret != old_secret
      assert rotated.client_id == before.client_id
      assert rotated.token_endpoint_auth_method == method
      assert rotated.client_secret_hash != before.client_secret_hash
      assert rotated.last_secret_rotated_at == now
      assert preserved_fields(rotated) == preserved_fields(before)
      assert Policy.verify_client_secret(rotated.client_secret_hash, new_secret)
      assert {:ok, stored} = Repository.fetch_client_by_id(client_id)
      assert stored == rotated

      assert {:ok, opened} =
               ClientSecretVerifier.open(
                 context,
                 client_id,
                 stored.client_secret_jwt_verifier_encrypted,
                 []
               )

      assert opened == new_secret
      assert audit_count(client_id) == before_audits + 1
      authenticate_old_and_new(method, before, old_secret, rotated, new_secret, context)
    end
  end

  test "invalid verifier custody fails before replacing or disclosing client credentials", %{
    cache_key: cache_key
  } do
    assert {:ok, registered} =
             ClientRegistration.register_client(client_attrs(:client_secret_basic))

    client_id = registered.client.client_id
    assert {:ok, before} = Repository.fetch_client_by_id(client_id)
    before_audits = audit_count(client_id)
    :persistent_term.put(cache_key, %Context{state: :invalid, reason: :invalid_options})

    result = Clients.rotate_client_secret(client_id)

    assert result == {:error, :client_secret_verifier_configuration_invalid}
    assert {:ok, after_attempt} = Repository.fetch_client_by_id(client_id)
    assert after_attempt.client_secret_hash == before.client_secret_hash

    assert after_attempt.client_secret_jwt_verifier_encrypted ==
             before.client_secret_jwt_verifier_encrypted

    assert audit_count(client_id) == before_audits
    refute match?({:ok, %{client_secret: _secret}}, result)
  end

  test "audit failure rolls back both replacement fields and returns no plaintext" do
    assert {:ok, registered} =
             ClientRegistration.register_client(client_attrs(:client_secret_basic))

    client_id = registered.client.client_id
    assert {:ok, before} = Repository.fetch_client_by_id(client_id)
    before_audits = audit_count(client_id)

    with_audit_failure(fn ->
      result = Clients.rotate_client_secret(client_id)
      assert {:error, _reason} = result
      refute match?({:ok, %{client_secret: _secret}}, result)
      assert {:ok, after_attempt} = Repository.fetch_client_by_id(client_id)
      assert after_attempt.client_secret_hash == before.client_secret_hash

      assert after_attempt.client_secret_jwt_verifier_encrypted ==
               before.client_secret_jwt_verifier_encrypted

      assert audit_count(client_id) == before_audits
    end)
  end

  defp authenticate_old_and_new(:client_secret_basic, _before, old, rotated, new, _context) do
    assert match?({:error, _}, basic_auth(rotated.client_id, old))
    assert match?({:ok, _}, basic_auth(rotated.client_id, new))
  end

  defp authenticate_old_and_new(:client_secret_post, _before, old, rotated, new, _context) do
    assert match?({:error, _}, post_auth(rotated.client_id, old))
    assert match?({:ok, _}, post_auth(rotated.client_id, new))
  end

  defp authenticate_old_and_new(:client_secret_jwt, before, old, rotated, new, context) do
    assert match?({:error, _}, jwt_auth(before, old, context))
    assert match?({:ok, _}, jwt_auth(rotated, new, context))
  end

  defp basic_auth(client_id, secret) do
    ClientAuth.authenticate(%{}, "Basic " <> Base.encode64("#{client_id}:#{secret}"),
      client_store: Repository
    )
  end

  defp post_auth(client_id, secret) do
    ClientAuth.authenticate(%{"client_id" => client_id, "client_secret" => secret}, nil,
      client_store: Repository
    )
  end

  defp jwt_auth(client, secret, context) do
    {params, _jti, _issued_at} = Fixtures.assertion(client, secret)

    ClientAuth.authenticate(params, nil,
      client_store: Repository,
      jti_store: Repository,
      server_policy_store: Repository,
      supported_jwt_auth_methods: [:client_secret_jwt],
      client_secret_verifier_context: context
    )
  end

  defp client_attrs(method) do
    %{
      client_id: unique_id(),
      name: "Verifier rotation #{method}",
      client_type: :confidential,
      redirect_uris: ["https://app.example.test/callback"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: method,
      token_endpoint_auth_signing_alg: if(method == :client_secret_jwt, do: :HS256)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp preserved_fields(%Client{} = client) do
    client
    |> Map.from_struct()
    |> Map.drop([
      :client_secret_hash,
      :client_secret_jwt_verifier_encrypted,
      :last_secret_rotated_at,
      :client_secret_expires_at,
      :updated_at
    ])
  end

  defp audit_count(client_id) do
    Lockspire.TestRepo.aggregate(
      from(event in AuditEventRecord, where: event.resource_id == ^client_id),
      :count
    )
  end

  defp with_audit_failure(fun) do
    Lockspire.TestRepo.query!(
      "DROP TRIGGER IF EXISTS lsp_17605_rotation_audit_failure ON lockspire_audit_events"
    )

    Lockspire.TestRepo.query!("""
    CREATE OR REPLACE FUNCTION lsp_17605_reject_rotation_audit() RETURNS trigger AS $$
    BEGIN
      IF NEW.action = 'client_secret_rotated' THEN
        RAISE EXCEPTION '176-05 injected rotation audit failure';
      END IF;
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql
    """)

    Lockspire.TestRepo.query!("""
    CREATE TRIGGER lsp_17605_rotation_audit_failure
    BEFORE INSERT ON lockspire_audit_events
    FOR EACH ROW EXECUTE FUNCTION lsp_17605_reject_rotation_audit()
    """)

    try do
      fun.()
    after
      Lockspire.TestRepo.query!(
        "DROP TRIGGER IF EXISTS lsp_17605_rotation_audit_failure ON lockspire_audit_events"
      )

      Lockspire.TestRepo.query!("DROP FUNCTION IF EXISTS lsp_17605_reject_rotation_audit()")
    end
  end

  defp verifier_context(key) do
    {:ok, context} =
      Context.resolve(
        {:present,
         [
           keys: [{"rotation-writer", Base.url_encode64(key, padding: false)}],
           current: "rotation-writer",
           write_mode: :dedicated,
           legacy_read: :allow
         ]},
        []
      )

    {:ok, validated} = Context.validate(context)
    validated
  end

  defp unique_id,
    do: "rotation-" <> Base.url_encode64(:crypto.strong_rand_bytes(18), padding: false)
end
