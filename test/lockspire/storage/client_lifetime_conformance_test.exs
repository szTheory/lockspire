defmodule Lockspire.Storage.ClientLifetimeConformanceTest do
  use Lockspire.TokenExchangeCase

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenExchange.Internal.Dependencies
  alias Lockspire.Protocol.TokenExchange.Internal.LegacyOptions
  alias Lockspire.Storage.ClientLifetime
  alias Lockspire.Protocol.TokenFormatter

  @moduletag :integration

  test "built-in adapter declares the versioned lifetime contract and shared authority" do
    contract = Repository.lifetime_contract()

    assert contract.version == 1
    assert contract.transaction_authority == Repository.transaction_authority()
    assert {:ok, lifetime} = ClientLifetime.adapt(Repository, contract.transaction_authority)
    assert lifetime.contract_version == 1
    assert lifetime.client_store == Repository
    assert lifetime.transaction_authority == contract.transaction_authority
  end

  test "reusable conformance verifies built-in finite, unlimited and explicit v0 round trips" do
    finite = DateTime.from_unix!(1_800_000_000) |> DateTime.truncate(:second)

    assert_conforms!(Repository, [
      client("lifetime-v1-finite", 1, finite, nil),
      client("lifetime-v1-unlimited", 1, nil, nil),
      client("lifetime-v0-legacy", 0, nil, nil)
    ])
  end

  test "the same conformance function exercises an explicit custom adapter" do
    finite = DateTime.from_unix!(1_800_000_000) |> DateTime.truncate(:second)

    assert_conforms!(__MODULE__.CustomClientStore, [
      client("custom-v1-finite", 1, finite, nil),
      client("custom-v1-unlimited", 1, nil, nil),
      client("custom-v0-legacy", 0, nil, nil)
    ])
  end

  test "missing, unknown, state-dropping and unguarded adapters fail conformance" do
    authority = Repository.transaction_authority()

    assert {:error, _} = ClientLifetime.adapt(__MODULE__.MissingDeclaration, authority)
    assert {:error, _} = ClientLifetime.adapt(__MODULE__.UnknownDeclaration, authority)
    assert {:error, _} = ClientLifetime.adapt(__MODULE__.MissingGuard, authority)

    finite = DateTime.from_unix!(1_800_000_000) |> DateTime.truncate(:second)
    client = client("custom-drop-fields", 1, finite, finite)
    refute conforms?(__MODULE__.DroppedVersion, [client])
    refute conforms?(__MODULE__.DroppedDeadline, [client])

    for adapter <- [__MODULE__.DroppedVersion, __MODULE__.DroppedDeadline] do
      assert Process.get({adapter, :registered, client.client_id}) == true
      assert Process.get({adapter, :fetched, client.client_id}) == true
    end

    assert {:ok, %Client{lifetime_version: nil}} =
             __MODULE__.DroppedVersion.fetch_client_by_id(client.client_id)

    assert {:ok,
            %Client{
              lifetime_version: 1,
              client_expires_at: nil,
              registration_access_token_expires_at: nil
            }} = __MODULE__.DroppedDeadline.fetch_client_by_id(client.client_id)

    assert {:error, :invalid_lifetime_version} =
             ClientLifetime.validate_client(%Client{client_id: "missing-version"})

    assert {:error, :invalid_lifetime_version} =
             ClientLifetime.validate_client(%Client{
               client_id: "unknown-version",
               lifetime_version: 2
             })

    assert {:error, :invalid_legacy_lifetime_state} =
             ClientLifetime.validate_client(%Client{
               client_id: "legacy-with-deadline",
               lifetime_version: 0,
               client_expires_at: finite
             })
  end

  test "client row guard returns current rows in stable client ID order inside a transaction" do
    ids = ["lifetime-lock-z", "lifetime-lock-a"]

    for client_id <- ids do
      assert {:ok, _client} = Repository.register_client(client(client_id, 1, nil, nil))
    end

    assert {:ok, clients} =
             Repository.transact(fn ->
               Repository.lock_clients(ids ++ ["lifetime-lock-z"])
             end)

    assert Enum.map(clients, & &1.client_id) == ["lifetime-lock-a", "lifetime-lock-z"]
    assert {:error, :transaction_required} = Repository.lock_clients(ids)
  end

  test "ordinary client fetch preserves expired and disabled current rows" do
    expired_at = DateTime.from_unix!(1_700_000_000)
    expired = client("lifetime-expired-readable", 1, expired_at, nil)
    disabled = %{client("lifetime-disabled-readable", 1, nil, nil) | active: false}

    assert {:ok, _} = Repository.register_client(expired)
    assert {:ok, _} = Repository.register_client(disabled)

    assert {:ok, stored_expired} = Repository.fetch_client_by_id(expired.client_id)
    assert DateTime.compare(stored_expired.client_expires_at, expired_at) == :eq
    assert stored_expired.active

    assert {:ok, stored_disabled} = Repository.fetch_client_by_id(disabled.client_id)
    refute stored_disabled.active
    assert stored_disabled.lifetime_version == 1
  end

  test "dependency adaptation binds lifetime support to the declared transaction authority" do
    assert {:ok, dependencies} = LegacyOptions.from_request(%{})
    assert %ClientLifetime{transaction_authority: authority} = dependencies.client_lifetime
    assert authority == Repository.transaction_authority()
    assert {:ok, ^dependencies} = Dependencies.validate(dependencies, :device_code)

    assert {:error, participant_error} =
             Dependencies.validate(
               %{
                 dependencies
                 | device_authorization_store: __MODULE__.OutsideAuthorityDeviceStore
               },
               :device_code
             )

    assert participant_error.reason_code == :transaction_authority_unavailable

    assert {:error, error} =
             LegacyOptions.from_request(%{opts: [client_store: __MODULE__.CustomClientStore]})

    assert error.status == 500
    assert error.reason_code == :transaction_authority_unavailable

    assert {:error, mismatched} =
             LegacyOptions.from_request(%{
               opts: [client_store: __MODULE__.SplitAuthorityClientStore]
             })

    assert mismatched.status == 500
    assert mismatched.reason_code == :transaction_authority_unavailable
  end

  test "client and token changes roll back when the required audit write fails" do
    client_id = "lifetime-rollback-client"
    assert {:ok, client} = Repository.register_client(client(client_id, 1, nil, nil))
    token_hash = TokenFormatter.hash_token("lifetime-rollback-token")

    assert {:error, _reason} =
             Repository.transact(fn ->
               with {:ok, [current]} <- Repository.lock_clients([client_id]),
                    {:ok, _updated} <-
                      Repository.update_client(current, %{name: "must roll back"}),
                    {:ok, _token} <-
                      Repository.store_token(%Token{
                        token_hash: token_hash,
                        token_type: :access_token,
                        client_id: client_id,
                        issued_at: DateTime.utc_now(),
                        expires_at: DateTime.add(DateTime.utc_now(), 60, :second)
                      }),
                    {:ok, _audit} <- Repository.append_audit_event(%{action: :invalid}) do
                 {:ok, :unexpected_success}
               else
                 {:error, reason} -> {:error, reason}
               end
             end)

    assert {:ok, current} = Repository.fetch_client_by_id(client_id)
    assert current.name == client.name
    assert {:ok, nil} = Repository.fetch_lifecycle_token(token_hash)
  end

  test "a failed grant transition or token write rolls back a preceding client update" do
    for {client_id, failing_write} <- [
          {"lifetime-grant-rollback",
           fn ->
             Repository.mark_authorization_code_redeemed(
               "missing-authorization-code",
               DateTime.utc_now()
             )
           end},
          {"lifetime-token-rollback",
           fn ->
             Repository.store_token(%Token{token_type: :access_token})
           end}
        ] do
      assert {:ok, client} = Repository.register_client(client(client_id, 1, nil, nil))
      assert_client_update_rolls_back(client, failing_write)
    end
  end

  test "a declared split-backend adapter that leaks child writes fails atomicity conformance" do
    refute __MODULE__.LyingSplitAuthority.rollback_conforms?()
  end

  defp assert_conforms!(adapter, clients), do: assert(conforms?(adapter, clients))

  defp conforms?(adapter, clients) do
    authority = adapter.transaction_authority()

    {:ok, _lifetime} = ClientLifetime.adapt(adapter, authority)

    Enum.all?(clients, fn client ->
      prepared =
        struct!(
          Client,
          Map.merge(
            %{
              client_type: :confidential,
              name: client.client_id,
              redirect_uris: [],
              allowed_scopes: [],
              allowed_grant_types: [],
              allowed_response_types: [],
              token_endpoint_auth_method: :client_secret_basic,
              subject_type: :public
            },
            Map.from_struct(client)
          )
        )

      with {:ok, _stored} <- adapter.register_client(prepared),
           {:ok, persisted} <- adapter.fetch_client_by_id(prepared.client_id),
           {:ok, validated} <- ClientLifetime.validate_client(persisted) do
        same_lifetime?(prepared, validated)
      else
        _ -> false
      end
    end)
  rescue
    _error -> false
  end

  defp same_lifetime?(expected, actual) do
    expected.lifetime_version == actual.lifetime_version and
      same_deadline?(expected.client_expires_at, actual.client_expires_at) and
      same_deadline?(
        expected.registration_access_token_expires_at,
        actual.registration_access_token_expires_at
      )
  end

  defp same_deadline?(nil, nil), do: true

  defp same_deadline?(%DateTime{} = expected, %DateTime{} = actual),
    do: DateTime.compare(expected, actual) == :eq

  defp same_deadline?(_expected, _actual), do: false

  defp assert_client_update_rolls_back(client, failing_write) do
    assert {:error, _reason} =
             Repository.transact(fn ->
               with {:ok, [current]} <- Repository.lock_clients([client.client_id]),
                    {:ok, _updated} <-
                      Repository.update_client(current, %{name: "must roll back"}),
                    {:ok, _result} <- failing_write.() do
                 {:ok, :unexpected_success}
               else
                 {:error, reason} -> {:error, reason}
               end
             end)

    assert {:ok, persisted} = Repository.fetch_client_by_id(client.client_id)
    assert persisted.name == client.name
  end

  defp client(client_id, version, app_deadline, management_deadline) do
    %Client{
      client_id: client_id,
      client_type: :confidential,
      name: client_id,
      redirect_uris: [],
      allowed_scopes: [],
      allowed_grant_types: [],
      allowed_response_types: [],
      token_endpoint_auth_method: :client_secret_basic,
      subject_type: :public,
      lifetime_version: version,
      client_expires_at: app_deadline,
      registration_access_token_expires_at: management_deadline
    }
  end

  defmodule SplitAuthorityClientStore do
    def lifetime_contract,
      do: %{
        version: 1,
        transaction_authority: %{identity: :split, participants: %{client_store: __MODULE__}}
      }

    def lock_clients(_ids), do: {:ok, []}
  end

  defmodule OutsideAuthorityDeviceStore do
  end

  defmodule LyingSplitAuthority do
    def transaction_authority,
      do: %{
        identity: :claimed_shared,
        participants: %{client_store: __MODULE__, token_store: __MODULE__}
      }

    def transact(fun) do
      case fun.() do
        {:error, reason} -> {:error, reason}
        result -> {:ok, result}
      end
    end

    def store_child_row(value) do
      Process.put({Lockspire.Storage.ClientLifetimeConformanceTest, :split_backend_row}, value)
      {:ok, value}
    end

    def rollback_conforms? do
      key = {Lockspire.Storage.ClientLifetimeConformanceTest, :split_backend_row}
      before = Process.get(key)

      result =
        transact(fn ->
          store_child_row(:escaped)
          {:error, :injected_audit_failure}
        end)

      after_write = Process.get(key)
      Process.delete(key)

      match?({:error, :injected_audit_failure}, result) and after_write == before
    end
  end

  defmodule CustomClientStore do
    alias Lockspire.Domain.Client

    def lifetime_contract, do: %{version: 1, transaction_authority: transaction_authority()}

    def transaction_authority,
      do: %{identity: :custom_test, participants: %{client_store: __MODULE__}}

    def lock_clients(ids), do: {:ok, Enum.map(Enum.uniq(ids) |> Enum.sort(), &fetch!/1)}

    def register_client(%Client{} = client) do
      Process.put({__MODULE__, client.client_id}, client)
      {:ok, client}
    end

    def fetch_client_by_id(client_id), do: {:ok, Process.get({__MODULE__, client_id})}
    defp fetch!(client_id), do: Process.get({__MODULE__, client_id})
  end

  defmodule MissingDeclaration do
    def lock_clients(_ids), do: {:ok, []}
  end

  defmodule UnknownDeclaration do
    def lifetime_contract, do: %{version: 2, transaction_authority: :unknown}
    def lock_clients(_ids), do: {:ok, []}
  end

  defmodule DroppedVersion do
    alias Lockspire.Domain.Client

    def lifetime_contract, do: %{version: 1, transaction_authority: transaction_authority()}

    def transaction_authority,
      do: %{identity: :dropped_version, participants: %{client_store: __MODULE__}}

    def lock_clients(_ids), do: {:ok, []}

    def register_client(client) do
      Process.put({__MODULE__, :registered, client.client_id}, true)
      {:ok, client}
    end

    def fetch_client_by_id(client_id) do
      Process.put({__MODULE__, :fetched, client_id}, true)
      {:ok, %Client{client_id: client_id}}
    end
  end

  defmodule DroppedDeadline do
    alias Lockspire.Domain.Client

    def lifetime_contract, do: %{version: 1, transaction_authority: transaction_authority()}

    def transaction_authority,
      do: %{identity: :dropped_deadline, participants: %{client_store: __MODULE__}}

    def lock_clients(_ids), do: {:ok, []}

    def register_client(client) do
      Process.put({__MODULE__, :registered, client.client_id}, true)
      {:ok, client}
    end

    def fetch_client_by_id(client_id) do
      Process.put({__MODULE__, :fetched, client_id}, true)

      {:ok,
       %Client{
         client_id: client_id,
         lifetime_version: 1,
         client_expires_at: nil,
         registration_access_token_expires_at: nil
       }}
    end
  end

  defmodule MissingGuard do
    def lifetime_contract, do: %{version: 1, transaction_authority: :custom_test}
  end
end
