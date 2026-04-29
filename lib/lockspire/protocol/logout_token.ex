defmodule Lockspire.Protocol.LogoutToken do
  @moduledoc """
  Signs OIDC Back-Channel Logout tokens from durable logout snapshot state.
  """

  alias Lockspire.Domain.LogoutDelivery
  alias Lockspire.Domain.LogoutEvent

  @logout_event_uri "http://schemas.openid.net/event/backchannel-logout"

  @spec sign(map()) :: {:ok, String.t(), String.t()} | {:error, atom()}
  def sign(%{
        issuer: issuer,
        logout_event: %LogoutEvent{} = logout_event,
        delivery: %LogoutDelivery{} = delivery,
        issued_at: %DateTime{} = issued_at,
        signing_key: %{kid: kid, alg: "RS256", private_jwk_encrypted: private_jwk}
      })
      when is_binary(issuer) do
    with {:ok, jwk_map} <- decode_private_jwk(private_jwk),
         {:ok, claims} <- build_claims(issuer, logout_event, delivery, issued_at),
         {_, compact} <-
           JOSE.JWT.sign(
             JOSE.JWK.from_map(jwk_map),
             %{"alg" => "RS256", "kid" => kid, "typ" => "logout+jwt"},
             claims
           )
           |> JOSE.JWS.compact() do
      {:ok, compact, claims["jti"]}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def sign(_params), do: {:error, :invalid_signing_key}

  defp build_claims(issuer, %LogoutEvent{} = logout_event, %LogoutDelivery{} = delivery, issued_at) do
    subject = normalize_optional_string(logout_event.subject)
    sid = maybe_sid(logout_event, delivery)

    if is_nil(subject) and is_nil(sid) do
      {:error, :invalid_logout_event}
    else
      {:ok,
       %{
         "iss" => issuer,
         "aud" => delivery.client_id,
         "iat" => DateTime.to_unix(issued_at),
         "jti" => Ecto.UUID.generate(),
         "events" => %{@logout_event_uri => %{}}
       }
       |> maybe_put_claim("sub", subject)
       |> maybe_put_claim("sid", sid)}
    end
  end

  defp maybe_sid(%LogoutEvent{} = logout_event, %LogoutDelivery{session_required: true}) do
    normalize_optional_string(logout_event.sid)
  end

  defp maybe_sid(_logout_event, _delivery), do: nil

  defp maybe_put_claim(claims, _key, nil), do: claims
  defp maybe_put_claim(claims, key, value), do: Map.put(claims, key, value)

  defp normalize_optional_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_optional_string(_value), do: nil

  defp decode_private_jwk(binary) when is_binary(binary) do
    case Jason.decode(binary) do
      {:ok, %{} = jwk_map} ->
        {:ok, jwk_map}

      _other ->
        decode_term_private_jwk(binary)
    end
  end

  defp decode_private_jwk(_binary), do: {:error, :invalid_signing_key}

  defp decode_term_private_jwk(binary) do
    try do
      case :erlang.binary_to_term(binary, [:safe]) do
        %{} = jwk_map -> {:ok, jwk_map}
        _other -> {:error, :invalid_signing_key}
      end
    rescue
      _error -> {:error, :invalid_signing_key}
    end
  end
end
