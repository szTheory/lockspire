defmodule Lockspire.Integration.AppLifetimeRegistrationTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Domain.Client
  alias Lockspire.Clients
  alias Lockspire.Protocol.Registration
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Test.Fixtures.DcrFixtures

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

  test "registration persists its app lifetime and current eligibility rejects the deadline" do
    server_policy = DcrFixtures.server_policy(%{dcr_default_client_lifetime_seconds: 60})
    {:ok, %ServerPolicy{}} = Repository.put_server_policy(server_policy)
    issued_at = DateTime.from_unix!(100)

    {:ok, %Registration.Success{client: created}} =
      Registration.register(
        DcrFixtures.register_request(
          metadata: %{
            "client_name" => "App lifetime public client",
            "redirect_uris" => ["https://app.example.test/callback"],
            "token_endpoint_auth_method" => "none"
          },
          server_policy: server_policy
        )
        |> Map.put(:now, issued_at)
      )

    assert {:ok, fetched} = Repository.fetch_client_by_id(created.client_id)
    assert fetched.lifetime_version == 1

    assert DateTime.compare(fetched.client_id_issued_at, issued_at) == :eq

    assert DateTime.compare(fetched.client_expires_at, DateTime.add(issued_at, 60, :second)) ==
             :eq

    assert Lockspire.Domain.Client.app_eligibility(
             fetched,
             DateTime.add(issued_at, 59, :second),
             :test
           ) ==
             :ok

    assert Lockspire.Domain.Client.app_eligibility(fetched, fetched.client_expires_at, :test) ==
             {:error, :expired}

    updated_policy = %ServerPolicy{server_policy | dcr_default_client_lifetime_seconds: 30}
    {:ok, _} = Repository.put_server_policy(updated_policy)
    assert {:ok, unchanged} = Repository.fetch_client_by_id(created.client_id)

    assert DateTime.compare(unchanged.client_expires_at, DateTime.add(issued_at, 60, :second)) ==
             :eq

    for lifetime <- [nil, 0] do
      policy = %ServerPolicy{server_policy | dcr_default_client_lifetime_seconds: lifetime}

      {:ok, %Registration.Success{client: unlimited}} =
        Registration.register(
          DcrFixtures.register_request(
            metadata: %{
              "client_name" => "Unlimited #{inspect(lifetime)} client",
              "redirect_uris" => ["https://app.example.test/callback"],
              "token_endpoint_auth_method" => "none"
            },
            server_policy: policy
          )
          |> Map.put(:now, issued_at)
        )

      assert unlimited.lifetime_version == 1
      assert unlimited.client_expires_at == nil
    end

    assert {:ok, %{client: direct}} =
             Clients.register_client(%{
               client_id: "operator-app-lifetime-client",
               client_type: :public,
               redirect_uris: ["https://app.example.test/callback"],
               allowed_scopes: ["openid"],
               allowed_grant_types: ["authorization_code"],
               token_endpoint_auth_method: :none
             })

    assert direct.lifetime_version == 1
    assert direct.client_expires_at == nil

    {:ok, clients_before_invalid} = Repository.list_clients()
    audits_before_invalid = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    for invalid_seconds <- [true, "60", 1.5, %{}, [], -1, 2_147_483_648] do
      invalid_policy = %ServerPolicy{
        server_policy
        | dcr_default_client_lifetime_seconds: invalid_seconds
      }

      assert {:error,
              %Registration.Error{
                code: :invalid_client_metadata,
                field: :default_client_lifetime_seconds,
                reason: :invalid_duration
              }} =
               Registration.register(
                 DcrFixtures.register_request(
                   server_policy: invalid_policy,
                   metadata: %{
                     "client_name" => "Rejected invalid lifetime",
                     "redirect_uris" => ["https://app.example.test/callback"],
                     "token_endpoint_auth_method" => "none"
                   }
                 )
                 |> Map.put(:now, issued_at)
               )
    end

    assert {:ok, ^clients_before_invalid} = Repository.list_clients()
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == audits_before_invalid

    for auth_method <- [:none, :private_key_jwt, :tls_client_auth] do
      current = %Client{
        active: true,
        lifetime_version: 1,
        client_expires_at: DateTime.add(issued_at, 1, :second),
        token_endpoint_auth_method: auth_method
      }

      assert Client.app_eligibility(current, issued_at, auth_method) == :ok
    end

    assert Client.app_eligibility(
             %Client{active: true, lifetime_version: 0, client_expires_at: nil},
             issued_at,
             :legacy
           ) == :ok

    assert Client.app_eligibility(
             %Client{active: true, lifetime_version: 1, client_expires_at: nil},
             issued_at,
             :unlimited
           ) == :ok

    assert Client.app_eligibility(
             %Client{active: true, lifetime_version: 2},
             issued_at,
             :unknown_version
           ) == {:error, :invalid_lifetime_state}

    assert Client.app_eligibility(%Client{active: true}, issued_at, :missing_version) ==
             {:error, :invalid_lifetime_state}

    assert Client.app_eligibility(
             %Client{active: false, lifetime_version: 1},
             issued_at,
             :disabled
           ) ==
             {:error, :disabled}

    assert Client.app_eligibility(
             %Client{
               active: true,
               lifetime_version: 1,
               client_expires_at: DateTime.add(issued_at, 1, :microsecond)
             },
             issued_at,
             :fractional
           ) == {:error, :invalid_lifetime_state}
  end
end
