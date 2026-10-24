# Test a host-owned client lifetime adapter

This bounded ExUnit example uses the public `ClientStore` and `TransactionStore`
behaviors with a host Ecto repo configured as Lockspire's `repo`. The selected
client and transaction modules must name the same PostgreSQL authority. Run the
test against a disposable PostgreSQL database using the same schema prefix as
the host application.

Copy the module into your host's `test/` directory, then run it with the host's
normal `mix test` command. It exercises registration, fetch, transaction-scoped
current-row locking, the inactive-client guard, replacement rollback, issuance
rollback across grant/token/audit rows, independent PostgreSQL observation and
unsupported lifetime-state failure using ExUnit, Ecto and documented Lockspire
seams.

```elixir
defmodule HostLifetimeAdapterTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Storage.Ecto.Repository

  @client_store Application.compile_env(:lockspire, :client_store)
  @transaction_store Application.compile_env(:lockspire, :transaction_store)

  test "the configured stores round-trip a client under one PostgreSQL authority" do
    suffix = suffix()
    client = client("host-lifetime-#{suffix}")

    assert %{version: 1, transaction_authority: authority} = @client_store.lifetime_contract()
    assert authority == @transaction_store.transaction_authority()
    assert authority.participants.client_store == @client_store
    assert authority.participants.transaction_store == @transaction_store

    assert {:ok, registered} = @client_store.register_client(client)
    assert {:ok, fetched} = @client_store.fetch_client_by_id(client.client_id)
    assert fetched.client_id == registered.client_id

    assert {:ok, [current]} =
             @transaction_store.transact(fn -> @client_store.lock_clients([client.client_id]) end)

    assert current.client_id == client.client_id
    assert {:ok, _disabled} = @client_store.update_client(current, %{active: false})

    assert {:error, :invalid_token} =
             @client_store.replace_client_registration(
               current,
               %{current | name: "Stale update"},
               "unused-registration-token-hash",
               %{action: "registration_updated", actor_type: "host"}
             )
  end

  test "a late replacement audit failure restores credentials for an independent observer" do
    suffix = suffix()
    client = client("host-lifetime-replace-#{suffix}")
    assert {:ok, registered} = @client_store.register_client(client)
    before = client_row(client.client_id)
    before_audits = audit_count(client.client_id)

    with_audit_failure(fn ->
      assert {:error, _reason} =
               @transaction_store.transact(fn ->
                 primary_pid = backend_pid(CleanRoomProvider.Repo)

                 result =
                   @client_store.replace_client_registration(
                     registered,
                     %{registered | name: "After #{suffix}"},
                     "replacement-hash-#{suffix}",
                     %{action: "registration_updated", actor_type: "host"}
                   )

                 send(self(), {:replacement_primary_pid, primary_pid})
                 result
               end)
    end)

    assert_receive {:replacement_primary_pid, primary_pid}
    with_observer(fn observer ->
      assert backend_pid(observer) != primary_pid
      assert client_row(client.client_id, observer) == before
      assert audit_count(client.client_id, observer) == before_audits
    end)

    IO.puts("LIFETIME_EXAMPLE_ROLLBACK client distinct_observer")
  end

  test "a late issuance audit failure restores grant, token and audit rows independently" do
    suffix = suffix()
    client = client("host-lifetime-issue-#{suffix}")
    assert {:ok, _registered} = @client_store.register_client(client)
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    code_hash = hash("code-#{suffix}")
    access_hash = hash("access-#{suffix}")

    assert {:ok, _code} =
             Repository.store_token(%Token{
               token_hash: code_hash,
               token_type: :authorization_code,
               client_id: client.client_id,
               account_id: "host-subject",
               interaction_id: "host-interaction-#{suffix}",
               issued_at: now,
               expires_at: DateTime.add(now, 300, :second)
             })

    before_code = token_row(code_hash)
    before_access = token_row(access_hash)
    before_audits = audit_count(client.client_id)

    with_audit_failure(fn ->
      assert {:error, _reason} =
               @transaction_store.transact(fn ->
                 primary_pid = backend_pid(CleanRoomProvider.Repo)

                 result =
                   with {:ok, _redeemed} <-
                          Repository.mark_authorization_code_redeemed(code_hash, now),
                        {:ok, _stored} <-
                          Repository.store_token(%Token{
                            token_hash: access_hash,
                            token_type: :access_token,
                            client_id: client.client_id,
                            account_id: "host-subject",
                            interaction_id: "host-interaction-#{suffix}",
                            issued_at: now,
                            expires_at: DateTime.add(now, 60, :second)
                          }),
                        {:ok, _audit} <-
                          Repository.append_audit_event(%{
                            action: "authorization_code_redeemed",
                            outcome: "success",
                            resource_type: "client",
                            resource_id: client.client_id
                          }) do
                     {:ok, :unexpected_success}
                   else
                     {:error, reason} -> {:error, reason}
                   end

                 send(self(), {:issuance_primary_pid, primary_pid})
                 result
               end)
    end)

    assert_receive {:issuance_primary_pid, primary_pid}
    with_observer(fn observer ->
      assert backend_pid(observer) != primary_pid
      assert token_row(code_hash, observer) == before_code
      assert token_row(access_hash, observer) == before_access
      assert audit_count(client.client_id, observer) == before_audits
    end)

    IO.puts("LIFETIME_EXAMPLE_ROLLBACK issuance distinct_observer")
  end

  test "unsupported lifetime state fails closed" do
    assert {:error, :invalid_lifetime_state} =
             Client.effective_app_deadline(%Client{lifetime_version: 7})

    IO.puts("LIFETIME_EXAMPLE_UNSUPPORTED rejected")
  end

  defp suffix, do: Base.url_encode64(:crypto.strong_rand_bytes(9), padding: false)

  defp client(client_id) do
    %Client{
      client_id: client_id,
      client_type: :confidential,
      name: "Host lifetime example",
      token_endpoint_auth_method: :client_secret_basic,
      client_secret_hash: "example-secret-hash-#{client_id}",
      registration_access_token_hash: "example-rat-hash-#{client_id}",
      lifetime_version: 0,
      provenance: :self_registered
    }
  end

  defp hash(value), do: :crypto.hash(:sha256, value) |> Base.url_encode64(padding: false)

  defp client_row(client_id, repo \\ CleanRoomProvider.Repo) do
    query_rows(
      repo,
      "SELECT client_id, client_secret_hash, client_secret_jwt_verifier_encrypted, registration_access_token_hash, lifetime_version, client_expires_at, client_secret_expires_at, registration_access_token_expires_at, name, redirect_uris, active FROM #{table("clients")} WHERE client_id = $1",
      [client_id]
    )
  end

  defp token_row(token_hash, repo \\ CleanRoomProvider.Repo) do
    query_rows(
      repo,
      "SELECT token_hash, token_type, client_id, redeemed_at, revoked_at FROM #{table("tokens")} WHERE token_hash = $1",
      [token_hash]
    )
  end

  defp audit_count(client_id, repo \\ CleanRoomProvider.Repo) do
    %{rows: [[count]]} =
      repo.query!("SELECT count(*) FROM #{table("audit_events")} WHERE resource_id = $1", [client_id])

    count
  end

  defp query_rows(repo, sql, params \\ []) do
    result = repo.query!(sql, params)
    Enum.map(result.rows, &Map.new(Enum.zip(result.columns, &1)))
  end

  defp backend_pid(repo) do
    %{rows: [[pid]]} = repo.query!("SELECT pg_backend_pid()")
    pid
  end

  defp table(name) do
    prefix = Application.get_env(:lockspire, :storage_prefix, "lockspire")
    table = ~s("lockspire_#{name}")

    normalized = if is_atom(prefix) and prefix not in [nil, false], do: Atom.to_string(prefix), else: prefix

    case normalized do
      value when value in [nil, false] -> table
      normalized ->
        quoted_prefix = String.replace(normalized, "\"", "\"\"")
        ~s("#{quoted_prefix}".#{table})
    end
  end

  defp with_observer(fun) do
    {:ok, observer_pid} =
      CleanRoomProvider.Repo.start_link(
        name: nil,
        url: System.fetch_env!("DATABASE_URL"),
        pool_size: 1
      )

    CleanRoomProvider.Repo.put_dynamic_repo(observer_pid)

    try do
      fun.(CleanRoomProvider.Repo)
    after
      CleanRoomProvider.Repo.put_dynamic_repo(CleanRoomProvider.Repo)
      GenServer.stop(observer_pid)
    end
  end

  defp with_audit_failure(fun) do
    CleanRoomProvider.Repo.query!("""
    CREATE OR REPLACE FUNCTION lockspire_example_reject_audit() RETURNS trigger AS $$
    BEGIN
      RAISE EXCEPTION 'packaged lifetime example audit failure';
    END;
    $$ LANGUAGE plpgsql
    """)

    CleanRoomProvider.Repo.query!("""
    CREATE TRIGGER lockspire_example_audit_failure
    BEFORE INSERT ON #{table("audit_events")}
    FOR EACH ROW EXECUTE FUNCTION lockspire_example_reject_audit()
    """)

    try do
      fun.()
    after
      CleanRoomProvider.Repo.query!("DROP TRIGGER IF EXISTS lockspire_example_audit_failure ON #{table("audit_events")}")
      CleanRoomProvider.Repo.query!("DROP FUNCTION IF EXISTS lockspire_example_reject_audit()")
    end
  end
end
```
