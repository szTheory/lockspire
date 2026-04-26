defmodule Lockspire.Storage.Ecto.ServerPolicyRecordTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Storage.Ecto.ServerPolicyRecord

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

  test "round-trip persists and reloads all DCR fields with Ecto.Enum atoms" do
    repo = Lockspire.TestRepo

    domain = %ServerPolicy{
      id: ServerPolicyRecord.singleton_id(),
      par_policy: :optional,
      registration_policy: :initial_access_token,
      dcr_allowed_scopes: ["openid", "profile"],
      dcr_allowed_grant_types: ["authorization_code", "refresh_token"],
      dcr_allowed_response_types: ["code"],
      dcr_allowed_redirect_uri_schemes: ["https"],
      dcr_allowed_redirect_uri_hosts: ["partner.example.com"],
      dcr_allowed_token_endpoint_auth_methods: ["client_secret_basic", "none"],
      dcr_default_client_lifetime_seconds: 86_400,
      dcr_default_client_secret_lifetime_seconds: 7_776_000,
      dcr_default_registration_access_token_lifetime_seconds: 3_600
    }

    {:ok, inserted} =
      %ServerPolicyRecord{}
      |> ServerPolicyRecord.changeset(domain)
      |> repo.insert()

    reloaded = repo.get!(ServerPolicyRecord, inserted.id)
    out = ServerPolicyRecord.to_domain(reloaded)

    assert out.registration_policy == :initial_access_token
    assert out.dcr_allowed_scopes == ["openid", "profile"]
    assert out.dcr_allowed_grant_types == ["authorization_code", "refresh_token"]
    assert out.dcr_allowed_response_types == ["code"]
    assert out.dcr_allowed_redirect_uri_schemes == ["https"]
    assert out.dcr_allowed_redirect_uri_hosts == ["partner.example.com"]
    assert out.dcr_allowed_token_endpoint_auth_methods == ["client_secret_basic", "none"]
    assert out.dcr_default_client_lifetime_seconds == 86_400
    assert out.dcr_default_client_secret_lifetime_seconds == 7_776_000
    assert out.dcr_default_registration_access_token_lifetime_seconds == 3_600
    # par_policy still works
    assert out.par_policy == :optional
  end

  test "default insert (no DCR fields supplied) backfills from defaults" do
    repo = Lockspire.TestRepo

    domain = %ServerPolicy{id: ServerPolicyRecord.singleton_id()}

    {:ok, inserted} =
      %ServerPolicyRecord{}
      |> ServerPolicyRecord.changeset(domain)
      |> repo.insert()

    out = ServerPolicyRecord.to_domain(repo.get!(ServerPolicyRecord, inserted.id))

    assert out.registration_policy == :disabled
    assert out.dcr_allowed_scopes == []
    assert out.dcr_allowed_grant_types == []
    assert out.dcr_allowed_response_types == []
    assert out.dcr_allowed_redirect_uri_schemes == []
    assert out.dcr_allowed_redirect_uri_hosts == []
    assert out.dcr_allowed_token_endpoint_auth_methods == []
    assert out.dcr_default_client_lifetime_seconds == nil
    assert out.dcr_default_client_secret_lifetime_seconds == nil
    assert out.dcr_default_registration_access_token_lifetime_seconds == nil
  end
end
