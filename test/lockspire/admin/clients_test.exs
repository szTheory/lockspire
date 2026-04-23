defmodule Lockspire.Admin.ClientsTest do
  use ExUnit.Case, async: false

  alias Lockspire.Admin.Clients
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

    {:ok, _client} =
      Repository.register_client(%Client{
        client_id: "admin-client",
        client_secret_hash: "sha256:old-salt:old-hash",
        client_type: :confidential,
        name: "Admin Client",
        redirect_uris: ["https://admin.example.com/callback"],
        allowed_scopes: ["email"],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{"tier" => "sandbox"}
      })

    :ok
  end

  test "create_client/1 reuses canonical registration and returns plaintext secret once" do
    assert {:ok, %RegistrationResult{client: client, client_secret: secret}} =
             Clients.create_client(%{
               client_id: "new-client",
               name: "New Client",
               client_type: :confidential,
               redirect_uris: ["https://new.example.com/callback"],
               allowed_scopes: ["profile"],
               allowed_grant_types: ["authorization_code"],
               token_endpoint_auth_method: :client_secret_basic
             })

    assert client.client_id == "new-client"
    assert is_binary(secret)
    assert client.client_secret_hash
  end

  test "update_client/2 allows safe metadata changes and rejects immutable fields" do
    assert {:ok, %Client{} = client} =
             Clients.update_client("admin-client", %{
               name: "Admin Client Updated",
               redirect_uris: ["https://admin.example.com/oidc/callback"],
               allowed_scopes: ["email", "profile"],
               contacts: ["ops@example.com"],
               metadata: %{"tier" => "production"}
             })

    assert client.name == "Admin Client Updated"
    assert client.redirect_uris == ["https://admin.example.com/oidc/callback"]
    assert client.allowed_scopes == ["email", "profile"]
    assert client.contacts == ["ops@example.com"]
    assert client.metadata == %{"tier" => "production"}

    assert {:error, errors} =
             Clients.update_client("admin-client", %{
               client_id: "renamed",
               token_endpoint_auth_method: :client_secret_post
             })

    assert Enum.any?(errors, &(&1.field == :client_id and &1.reason == :immutable_field))

    assert Enum.any?(
             errors,
             &(&1.field == :token_endpoint_auth_method and &1.reason == :immutable_field)
           )
  end

  test "update_client/2 preserves redirect validation discipline" do
    assert {:error, errors} =
             Clients.update_client("admin-client", %{
               redirect_uris: ["https://*.example.com/callback"]
             })

    assert Enum.any?(errors, &(&1.field == :redirect_uris and &1.reason == :invalid_redirect_uri))
  end

  test "rotate_client_secret/2 returns a plaintext secret once and persists only the hash" do
    assert {:ok, %{client: %Client{} = client, client_secret: secret}} =
             Clients.rotate_client_secret("admin-client", %{rotated_at: DateTime.utc_now()})

    assert is_binary(secret)
    refute secret == client.client_secret_hash
    assert client.last_secret_rotated_at

    assert {:ok, %Client{} = stored_client} = Repository.fetch_client_by_id("admin-client")
    assert stored_client.client_secret_hash == client.client_secret_hash
    refute stored_client.client_secret_hash == secret
  end

  test "disable_client/2 and enable_client/2 expose queryable lifecycle state" do
    assert {:ok, %Client{} = disabled_client} =
             Clients.disable_client("admin-client", %{disabled_by: "ops@example.com"})

    refute disabled_client.active
    assert disabled_client.disabled_by == "ops@example.com"
    assert disabled_client.disabled_at

    assert {:ok, disabled_clients} = Clients.list_clients(active: false)
    assert Enum.any?(disabled_clients, &(&1.client_id == "admin-client"))

    assert {:ok, %Client{} = enabled_client} = Clients.enable_client("admin-client")
    assert enabled_client.active
    assert is_nil(enabled_client.disabled_at)
    assert is_nil(enabled_client.disabled_by)
  end
end
