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
      client_secret_jwt_verifier_encrypted: "sealed-dcr-verifier",
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
    assert out.client_secret_jwt_verifier_encrypted == "sealed-dcr-verifier"

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

  test "MTLS attributes round-trip through ClientRecord" do
    repo = Lockspire.TestRepo

    client = %Client{
      client_id: "mtls_client_round_trip",
      client_type: :confidential,
      redirect_uris: ["https://app.example.com/cb"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :tls_client_auth,
      pkce_required: true,
      subject_type: :public,
      active: true,
      tls_client_auth_subject_dn: "CN=client.example.com",
      tls_client_auth_san_dns: "client.example.com",
      tls_client_auth_san_uri: "https://client.example.com",
      tls_client_auth_san_ip: "192.168.1.1",
      tls_client_auth_san_email: "admin@example.com"
    }

    {:ok, inserted} =
      %ClientRecord{}
      |> ClientRecord.changeset(client)
      |> repo.insert()

    out = ClientRecord.to_domain(repo.get!(ClientRecord, inserted.id))

    assert out.token_endpoint_auth_method == :tls_client_auth
    assert out.tls_client_auth_subject_dn == "CN=client.example.com"
    assert out.tls_client_auth_san_dns == "client.example.com"
    assert out.tls_client_auth_san_uri == "https://client.example.com"
    assert out.tls_client_auth_san_ip == "192.168.1.1"
    assert out.tls_client_auth_san_email == "admin@example.com"
  end

  test "logout propagation fields round-trip through ClientRecord" do
    repo = Lockspire.TestRepo

    client = %Client{
      client_id: "logout_round_trip",
      client_type: :confidential,
      redirect_uris: ["https://app.example.test/callback"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      active: true,
      backchannel_logout_uri: "https://rp.example.test/backchannel-logout",
      backchannel_logout_session_required: true,
      frontchannel_logout_uri: "https://app.example.test/frontchannel-logout",
      frontchannel_logout_session_required: true
    }

    {:ok, inserted} =
      %ClientRecord{}
      |> ClientRecord.changeset(client)
      |> repo.insert()

    out = ClientRecord.to_domain(repo.get!(ClientRecord, inserted.id))

    assert out.backchannel_logout_uri == "https://rp.example.test/backchannel-logout"
    assert out.backchannel_logout_session_required == true
    assert out.frontchannel_logout_uri == "https://app.example.test/frontchannel-logout"
    assert out.frontchannel_logout_session_required == true
    assert out.metadata == %{}
  end

  test "client_secret_jwt verifier material round-trips and updates through persistence" do
    repo = Lockspire.TestRepo

    client = %Client{
      client_id: "client_secret_jwt_verifier_round_trip",
      client_type: :confidential,
      client_secret_hash: "sha256:salt:hash",
      client_secret_jwt_verifier_encrypted: "sealed-initial",
      token_endpoint_auth_signing_alg: :HS256,
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

    assert repo.get!(ClientRecord, inserted.id).client_secret_jwt_verifier_encrypted ==
             "sealed-initial"

    assert repo.get!(ClientRecord, inserted.id).token_endpoint_auth_signing_alg == :HS256

    {:ok, updated} =
      inserted
      |> ClientRecord.changeset(%Client{
        ClientRecord.to_domain(inserted)
        | client_secret_jwt_verifier_encrypted: "sealed-rotated",
          token_endpoint_auth_signing_alg: :RS256
      })
      |> repo.update()

    out = ClientRecord.to_domain(repo.get!(ClientRecord, updated.id))
    assert out.client_secret_jwt_verifier_encrypted == "sealed-rotated"
    assert out.token_endpoint_auth_signing_alg == :RS256
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

  test "authorization response encryption metadata round-trips through persistence" do
    repo = Lockspire.TestRepo

    client = %Client{
      client_id: "jarm_encryption_round_trip",
      client_type: :confidential,
      redirect_uris: ["https://app.example.com/cb"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :private_key_jwt,
      pkce_required: true,
      subject_type: :public,
      active: true,
      authorization_signed_response_alg: :RS256,
      authorization_encrypted_response_alg: :RSA_OAEP_256,
      authorization_encrypted_response_enc: :A256GCM,
      jwks: %{"keys" => [%{"kty" => "RSA", "kid" => "enc-1"}]}
    }

    {:ok, inserted} =
      %ClientRecord{}
      |> ClientRecord.changeset(client)
      |> repo.insert()

    out = ClientRecord.to_domain(repo.get!(ClientRecord, inserted.id))

    assert out.authorization_signed_response_alg == :RS256
    assert out.authorization_encrypted_response_alg == :RSA_OAEP_256
    assert out.authorization_encrypted_response_enc == :A256GCM
  end

  test "changeset/2 and update_changeset/2 accept only the narrow JARM encryption allow-list" do
    repo = Lockspire.TestRepo

    valid_client = %Client{
      client_id: "jarm_encryption_valid_algs",
      client_type: :confidential,
      redirect_uris: ["https://app.example.com/cb"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :private_key_jwt,
      pkce_required: true,
      subject_type: :public,
      active: true,
      authorization_signed_response_alg: :RS256,
      authorization_encrypted_response_alg: :ECDH_ES,
      authorization_encrypted_response_enc: :A128GCM,
      jwks: %{"keys" => [%{"kty" => "EC", "kid" => "enc-2"}]}
    }

    assert ClientRecord.changeset(%ClientRecord{}, valid_client).valid?

    {:ok, inserted} =
      %ClientRecord{}
      |> ClientRecord.changeset(valid_client)
      |> repo.insert()

    valid_update =
      ClientRecord.update_changeset(inserted, %{
        redirect_uris: ["https://app.example.com/cb"],
        allowed_scopes: ["openid"],
        active: true,
        authorization_encrypted_response_alg: "RSA_OAEP_256",
        authorization_encrypted_response_enc: "A256GCM"
      })

    assert valid_update.valid?

    invalid_alg =
      ClientRecord.changeset(%ClientRecord{}, %{
        valid_client
        | client_id: "jarm_encryption_invalid_alg",
          authorization_encrypted_response_alg: :RSA1_5
      })

    refute invalid_alg.valid?
    assert Keyword.has_key?(invalid_alg.errors, :authorization_encrypted_response_alg)

    invalid_enc =
      ClientRecord.update_changeset(inserted, %{
        redirect_uris: ["https://app.example.com/cb"],
        allowed_scopes: ["openid"],
        active: true,
        authorization_encrypted_response_enc: "A128CBC_HS256"
      })

    refute invalid_enc.valid?
    assert Keyword.has_key?(invalid_enc.errors, :authorization_encrypted_response_enc)
  end

  test "persisted clients without authorization response encryption metadata remain valid" do
    repo = Lockspire.TestRepo

    client = %Client{
      client_id: "jarm_encryption_optional",
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

    assert out.authorization_encrypted_response_alg == nil
    assert out.authorization_encrypted_response_enc == nil
    assert out.token_endpoint_auth_method == :client_secret_basic
  end

  # security_profile field tests (Phase 41)

  test "changeset/2 accepts :fapi_2_0_security security_profile and is valid" do
    client = %Client{
      client_id: "fapi_client_changeset_test",
      client_type: :confidential,
      redirect_uris: ["https://app.example.com/cb"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      active: true,
      security_profile: :fapi_2_0_security
    }

    changeset = ClientRecord.changeset(%ClientRecord{}, client)

    assert changeset.valid?
    assert Ecto.Changeset.get_change(changeset, :security_profile) == :fapi_2_0_security
  end

  test "changeset/2 accepts :fapi_2_0_message_signing security_profile and is valid" do
    client = %Client{
      client_id: "fapi_message_signing_client_changeset_test",
      client_type: :confidential,
      redirect_uris: ["https://app.example.com/cb"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      active: true,
      security_profile: :fapi_2_0_message_signing
    }

    changeset = ClientRecord.changeset(%ClientRecord{}, client)

    assert changeset.valid?
    assert Ecto.Changeset.get_change(changeset, :security_profile) == :fapi_2_0_message_signing
  end

  test "changeset/2 with default :inherit security_profile round-trips through to_domain/1" do
    repo = Lockspire.TestRepo

    client = %Client{
      client_id: "inherit_security_profile_client",
      client_type: :confidential,
      redirect_uris: ["https://app.example.com/cb"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      active: true,
      security_profile: :inherit
    }

    {:ok, inserted} =
      %ClientRecord{}
      |> ClientRecord.changeset(client)
      |> repo.insert()

    out = ClientRecord.to_domain(repo.get!(ClientRecord, inserted.id))

    assert out.security_profile == :inherit
  end

  test "update_changeset/2 with security_profile 'fapi_2_0_security' string is valid and sets the field" do
    repo = Lockspire.TestRepo

    client = %Client{
      client_id: "update_security_profile_client",
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

    # Critical: :security_profile MUST be in update_changeset/2 cast whitelist.
    {:ok, updated} =
      inserted
      |> ClientRecord.update_changeset(%{
        security_profile: "fapi_2_0_security",
        redirect_uris: ["https://app.example.com/cb"],
        allowed_scopes: ["openid"],
        active: true
      })
      |> repo.update()

    out = ClientRecord.to_domain(repo.get!(ClientRecord, updated.id))

    assert out.security_profile == :fapi_2_0_security,
           "update_changeset/2 must include :security_profile in cast whitelist"
  end

  test "update_changeset/2 with security_profile 'bogus' fails the changeset" do
    repo = Lockspire.TestRepo

    client = %Client{
      client_id: "bogus_security_profile_client",
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

    changeset =
      ClientRecord.update_changeset(inserted, %{
        security_profile: "bogus",
        redirect_uris: ["https://app.example.com/cb"],
        allowed_scopes: ["openid"],
        active: true
      })

    refute changeset.valid?
    assert Keyword.has_key?(changeset.errors, :security_profile)
  end

  test "changeset/2 rejects RS256 id_token_signed_response_alg when fapi_2_0_security is enabled" do
    client = %Client{
      client_id: "fapi_rs256_client",
      client_type: :confidential,
      redirect_uris: ["https://app.example.com/cb"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      active: true,
      security_profile: :fapi_2_0_security,
      id_token_signed_response_alg: :RS256
    }

    changeset = ClientRecord.changeset(%ClientRecord{}, client)

    refute changeset.valid?
    assert Keyword.has_key?(changeset.errors, :id_token_signed_response_alg)
  end

  test "update_changeset/2 rejects RS256 id_token_signed_response_alg when fapi_2_0_security is enabled" do
    repo = Lockspire.TestRepo

    client = %Client{
      client_id: "update_fapi_rs256_client",
      client_type: :confidential,
      redirect_uris: ["https://app.example.com/cb"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      active: true,
      security_profile: :fapi_2_0_security,
      id_token_signed_response_alg: :ES256
    }

    {:ok, inserted} =
      %ClientRecord{}
      |> ClientRecord.changeset(client)
      |> repo.insert()

    changeset =
      ClientRecord.update_changeset(inserted, %{
        id_token_signed_response_alg: "RS256"
      })

    refute changeset.valid?
    assert Keyword.has_key?(changeset.errors, :id_token_signed_response_alg)
  end

  test "changeset/2 rejects RS256 id_token_signed_response_alg when fapi_2_0_message_signing is enabled" do
    client = %Client{
      client_id: "fapi_message_signing_rs256_client",
      client_type: :confidential,
      redirect_uris: ["https://app.example.com/cb"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      active: true,
      security_profile: :fapi_2_0_message_signing,
      id_token_signed_response_alg: :RS256
    }

    changeset = ClientRecord.changeset(%ClientRecord{}, client)

    refute changeset.valid?
    assert Keyword.has_key?(changeset.errors, :id_token_signed_response_alg)
  end

  test "update_changeset/2 allows RS256 id_token_signed_response_alg when security_profile is not fapi_2_0_security" do
    repo = Lockspire.TestRepo

    client = %Client{
      client_id: "update_none_rs256_client",
      client_type: :confidential,
      redirect_uris: ["https://app.example.com/cb"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      active: true,
      security_profile: :none,
      id_token_signed_response_alg: :ES256
    }

    {:ok, inserted} =
      %ClientRecord{}
      |> ClientRecord.changeset(client)
      |> repo.insert()

    changeset =
      ClientRecord.update_changeset(inserted, %{
        id_token_signed_response_alg: "RS256"
      })

    assert changeset.valid?
  end

  # access_token_format field tests (Phase 99 Task 3)

  test "a new Client struct defaults access_token_format to nil (inherit)" do
    assert %Client{}.access_token_format == nil
  end

  test "changeset/2 casting access_token_format \"opaque\" yields :opaque" do
    client = %Client{
      client_id: "atf_changeset_opaque",
      client_type: :confidential,
      redirect_uris: ["https://app.example.com/cb"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      active: true,
      access_token_format: :opaque
    }

    changeset = ClientRecord.changeset(%ClientRecord{}, client)

    assert changeset.valid?
    assert Ecto.Changeset.get_field(changeset, :access_token_format) == :opaque
  end

  test "update_changeset/2 (admin-mutable path) casting access_token_format \"jwt\" yields :jwt" do
    repo = Lockspire.TestRepo

    client = %Client{
      client_id: "atf_update_jwt",
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

    # Critical: :access_token_format MUST be in update_changeset/2 cast whitelist
    # (the admin-mutable path).
    {:ok, updated} =
      inserted
      |> ClientRecord.update_changeset(%{
        access_token_format: "jwt",
        redirect_uris: ["https://app.example.com/cb"],
        allowed_scopes: ["openid"],
        active: true
      })
      |> repo.update()

    out = ClientRecord.to_domain(repo.get!(ClientRecord, updated.id))

    assert out.access_token_format == :jwt,
           "update_changeset/2 must include :access_token_format in cast whitelist"
  end

  test "to_domain/1 maps a nil access_token_format record onto a nil domain value" do
    repo = Lockspire.TestRepo

    client = %Client{
      client_id: "atf_inherit_nil",
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

    assert out.access_token_format == nil
  end

  test "access_token_format round-trips :jwt through changeset/2 and to_domain/1" do
    repo = Lockspire.TestRepo

    client = %Client{
      client_id: "atf_changeset_jwt_round_trip",
      client_type: :confidential,
      redirect_uris: ["https://app.example.com/cb"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      active: true,
      access_token_format: :jwt
    }

    {:ok, inserted} =
      %ClientRecord{}
      |> ClientRecord.changeset(client)
      |> repo.insert()

    out = ClientRecord.to_domain(repo.get!(ClientRecord, inserted.id))

    assert out.access_token_format == :jwt
  end
end
