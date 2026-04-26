defmodule Lockspire.Protocol.DcrPolicyTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Protocol.DcrPolicy
  alias Lockspire.Protocol.DcrPolicy.Resolved

  defp open_policy do
    %ServerPolicy{
      registration_policy: :open,
      dcr_allowed_scopes: ["openid", "profile", "email"],
      dcr_allowed_grant_types: ["authorization_code", "refresh_token"],
      dcr_allowed_response_types: ["code"],
      dcr_allowed_redirect_uri_schemes: ["https"],
      dcr_allowed_redirect_uri_hosts: ["partner.example.com", "other.example.com"],
      dcr_allowed_token_endpoint_auth_methods: ["client_secret_basic", "none"],
      dcr_default_client_lifetime_seconds: 86_400,
      dcr_default_client_secret_lifetime_seconds: 7_776_000,
      dcr_default_registration_access_token_lifetime_seconds: 3_600
    }
  end

  test "resolve/3 with empty inbound returns Resolved with empty allowlists and scalar defaults" do
    assert {:ok, %Resolved{} = resolved} = DcrPolicy.resolve(open_policy(), nil, %{})

    assert resolved.allowed_scopes == []
    assert resolved.allowed_grant_types == []
    assert resolved.allowed_response_types == []
    assert resolved.allowed_redirect_uri_schemes == []
    assert resolved.allowed_redirect_uri_hosts == []
    assert resolved.allowed_token_endpoint_auth_methods == []

    # Scalar defaults are carried through verbatim (D-17: only allowlists are intersected).
    assert resolved.default_client_lifetime_seconds == 86_400
    assert resolved.default_client_secret_lifetime_seconds == 7_776_000
    assert resolved.default_registration_access_token_lifetime_seconds == 3_600
  end

  test "resolve/3 fully-narrowed inbound (scope, grant_types, response_types) intersects to itself" do
    inbound = %{
      "scope" => "openid profile",
      "grant_types" => ["authorization_code"],
      "response_types" => ["code"],
      "redirect_uris" => ["https://partner.example.com/callback"],
      "token_endpoint_auth_method" => "client_secret_basic"
    }

    assert {:ok, %Resolved{} = resolved} = DcrPolicy.resolve(open_policy(), nil, inbound)

    assert MapSet.equal?(MapSet.new(resolved.allowed_scopes), MapSet.new(["openid", "profile"]))
    assert resolved.allowed_grant_types == ["authorization_code"]
    assert resolved.allowed_response_types == ["code"]
    assert resolved.allowed_redirect_uri_schemes == ["https"]
    assert resolved.allowed_redirect_uri_hosts == ["partner.example.com"]
    assert resolved.allowed_token_endpoint_auth_methods == ["client_secret_basic"]
  end

  test "resolve/3 returns invalid_client_metadata when inbound scope exceeds server allowlist" do
    inbound = %{"scope" => "openid offline_access"}

    assert {:error, :invalid_client_metadata,
            %{field: :scope, reason: :not_in_allowlist, allowed: allowed}} =
             DcrPolicy.resolve(open_policy(), nil, inbound)

    assert "openid" in allowed
    assert "profile" in allowed
    assert "email" in allowed
    refute "offline_access" in allowed
  end

  test "resolve/3 returns invalid_client_metadata when inbound grant_types exceeds allowlist" do
    inbound = %{"grant_types" => ["authorization_code", "client_credentials"]}

    assert {:error, :invalid_client_metadata,
            %{
              field: :grant_types,
              reason: :not_in_allowlist,
              allowed: ["authorization_code", "refresh_token"]
            }} = DcrPolicy.resolve(open_policy(), nil, inbound)
  end

  test "resolve/3 returns invalid_client_metadata when redirect_uri scheme is not allowed" do
    inbound = %{"redirect_uris" => ["http://partner.example.com/callback"]}

    assert {:error, :invalid_client_metadata,
            %{field: :redirect_uri_scheme, reason: :not_in_allowlist, allowed: ["https"]}} =
             DcrPolicy.resolve(open_policy(), nil, inbound)
  end

  test "resolve/3 returns invalid_client_metadata when redirect_uri host is not allowed" do
    inbound = %{"redirect_uris" => ["https://attacker.example.com/callback"]}

    assert {:error, :invalid_client_metadata,
            %{field: :redirect_uri_host, reason: :not_in_allowlist}} =
             DcrPolicy.resolve(open_policy(), nil, inbound)
  end

  test "resolve/3 returns invalid_client_metadata when token_endpoint_auth_method is not allowed" do
    inbound = %{"token_endpoint_auth_method" => "private_key_jwt"}

    assert {:error, :invalid_client_metadata,
            %{
              field: :token_endpoint_auth_method,
              reason: :not_in_allowlist,
              allowed: allowed
            }} = DcrPolicy.resolve(open_policy(), nil, inbound)

    refute "private_key_jwt" in allowed
  end

  test "resolve/3 with IAT overrides further narrows below server allowlist" do
    inbound = %{
      "scope" => "openid profile email",
      "grant_types" => ["authorization_code", "refresh_token"]
    }

    iat_overrides = %{
      "allowed_scopes" => ["openid", "profile"],
      "allowed_grant_types" => ["authorization_code"]
    }

    assert {:ok, %Resolved{} = resolved} =
             DcrPolicy.resolve(open_policy(), iat_overrides, inbound)

    assert MapSet.equal?(MapSet.new(resolved.allowed_scopes), MapSet.new(["openid", "profile"]))
    refute "email" in resolved.allowed_scopes
    assert resolved.allowed_grant_types == ["authorization_code"]
    refute "refresh_token" in resolved.allowed_grant_types
  end

  test "resolve/3 IAT override carrying out-of-allowlist value is naturally dropped (never widens)" do
    # D-18: resolver assumes IAT overrides ⊆ server allowlist at mint time, but if a stale
    # override carries a value not in server allowlist, intersection naturally drops it.
    inbound = %{"scope" => "openid"}

    iat_overrides = %{
      # "offline_access" is NOT in server allowlist; should be dropped, not raise an error.
      "allowed_scopes" => ["openid", "offline_access"]
    }

    assert {:ok, %Resolved{} = resolved} =
             DcrPolicy.resolve(open_policy(), iat_overrides, inbound)

    assert resolved.allowed_scopes == ["openid"]
    refute "offline_access" in resolved.allowed_scopes
  end

  test "resolve/3 three-way intersection (server x IAT x inbound) returns the smallest set" do
    server = %ServerPolicy{
      registration_policy: :initial_access_token,
      dcr_allowed_scopes: ["openid", "profile", "email"],
      dcr_allowed_grant_types: ["authorization_code", "refresh_token"],
      dcr_allowed_response_types: ["code"],
      dcr_allowed_redirect_uri_schemes: ["https"],
      dcr_allowed_redirect_uri_hosts: ["partner.example.com"],
      dcr_allowed_token_endpoint_auth_methods: ["client_secret_basic", "none"]
    }

    iat = %{"allowed_scopes" => ["openid", "profile"]}
    inbound = %{"scope" => "openid email"}

    # server allows {openid, profile, email}; IAT narrows to {openid, profile};
    # inbound requests {openid, email}. Intersection is {openid}.
    # email is in server allowlist (so no error), but not in IAT override → dropped.
    assert {:ok, %Resolved{} = resolved} = DcrPolicy.resolve(server, iat, inbound)
    assert resolved.allowed_scopes == ["openid"]
  end

  test "resolve/3 short-circuits at the first failing axis (deterministic order)" do
    # If both scope and grant_types are out-of-allowlist, the first axis checked (scope)
    # is the one returned in the error.
    inbound = %{
      "scope" => "openid bad_scope",
      "grant_types" => ["bad_grant"]
    }

    assert {:error, :invalid_client_metadata, %{field: :scope}} =
             DcrPolicy.resolve(open_policy(), nil, inbound)
  end

  test "resolve/3 rejects unparseable redirect_uris (relative path)" do
    inbound = %{"redirect_uris" => ["/callback"]}

    assert {:error, :invalid_client_metadata,
            %{field: :redirect_uris, reason: :unparseable, allowed: []}} =
             DcrPolicy.resolve(open_policy(), nil, inbound)
  end

  test "resolve/3 rejects unparseable redirect_uris (empty string)" do
    inbound = %{"redirect_uris" => [""]}

    assert {:error, :invalid_client_metadata,
            %{field: :redirect_uris, reason: :unparseable, allowed: []}} =
             DcrPolicy.resolve(open_policy(), nil, inbound)
  end

  test "resolve/3 rejects unparseable redirect_uris (free text)" do
    inbound = %{"redirect_uris" => ["not a uri"]}

    assert {:error, :invalid_client_metadata,
            %{field: :redirect_uris, reason: :unparseable, allowed: []}} =
             DcrPolicy.resolve(open_policy(), nil, inbound)
  end

  test "resolve/3 rejects redirect_uris with scheme but missing host (e.g., javascript:)" do
    inbound = %{"redirect_uris" => ["javascript:alert(1)"]}

    assert {:error, :invalid_client_metadata,
            %{field: :redirect_uris, reason: :unparseable, allowed: []}} =
             DcrPolicy.resolve(open_policy(), nil, inbound)
  end

  test "resolve/3 ignores unknown inbound keys and missing optional keys" do
    inbound = %{
      "scope" => "openid",
      "client_name" => "My App",
      "logo_uri" => "https://partner.example.com/logo.png",
      "unknown_future_key" => "ignored"
    }

    assert {:ok, %Resolved{} = resolved} = DcrPolicy.resolve(open_policy(), nil, inbound)
    assert resolved.allowed_scopes == ["openid"]
  end
end
