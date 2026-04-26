defmodule Lockspire.Storage.Ecto.ClientRecordTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.ClientRecord

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

  test "self-registered client round-trips provenance + RAT/IAT/timestamp fields" do
    repo = Lockspire.TestRepo
    issued_at = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    expires_at = DateTime.add(issued_at, 7_776_000, :second)

    client = %Client{
      client_id: "dcr_client_round_trip",
      client_type: :confidential,
      redirect_uris: ["https://partner.example.com/callback"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      active: true,
      provenance: :self_registered,
      registration_access_token_hash: "rat_hash_round_trip",
      registration_client_uri: "https://issuer.example.com/register/dcr_client_round_trip",
      initial_access_token_id: nil,
      client_id_issued_at: issued_at,
      client_secret_expires_at: expires_at
    }

    {:ok, inserted} =
      %ClientRecord{}
      |> ClientRecord.changeset(client)
      |> repo.insert()

    out = ClientRecord.to_domain(repo.get!(ClientRecord, inserted.id))

    assert out.provenance == :self_registered
    assert out.registration_access_token_hash == "rat_hash_round_trip"

    assert out.registration_client_uri ==
             "https://issuer.example.com/register/dcr_client_round_trip"

    assert out.initial_access_token_id == nil
    assert DateTime.compare(out.client_id_issued_at, issued_at) == :eq
    assert DateTime.compare(out.client_secret_expires_at, expires_at) == :eq
  end

  test "default provenance is :operator (matches column default)" do
    repo = Lockspire.TestRepo

    client = %Client{
      client_id: "operator_client_default",
      client_type: :confidential,
      redirect_uris: ["https://app.example.com/cb"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      active: true
    }

    {:ok, inserted} =
      %ClientRecord{}
      |> ClientRecord.changeset(client)
      |> repo.insert()

    out = ClientRecord.to_domain(repo.get!(ClientRecord, inserted.id))

    assert out.provenance == :operator
  end

  test "update_changeset/2 does NOT cast :provenance (provenance is create-time only)" do
    repo = Lockspire.TestRepo

    client = %Client{
      client_id: "operator_client_update_test",
      client_type: :confidential,
      redirect_uris: ["https://app.example.com/cb"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      active: true,
      provenance: :operator
    }

    {:ok, inserted} =
      %ClientRecord{}
      |> ClientRecord.changeset(client)
      |> repo.insert()

    # Attempt to mutate provenance via update_changeset/2 — must be silently ignored.
    {:ok, updated} =
      inserted
      |> ClientRecord.update_changeset(%{
        provenance: :self_registered,
        name: "renamed",
        redirect_uris: ["https://app.example.com/cb"],
        allowed_scopes: ["openid"],
        active: true
      })
      |> repo.update()

    out = ClientRecord.to_domain(repo.get!(ClientRecord, updated.id))
    assert out.provenance == :operator, "update_changeset/2 must not allow provenance mutation"
    assert out.name == "renamed", "update_changeset/2 still updates other allowed fields"
  end
end
