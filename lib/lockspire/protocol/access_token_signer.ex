defmodule Lockspire.Protocol.AccessTokenSigner do
  @moduledoc """
  Shared access-token issuance for all Lockspire grant paths.

  Owns the single RFC 9068 `at+jwt` signing site, the opaque-token delegate, and
  the one-place format decision (per-client override -> server default -> `:jwt`).

  ## Format resolution

  The effective access-token format is resolved in exactly one place
  (`resolve_format/2`):

    1. a per-client `access_token_format` of `:jwt` or `:opaque` wins;
    2. otherwise (`nil`) the server-wide `ServerPolicy.access_token_format`
       read via `request.opts[:server_policy_store]` is used;
    3. otherwise it falls back to `:jwt`.

  ## Audience derivation

  The four grant paths (authorization-code, refresh, device-code, CIBA) emit a
  LIST `aud`: the requested resource(s) when present, otherwise `[client_id]`.
  The RFC 8693 token-exchange path keeps a BARE-STRING `aud == client_id` via
  `issue_exchange/4`, preserving the historical exchange wire shape.

  ## Security

  The signing `alg`/`kid` are taken ONLY from the active signing key — never from
  client-controlled input — and `none` is never emitted. On a missing or invalid
  key the error path logs `inspect(reason)` only: no key material reaches logs.
  """

  require Logger

  alias Lockspire.Config
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenExchange.Error
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Security.Policy

  @access_token_ttl_seconds 3600

  @type result :: {:ok, String.t(), String.t()} | {:error, Error.t()}

  @doc """
  Issue an access token for a standard grant path.

  Resolves the effective format and returns `{:ok, raw, hash}` where
  `hash == Lockspire.Security.Policy.hash_token(raw)`, or a 500
  `:token_signing_failed` error when the `:jwt` branch cannot sign.

  The `:jwt` branch emits a LIST `aud` derived from `token.audience`.
  """
  @spec issue(Token.t(), Client.t(), map()) :: result()
  def issue(%Token{} = token, %Client{} = client, request) do
    case resolve_format(client, server_policy(request)) do
      :opaque ->
        format_opaque(request)

      :jwt ->
        aud = derive_aud(token.audience, client.client_id)
        claims = base_claims(token, client, aud)
        sign_jwt(claims, request)
    end
  end

  @doc """
  Issue a signed `at+jwt` access token for the RFC 8693 token-exchange path.

  Always `:jwt`. Emits a BARE-STRING `aud == client.client_id` (the exchange
  carve-out) and merges `custom_claims` over the base claims after dropping the
  restricted claims `iss sub aud exp iat jti client_id`.
  """
  @spec issue_exchange(Token.t(), Client.t(), map(), map()) :: result()
  def issue_exchange(%Token{} = token, %Client{} = client, custom_claims, request)
      when is_map(custom_claims) do
    base = base_claims(token, client, client.client_id)
    safe_custom_claims = Map.drop(custom_claims, ~w(iss sub aud exp iat jti client_id))
    claims = Map.merge(base, safe_custom_claims)
    sign_jwt(claims, request)
  end

  # --------------------------------------------------------------------------
  # Format resolution — one place (per-client override -> server default -> :jwt)
  # --------------------------------------------------------------------------

  @spec resolve_format(Client.t(), ServerPolicy.t() | nil) :: :jwt | :opaque
  defp resolve_format(%Client{access_token_format: fmt}, _server_policy)
       when fmt in [:jwt, :opaque],
       do: fmt

  defp resolve_format(%Client{access_token_format: nil}, %ServerPolicy{
         access_token_format: server_fmt
       }),
       do: server_fmt

  defp resolve_format(%Client{access_token_format: nil}, _server_policy), do: :jwt

  defp server_policy(request) do
    store =
      request
      |> Map.get(:opts, [])
      |> Keyword.get(:server_policy_store)

    cond do
      is_nil(store) -> nil
      not function_exported?(store, :get_server_policy, 0) -> nil
      true -> normalize_server_policy(store.get_server_policy())
    end
  end

  defp normalize_server_policy({:ok, %ServerPolicy{} = policy}), do: policy
  defp normalize_server_policy(%ServerPolicy{} = policy), do: policy
  defp normalize_server_policy(_other), do: nil

  # --------------------------------------------------------------------------
  # Audience derivation — D-08 + RFC 8693 carve-out
  # --------------------------------------------------------------------------

  @spec derive_aud([String.t()], String.t()) :: [String.t()]
  defp derive_aud([], client_id), do: [client_id]
  defp derive_aud(audience, _client_id) when is_list(audience), do: audience

  # --------------------------------------------------------------------------
  # Claim assembly (shared by both callers; aud passed in by the caller so the
  # list-vs-string carve-out lives at the boundary, not in the signing core)
  # --------------------------------------------------------------------------

  defp base_claims(%Token{} = token, %Client{} = client, aud) do
    issued_at = token.issued_at || DateTime.utc_now()
    iat = DateTime.to_unix(issued_at)

    %{
      "iss" => Config.issuer!(),
      "sub" => token.account_id,
      "aud" => aud,
      "exp" => iat + @access_token_ttl_seconds,
      "iat" => iat,
      "client_id" => client.client_id,
      "jti" => generate_jti(),
      "scope" => Enum.join(token.scopes, " ")
    }
    |> maybe_put_cnf(token.cnf)
  end

  defp maybe_put_cnf(claims, nil), do: claims
  defp maybe_put_cnf(claims, cnf) when is_map(cnf), do: Map.put(claims, "cnf", cnf)

  defp generate_jti, do: TokenFormatter.format_access_token([]).token

  # --------------------------------------------------------------------------
  # Opaque branch — delegate to TokenFormatter
  # --------------------------------------------------------------------------

  defp format_opaque(_request) do
    formatted = TokenFormatter.format_access_token([])
    {:ok, formatted.token, formatted.token_hash}
  end

  # --------------------------------------------------------------------------
  # The single JOSE signing site — all :jwt callers funnel through here
  # --------------------------------------------------------------------------

  defp sign_jwt(claims, request) do
    with {:ok, %{kid: kid, alg: alg, private_jwk_encrypted: private_jwk}} <-
           fetch_signing_key(request),
         {:ok, jwk_map} <- decode_private_jwk(private_jwk) do
      {_, compact} =
        JOSE.JWT.sign(
          JOSE.JWK.from_map(jwk_map),
          %{"alg" => alg, "kid" => kid, "typ" => "at+jwt"},
          claims
        )
        |> JOSE.JWS.compact()

      {:ok, compact, Policy.hash_token(compact)}
    else
      {:error, reason} ->
        Logger.error("Failed to sign access token: #{inspect(reason)}")

        {:error,
         %Error{
           status: 500,
           error: "server_error",
           error_description: "Unable to sign access token.",
           reason_code: :token_signing_failed
         }}
    end
  end

  # --------------------------------------------------------------------------
  # Key fetch + JWK decode (moved from rfc8693_exchange.ex:363-399)
  # --------------------------------------------------------------------------

  defp fetch_signing_key(request) do
    key_store =
      request
      |> Map.get(:opts, [])
      |> Keyword.get(:key_store, Config.repo!())

    case key_store.fetch_active_signing_key([]) do
      {:ok, %{alg: alg, private_jwk_encrypted: private_jwk} = key}
      when is_binary(private_jwk) and is_binary(alg) ->
        {:ok, key}

      {:ok, nil} ->
        {:error, :signing_key_not_found}

      {:ok, _key} ->
        {:error, :invalid_signing_key}

      {:error, _reason} ->
        {:error, :signing_key_lookup_failed}
    end
  end

  defp decode_private_jwk(binary) when is_binary(binary) do
    case Jason.decode(binary) do
      {:ok, %{} = jwk} -> {:ok, jwk}
      _other -> decode_erlang_jwk(binary)
    end
  end

  defp decode_erlang_jwk(binary) do
    case Plug.Crypto.non_executable_binary_to_term(binary, [:safe]) do
      %{} = jwk -> {:ok, jwk}
      _other -> {:error, :invalid_signing_key}
    end
  rescue
    _ -> {:error, :invalid_signing_key}
  end
end
