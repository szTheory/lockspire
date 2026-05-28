defmodule Lockspire.Plug.VerifyToken do
  @moduledoc """
  A plug that extracts and verifies a Bearer token from the Authorization header.

  This plug performs "soft validation". It never halts the connection, but instead
  assigns a `Lockspire.AccessToken` struct to `conn.assigns[:access_token]`. If the
  token is invalid or missing, the struct will contain an error reason.
  """

  @behaviour Plug

  import Plug.Conn
  require Logger

  alias Lockspire.AccessToken
  alias Lockspire.Config
  alias Lockspire.KeyCache

  @allowed_algs ["RS256", "ES256", "PS256"]
  @base64url_segment ~r/^[A-Za-z0-9_\-]+$/
  @options_schema [
    scopes: [
      type: {:list, :string},
      required: false,
      default: [],
      doc: "Exact case-sensitive scopes required for the route."
    ],
    audience: [
      type: :string,
      required: false,
      doc: "Single expected audience value for the route."
    ],
    audiences: [
      type: {:list, :string},
      required: false,
      doc: "Any-of audience values accepted for the route."
    ],
    enforce_audience: [
      type: :boolean,
      required: false,
      default: false,
      doc:
        "When true, init/1 raises if neither :audience nor :audiences is supplied. " <>
          "Closes VERIFIER-06 cross-API token reuse on pipelines that declare audience enforcement (D-07)."
    ]
  ]

  @impl Plug
  def init(opts) do
    opts = NimbleOptions.validate!(opts, @options_schema)

    if Keyword.has_key?(opts, :audience) and Keyword.has_key?(opts, :audiences) do
      raise ArgumentError, "expected only one of :audience or :audiences"
    end

    if Keyword.get(opts, :enforce_audience, false) and
         not Keyword.has_key?(opts, :audience) and
         not Keyword.has_key?(opts, :audiences) do
      raise ArgumentError,
            "expected :audience or :audiences when :enforce_audience is true (D-07)"
    end

    opts
    |> validate_non_empty_values!(:scopes)
    |> validate_non_empty_value!(:audience)
    |> validate_non_empty_values!(:audiences)
    |> validate_audiences_not_empty!()
  end

  @impl Plug
  def call(conn, opts) do
    case extract_token(conn) do
      {:ok, authorization_scheme, token} ->
        access_token = verify_token(token, authorization_scheme, opts)
        assign(conn, :access_token, access_token)

      {:error, reason} ->
        log_missing_token()
        assign(conn, :access_token, %AccessToken{error: reason})
    end
  end

  defp extract_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token | _] -> {:ok, "Bearer", String.trim(token)}
      ["DPoP " <> token | _] -> {:ok, "DPoP", String.trim(token)}
      _ -> {:error, :missing_token}
    end
  end

  defp verify_token(token, authorization_scheme, opts) do
    # Front-edge structural check (D-01): a token that does not split into exactly
    # three non-empty Base64URL segments by `.` short-circuits here with
    # reason_code: :opaque_token_not_accepted instead of falling through to JOSE
    # and being silently lumped under :malformed.
    if opaque_shape?(token) do
      error = opaque_token_error()
      log_invalid_token(error, authorization_scheme)

      %AccessToken{
        token: token,
        authorization_scheme: authorization_scheme,
        error: error
      }
    else
      do_verify_token(token, authorization_scheme, opts)
    end
  end

  defp do_verify_token(token, authorization_scheme, opts) do
    with {:ok, kid} <- extract_kid(token),
         {:ok, jwk} <- fetch_key(kid),
         {:ok, claims} <- verify_signature_and_claims(jwk, token) do
      %AccessToken{
        token: token,
        claims: claims,
        client_id: Map.get(claims, "client_id"),
        authorization_scheme: authorization_scheme,
        binding_type: binding_type(claims),
        binding_requirements: binding_requirements(claims)
      }
      |> apply_restrictions(opts)
    else
      {:error, %{reason_code: _} = structured_error} ->
        # D-04: structured-map error (e.g. the five RFC 9068 reason codes from
        # validate_rfc9068_compliance/2) propagates through to AccessToken.error
        # so RequireToken's WWW-Authenticate emission carries the distinct
        # error_description naming the violated rule.
        log_invalid_token(structured_error, authorization_scheme)

        %AccessToken{
          error: structured_error,
          token: token,
          authorization_scheme: authorization_scheme
        }

      {:error, reason_code} when is_atom(reason_code) ->
        log_invalid_token(reason_code, authorization_scheme)

        %AccessToken{
          error: :invalid_token,
          token: token,
          authorization_scheme: authorization_scheme
        }
    end
  end

  # Returns true when the token does NOT split into exactly three non-empty
  # Base64URL segments by `.`. Three-segment-but-bad inputs (e.g. "not.a.jwt")
  # return false so they continue to fall through to the existing JOSE path
  # and classify as `:malformed`, preserving the contract documented in D-01.
  defp opaque_shape?(token) when is_binary(token) do
    case String.split(token, ".", parts: 4) do
      [a, b, c] ->
        not (base64url_segment?(a) and base64url_segment?(b) and base64url_segment?(c))

      _ ->
        true
    end
  end

  defp opaque_shape?(_token), do: true

  defp base64url_segment?(segment) when is_binary(segment) do
    segment != "" and Regex.match?(@base64url_segment, segment)
  end

  defp base64url_segment?(_segment), do: false

  defp opaque_token_error do
    %{
      category: :token_format,
      challenge: :bearer,
      reason_code: :opaque_token_not_accepted,
      error: "invalid_token",
      error_description: "opaque tokens not accepted on this route"
    }
  end

  defp apply_restrictions(%AccessToken{} = access_token, opts) do
    with :ok <- validate_audience(access_token.claims, opts),
         :ok <- validate_scopes(access_token.claims, opts) do
      access_token
    else
      {:error, error} ->
        log_restriction_failure(error, access_token.authorization_scheme)
        %AccessToken{access_token | error: error}
    end
  end

  defp validate_audience(claims, opts) do
    case configured_audiences(opts) do
      [] ->
        :ok

      expected_audiences ->
        with {:ok, token_audiences} <- normalize_token_audiences(claims),
             true <- Enum.any?(expected_audiences, &Enum.member?(token_audiences, &1)) do
          :ok
        else
          {:error, reason_code} ->
            {:error, invalid_audience_error(reason_code, expected_audiences)}

          false ->
            {:error, invalid_audience_error(:invalid_audience, expected_audiences)}
        end
    end
  end

  defp validate_scopes(claims, opts) do
    required_scopes = Keyword.get(opts, :scopes, [])

    if required_scopes == [] do
      :ok
    else
      token_scopes = normalize_token_scopes(Map.get(claims, "scope"))

      if Enum.all?(required_scopes, &Enum.member?(token_scopes, &1)) do
        :ok
      else
        {:error, insufficient_scope_error(required_scopes)}
      end
    end
  end

  defp configured_audiences(opts) do
    case Keyword.fetch(opts, :audience) do
      {:ok, audience} -> [audience]
      :error -> Keyword.get(opts, :audiences, [])
    end
  end

  defp normalize_token_audiences(claims) do
    case Map.get(claims, "aud") do
      nil ->
        {:error, :missing_audience}

      audience when is_binary(audience) ->
        if String.trim(audience) == "" do
          {:error, :invalid_audience}
        else
          {:ok, [audience]}
        end

      audiences when is_list(audiences) ->
        cond do
          audiences == [] -> {:error, :invalid_audience}
          Enum.all?(audiences, &non_empty_string?/1) -> {:ok, audiences}
          true -> {:error, :invalid_audience}
        end

      _other ->
        {:error, :invalid_audience}
    end
  end

  defp normalize_token_scopes(scope_claim) when is_binary(scope_claim) do
    scope_claim
    |> String.split(~r/\s+/, trim: true)
    |> Enum.uniq()
  end

  defp normalize_token_scopes(_scope_claim), do: []

  defp invalid_audience_error(reason_code, expected_audiences) do
    %{
      category: :token_restriction,
      challenge: :bearer,
      reason_code: reason_code,
      error: "invalid_token",
      error_description: "The access token audience is invalid for this route",
      required_audiences: expected_audiences
    }
  end

  # D-04: structured error map shape for the five RFC 9068 / RFC 8725 reason
  # codes that `validate_rfc9068_compliance/2` produces. Sibling of
  # `invalid_audience_error/2` so the structured-error taxonomy reads as one
  # unit. `challenge:` is hard-coded `:bearer` for Phase 98 Plan 03; Plan 04
  # (VERIFIER-05) replaces this with a binding-derived value via D-05/D-06.
  defp rfc9068_error(:invalid_typ) do
    %{
      category: :token_validation,
      challenge: :bearer,
      reason_code: :invalid_typ,
      error: "invalid_token",
      error_description:
        "access token JWT header \"typ\" is not \"at+jwt\" per RFC 9068 §2.1 / RFC 8725 §3.11"
    }
  end

  defp rfc9068_error(:invalid_issuer) do
    %{
      category: :token_validation,
      challenge: :bearer,
      reason_code: :invalid_issuer,
      error: "invalid_token",
      error_description:
        "access token \"iss\" claim does not match expected issuer per RFC 9068 §4"
    }
  end

  defp rfc9068_error(:missing_exp) do
    %{
      category: :token_validation,
      challenge: :bearer,
      reason_code: :missing_exp,
      error: "invalid_token",
      error_description: "access token is missing required \"exp\" claim per RFC 9068 §2.2"
    }
  end

  defp rfc9068_error(:missing_iat) do
    %{
      category: :token_validation,
      challenge: :bearer,
      reason_code: :missing_iat,
      error: "invalid_token",
      error_description: "access token is missing required \"iat\" claim per RFC 9068 §2.2"
    }
  end

  defp rfc9068_error(:missing_sub) do
    %{
      category: :token_validation,
      challenge: :bearer,
      reason_code: :missing_sub,
      error: "invalid_token",
      error_description: "access token is missing required \"sub\" claim per RFC 9068 §2.2"
    }
  end

  defp insufficient_scope_error(required_scopes) do
    %{
      category: :insufficient_scope,
      challenge: :bearer,
      reason_code: :insufficient_scope,
      error: "insufficient_scope",
      error_description: "The access token is missing a required scope",
      required_scopes: required_scopes
    }
  end

  defp validate_non_empty_values!(opts, key) do
    case Keyword.get(opts, key) do
      nil ->
        opts

      values when is_list(values) ->
        if Enum.all?(values, &non_empty_string?/1) do
          opts
        else
          raise ArgumentError, "expected :#{key} to contain non-empty strings"
        end
    end
  end

  defp validate_non_empty_value!(opts, key) do
    case Keyword.get(opts, key) do
      nil ->
        opts

      value ->
        if non_empty_string?(value) do
          opts
        else
          raise ArgumentError, "expected :#{key} to be a non-empty string"
        end
    end
  end

  defp validate_audiences_not_empty!(opts) do
    case Keyword.get(opts, :audiences) do
      nil -> opts
      [] -> raise ArgumentError, "expected :audiences to contain at least one value"
      _values -> opts
    end
  end

  defp non_empty_string?(value), do: is_binary(value) and String.trim(value) != ""

  defp log_missing_token do
    Logger.warning(
      "Lockspire.VerifyToken missing token",
      event: :lockspire_verify_token_failed,
      category: :token_extraction,
      reason_code: :missing_token
    )
  end

  defp log_invalid_token(%{reason_code: reason_code, category: category}, authorization_scheme) do
    Logger.warning(
      "Lockspire.VerifyToken invalid token category=#{category} reason=#{reason_code}",
      event: :lockspire_verify_token_failed,
      category: category,
      authorization_scheme: authorization_scheme,
      reason_code: reason_code
    )
  end

  defp log_invalid_token(reason_code, authorization_scheme) when is_atom(reason_code) do
    Logger.warning(
      "Lockspire.VerifyToken invalid token reason=#{reason_code}",
      event: :lockspire_verify_token_failed,
      category: :token_validation,
      authorization_scheme: authorization_scheme,
      reason_code: reason_code
    )
  end

  defp log_restriction_failure(error, authorization_scheme) do
    metadata =
      [
        event: :lockspire_verify_token_failed,
        category: error.category,
        authorization_scheme: authorization_scheme,
        reason_code: error.reason_code
      ] ++ restriction_log_metadata(error)

    Logger.warning(
      "Lockspire.VerifyToken restriction failure category=#{error.category} reason=#{error.reason_code}",
      metadata
    )
  end

  defp restriction_log_metadata(%{required_audiences: audiences}) do
    [required_audiences_count: length(audiences)]
  end

  defp restriction_log_metadata(%{required_scopes: scopes}) do
    [required_scopes_count: length(scopes)]
  end

  defp restriction_log_metadata(_error), do: []

  defp binding_type(%{"cnf" => %{} = cnf}) do
    has_dpop? = present?(Map.get(cnf, "jkt"))
    has_mtls? = present?(Map.get(cnf, "x5t#S256"))

    cond do
      has_dpop? and has_mtls? -> "dpop+mtls"
      has_dpop? -> "dpop"
      has_mtls? -> "mtls"
      true -> nil
    end
  end

  defp binding_type(_claims), do: nil

  defp binding_requirements(%{"cnf" => %{} = cnf}) do
    requirements =
      %{}
      |> put_requirement(:dpop_jkt, Map.get(cnf, "jkt"))
      |> put_requirement(:mtls_x5t_s256, Map.get(cnf, "x5t#S256"))

    if map_size(requirements) == 0, do: nil, else: requirements
  end

  defp binding_requirements(_claims), do: nil

  defp put_requirement(requirements, _key, value) when not is_binary(value), do: requirements

  defp put_requirement(requirements, key, value) do
    trimmed = String.trim(value)

    if trimmed == "" do
      requirements
    else
      Map.put(requirements, key, trimmed)
    end
  end

  defp extract_kid(token) do
    protected_headers = JOSE.JWT.peek_protected(token)
    {_alg_map, map} = JOSE.JWS.to_map(protected_headers)

    case map do
      %{"kid" => kid} when is_binary(kid) -> {:ok, kid}
      _ -> {:error, :no_kid}
    end
  rescue
    _ -> {:error, :malformed}
  end

  defp fetch_key(kid) do
    case KeyCache.get_key(kid) do
      {:ok, jwk} -> {:ok, jwk}
      {:error, _} -> {:error, :key_not_found}
    end
  end

  defp verify_signature_and_claims(jwk, token) do
    case JOSE.JWT.verify_strict(jwk, @allowed_algs, token) do
      {true, %JOSE.JWT{fields: claims}, _jws} ->
        # D-02: RFC 9068 / RFC 8725 compliance runs AFTER the signature is
        # verified (so we never inspect claims on an unverified token) and
        # BEFORE time_claims_valid?/1 + apply_restrictions/2 (so the named
        # RFC 9068 reason codes win over the legacy :invalid_time_claims and
        # over audience/scope restriction failures).
        with {:ok, claims} <- validate_rfc9068_compliance(token, claims) do
          if time_claims_valid?(claims) do
            {:ok, claims}
          else
            {:error, :invalid_time_claims}
          end
        end

      {false, _, _} ->
        {:error, :invalid_signature}
    end
  rescue
    _ -> {:error, :verification_crashed}
  end

  defp time_claims_valid?(claims) do
    now = System.os_time(:second)

    exp_valid? =
      case Map.get(claims, "exp") do
        exp when is_integer(exp) -> exp > now
        _ -> true
      end

    nbf_valid? =
      case Map.get(claims, "nbf") do
        nbf when is_integer(nbf) -> nbf <= now
        _ -> true
      end

    exp_valid? and nbf_valid?
  end

  # D-02 / D-03 / D-04: enforce the five RFC 9068 / RFC 8725 compliance rules
  # that JOSE.JWT.verify_strict/3 does not check by itself. Runs after the
  # signature has been verified (so `claims` are trustworthy in the
  # "signed by a configured JWKS key" sense) and before time_claims_valid?/1
  # and apply_restrictions/2, so the named reason codes from this step win
  # over :invalid_time_claims and the audience/scope reason codes.
  #
  # Intentionally more permissive than the issuance-side `typ` check at
  # `Lockspire.Protocol.DPoP.check_typ/1` (which exact-matches `"dpop+jwt"`).
  # The verifier accepts `at+jwt`, `AT+JWT`, `At+Jwt`, and the
  # `application/at+jwt` variant. This forward-compatibility margin lets
  # Phase 99's `Protocol.AccessTokenSigner` extraction evolve issuance to
  # emit `application/at+jwt` (stricter RFC 9068 §2.1 conformance) without
  # breaking Phase 98's verifier.
  defp validate_rfc9068_compliance(token, claims) do
    expected_issuer = Config.issuer!()

    with :ok <- check_at_jwt_typ(token),
         :ok <- check_issuer(claims, expected_issuer),
         :ok <- check_exp_positive_integer(claims),
         :ok <- check_iat_positive_integer(claims),
         :ok <- check_sub_non_empty_string(claims) do
      {:ok, claims}
    end
  end

  defp check_at_jwt_typ(token) do
    case peek_typ(token) do
      typ when is_binary(typ) ->
        normalized =
          typ
          |> String.trim()
          |> String.downcase()
          |> String.replace_prefix("application/", "")

        if normalized == "at+jwt" do
          :ok
        else
          {:error, rfc9068_error(:invalid_typ)}
        end

      _ ->
        {:error, rfc9068_error(:invalid_typ)}
    end
  end

  defp peek_typ(token) do
    protected_headers = JOSE.JWT.peek_protected(token)
    {_alg_map, header_map} = JOSE.JWS.to_map(protected_headers)
    Map.get(header_map, "typ")
  rescue
    _ -> nil
  end

  defp check_issuer(claims, expected_issuer) do
    case Map.get(claims, "iss") do
      iss when is_binary(iss) and iss == expected_issuer -> :ok
      _ -> {:error, rfc9068_error(:invalid_issuer)}
    end
  end

  defp check_exp_positive_integer(claims) do
    case Map.get(claims, "exp") do
      exp when is_integer(exp) and exp > 0 -> :ok
      _ -> {:error, rfc9068_error(:missing_exp)}
    end
  end

  defp check_iat_positive_integer(claims) do
    case Map.get(claims, "iat") do
      iat when is_integer(iat) and iat > 0 -> :ok
      _ -> {:error, rfc9068_error(:missing_iat)}
    end
  end

  defp check_sub_non_empty_string(claims) do
    case Map.get(claims, "sub") do
      sub when is_binary(sub) ->
        if non_empty_string?(sub) do
          :ok
        else
          {:error, rfc9068_error(:missing_sub)}
        end

      _ ->
        {:error, rfc9068_error(:missing_sub)}
    end
  end

  defp present?(value), do: is_binary(value) and String.trim(value) != ""
end
