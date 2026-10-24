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

  test "built-in and custom adapters execute secret replacement with deferred time" do
    now = DateTime.from_unix!(1_900_000_000) |> DateTime.truncate(:second)

    for {adapter, id} <- [
          {Repository, "built-in-replacement-#{System.unique_integer([:positive])}"},
          {__MODULE__.CustomClientStore,
           "custom-replacement-#{System.unique_integer([:positive])}"}
        ] do
      original = %{
        client(id, 1, DateTime.add(now, 100, :second), DateTime.add(now, 200, :second))
        | client_secret_expires_at: DateTime.add(now, 50, :second),
          client_secret_hash: "old-hash",
          client_secret_jwt_verifier_encrypted: "old-verifier"
      }

      assert {:ok, stored} = adapter.register_client(original)
      assert rotation_conforms?(adapter, stored, now)
      assert Process.get({adapter, :rotation_clock_called, id}) == true
    end
  end

  test "built-in and custom adapters persist management replacement fields" do
    now = DateTime.from_unix!(1_900_000_000) |> DateTime.truncate(:second)

    for {adapter, id} <- [
          {Repository, "built-in-management-#{System.unique_integer([:positive])}"},
          {__MODULE__.CustomClientStore,
           "custom-management-#{System.unique_integer([:positive])}"}
        ] do
      app_deadline = DateTime.add(now, 100, :second)
      secret_deadline = DateTime.add(now, 50, :second)

      original = %{
        client(id, 1, app_deadline, DateTime.add(now, 200, :second))
        | client_secret_expires_at: secret_deadline,
          client_secret_hash: "management-old-secret",
          client_secret_jwt_verifier_encrypted: "management-old-verifier",
          registration_access_token_hash: "management-old-hash"
      }

      assert {:ok, stored} = adapter.register_client(original)
      assert management_rotation_conforms?(adapter, stored, now, DateTime.add(now, 40, :second))

      assert {:ok, replaced} = adapter.fetch_client_by_id(id)
      assert replaced.registration_access_token_hash == "management-replacement-hash"

      assert DateTime.compare(
               replaced.registration_access_token_expires_at,
               DateTime.add(now, 40, :second)
             ) == :eq

      assert DateTime.compare(replaced.client_expires_at, app_deadline) == :eq
      assert DateTime.compare(replaced.client_secret_expires_at, secret_deadline) == :eq
      assert replaced.client_secret_hash == original.client_secret_hash

      assert replaced.client_secret_jwt_verifier_encrypted ==
               original.client_secret_jwt_verifier_encrypted
    end
  end

  test "management callback conformance rejects dropped deadline or version fields after invocation" do
    now = DateTime.from_unix!(1_900_000_000) |> DateTime.truncate(:second)
    deadline = DateTime.add(now, 40, :second)
    original = client("custom-drop-management", 1, nil, nil)

    for adapter <- [__MODULE__.DroppedManagementDeadline, __MODULE__.DroppedManagementVersion] do
      assert {:ok, stored} = adapter.register_client(original)
      refute management_rotation_conforms?(adapter, stored, now, deadline)
      assert Process.get({adapter, :management_rotation_called, original.client_id}) == true
    end
  end

  test "management conformance rejects a split transaction authority" do
    now = DateTime.from_unix!(1_900_000_000) |> DateTime.truncate(:second)
    client = client("custom-split-management", 1, nil, nil)
    assert {:ok, stored} = __MODULE__.SplitManagementAuthority.register_client(client)

    refute management_rotation_conforms?(
             __MODULE__.SplitManagementAuthority,
             stored,
             now,
             DateTime.add(now, 40, :second),
             Repository.transaction_authority()
           )
  end

  test "an adapter that ignores the deferred clock fails executed replacement conformance" do
    now = DateTime.from_unix!(1_900_000_000) |> DateTime.truncate(:second)
    client = client("custom-ignore-clock", 1, nil, nil)
    assert {:ok, stored} = __MODULE__.IgnoringClock.register_client(client)

    refute rotation_conforms?(__MODULE__.IgnoringClock, stored, now)
    assert Process.get({__MODULE__.IgnoringClock, :rotation_called, client.client_id}) == true
    refute Process.get({__MODULE__.IgnoringClock, :rotation_clock_called, client.client_id})
  end

  test "missing, unknown, state-dropping and unguarded adapters fail conformance" do
    authority = Repository.transaction_authority()

    assert {:error, _} = ClientLifetime.adapt(__MODULE__.MissingDeclaration, authority)
    assert {:error, _} = ClientLifetime.adapt(__MODULE__.UnknownDeclaration, authority)
    assert {:error, _} = ClientLifetime.adapt(__MODULE__.MissingGuard, authority)

    assert {:ok, _lifetime} =
             ClientLifetime.adapt(
               __MODULE__.MissingRotation,
               __MODULE__.MissingRotation.transaction_authority()
             )

    assert {:error, :client_secret_rotation_unavailable} =
             ClientLifetime.ensure_secret_rotation_available(__MODULE__.MissingRotation)

    finite = DateTime.from_unix!(1_800_000_000) |> DateTime.truncate(:second)
    client = client("custom-drop-fields", 1, finite, finite)
    refute conforms?(__MODULE__.DroppedVersion, [client])
    refute conforms?(__MODULE__.DroppedDeadline, [client])

    for adapter <- [__MODULE__.DroppedVersion, __MODULE__.DroppedDeadline] do
      assert Process.get({adapter, :registered, client.client_id}) == true
      assert Process.get({adapter, :fetched, client.client_id}) == true
    end

    for adapter <- [__MODULE__.DroppedVersion, __MODULE__.DroppedDeadline] do
      assert {:ok, stored} = adapter.register_client(client)
      refute rotation_conforms?(adapter, stored, finite)
      assert Process.get({adapter, :rotation_called, client.client_id}) == true
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
      ) and same_deadline?(expected.client_secret_expires_at, actual.client_secret_expires_at)
  end

  defp rotation_conforms?(adapter, client, now) do
    {:ok, _lifetime} = ClientLifetime.adapt(adapter, adapter.transaction_authority())

    clock = fn ->
      Process.put({adapter, :rotation_clock_called, client.client_id}, true)
      now
    end

    with {:ok, rotated} <-
           adapter.rotate_client_secret(client, "replacement-hash", "replacement-verifier", clock),
         {:ok, validated} <- ClientLifetime.validate_client(rotated) do
      validated.client_secret_hash == "replacement-hash" and
        validated.client_secret_jwt_verifier_encrypted == "replacement-verifier" and
        DateTime.compare(validated.last_secret_rotated_at, now) == :eq and
        same_lifetime?(%{client | client_secret_expires_at: nil, lifetime_version: 1}, validated)
    else
      _ -> false
    end
  rescue
    _error -> false
  end

  defp management_rotation_conforms?(
         adapter,
         client,
         now,
         deadline,
         expected_authority \\ nil
       ) do
    expected_authority = expected_authority || adapter.transaction_authority()

    with {:ok, _lifetime} <- ClientLifetime.adapt(adapter, expected_authority),
         {:ok, current} <- adapter.fetch_client_by_id(client.client_id),
         {:ok, lifetime_changes} <-
           Client.credential_lifetime_changes(current, :management, deadline) do
      candidate = %{current | registration_access_token_expires_at: deadline, updated_at: now}

      expected =
        current
        |> Map.from_struct()
        |> Map.merge(lifetime_changes)
        |> Map.merge(%{
          registration_access_token_hash: "management-replacement-hash",
          updated_at: now
        })
        |> then(&struct!(Client, &1))

      audit = management_audit(candidate, now)

      with {:ok, _rotated} <-
             adapter.rotate_registration_access_token(
               candidate,
               "management-replacement-hash",
               audit
             ),
           {:ok, persisted} <- adapter.fetch_client_by_id(client.client_id),
           {:ok, validated} <- ClientLifetime.validate_client(persisted) do
        result =
          validated.registration_access_token_hash == "management-replacement-hash" and
            validated.lifetime_version == expected.lifetime_version and
            same_deadline?(validated.registration_access_token_expires_at, deadline) and
            same_deadline?(validated.client_expires_at, expected.client_expires_at) and
            same_deadline?(validated.client_secret_expires_at, expected.client_secret_expires_at) and
            DateTime.compare(validated.updated_at, now) == :eq

        result
      else
        _ -> false
      end
    else
      _ -> false
    end
  rescue
    _error -> false
  end

  defp management_audit(client, now) do
    %{
      action: :dcr_management_rat_rotated,
      outcome: :succeeded,
      actor: %{type: :operator, id: "conformance-test"},
      resource: %{type: :client, id: client.client_id},
      metadata: %{rotated_at: now}
    }
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

    def rotate_client_secret(%Client{} = client, secret_hash, verifier, clock) do
      current = Process.get({__MODULE__, client.client_id})
      now = clock.()

      with {:ok, lifetime} <- Client.credential_lifetime_changes(current, :secret, nil) do
        rotated =
          current
          |> Map.from_struct()
          |> Map.merge(lifetime)
          |> Map.merge(%{
            client_secret_hash: secret_hash,
            client_secret_jwt_verifier_encrypted: verifier,
            last_secret_rotated_at: now
          })
          |> then(&struct!(Client, &1))

        Process.put({__MODULE__, client.client_id}, rotated)
        {:ok, rotated}
      end
    end

    def rotate_registration_access_token(%Client{} = candidate, rat_hash, _audit) do
      current = Process.get({__MODULE__, candidate.client_id})

      with {:ok, lifetime} <-
             Client.credential_lifetime_changes(
               current,
               :management,
               candidate.registration_access_token_expires_at
             ) do
        updated =
          current
          |> Map.from_struct()
          |> Map.merge(lifetime)
          |> Map.merge(%{
            registration_access_token_hash: rat_hash,
            updated_at: candidate.updated_at
          })
          |> then(&struct!(Client, &1))

        Process.put({__MODULE__, candidate.client_id}, updated)
        {:ok, updated}
      end
    end
  end

  defmodule DroppedManagementDeadline do
    alias Lockspire.Domain.Client

    def lifetime_contract, do: %{version: 1, transaction_authority: transaction_authority()}

    def transaction_authority,
      do: %{identity: :drop_management_deadline, participants: %{client_store: __MODULE__}}

    def lock_clients(ids), do: {:ok, Enum.map(ids, &Process.get({__MODULE__, &1}))}

    def register_client(client),
      do:
        (
          Process.put({__MODULE__, client.client_id}, client)
          {:ok, client}
        )

    def fetch_client_by_id(id), do: {:ok, Process.get({__MODULE__, id})}

    def rotate_registration_access_token(candidate, hash, _audit) do
      Process.put({__MODULE__, :management_rotation_called, candidate.client_id}, true)
      current = Process.get({__MODULE__, candidate.client_id})

      updated = %{
        current
        | registration_access_token_hash: hash,
          registration_access_token_expires_at: nil,
          updated_at: candidate.updated_at
      }

      Process.put({__MODULE__, candidate.client_id}, updated)
      {:ok, updated}
    end
  end

  defmodule DroppedManagementVersion do
    alias Lockspire.Domain.Client

    def lifetime_contract, do: %{version: 1, transaction_authority: transaction_authority()}

    def transaction_authority,
      do: %{identity: :drop_management_version, participants: %{client_store: __MODULE__}}

    def lock_clients(ids), do: {:ok, Enum.map(ids, &Process.get({__MODULE__, &1}))}

    def register_client(client),
      do:
        (
          Process.put({__MODULE__, client.client_id}, client)
          {:ok, client}
        )

    def fetch_client_by_id(id), do: {:ok, Process.get({__MODULE__, id})}

    def rotate_registration_access_token(candidate, hash, _audit) do
      Process.put({__MODULE__, :management_rotation_called, candidate.client_id}, true)
      current = Process.get({__MODULE__, candidate.client_id})

      updated = %{
        current
        | registration_access_token_hash: hash,
          registration_access_token_expires_at: candidate.registration_access_token_expires_at,
          lifetime_version: nil,
          updated_at: candidate.updated_at
      }

      Process.put({__MODULE__, candidate.client_id}, updated)
      {:ok, updated}
    end
  end

  defmodule SplitManagementAuthority do
    alias Lockspire.Domain.Client

    def lifetime_contract, do: %{version: 1, transaction_authority: transaction_authority()}

    def transaction_authority,
      do: %{identity: :management_split, participants: %{client_store: __MODULE__}}

    def lock_clients(_ids), do: {:ok, []}

    def register_client(client),
      do:
        (
          Process.put({__MODULE__, client.client_id}, client)
          {:ok, client}
        )

    def fetch_client_by_id(id), do: {:ok, Process.get({__MODULE__, id})}

    def rotate_registration_access_token(_candidate, _hash, _audit) do
      Process.put({__MODULE__, :management_rotation_called}, true)
      {:error, :split_authority}
    end
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

    def rotate_client_secret(client, hash, verifier, clock) do
      Process.put({__MODULE__, :rotation_called, client.client_id}, true)
      now = clock.()

      {:ok,
       %{
         client
         | client_secret_hash: hash,
           client_secret_jwt_verifier_encrypted: verifier,
           last_secret_rotated_at: now,
           lifetime_version: nil
       }}
    end

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

    def rotate_client_secret(client, hash, verifier, clock) do
      Process.put({__MODULE__, :rotation_called, client.client_id}, true)
      now = clock.()

      {:ok,
       %{
         client
         | client_secret_hash: hash,
           client_secret_jwt_verifier_encrypted: verifier,
           last_secret_rotated_at: now,
           lifetime_version: 1,
           client_expires_at: nil,
           client_secret_expires_at: nil,
           registration_access_token_expires_at: nil
       }}
    end

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

  defmodule MissingRotation do
    def lifetime_contract,
      do: %{version: 1, transaction_authority: transaction_authority()}

    def transaction_authority,
      do: %{identity: :missing_rotation, participants: %{client_store: __MODULE__}}

    def lock_clients(_ids), do: {:ok, []}
  end

  defmodule IgnoringClock do
    alias Lockspire.Domain.Client

    def lifetime_contract, do: %{version: 1, transaction_authority: transaction_authority()}

    def transaction_authority,
      do: %{identity: :ignoring_clock, participants: %{client_store: __MODULE__}}

    def lock_clients(ids), do: {:ok, Enum.map(Enum.uniq(ids) |> Enum.sort(), &fetch!/1)}

    def register_client(%Client{} = client) do
      Process.put({__MODULE__, client.client_id}, client)
      {:ok, client}
    end

    def fetch_client_by_id(client_id), do: {:ok, Process.get({__MODULE__, client_id})}
    defp fetch!(client_id), do: Process.get({__MODULE__, client_id})

    def rotate_client_secret(%Client{} = client, hash, verifier, _clock) do
      Process.put({__MODULE__, :rotation_called, client.client_id}, true)

      {:ok,
       %{
         client
         | client_secret_hash: hash,
           client_secret_jwt_verifier_encrypted: verifier,
           lifetime_version: 1,
           client_secret_expires_at: nil
       }}
    end
  end
end
