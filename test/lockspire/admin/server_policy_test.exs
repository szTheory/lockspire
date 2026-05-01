defmodule Lockspire.Admin.ServerPolicyTest do
  use ExUnit.Case, async: false

  alias Lockspire.Admin.ServerPolicy
  alias Lockspire.Domain.ServerPolicy, as: DomainServerPolicy
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

  test "get_server_policy/0 returns an optional default when no durable row exists" do
    assert {:ok, %DomainServerPolicy{} = policy} = ServerPolicy.get_server_policy()
    assert policy.par_policy == :optional
    assert policy.dpop_policy == :bearer
  end

  test "put_server_policy/1 persists optional and required modes across fresh fetches" do
    assert {:ok, %DomainServerPolicy{} = required_policy} =
             ServerPolicy.put_server_policy(:required)

    assert required_policy.par_policy == :required

    assert {:ok, %DomainServerPolicy{} = admin_policy} = ServerPolicy.get_server_policy()
    assert admin_policy.par_policy == :required

    assert {:ok, %DomainServerPolicy{} = stored_policy} = Repository.get_server_policy()
    assert stored_policy.par_policy == :required

    assert {:ok, %DomainServerPolicy{} = optional_policy} =
             ServerPolicy.put_server_policy(:optional)

    assert optional_policy.par_policy == :optional

    assert {:ok, %DomainServerPolicy{} = fresh_policy} = Repository.get_server_policy()
    assert fresh_policy.par_policy == :optional
  end

  test "put_server_policy/1 rejects modes outside optional and required" do
    assert {:error, [%{field: :par_policy, reason: :invalid_par_policy, detail: :inherit}]} =
             ServerPolicy.put_server_policy(:inherit)
  end

  test "put_dpop_policy/1 persists bearer and dpop modes across fresh fetches" do
    assert {:ok, %DomainServerPolicy{} = dpop_policy} = ServerPolicy.put_dpop_policy(:dpop)
    assert dpop_policy.dpop_policy == :dpop

    assert {:ok, %DomainServerPolicy{} = admin_policy} = ServerPolicy.get_server_policy()
    assert admin_policy.dpop_policy == :dpop

    assert {:ok, %DomainServerPolicy{} = stored_policy} = Repository.get_server_policy()
    assert stored_policy.dpop_policy == :dpop

    assert {:ok, %DomainServerPolicy{} = bearer_policy} =
             ServerPolicy.put_dpop_policy("bearer")

    assert bearer_policy.dpop_policy == :bearer
  end

  test "put_dpop_policy/1 rejects modes outside bearer and dpop" do
    assert {:error, [%{field: :dpop_policy, reason: :invalid_dpop_policy, detail: :inherit}]} =
             ServerPolicy.put_dpop_policy(:inherit)
  end

  test "get_dcr_policy/0 returns disabled defaults when no durable row exists" do
    assert {:ok, %DomainServerPolicy{} = policy} = ServerPolicy.get_dcr_policy()
    assert policy.registration_policy == :disabled
    assert policy.dcr_allowed_scopes == []
    assert policy.dcr_allowed_grant_types == []
    assert policy.dcr_allowed_response_types == []
    assert policy.dcr_allowed_redirect_uri_schemes == []
    assert policy.dcr_allowed_redirect_uri_hosts == []
    assert policy.dcr_allowed_token_endpoint_auth_methods == []
    assert policy.dcr_default_client_lifetime_seconds == nil
    assert policy.dcr_default_client_secret_lifetime_seconds == nil
    assert policy.dcr_default_registration_access_token_lifetime_seconds == nil
  end

  test "put_dcr_policy/1 round-trip with allowlists and lifetimes" do
    attrs = %{
      registration_policy: :initial_access_token,
      dcr_allowed_scopes: ["openid", "profile"],
      dcr_allowed_grant_types: ["authorization_code", "refresh_token"],
      dcr_allowed_response_types: ["code"],
      dcr_allowed_redirect_uri_schemes: ["https"],
      dcr_allowed_redirect_uri_hosts: ["partner.example.com"],
      dcr_allowed_token_endpoint_auth_methods: ["client_secret_basic"],
      dcr_default_client_lifetime_seconds: 86_400,
      dcr_default_client_secret_lifetime_seconds: 7_776_000,
      dcr_default_registration_access_token_lifetime_seconds: 3_600
    }

    assert {:ok, %DomainServerPolicy{} = persisted} = ServerPolicy.put_dcr_policy(attrs)
    assert persisted.registration_policy == :initial_access_token
    assert persisted.dcr_allowed_scopes == ["openid", "profile"]
    assert persisted.dcr_default_client_lifetime_seconds == 86_400

    assert {:ok, %DomainServerPolicy{} = admin_view} = ServerPolicy.get_dcr_policy()
    assert admin_view.registration_policy == :initial_access_token
    assert admin_view.dcr_allowed_grant_types == ["authorization_code", "refresh_token"]
    assert admin_view.dcr_allowed_token_endpoint_auth_methods == ["client_secret_basic"]

    assert {:ok, %DomainServerPolicy{} = stored} = Repository.get_server_policy()
    assert stored.registration_policy == :initial_access_token
    assert stored.dcr_allowed_redirect_uri_hosts == ["partner.example.com"]
  end

  test "put_dcr_policy/1 preserves par_policy on the same singleton row" do
    assert {:ok, %DomainServerPolicy{par_policy: :required}} =
             ServerPolicy.put_server_policy(:required)

    assert {:ok, %DomainServerPolicy{} = persisted} =
             ServerPolicy.put_dcr_policy(%{registration_policy: :open})

    assert persisted.par_policy == :required
    assert persisted.registration_policy == :open

    assert {:ok, %DomainServerPolicy{} = fresh} = Repository.get_server_policy()
    assert fresh.par_policy == :required
    assert fresh.registration_policy == :open
  end

  test "put_server_policy/1 preserves DCR fields when called after put_dcr_policy/1" do
    assert {:ok, _} =
             ServerPolicy.put_dcr_policy(%{
               registration_policy: :initial_access_token,
               dcr_allowed_scopes: ["openid"]
             })

    assert {:ok, %DomainServerPolicy{} = after_par} = ServerPolicy.put_server_policy(:required)
    assert after_par.par_policy == :required
    assert after_par.registration_policy == :initial_access_token
    assert after_par.dcr_allowed_scopes == ["openid"]
  end

  test "put_dcr_policy/1 rejects invalid registration_policy with structured error" do
    assert {:error,
            [%{field: :registration_policy, reason: :invalid_registration_policy, detail: :bogus}]} =
             ServerPolicy.put_dcr_policy(%{registration_policy: :bogus})
  end

  test "concurrent put_server_policy/1 and put_dcr_policy/1 do not lose updates" do
    # Seed an initial baseline so both setters update an existing row.
    assert {:ok, _} =
             ServerPolicy.put_dcr_policy(%{
               registration_policy: :open,
               dcr_allowed_scopes: ["openid"]
             })

    # Drive interleaved writes from multiple processes. Each task uses its own sandbox
    # checkout (allow_concurrency through `Sandbox.allow/3`) so the read-merge-write
    # cycles can race the way they would in production.
    parent = self()

    tasks =
      for i <- 1..16 do
        Task.async(fn ->
          :ok = Ecto.Adapters.SQL.Sandbox.allow(Lockspire.TestRepo, parent, self())

          if rem(i, 2) == 0 do
            ServerPolicy.put_server_policy(:required)
          else
            ServerPolicy.put_dcr_policy(%{registration_policy: :initial_access_token})
          end
        end)
      end

    for task <- tasks do
      assert {:ok, %DomainServerPolicy{}} = Task.await(task, 5_000)
    end

    # After all writes settle, both fields must reflect the *last* successful write of each
    # axis — not a stale value reverted by a concurrent read-merge-write race. The
    # update_server_policy/1 mutator runs under FOR UPDATE so each task observes the
    # latest committed state before merging its own delta.
    assert {:ok, %DomainServerPolicy{} = final} = Repository.get_server_policy()
    assert final.par_policy == :required
    assert final.registration_policy == :initial_access_token
    assert final.dcr_allowed_scopes == ["openid"]
  end

  test "put_dcr_policy/1 accepts string-keyed input (admin form simulation)" do
    attrs = %{
      "registration_policy" => "open",
      "dcr_allowed_scopes" => ["openid"],
      "dcr_allowed_grant_types" => ["authorization_code"]
    }

    assert {:ok, %DomainServerPolicy{} = persisted} = ServerPolicy.put_dcr_policy(attrs)
    assert persisted.registration_policy == :open
    assert persisted.dcr_allowed_scopes == ["openid"]
    assert persisted.dcr_allowed_grant_types == ["authorization_code"]
  end

  # security_profile admin command tests (Phase 41 Task 3)

  test "put_security_profile/1 persists :fapi_2_0_security and returns updated policy" do
    assert {:ok, %DomainServerPolicy{} = policy} =
             ServerPolicy.put_security_profile(:fapi_2_0_security)

    assert policy.security_profile == :fapi_2_0_security

    assert {:ok, %DomainServerPolicy{} = stored} = Repository.get_server_policy()
    assert stored.security_profile == :fapi_2_0_security
  end

  test "put_security_profile/1 accepts string form 'none' from LiveView form post" do
    assert {:ok, %DomainServerPolicy{} = policy} = ServerPolicy.put_security_profile("none")

    assert policy.security_profile == :none
  end

  test "put_security_profile/1 rejects unknown atom :strict with canonical error shape" do
    assert {:error,
            [
              %{
                field: :security_profile,
                reason: :invalid_security_profile,
                detail: :strict
              }
            ]} = ServerPolicy.put_security_profile(:strict)
  end

  test "Lockspire.Admin.put_security_profile/1 is delegated to Admin.ServerPolicy (facade test)" do
    assert {:ok, %DomainServerPolicy{} = policy} =
             Lockspire.Admin.put_security_profile(:fapi_2_0_security)

    assert policy.security_profile == :fapi_2_0_security
  end
end
