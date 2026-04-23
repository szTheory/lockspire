defmodule Lockspire.ClientsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Lockspire.Clients
  alias Lockspire.Clients.RegistrationResult
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository

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

  test "register_client/1 persists hashed secrets and returns the plaintext once for confidential clients" do
    events = attach_events(self())

    assert {:ok, %RegistrationResult{client: %Client{} = client, client_secret: secret}} =
             Clients.register_client(%{
               name: "Acme Integrations",
               client_type: :confidential,
               redirect_uris: ["https://client.example.com/callback"],
               allowed_scopes: ["profile", "email"],
               allowed_grant_types: ["authorization_code"],
               token_endpoint_auth_method: :client_secret_basic,
               created_by: "ops@example.com"
             })

    assert is_binary(secret)
    assert secret != ""
    assert client.client_secret_hash
    refute client.client_secret_hash == secret

    assert {:ok, %Client{} = stored_client} = Repository.fetch_client_by_id(client.client_id)
    assert stored_client.client_secret_hash == client.client_secret_hash
    refute Map.has_key?(Map.from_struct(stored_client), :client_secret)

    client_id = client.client_id

    assert_received {:telemetry_event, [:lockspire, :client_registration_succeeded],
                     %{client_id: ^client_id}}

    assert_received {:telemetry_event, [:lockspire, :audit, :client_registration_succeeded],
                     %{client_id: ^client_id}}

    detach_events(events)
  end

  test "register_client/1 rejects wildcard redirect uris and rejects openid scopes" do
    events = attach_events(self())

    assert {:error, errors} =
             Clients.register_client(%{
               client_type: :public,
               redirect_uris: ["https://*.example.com/callback"],
               allowed_scopes: ["openid"],
               allowed_grant_types: ["authorization_code"],
               token_endpoint_auth_method: :none
             })

    assert Enum.any?(errors, &(&1.reason == :invalid_redirect_uri))
    assert Enum.any?(errors, &(&1.reason == :invalid_scope))

    assert_received {:telemetry_event, [:lockspire, :client_registration_rejected],
                     %{reason_codes: reason_codes}}

    assert :invalid_redirect_uri in reason_codes
    assert :invalid_scope in reason_codes

    detach_events(events)
  end

  test "register_client/1 returns a validation error for unknown client_type input" do
    assert {:error, errors} =
             Clients.register_client(%{
               name: "Bad Client Type",
               client_type: "zzzz_not_a_real_type",
               redirect_uris: ["https://client.example.com/callback"],
               allowed_scopes: ["profile"],
               allowed_grant_types: ["authorization_code"],
               token_endpoint_auth_method: :none
             })

    assert Enum.any?(errors, fn error ->
             error.field == :client_type and error.reason == :invalid_client_type
           end)
  end

  test "mix lockspire.client.create prints the plaintext secret once and persists only the hash" do
    output =
      capture_io(fn ->
        Mix.Tasks.Lockspire.Client.Create.run([
          "--client-id",
          "cli_client",
          "--name",
          "CLI Client",
          "--client-type",
          "confidential",
          "--redirect-uri",
          "https://client.example.com/callback",
          "--scope",
          "profile",
          "--grant-type",
          "authorization_code"
        ])
      end)

    assert output =~ "client_id=cli_client"
    assert output =~ "client_secret="

    assert {:ok, %Client{} = client} = Repository.fetch_client_by_id("cli_client")
    assert client.client_secret_hash
    refute output =~ client.client_secret_hash
  end

  defp attach_events(pid) do
    handler_id = "clients-test-#{System.unique_integer([:positive])}"

    events = [
      [:lockspire, :client_registration_succeeded],
      [:lockspire, :audit, :client_registration_succeeded],
      [:lockspire, :client_registration_rejected]
    ]

    :ok =
      :telemetry.attach_many(
        handler_id,
        events,
        fn event, _measurements, metadata, test_pid ->
          send(test_pid, {:telemetry_event, event, metadata})
        end,
        pid
      )

    {handler_id, events}
  end

  defp detach_events({handler_id, _events}) do
    :telemetry.detach(handler_id)
  end
end
