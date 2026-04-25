defmodule Lockspire.JarTestHelpers do
  @moduledoc false

  # Test-only helpers for signing JAR (RFC 9101 request object) JWTs and
  # registering matching client JWKs. Used by:
  #
  # - test/lockspire/protocol/jar_test.exs (Phase 21 + Plan 22-01 extensions)
  # - test/lockspire/protocol/authorization_request_test.exs (Plan 22-04)
  # - test/lockspire/protocol/pushed_authorization_request_test.exs (Plan 22-05)
  # - test/lockspire/web/authorize_controller_test.exs (Plan 22-06)
  # - test/integration/phase15_par_authorization_e2e_test.exs (Plan 22-07)
  #
  # Compiled in the :test env via mix.exs's `elixirc_paths(:test) -> ["lib", "test/support"]`.
  # Mirrors test/support/endpoint.ex's plain-module shape - no `use ExUnit.Case`,
  # no setup callbacks; just public functions callers `alias` and call directly.

  alias Lockspire.Domain.Client

  @doc """
  Generates an RSA-2048 keypair plus the JOSE pub/priv map forms.

  Returns `%{private_jwk: %JOSE.JWK{}, pub_jwk_map: map(), priv_jwk_map: map()}`.
  """
  @spec generate_keys() :: %{
          required(:private_jwk) => JOSE.JWK.t(),
          required(:pub_jwk_map) => map(),
          required(:priv_jwk_map) => map()
        }
  def generate_keys do
    private_jwk = JOSE.JWK.generate_key({:rsa, 2048})
    {_modules, pub_jwk_map} = JOSE.JWK.to_public_map(private_jwk)
    {_modules, priv_jwk_map} = JOSE.JWK.to_map(private_jwk)
    %{private_jwk: private_jwk, pub_jwk_map: pub_jwk_map, priv_jwk_map: priv_jwk_map}
  end

  @doc """
  Signs a claim map as a compact-serialized JWT.

  Options:
  - `:alg` (binary) - JWS algorithm; defaults to `"RS256"`.
  - `:extra_header` (map) - additional protected-header fields (e.g. `%{"typ" => "oauth-authz-req+jwt"}`).
  """
  @spec sign_jar(JOSE.JWK.t(), map(), keyword()) :: String.t()
  def sign_jar(private_jwk, claims, opts \\ []) when is_map(claims) and is_list(opts) do
    alg = Keyword.get(opts, :alg, "RS256")
    extra_header = Keyword.get(opts, :extra_header, %{})
    header = Map.merge(%{"alg" => alg}, extra_header)

    private_jwk
    |> JOSE.JWT.sign(header, claims)
    |> JOSE.JWS.compact()
    |> elem(1)
  end

  @doc "Returns a `%Client{}` with a single inline public JWK (RFC 7517 form)."
  @spec client_with_single_jwk(map()) :: Client.t()
  def client_with_single_jwk(pub_jwk_map) when is_map(pub_jwk_map) do
    %Client{jwks: pub_jwk_map}
  end

  @doc "Returns a `%Client{}` with a JWK Set containing one public key."
  @spec client_with_jwks_set(map()) :: Client.t()
  def client_with_jwks_set(pub_jwk_map) when is_map(pub_jwk_map) do
    %Client{jwks: %{"keys" => [pub_jwk_map]}}
  end
end
