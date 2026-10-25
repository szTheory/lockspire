defmodule Lockspire.Integration.ClientSecretVerifierDcrWriterTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Protocol.Registration
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Test.Fixtures.DcrFixtures
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

  test "basic, post, and JWT DCR clients persist coherent final-ID pairs and hand plaintext off once",
       %{
         context: context
       } do
    for method <- ["client_secret_basic", "client_secret_post", "client_secret_jwt"] do
      policy =
        DcrFixtures.client_secret_jwt_server_policy(%{
          dcr_default_client_lifetime_seconds: nil,
          dcr_default_client_secret_lifetime_seconds: nil
        })

      request =
        DcrFixtures.register_request(
          server_policy: policy,
          metadata:
            %{
              "client_name" => "DCR verifier #{method}",
              "redirect_uris" => ["https://app.example.test/callback"],
              "token_endpoint_auth_method" => method,
              "token_endpoint_auth_signing_alg" => if(method == "client_secret_jwt", do: "HS256")
            }
            |> Enum.reject(fn {_key, value} -> is_nil(value) end)
            |> Map.new()
        )

      assert {:ok, %Registration.Success{} = success} = Registration.register(request)
      assert is_binary(success.client_secret_plaintext)
      assert byte_size(success.client_secret_plaintext) == 43

      assert {:ok, stored} = Repository.fetch_client_by_id(success.client.client_id)
      assert stored.client_id == success.client.client_id
      assert stored.client_secret_hash == success.client.client_secret_hash

      assert Policy.verify_client_secret(
               stored.client_secret_hash,
               success.client_secret_plaintext
             )

      assert is_nil(Map.get(Map.from_struct(stored), :client_secret))

      assert {:ok, opened} =
               ClientSecretVerifier.open(
                 context,
                 stored.client_id,
                 stored.client_secret_jwt_verifier_encrypted,
                 []
               )

      assert opened == success.client_secret_plaintext

      if method == "client_secret_jwt" do
        {params, _jti, _issued_at} = Fixtures.assertion(stored, success.client_secret_plaintext)

        assert {:ok, _authenticated} =
                 ClientAuth.authenticate(params, nil,
                   client_store: Repository,
                   jti_store: Repository,
                   server_policy_store: Repository,
                   supported_jwt_auth_methods: [:client_secret_jwt],
                   client_secret_verifier_context: context
                 )
      end
    end
  end

  test "nil, zero, and positive configured secret lifetimes retain their exact DCR deadlines" do
    for {duration, issued_at, expected_deadline} <- [
          {nil, DateTime.from_unix!(100), nil},
          {0, DateTime.from_unix!(200), nil},
          {10, DateTime.from_unix!(300), DateTime.from_unix!(310)}
        ] do
      policy =
        DcrFixtures.server_policy(%{
          dcr_default_client_lifetime_seconds: nil,
          dcr_default_client_secret_lifetime_seconds: duration
        })

      request =
        DcrFixtures.register_request(server_policy: policy)
        |> Map.put(:now, issued_at)

      assert {:ok, %Registration.Success{} = success} = Registration.register(request)
      assert {:ok, stored} = Repository.fetch_client_by_id(success.client.client_id)

      case expected_deadline do
        nil ->
          assert is_nil(stored.client_secret_expires_at)

        %DateTime{} = deadline ->
          assert DateTime.compare(stored.client_secret_expires_at, deadline) == :eq
      end
    end
  end

  test "invalid verifier custody returns a bounded server error before client or success audit persistence",
       %{
         cache_key: cache_key
       } do
    :persistent_term.put(cache_key, %Context{state: :invalid, reason: :invalid_options})
    policy = DcrFixtures.server_policy(%{dcr_default_client_lifetime_seconds: nil})
    before_audits = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    before_clients =
      Lockspire.TestRepo.aggregate(Lockspire.Storage.Ecto.ClientRecord, :count)

    assert {:error, %Registration.Error{code: :server_error, reason: reason} = error} =
             Registration.register(DcrFixtures.register_request(server_policy: policy))

    assert reason == :client_secret_verifier_configuration_invalid
    refute Map.has_key?(Map.from_struct(error), :client_secret)
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == before_audits

    assert Lockspire.TestRepo.aggregate(Lockspire.Storage.Ecto.ClientRecord, :count) ==
             before_clients
  end

  defp verifier_context(key) do
    {:ok, context} =
      Context.resolve(
        {:present,
         [
           keys: [{"dcr-writer", Base.url_encode64(key, padding: false)}],
           current: "dcr-writer",
           write_mode: :dedicated,
           legacy_read: :allow
         ]},
        []
      )

    {:ok, validated} = Context.validate(context)
    validated
  end
end
