defmodule Lockspire.Integration.ManagementTokenLifetimeRegistrationTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Protocol.Registration
  alias Lockspire.Protocol.RegistrationManagement
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Test.Fixtures.DcrFixtures
  alias Lockspire.Web.RegistrationJSON

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

  @tag :management_issuance_snapshot
  test "issuance snapshots app, secret, and management lifetimes and GET preserves them" do
    issued_at = DateTime.from_unix!(100)

    policy =
      DcrFixtures.server_policy(%{
        dcr_default_client_lifetime_seconds: 60,
        dcr_default_client_secret_lifetime_seconds: 10,
        dcr_default_registration_access_token_lifetime_seconds: 20
      })

    request =
      DcrFixtures.register_request(server_policy: policy)
      |> Map.put(:now, issued_at)

    assert {:ok, %Registration.Success{} = success} = Registration.register(request)
    assert {:ok, stored} = Repository.fetch_client_by_id(success.client.client_id)
    response = RegistrationJSON.success_response(success)

    assert DateTime.compare(stored.client_expires_at, DateTime.from_unix!(160)) == :eq
    assert DateTime.compare(stored.client_secret_expires_at, DateTime.from_unix!(110)) == :eq

    assert stored.registration_access_token_expires_at &&
             DateTime.compare(
               stored.registration_access_token_expires_at,
               DateTime.from_unix!(120)
             ) ==
               :eq

    assert response.lockspire_client_expires_at == 160
    assert response.lockspire_registration_access_token_expires_at == 120
    assert response.registration_access_token == success.registration_access_token_plaintext
    assert stored.registration_access_token_hash != success.registration_access_token_plaintext

    assert {:ok, lookup} =
             Repository.get_client_by_registration_access_token_hash(
               stored.registration_access_token_hash
             )

    assert {:ok, current} =
             RegistrationManagement.read(stored.client_id, lookup,
               now: fn -> DateTime.from_unix!(115) end
             )

    get_response = RegistrationJSON.read_response(current)
    assert get_response.lockspire_registration_access_token_expires_at == 120
    refute Map.has_key?(get_response, :registration_access_token)
    refute Map.has_key?(get_response, :client_secret)

    assert {:ok, after_get} = Repository.fetch_client_by_id(stored.client_id)

    assert after_get.registration_access_token_expires_at ==
             stored.registration_access_token_expires_at

    assert {:ok, _} =
             Repository.put_server_policy(%{
               policy
               | dcr_default_registration_access_token_lifetime_seconds: 1
             })

    assert {:ok, after_policy_edit} = Repository.fetch_client_by_id(stored.client_id)

    assert after_policy_edit.registration_access_token_expires_at ==
             stored.registration_access_token_expires_at
  end

  test "nil and zero are unlimited while the maximum positive duration is finite" do
    for duration <- [nil, 0, 2_147_483_647] do
      policy =
        DcrFixtures.server_policy(%{
          dcr_default_client_lifetime_seconds: nil,
          dcr_default_client_secret_lifetime_seconds: nil,
          dcr_default_registration_access_token_lifetime_seconds: duration
        })

      request =
        DcrFixtures.register_request(server_policy: policy)
        |> Map.put(:now, DateTime.from_unix!(200))

      assert {:ok, %Registration.Success{} = success} = Registration.register(request)
      assert {:ok, stored} = Repository.fetch_client_by_id(success.client.client_id)
      expected = if duration in [nil, 0], do: nil, else: DateTime.from_unix!(200 + duration)

      assert if(expected,
               do: DateTime.compare(stored.registration_access_token_expires_at, expected) == :eq,
               else: is_nil(stored.registration_access_token_expires_at)
             )

      assert RegistrationJSON.success_response(success).lockspire_registration_access_token_expires_at ==
               if(expected, do: DateTime.to_unix(expected), else: 0)
    end
  end

  test "public and public-key auth methods receive the DCR management lifecycle" do
    public_key_metadata = DcrFixtures.private_key_jwt_jwks_uri_metadata()

    tls_metadata =
      Map.put(DcrFixtures.valid_metadata(), "token_endpoint_auth_method", "tls_client_auth")

    self_signed_tls_metadata =
      Map.put(
        DcrFixtures.valid_metadata(),
        "token_endpoint_auth_method",
        "self_signed_tls_client_auth"
      )

    for {metadata, policy, expected_auth_method} <- [
          {Map.put(DcrFixtures.valid_metadata(), "token_endpoint_auth_method", "none"),
           DcrFixtures.server_policy(), :none},
          {public_key_metadata, DcrFixtures.private_key_jwt_server_policy(), :private_key_jwt},
          {tls_metadata, DcrFixtures.server_policy(), :tls_client_auth},
          {self_signed_tls_metadata, DcrFixtures.server_policy(), :self_signed_tls_client_auth}
        ] do
      policy =
        Map.update!(policy, :dcr_allowed_token_endpoint_auth_methods, fn methods ->
          methods ++ ["tls_client_auth", "self_signed_tls_client_auth"]
        end)

      policy =
        Map.put(
          policy,
          :dcr_default_registration_access_token_lifetime_seconds,
          20
        )

      request =
        DcrFixtures.register_request(metadata: metadata, server_policy: policy)
        |> Map.put(:now, DateTime.from_unix!(300))

      assert {:ok, %Registration.Success{} = success} = Registration.register(request)
      assert {:ok, stored} = Repository.fetch_client_by_id(success.client.client_id)
      assert stored.provenance == :self_registered
      assert stored.token_endpoint_auth_method == expected_auth_method
      assert is_nil(success.client_secret_plaintext)

      assert DateTime.compare(
               stored.registration_access_token_expires_at,
               DateTime.from_unix!(320)
             ) ==
               :eq

      assert RegistrationJSON.success_response(success).lockspire_registration_access_token_expires_at ==
               320
    end
  end
end
