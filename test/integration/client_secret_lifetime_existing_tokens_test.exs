defmodule Lockspire.Integration.ClientSecretLifetimeExistingTokensTest do
  use Lockspire.TokenExchangeCase, async: false

  import Ecto.Query

  alias Lockspire.Domain.Client
  alias Lockspire.Host.Claims
  alias Lockspire.Protocol.Introspection
  alias Lockspire.Protocol.TokenExchange
  alias Lockspire.Protocol.TokenExchange.Internal.ClientAuthentication
  alias Lockspire.Protocol.TokenExchange.Internal.GrantPersistence
  alias Lockspire.Protocol.Userinfo
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.ClientRecord

  @moduletag :integration

  defmodule Resolver do
    def resolve_account(id, _context), do: {:ok, %{id: id}}

    def build_claims(account, _context),
      do:
        {:ok, %Claims{subject: account.id, userinfo: %{"email" => "#{account.id}@example.test"}}}
  end

  setup do
    previous_resolver = Application.get_env(:lockspire, :account_resolver)
    Application.put_env(:lockspire, :account_resolver, Resolver)

    on_exit(fn ->
      if is_nil(previous_resolver),
        do: Application.delete_env(:lockspire, :account_resolver),
        else: Application.put_env(:lockspire, :account_resolver, previous_resolver)
    end)

    :ok
  end

  test "issued access token validity and online targets survive secret expiry and rotation" do
    now = future_now()
    secret = "existing-token-secret-#{Ecto.UUID.generate()}"
    client_id = "existing-token-client-#{Ecto.UUID.generate()}"
    app_deadline = DateTime.add(now, 10_000, :second)
    secret_deadline = DateTime.add(now, 1, :second)

    {:ok, client} =
      create_client(
        client_id,
        :client_secret_basic,
        secret,
        ["authorization_code", "refresh_token"],
        %{
          access_token_format: :jwt,
          allowed_scopes: ["email", "offline_access"],
          allowed_response_types: ["code"]
        }
      )

    kid = "kid-existing-#{client_id}"
    publish_signing_key(kid)
    set_lifetimes(client, to_usec(app_deadline), to_usec(secret_deadline))
    raw_code = "existing-token-code-#{Ecto.UUID.generate()}"
    verifier = "existing-token-verifier"

    {:ok, _code} =
      create_authorization_code(client,
        raw_code: raw_code,
        code_verifier: verifier,
        scopes: ["email", "offline_access"]
      )

    assert {:ok, issued} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => raw_code,
                 "code_verifier" => verifier,
                 "redirect_uri" => "https://client.example.com/callback"
               },
               authorization: basic_auth(client_id, secret),
               now: fn -> now end
             )

    assert {:ok, access_before} =
             Repository.fetch_lifecycle_token(Policy.hash_token(issued.access_token))

    assert {:ok, refresh_before} =
             Repository.fetch_refresh_token(Policy.hash_token(issued.refresh_token))

    {_header, claims_before} = verify_at_jwt(issued.access_token)
    assert claims_before["exp"] == DateTime.to_unix(access_before.expires_at)
    assert DateTime.compare(access_before.expires_at, secret_deadline) == :gt
    assert DateTime.compare(access_before.expires_at, app_deadline) == :lt
    assert is_binary(issued.access_token)

    assert {:ok, %{"sub" => subject, "email" => email}} =
             Userinfo.fetch_claims(%{
               authorization: "Bearer #{issued.access_token}",
               opts: online_options(fn -> secret_deadline end)
             })

    assert subject == "subject-123"
    assert email == "subject-123@example.test"

    assert {:ok, %{payload: %{active: true}}} =
             Introspection.introspect(%{
               params: %{"token" => issued.access_token},
               authorization: basic_auth(client_id, secret),
               opts:
                 online_options(sequence_clock([DateTime.add(now, -1, :second), secret_deadline])) ++
                   [token_store: Repository]
             })

    assert {:error, %{status: 401, error: "invalid_client"}} =
             refresh_exchange(client_id, secret, issued.refresh_token, secret_deadline)

    assert {:ok, refresh_after_rejection} =
             Repository.fetch_refresh_token(Policy.hash_token(issued.refresh_token))

    assert is_nil(refresh_after_rejection.redeemed_at)
    assert DateTime.compare(refresh_after_rejection.expires_at, refresh_before.expires_at) == :eq

    rotation_time = DateTime.add(secret_deadline, 1, :second)

    assert {:ok, %{client: rotated, client_secret: replacement_secret}} =
             Lockspire.Admin.Clients.rotate_client_secret(client_id, %{
               now: fn -> rotation_time end,
               actor: %{type: :operator, id: "existing-token-test"}
             })

    assert is_nil(rotated.client_secret_expires_at)

    assert {:ok, access_after_rotation} =
             Repository.fetch_lifecycle_token(Policy.hash_token(issued.access_token))

    assert access_after_rotation.expires_at == access_before.expires_at
    {_header, claims_after_rotation} = verify_at_jwt(issued.access_token)
    assert claims_after_rotation["exp"] == claims_before["exp"]

    assert {:ok, refreshed} =
             refresh_exchange(
               client_id,
               replacement_secret,
               issued.refresh_token,
               DateTime.add(rotation_time, 1, :second)
             )

    assert is_binary(refreshed.access_token)
    assert is_binary(refreshed.refresh_token)
  end

  test "non-secret final issuance authority ignores dormant expired secret material" do
    now = future_now()

    for method <- [
          :none,
          :private_key_jwt,
          :tls_client_auth,
          :self_signed_tls_client_auth
        ] do
      client = %Client{
        active: true,
        lifetime_version: 1,
        client_id: "non-secret-#{method}-#{Ecto.UUID.generate()}",
        client_type: if(method == :none, do: :public, else: :confidential),
        token_endpoint_auth_method: method,
        client_secret_hash: "dormant-secret-hash",
        client_secret_expires_at: DateTime.add(now, -1, :second),
        client_expires_at: DateTime.add(now, 60, :second),
        jwks: if(method in [:private_key_jwt, :self_signed_tls_client_auth], do: %{"keys" => []}),
        tls_client_auth_subject_dn:
          if(method in [:tls_client_auth, :self_signed_tls_client_auth],
            do: "CN=client.example.test"
          )
      }

      context = %{
        verified_client_identity: ClientAuthentication.verified_identity(client)
      }

      assert :ok =
               GrantPersistence.validate_current_authority(
                 client,
                 context,
                 now,
                 :guarded_token_redemption
               )
    end
  end

  defp refresh_exchange(client_id, secret, refresh_token, now) do
    TokenExchange.exchange(%{
      params: %{"grant_type" => "refresh_token", "refresh_token" => refresh_token},
      authorization: basic_auth(client_id, secret),
      opts: exchange_options(fn -> now end)
    })
  end

  defp exchange_options(clock) do
    [
      client_store: Repository,
      token_store: Repository,
      transaction_store: Repository,
      audit_store: Repository,
      interaction_store: Repository,
      key_store: Repository,
      server_policy_store: Repository,
      now: clock
    ]
  end

  defp online_options(clock) do
    [
      client_store: Repository,
      transaction_store: Repository,
      token_store: Repository,
      server_policy_store: Repository,
      now: clock
    ]
  end

  defp set_lifetimes(client, app_deadline, secret_deadline) do
    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(record in ClientRecord, where: record.client_id == ^client.client_id),
               set: [
                 lifetime_version: 1,
                 client_expires_at: app_deadline,
                 client_secret_expires_at: secret_deadline
               ]
             )
  end

  defp sequence_clock(values) do
    counter = :atomics.new(1, [])
    count = length(values)
    fn -> Enum.at(values, min(:atomics.add_get(counter, 1, 1) - 1, count - 1)) end
  end

  defp future_now, do: DateTime.add(DateTime.utc_now(), 30, :second) |> DateTime.truncate(:second)

  defp to_usec(datetime),
    do: DateTime.from_unix!(DateTime.to_unix(datetime) * 1_000_000, :microsecond)
end
