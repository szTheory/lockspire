defmodule Lockspire.Test.Fixtures.DcrFixtures do
  @moduledoc """
  RFC 7591 inbound metadata fixtures + `Lockspire.Protocol.Registration.register/1`
  request-tuple builder for Phase 26 protocol-module tests.

  Each metadata function targets a specific D-14 / D-15 validator axis. Helpers
  use STRING keys (the RFC 7591 wire format is JSON; the validator must handle
  string keys at intake).
  """

  alias Lockspire.Domain.ServerPolicy

  @valid_metadata %{
    "client_name" => "Phase-26 fixture client",
    "redirect_uris" => ["https://app.example.test/callback"],
    "grant_types" => ["authorization_code", "refresh_token"],
    "response_types" => ["code"],
    "token_endpoint_auth_method" => "client_secret_basic",
    "scope" => "openid profile"
  }

  @spec valid_metadata() :: map()
  def valid_metadata, do: @valid_metadata

  @spec invalid_jwks_uri_metadata() :: map()
  def invalid_jwks_uri_metadata do
    Map.put(@valid_metadata, "jwks_uri", "https://app.example.test/.well-known/jwks.json")
  end

  @spec mutual_jwks_metadata() :: map()
  def mutual_jwks_metadata do
    @valid_metadata
    |> Map.put("jwks", %{"keys" => []})
    |> Map.put("jwks_uri", "https://app.example.test/.well-known/jwks.json")
  end

  @spec incoherent_grant_response_metadata() :: map()
  def incoherent_grant_response_metadata do
    # refresh_token without authorization_code — RFC 7591 §2 coherence violation
    @valid_metadata
    |> Map.put("grant_types", ["refresh_token"])
    |> Map.put("response_types", ["code"])
  end

  @spec invalid_redirect_uri_metadata() :: map()
  def invalid_redirect_uri_metadata do
    # ftp:// is rejected by Lockspire.Clients.validate_redirect_uris/1
    Map.put(@valid_metadata, "redirect_uris", ["ftp://app.example.test/callback"])
  end

  @spec pkce_required_false_metadata() :: map()
  def pkce_required_false_metadata do
    Map.put(@valid_metadata, "pkce_required", false)
  end

  @spec server_policy(map()) :: ServerPolicy.t()
  def server_policy(attrs \\ %{}) when is_map(attrs) do
    base = %ServerPolicy{
      registration_policy: :open,
      dcr_allowed_grant_types: ["authorization_code", "refresh_token"],
      dcr_allowed_response_types: ["code"],
      dcr_allowed_token_endpoint_auth_methods: [
        "client_secret_basic",
        "client_secret_post",
        "none"
      ],
      dcr_allowed_redirect_uri_hosts: ["app.example.test"],
      dcr_allowed_redirect_uri_schemes: ["https"],
      dcr_allowed_scopes: ["openid", "profile", "email"],
      dcr_default_client_lifetime_seconds: 365 * 24 * 3600,
      dcr_default_client_secret_lifetime_seconds: 90 * 24 * 3600,
      dcr_default_registration_access_token_lifetime_seconds: 30 * 24 * 3600
    }

    struct!(base, attrs)
  end

  @spec register_request(keyword()) :: map()
  def register_request(opts \\ []) do
    %{
      metadata: Keyword.get(opts, :metadata, valid_metadata()),
      iat: Keyword.get(opts, :iat, nil),
      server_policy: Keyword.get(opts, :server_policy, server_policy(%{})),
      source: Keyword.get(opts, :source, %{ip: "127.0.0.1", user_agent: "test"})
    }
  end
end
