defmodule Lockspire.Plug.VerifyToken do
  @moduledoc """
  A plug that extracts and verifies a Bearer token from the Authorization header.
  
  This plug performs "soft validation". It never halts the connection, but instead
  assigns a `Lockspire.AccessToken` struct to `conn.assigns[:access_token]`. If the
  token is invalid or missing, the struct will contain an error reason.
  """

  @behaviour Plug

  import Plug.Conn

  alias Lockspire.AccessToken
  alias Lockspire.KeyCache

  @allowed_algs ["RS256", "ES256", "PS256"]

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    case extract_token(conn) do
      {:ok, authorization_scheme, token} ->
        access_token = verify_token(token, authorization_scheme)
        assign(conn, :access_token, access_token)

      {:error, reason} ->
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

  defp verify_token(token, authorization_scheme) do
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
    else
      _ -> %AccessToken{error: :invalid_token, token: token}
    end
  end

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
    try do
      protected_headers = JOSE.JWT.peek_protected(token)
      {_alg_map, map} = JOSE.JWS.to_map(protected_headers)

      case map do
        %{"kid" => kid} when is_binary(kid) -> {:ok, kid}
        _ -> {:error, :no_kid}
      end
    rescue
      _ -> {:error, :malformed}
    end
  end

  defp fetch_key(kid) do
    case KeyCache.get_key(kid) do
      {:ok, jwk} -> {:ok, jwk}
      {:error, _} -> {:error, :key_not_found}
    end
  end

  defp verify_signature_and_claims(jwk, token) do
    try do
      case JOSE.JWT.verify_strict(jwk, @allowed_algs, token) do
        {true, %JOSE.JWT{fields: claims}, _jws} ->
          if time_claims_valid?(claims) do
            {:ok, claims}
          else
            {:error, :invalid_time_claims}
          end

        {false, _, _} ->
          {:error, :invalid_signature}
      end
    rescue
      _ -> {:error, :verification_crashed}
    end
  end

  defp time_claims_valid?(claims) do
    now = System.os_time(:second)

    exp_valid? =
      case Map.get(claims, "exp") do
        exp when is_integer(exp) -> exp > now
        _ -> true # If exp is missing, technically it doesn't expire, but usually it's required. The spec doesn't mandate exp presence here unless specified. Let's assume it's valid if missing. If we want strict exp, we'd enforce it.
      end

    nbf_valid? =
      case Map.get(claims, "nbf") do
        nbf when is_integer(nbf) -> nbf <= now
        _ -> true
      end

    exp_valid? and nbf_valid?
  end

  defp present?(value), do: is_binary(value) and String.trim(value) != ""
end
