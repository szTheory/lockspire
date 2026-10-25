defmodule Lockspire.Integration.ClientSecretVerifierDirectWriterTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Clients
  alias Lockspire.Clients.RegistrationResult
  alias Lockspire.Config
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Security.Policy
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
    cache_key = Config.client_secret_verifier_cache_key()
    cached_context = :persistent_term.get(cache_key, :missing)
    context = verifier_context(:crypto.strong_rand_bytes(32))
    :persistent_term.put(cache_key, context)

    on_exit(fn ->
      if cached_context == :missing do
        :persistent_term.erase(cache_key)
      else
        :persistent_term.put(cache_key, cached_context)
      end
    end)

    %{context: context, cache_key: cache_key}
  end

  test "direct Basic, post, and JWT registrations persist coherent final-ID pairs", %{
    context: context
  } do
    cases = [
      {:client_secret_basic, "custom-é-client"},
      {:client_secret_post, nil},
      {:client_secret_jwt, nil}
    ]

    for {auth_method, supplied_id} <- cases do
      attrs = registration_attrs(auth_method, supplied_id)

      result = register_capturing_errors(attrs)
      assert match?({:ok, %RegistrationResult{}}, result)
      {:ok, %RegistrationResult{client: client, client_secret: plaintext}} = result

      assert is_binary(plaintext) and byte_size(plaintext) == 43

      if is_nil(supplied_id) do
        assert String.starts_with?(client.client_id, "ls_")
        assert byte_size(client.client_id) == 35
      else
        assert client.client_id == supplied_id
      end

      assert {:ok, stored} = Repository.fetch_client_by_id(client.client_id)
      assert stored.client_secret_hash == client.client_secret_hash
      assert Policy.verify_client_secret(stored.client_secret_hash, plaintext)
      assert is_binary(stored.client_secret_jwt_verifier_encrypted)
      assert Map.has_key?(Map.from_struct(stored), :client_secret) == false

      opened =
        ClientSecretVerifier.open(
          context,
          client.client_id,
          stored.client_secret_jwt_verifier_encrypted,
          []
        )

      assert match?({:ok, _secret}, opened)
      assert elem(opened, 1) == plaintext
      assert String.starts_with?(stored.client_secret_jwt_verifier_encrypted, "LSCV1.")

      authenticate_existing_method(auth_method, stored, plaintext, context)
    end
  end

  test "missing or invalid dedicated custody returns a typed error before persistence", %{
    cache_key: cache_key
  } do
    :persistent_term.put(cache_key, %Context{state: :invalid, reason: :invalid_options})
    client_id = unique_id("invalid-context")

    result = register_capturing_errors(registration_attrs(:client_secret_basic, client_id))

    assert match?(
             {:error,
              [
                %{
                  field: :client_secret_jwt_verifier_encrypted,
                  reason: :missing_cryptographic_material,
                  detail: :client_secret_verifier_configuration_invalid
                }
              ]},
             result
           )

    assert {:ok, nil} = Repository.fetch_client_by_id(client_id)
  end

  test "duplicate direct registration does not replace existing hash or verifier", %{
    context: context
  } do
    client_id = unique_id("duplicate")

    first_result = register_capturing_errors(registration_attrs(:client_secret_basic, client_id))
    assert match?({:ok, %RegistrationResult{}}, first_result)
    {:ok, %RegistrationResult{client: first, client_secret: first_secret}} = first_result

    assert {:ok, original} = Repository.fetch_client_by_id(client_id)

    second_result =
      register_capturing_errors(registration_attrs(:client_secret_basic, client_id))

    assert match?({:error, [_error | _]}, second_result)
    assert {:ok, stored} = Repository.fetch_client_by_id(client_id)
    assert stored.client_secret_hash == original.client_secret_hash

    assert stored.client_secret_jwt_verifier_encrypted ==
             original.client_secret_jwt_verifier_encrypted

    assert Policy.verify_client_secret(stored.client_secret_hash, first_secret)

    opened =
      ClientSecretVerifier.open(
        context,
        first.client_id,
        stored.client_secret_jwt_verifier_encrypted,
        []
      )

    assert match?({:ok, _secret}, opened)
    assert elem(opened, 1) == first_secret
  end

  defp authenticate_existing_method(:client_secret_basic, client, secret, _context) do
    authorization = "Basic " <> Base.encode64("#{client.client_id}:#{secret}")
    result = ClientAuth.authenticate(%{}, authorization, client_store: Repository)
    assert match?({:ok, _client}, result)
  end

  defp authenticate_existing_method(:client_secret_post, client, secret, _context) do
    result =
      ClientAuth.authenticate(
        %{"client_id" => client.client_id, "client_secret" => secret},
        nil,
        client_store: Repository
      )

    assert match?({:ok, _client}, result)
  end

  defp authenticate_existing_method(:client_secret_jwt, client, secret, context) do
    {params, _jti, _issued_at} = Fixtures.assertion(client, secret)

    result =
      ClientAuth.authenticate(params, nil,
        client_store: Repository,
        jti_store: Repository,
        server_policy_store: Repository,
        supported_jwt_auth_methods: [:client_secret_jwt],
        client_secret_verifier_context: context
      )

    assert match?({:ok, _client}, result)
  end

  defp registration_attrs(auth_method, client_id) do
    %{
      client_id: client_id,
      name: "Direct #{auth_method} verifier",
      client_type: :confidential,
      redirect_uris: ["https://app.example.test/callback"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      token_endpoint_auth_method: auth_method,
      token_endpoint_auth_signing_alg: if(auth_method == :client_secret_jwt, do: :HS256)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp register_capturing_errors(attrs) do
    try do
      Clients.register_client(attrs)
    rescue
      _error -> :raised
    end
  end

  defp verifier_context(key) do
    {:ok, context} =
      Context.resolve(
        {:present,
         [
           keys: [{"direct-writer", Base.url_encode64(key, padding: false)}],
           current: "direct-writer",
           write_mode: :dedicated,
           legacy_read: :allow
         ]},
        []
      )

    {:ok, validated} = Context.validate(context)
    validated
  end

  defp unique_id(prefix),
    do: "#{prefix}-" <> Base.url_encode64(:crypto.strong_rand_bytes(18), padding: false)
end
