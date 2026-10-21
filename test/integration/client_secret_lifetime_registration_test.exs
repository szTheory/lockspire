defmodule Lockspire.Integration.ClientSecretLifetimeRegistrationTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Protocol.Registration
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

  test "DCR stores, advertises, and enforces the finite Basic secret deadline" do
    issued_at = DateTime.from_unix!(100)

    policy =
      DcrFixtures.server_policy(%{
        dcr_default_client_lifetime_seconds: nil,
        dcr_default_client_secret_lifetime_seconds: 10
      })

    request =
      DcrFixtures.register_request(
        server_policy: policy,
        metadata: %{
          "client_name" => "Finite secret tracer",
          "redirect_uris" => ["https://app.example.test/callback"],
          "token_endpoint_auth_method" => "client_secret_basic"
        }
      )
      |> Map.put(:now, issued_at)

    assert {:ok, %Registration.Success{} = success} = Registration.register(request)
    assert {:ok, stored} = Repository.fetch_client_by_id(success.client.client_id)
    response = RegistrationJSON.success_response(success)
    deadline = DateTime.from_unix!(110)

    assert stored.provenance == :self_registered
    assert stored.lifetime_version == 1
    assert stored.client_secret_hash != success.client_secret_plaintext
    assert DateTime.compare(stored.client_secret_expires_at, deadline) == :eq
    assert response.client_secret_expires_at == 110
    assert response.client_secret == success.client_secret_plaintext

    authorization =
      "Basic " <> Base.encode64("#{stored.client_id}:#{success.client_secret_plaintext}")

    assert {:ok, _client} =
             ClientAuth.authenticate(%{}, authorization,
               client_store: Repository,
               now: fn -> DateTime.from_unix!(109) end
             )

    for now <- [deadline, DateTime.from_unix!(111)] do
      assert {:error, %ClientAuth.Error{status: 401, error: "invalid_client"} = error} =
               ClientAuth.authenticate(%{}, authorization,
                 client_store: Repository,
                 now: fn -> now end
               )

      refute error.error_description =~ "expir"
    end
  end
end
