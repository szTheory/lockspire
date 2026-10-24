defmodule Lockspire.Integration.AppLifetimeRfc8693Test do
  use Lockspire.TokenExchangeCase, async: false

  import Ecto.Query

  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.ClientRecord

  @moduletag :integration

  defmodule Validator do
    def validate(context) do
      send(Process.get({__MODULE__, :owner}), {:validated, context})
      Process.get({__MODULE__, :result}, :ok)
    end
  end

  test "expired subject and actor issuers reject before host validation or writes" do
    now = DateTime.utc_now() |> DateTime.add(30, :second) |> DateTime.truncate(:second)
    requester = public_client("rfc-requester", now, nil)
    subject_issuer = public_client("rfc-subject-issuer", now, DateTime.add(now, -1, :second))
    actor_issuer = public_client("rfc-actor-issuer", now, nil)
    {subject, subject_raw} = seed_access_token(subject_issuer, "rfc-subject-token", now)
    {actor, actor_raw} = seed_access_token(actor_issuer, "rfc-actor-token", now)
    before_tokens = Lockspire.TestRepo.aggregate(TokenRecord, :count)
    before_audits = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)
    Process.put({Validator, :owner}, self())

    assert {:error, error} = exchange(requester, subject, subject_raw, actor, actor_raw, now)
    assert error.error == "invalid_grant"
    refute_receive {:validated, _}, 0
    assert Lockspire.TestRepo.aggregate(TokenRecord, :count) == before_tokens
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == before_audits
  end

  test "requester deadline caps opaque durable output and response at final time" do
    now = DateTime.utc_now() |> DateTime.add(30, :second) |> DateTime.truncate(:second)
    deadline = DateTime.add(now, 1, :second)
    requester = public_client("rfc-requester-cap", now, deadline)
    issuer = public_client("rfc-issuer-cap", now, nil)
    {subject, subject_raw} = seed_access_token(issuer, "rfc-subject-cap", now)
    Process.put({Validator, :owner}, self())

    assert {:ok, success} = exchange(requester, subject, subject_raw, nil, nil, now)
    assert success.expires_in == 1
    refute String.contains?(success.access_token, ".")
    assert_receive {:validated, context}
    assert context.subject_token.token_hash == subject.token_hash
    assert context.actor_token_identity == nil

    assert {:ok, persisted} =
             Repository.fetch_lifecycle_token(Policy.hash_token(success.access_token))

    assert DateTime.compare(persisted.expires_at, deadline) == :eq
    assert DateTime.compare(persisted.issued_at, now) == :eq
  end

  test "signed exchange uses the same final app deadline in JWT, row and response" do
    now = DateTime.utc_now() |> DateTime.add(30, :second) |> DateTime.truncate(:second)
    deadline = DateTime.add(now, 1, :second)
    requester = public_client("rfc-requester-signed", now, deadline)
    issuer = public_client("rfc-issuer-signed", now, nil)
    actor_issuer = public_client("rfc-actor-signed", now, nil)
    {subject, subject_raw} = seed_access_token(issuer, "rfc-subject-signed", now)
    {actor, actor_raw} = seed_access_token(actor_issuer, "rfc-actor-signed-token", now)
    publish_signing_key("kid-rfc8693-signed")
    Process.put({Validator, :owner}, self())
    Process.put({Validator, :result}, {:ok, %{claims: %{"role" => "reader"}}})

    assert {:ok, success} = exchange(requester, subject, subject_raw, actor, actor_raw, now)
    assert success.expires_in == 1
    assert [_, payload, _] = String.split(success.access_token, ".")
    claims = payload |> Base.url_decode64!(padding: false) |> Jason.decode!()
    assert claims["exp"] == DateTime.to_unix(deadline)
    assert claims["role"] == "reader"
    assert_receive {:validated, context}
    assert context.subject_token.token_hash == subject.token_hash
    assert context.actor_token_identity.token_hash == actor.token_hash
    assert context.actor_token["client_id"] == actor_issuer.client_id

    assert {:ok, persisted} =
             Repository.fetch_lifecycle_token(Policy.hash_token(success.access_token))

    assert DateTime.compare(persisted.expires_at, deadline) == :eq
    assert DateTime.to_unix(persisted.expires_at) == claims["exp"]
  end

  test "final equality rejects without writing an output token or audit" do
    now = DateTime.utc_now() |> DateTime.add(30, :second) |> DateTime.truncate(:second)
    deadline = DateTime.add(now, 1, :second)
    requester = public_client("rfc-requester-equality", now, deadline)
    issuer = public_client("rfc-issuer-equality", now, nil)
    {subject, subject_raw} = seed_access_token(issuer, "rfc-subject-equality", now)
    before_tokens = Lockspire.TestRepo.aggregate(TokenRecord, :count)
    before_audits = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)
    Process.put({Validator, :owner}, self())

    assert {:error, error} =
             exchange(
               requester,
               subject,
               subject_raw,
               nil,
               nil,
               sequence_clock([now, now, now, deadline])
             )

    assert error.error == "invalid_client"
    assert Lockspire.TestRepo.aggregate(TokenRecord, :count) == before_tokens
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == before_audits
  end

  test "subject and actor durable identities reach host validation and actor expiry gates independently" do
    now = DateTime.utc_now() |> DateTime.add(30, :second) |> DateTime.truncate(:second)
    requester = public_client("rfc-requester-actor", now, nil)
    subject_issuer = public_client("rfc-subject-actor", now, nil)
    actor_issuer = public_client("rfc-actor-actor", now, DateTime.add(now, -1, :second))
    {subject, subject_raw} = seed_access_token(subject_issuer, "rfc-subject-actor-token", now)
    {actor, actor_raw} = seed_access_token(actor_issuer, "rfc-actor-actor-token", now)
    before_tokens = Lockspire.TestRepo.aggregate(TokenRecord, :count)
    Process.put({Validator, :owner}, self())

    assert {:error, error} = exchange(requester, subject, subject_raw, actor, actor_raw, now)
    assert error.error == "invalid_grant"
    refute_receive {:validated, _}, 0
    assert Lockspire.TestRepo.aggregate(TokenRecord, :count) == before_tokens
  end

  defp public_client(id, _now, deadline) do
    {:ok, client} =
      create_client(id, :none, "unused", ["urn:ietf:params:oauth:grant-type:token-exchange"], %{
        client_type: :public,
        allowed_grant_types: ["urn:ietf:params:oauth:grant-type:token-exchange"],
        access_token_format: :opaque,
        allowed_scopes: ["read"]
      })

    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(record in ClientRecord, where: record.client_id == ^client.client_id),
               set: [lifetime_version: 1, client_expires_at: deadline]
             )

    {:ok, current} = Repository.fetch_client_by_id(client.client_id)
    current
  end

  defp seed_access_token(client, raw, now) do
    {:ok, token} =
      Repository.store_token(%Token{
        token_hash: Policy.hash_token(raw),
        token_type: :access_token,
        family_id: "family-#{raw}",
        generation: 1,
        client_id: client.client_id,
        account_id: "account-#{client.client_id}",
        scopes: ["read"],
        audience: ["api.example.test"],
        issued_at: DateTime.add(now, -1, :second),
        expires_at: DateTime.add(now, 600, :second)
      })

    {token, raw}
  end

  defp exchange(requester, _subject, subject_raw, actor, actor_raw, now) do
    params = %{
      "grant_type" => "urn:ietf:params:oauth:grant-type:token-exchange",
      "subject_token" => subject_raw,
      "scope" => "read"
    }

    params = if actor, do: Map.put(params, "actor_token", actor_raw), else: params
    params = Map.put(params, "client_id", requester.client_id)

    TokenExchange.exchange(%{
      params: params,
      authorization: nil,
      opts: [
        client_store: Repository,
        client_lifetime: nil,
        token_store: Repository,
        transaction_store: Repository,
        audit_store: Repository,
        interaction_store: Repository,
        key_store: Repository,
        server_policy_store: Repository,
        token_exchange_validator: Validator,
        now: clock(now)
      ]
    })
  end

  defp clock(%DateTime{} = now), do: fn -> now end
  defp clock(fun) when is_function(fun, 0), do: fun

  defp sequence_clock(values) do
    counter = :atomics.new(1, [])
    count = length(values)

    fn ->
      index = :atomics.add_get(counter, 1, 1) - 1
      Enum.at(values, min(index, count - 1))
    end
  end
end
