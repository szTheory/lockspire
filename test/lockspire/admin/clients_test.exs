# credo:disable-for-this-file
defmodule Lockspire.Admin.ClientsTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Lockspire.Admin.Clients
  alias Lockspire.Clients.RegistrationResult
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    handler_id = attach_events(self())

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

    on_exit(fn -> :telemetry.detach(handler_id) end)

    %{handler_id: handler_id}
  end

  describe "actor_from_attrs/1 enforcement (D-22)" do
    test "missing actor.type raises ArgumentError" do
      assert_raise ArgumentError, ~r/actor\.type is required/, fn ->
        Clients.create_client(%{client_id: "test-no-actor"})
      end
    end

    test "nil actor.type raises ArgumentError" do
      assert_raise ArgumentError, ~r/actor\.type is required/, fn ->
        Clients.create_client(%{client_id: "test-no-actor", actor: %{type: nil, id: "x"}})
      end
    end

    test "blank actor.type raises ArgumentError" do
      assert_raise ArgumentError, ~r/actor\.type cannot be blank/, fn ->
        Clients.create_client(%{client_id: "test-no-actor", actor: %{type: "  ", id: "x"}})
      end
    end

    test "non-atom/non-string actor.type raises ArgumentError" do
      assert_raise ArgumentError, ~r/actor\.type must be an atom or non-blank string/, fn ->
        Clients.create_client(%{client_id: "test-no-actor", actor: %{type: 12345, id: "x"}})
      end
    end

    test "valid operator actor.type passes (regression sentinel)" do
      assert {:ok, %RegistrationResult{client: client}} =
               Clients.create_client(%{
                 client_id: "new-client-valid",
                 name: "New Client",
                 client_type: :confidential,
                 redirect_uris: ["https://new.example.com/callback"],
                 allowed_scopes: ["profile"],
                 allowed_grant_types: ["authorization_code"],
                 token_endpoint_auth_method: :client_secret_basic,
                 actor: %{
                   type: :operator,
                   id: "ops-123"
                 }
               })

      assert client.client_id == "new-client-valid"
    end
  end

  describe "create_dcr_client/1 (DCR-aware persistence)" do
    test "preserves DCR fields verbatim" do
      iat_id = nil
      now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
      expires = DateTime.add(now, 90 * 24 * 3600, :second)
      rat_hash = Lockspire.Security.Policy.hash_token("test_rat_plaintext_for_fixture")
      {client_secret_hash, _plaintext} = Lockspire.Clients.rotate_secret_hash()

      client = %Lockspire.Domain.Client{
        client_id: "ls_dcr_test_" <> Integer.to_string(System.unique_integer([:positive])),
        client_secret_hash: client_secret_hash,
        client_type: :confidential,
        redirect_uris: ["https://app.example.test/cb"],
        allowed_scopes: ["openid", "profile"],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        provenance: :self_registered,
        registration_access_token_hash: rat_hash,
        initial_access_token_id: iat_id,
        client_id_issued_at: now,
        client_secret_expires_at: expires,
        active: true
      }

      {:ok, persisted} =
        Lockspire.Admin.Clients.create_dcr_client(%{
          client: client,
          actor: %{type: :dcr, id: "none", display: "127.0.0.1"}
        })

      assert persisted.provenance == :self_registered
      assert persisted.registration_access_token_hash == rat_hash
      assert persisted.initial_access_token_id == iat_id
      assert DateTime.compare(persisted.client_id_issued_at, now) in [:eq, :gt]
      assert DateTime.compare(persisted.client_secret_expires_at, expires) in [:eq, :gt]
      assert persisted.client_secret_hash == client_secret_hash

      assert Lockspire.Security.Policy.verify_client_secret(
               persisted.client_secret_hash,
               _plaintext
             )
    end

    test "raises ArgumentError when actor is missing" do
      client = %Lockspire.Domain.Client{
        client_id: "ls_dcr_test_no_actor",
        client_type: :confidential
      }

      assert_raise ArgumentError, ~r/actor\.type is required/, fn ->
        Lockspire.Admin.Clients.create_dcr_client(%{client: client})
      end
    end
  end

  test "create_client/1 reuses canonical registration, emits telemetry, and appends operator audit" do
    assert {:ok, %RegistrationResult{client: client, client_secret: secret}} =
             Clients.create_client(%{
               client_id: "new-client",
               name: "New Client",
               client_type: :confidential,
               redirect_uris: ["https://new.example.com/callback"],
               allowed_scopes: ["profile"],
               allowed_grant_types: ["authorization_code"],
               token_endpoint_auth_method: :client_secret_basic,
               actor: %{
                 type: :operator,
                 id: "ops-123",
                 display: "Ops User"
               }
             })

    assert client.client_id == "new-client"
    assert is_binary(secret)
    assert client.client_secret_hash

    assert_received {:telemetry_event, [:lockspire, :client_created],
                     %{client_id: "new-client", actor_type: :operator, actor_id: "ops-123"}}

    assert_received {:telemetry_event, [:lockspire, :audit, :client_created],
                     %{client_id: "new-client", actor_type: :operator, actor_id: "ops-123"}}

    assert %AuditEventRecord{} = audit = latest_audit!("client_created")
    assert audit.resource_type == "client"
    assert audit.resource_id == "new-client"
    assert audit.actor_type == "operator"
    assert audit.actor_id == "ops-123"
    assert audit.actor_display == "Ops User"
    assert audit.outcome == "succeeded"
    assert audit.reason_code == "client_created"
    assert audit.metadata["client_type"] == "confidential"
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

  test "update_client/2 validates and persists post_logout_redirect_uris" do
    assert {:ok, %Client{} = client} =
             Clients.update_client("admin-client", %{
               post_logout_redirect_uris: ["https://admin.example.com/logout"]
             })

    assert client.post_logout_redirect_uris == ["https://admin.example.com/logout"]

    assert {:error, errors} =
             Clients.update_client("admin-client", %{
               post_logout_redirect_uris: ["https://*.example.com/logout"]
             })

    assert Enum.any?(
             errors,
             &(&1.field == :post_logout_redirect_uris and &1.reason == :invalid_redirect_uri)
           )
  end

  test "repository round-trips typed logout propagation fields" do
    client_id = "logout-client-#{System.unique_integer([:positive])}"

    assert {:ok, %Client{} = created} =
             Repository.register_client(%Client{
               client_id: client_id,
               client_secret_hash: "sha256:logout-salt:logout-hash",
               client_type: :confidential,
               name: "Logout Client",
               redirect_uris: ["https://logout.example.com/callback"],
               allowed_scopes: ["email"],
               allowed_grant_types: ["authorization_code", "refresh_token"],
               allowed_response_types: ["code"],
               token_endpoint_auth_method: :client_secret_basic,
               pkce_required: true,
               subject_type: :public,
               backchannel_logout_uri: "https://logout.example.com/backchannel",
               backchannel_logout_session_required: true,
               frontchannel_logout_uri: "https://logout.example.com/frontchannel",
               frontchannel_logout_session_required: true,
               created_at: DateTime.utc_now(),
               metadata: %{}
             })

    assert created.backchannel_logout_uri == "https://logout.example.com/backchannel"
    assert created.backchannel_logout_session_required == true
    assert created.frontchannel_logout_uri == "https://logout.example.com/frontchannel"
    assert created.frontchannel_logout_session_required == true

    assert {:ok, %Client{} = fetched} = Repository.fetch_client_by_id(client_id)
    assert fetched.backchannel_logout_uri == "https://logout.example.com/backchannel"
    assert fetched.backchannel_logout_session_required == true
    assert fetched.frontchannel_logout_uri == "https://logout.example.com/frontchannel"
    assert fetched.frontchannel_logout_session_required == true
  end

  test "update_client/2 persists normalized logout propagation settings" do
    assert {:ok, %Client{} = client} =
             Clients.update_client("admin-client", %{
               backchannel_logout_uri: " https://admin.example.com/backchannel ",
               backchannel_logout_session_required: "true",
               frontchannel_logout_uri: " https://admin.example.com/frontchannel ",
               frontchannel_logout_session_required: true
             })

    assert client.backchannel_logout_uri == "https://admin.example.com/backchannel"
    assert client.backchannel_logout_session_required == true
    assert client.frontchannel_logout_uri == "https://admin.example.com/frontchannel"
    assert client.frontchannel_logout_session_required == true

    assert {:ok, %Client{} = fetched} = Repository.fetch_client_by_id("admin-client")
    assert fetched.backchannel_logout_uri == "https://admin.example.com/backchannel"
    assert fetched.backchannel_logout_session_required == true
    assert fetched.frontchannel_logout_uri == "https://admin.example.com/frontchannel"
    assert fetched.frontchannel_logout_session_required == true
  end

  test "update_client/2 rejects invalid logout propagation combinations with field-specific errors" do
    assert {:error, errors} =
             Clients.update_client("admin-client", %{
               backchannel_logout_session_required: true,
               frontchannel_logout_uri: "https://logout.example.com/frontchannel#fragment",
               frontchannel_logout_session_required: true
             })

    assert Enum.any?(
             errors,
             &(&1.field == :backchannel_logout_session_required and
                 &1.reason == :logout_uri_required)
           )

    assert Enum.any?(
             errors,
             &(&1.field == :frontchannel_logout_uri and &1.reason == :invalid_logout_uri and
                 &1.detail == :fragment_not_allowed)
           )

    assert {:error, errors} =
             Clients.update_client("admin-client", %{
               frontchannel_logout_uri: "https://other.example.com/frontchannel"
             })

    assert Enum.any?(
             errors,
             &(&1.field == :frontchannel_logout_uri and
                 &1.reason == :frontchannel_logout_origin_mismatch)
           )
  end

  test "update_client/2 accepts only inherit, required, and optional for par_policy" do
    assert {:ok, %Client{} = client} =
             Clients.update_client("admin-client", %{
               par_policy: "required"
             })

    assert client.par_policy == :required

    assert {:ok, %Client{} = fetched_client} = Repository.fetch_client_by_id("admin-client")
    assert fetched_client.par_policy == :required

    assert {:ok, %Client{} = optional_client} =
             Clients.update_client("admin-client", %{
               par_policy: :optional
             })

    assert optional_client.par_policy == :optional

    assert {:ok, %Client{} = inherited_client} =
             Clients.update_client("admin-client", %{
               par_policy: :inherit
             })

    assert inherited_client.par_policy == :inherit

    assert {:error, [%{field: :par_policy, reason: :invalid_par_policy, detail: "strict"}]} =
             Clients.update_client("admin-client", %{
               par_policy: "strict"
             })
  end

  test "registered clients default to inherited DPoP policy and updates round-trip explicit modes" do
    assert {:ok, %Client{} = fetched_client} = Repository.fetch_client_by_id("admin-client")
    assert fetched_client.dpop_policy == :inherit

    assert {:ok, %Client{} = dpop_client} =
             Clients.update_client("admin-client", %{
               dpop_policy: "dpop"
             })

    assert dpop_client.dpop_policy == :dpop

    assert {:ok, %Client{} = stored_dpop_client} = Repository.fetch_client_by_id("admin-client")
    assert stored_dpop_client.dpop_policy == :dpop

    assert {:ok, %Client{} = bearer_client} =
             Clients.update_client("admin-client", %{
               dpop_policy: :bearer
             })

    assert bearer_client.dpop_policy == :bearer

    assert {:ok, %Client{} = inherited_client} =
             Clients.update_client("admin-client", %{
               dpop_policy: :inherit
             })

    assert inherited_client.dpop_policy == :inherit
  end

  test "update_client/2 accepts only inherit, bearer, and dpop for dpop_policy" do
    assert {:error, [%{field: :dpop_policy, reason: :invalid_dpop_policy, detail: "strict"}]} =
             Clients.update_client("admin-client", %{
               dpop_policy: "strict"
             })
  end

  test "update_client/2 with security_profile 'fapi_2_0_security' persists and returns :fapi_2_0_security" do
    now = DateTime.utc_now()
    Repository.publish_key(%Lockspire.Domain.SigningKey{
      kid: "fapi-update-ready",
      use: :sig,
      status: :active,
      published_at: now,
      activated_at: now,
      public_jwk: %{"kty" => "EC", "crv" => "P-256", "kid" => "fapi-update-ready", "alg" => "ES256", "use" => "sig"},
      private_jwk_encrypted: <<1>>,
      kty: :EC,
      alg: "ES256"
    })

    assert {:ok, %Client{} = client} =
             Clients.update_client("admin-client", %{
               security_profile: "fapi_2_0_security",
               actor: %{type: :operator, id: "ops-security"}
             })

    assert client.security_profile == :fapi_2_0_security

    assert {:ok, %Client{} = fetched} = Repository.fetch_client_by_id("admin-client")
    assert fetched.security_profile == :fapi_2_0_security
  end

  test "update_client/2 rejects security_profile 'fapi_2_0_security' when signing posture is not compliant" do
    # Do not publish a key for this test
    assert {:error, errors} =
             Clients.update_client("admin-client", %{
               security_profile: "fapi_2_0_security",
               actor: %{type: :operator, id: "ops-security"}
             })

    assert Enum.any?(errors, fn err ->
             err.field == :security_profile and err.reason in [:missing_compliant_active_key, :missing_compliant_publishable_key]
           end)
  end

  test "update_client/2 with security_profile 'bogus' returns error with :invalid_security_profile reason" do
    assert {:error, errors} =
             Clients.update_client("admin-client", %{
               security_profile: "bogus",
               actor: %{type: :operator, id: "ops-security"}
             })

    assert Enum.any?(errors, fn err ->
             err.field == :security_profile and err.reason == :invalid_security_profile
           end)
  end

  test "update_client/2 updating :security_profile does not clobber other mutable fields" do
    # First set redirect_uris to a known value
    assert {:ok, _} =
             Clients.update_client("admin-client", %{
               redirect_uris: ["https://admin.example.com/callback"],
               actor: %{type: :operator, id: "ops-security"}
             })

    # Now update only security_profile — redirect_uris must remain unchanged
    assert {:ok, %Client{} = client} =
             Clients.update_client("admin-client", %{
               security_profile: :none,
               actor: %{type: :operator, id: "ops-security"}
             })

    assert client.security_profile == :none
    assert client.redirect_uris == ["https://admin.example.com/callback"]

    assert {:ok, %Client{} = fetched} = Repository.fetch_client_by_id("admin-client")
    assert fetched.redirect_uris == ["https://admin.example.com/callback"]
  end

  test "rotate_client_secret/2 returns a plaintext secret once, emits telemetry, and appends operator audit" do
    assert {:ok, %{client: %Client{} = client, client_secret: secret}} =
             Clients.rotate_client_secret("admin-client", %{
               rotated_at: DateTime.utc_now(),
               actor: %{type: :operator, id: "ops-rotate", display: "Rotate User"}
             })

    assert is_binary(secret)
    refute secret == client.client_secret_hash
    assert client.last_secret_rotated_at

    assert {:ok, %Client{} = stored_client} = Repository.fetch_client_by_id("admin-client")
    assert stored_client.client_secret_hash == client.client_secret_hash
    refute stored_client.client_secret_hash == secret

    assert_received {:telemetry_event, [:lockspire, :client_secret_rotated],
                     %{client_id: "admin-client", actor_id: "ops-rotate"}}

    assert %AuditEventRecord{} = audit = latest_audit!("client_secret_rotated")
    assert audit.resource_id == "admin-client"
    assert audit.actor_id == "ops-rotate"
    assert audit.reason_code == "client_secret_rotated"
  end

  test "disable_client/2 and enable_client/2 expose queryable lifecycle state with operator evidence" do
    assert {:ok, %Client{} = disabled_client} =
             Clients.disable_client("admin-client", %{
               disabled_by: "ops@example.com",
               actor: %{type: :operator, id: "ops-disable", display: "Disable User"}
             })

    refute disabled_client.active
    assert disabled_client.disabled_by == "ops@example.com"
    assert disabled_client.disabled_at

    assert {:ok, disabled_clients} = Clients.list_clients(active: false)
    assert Enum.any?(disabled_clients, &(&1.client_id == "admin-client"))

    assert {:ok, %Client{} = enabled_client} = Clients.enable_client("admin-client")
    assert enabled_client.active
    assert is_nil(enabled_client.disabled_at)
    assert is_nil(enabled_client.disabled_by)

    assert_received {:telemetry_event, [:lockspire, :client_disabled],
                     %{client_id: "admin-client", actor_id: "ops-disable"}}

    assert %AuditEventRecord{} = audit = latest_audit!("client_disabled")
    assert audit.resource_id == "admin-client"
    assert audit.actor_id == "ops-disable"
    assert audit.metadata["disabled_by"] == "ops@example.com"
  end

  def handle_event(event, _measurements, metadata, pid) do
    send(pid, {:telemetry_event, event, metadata})
  end

  defp attach_events(pid) do
    handler_id = "admin-clients-test-#{System.unique_integer([:positive])}"

    :ok =
      :telemetry.attach_many(
        handler_id,
        [
          [:lockspire, :client_created],
          [:lockspire, :audit, :client_created],
          [:lockspire, :client_secret_rotated],
          [:lockspire, :audit, :client_secret_rotated],
          [:lockspire, :client_disabled],
          [:lockspire, :audit, :client_disabled]
        ],
        &__MODULE__.handle_event/4,
        pid
      )

    handler_id
  end

  defp latest_audit!(action) do
    Lockspire.TestRepo.one!(
      from(audit in AuditEventRecord,
        where: audit.action == ^to_string(action),
        order_by: [desc: audit.id],
        limit: 1
      )
    )
  end
end
