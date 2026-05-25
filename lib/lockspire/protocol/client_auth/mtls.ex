defmodule Lockspire.Protocol.ClientAuth.MTLS do
  @moduledoc false

  alias Lockspire.Domain.Client
  alias Lockspire.Mtls.Certificate
  alias Lockspire.Observability
  alias Lockspire.RemoteJwksDiagnostics
  alias Lockspire.Config

  @spec verify(
          Client.t(),
          binary() | nil,
          :tls_client_auth | :self_signed_tls_client_auth,
          keyword()
        ) :: :ok | {:error, atom()}
  def verify(%Client{} = client, mtls_cert_der, auth_method, opts)
      when auth_method in [:tls_client_auth, :self_signed_tls_client_auth] do
    case mtls_cert_der do
      nil ->
        record_failure(:missing_certificate, client, auth_method, opts)
        {:error, :missing_certificate}

      der when is_binary(der) ->
        case Certificate.parse(der) do
          {:ok, cert} ->
            result =
              case auth_method do
                :tls_client_auth ->
                  verify_pki(client, cert)

                :self_signed_tls_client_auth ->
                  verify_self_signed(client, cert, opts)
              end

            case result do
              :ok ->
                record_success(client, auth_method, opts)
                :ok

              {:error, reason} ->
                record_failure(reason, client, auth_method, opts)
                {:error, reason}
            end

          {:error, _reason} ->
            record_failure(:invalid_certificate, client, auth_method, opts)
            {:error, :invalid_certificate}
        end
    end
  end

  defp verify_pki(%Client{} = client, %Certificate{} = cert) do
    if matches_pki_attribute?(client, cert) do
      :ok
    else
      {:error, :certificate_attribute_mismatch}
    end
  end

  defp matches_pki_attribute?(%Client{} = client, %Certificate{} = cert) do
    match_dn?(client.tls_client_auth_subject_dn, cert.subject_dn) or
      match_san?(client.tls_client_auth_san_dns, cert.sans.dns) or
      match_san?(client.tls_client_auth_san_uri, cert.sans.uri) or
      match_san?(client.tls_client_auth_san_ip, cert.sans.ip) or
      match_san?(client.tls_client_auth_san_email, cert.sans.email)
  end

  defp match_dn?(nil, _cert_dn), do: false
  defp match_dn?(client_dn, cert_dn), do: client_dn == cert_dn

  defp match_san?(nil, _cert_sans), do: false
  defp match_san?(client_san, cert_sans), do: client_san in cert_sans

  defp verify_self_signed(%Client{} = client, %Certificate{} = cert, opts) do
    jwk = JOSE.JWK.from_key(cert.public_key)

    case resolve_keys(client, opts) do
      {:ok, verified_client} ->
        if jwks_contains_key?(verified_client.jwks, jwk) do
          :ok
        else
          {:error, :no_matching_key}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp resolve_keys(%Client{jwks: jwks} = client, _opts) when is_map(jwks), do: {:ok, client}

  defp resolve_keys(%Client{jwks_uri: jwks_uri} = client, opts) when is_binary(jwks_uri) do
    fetcher = Keyword.get(opts, :jwks_fetcher, Config.jwks_fetcher())
    fetcher_opts = Keyword.merge(Config.jwks_fetcher_opts(), Keyword.get(opts, :jwks_fetcher_opts, []))

    case fetcher.get_keys(jwks_uri, fetcher_opts) do
      {:ok, jwk_set} ->
        {_modules, jwks} = JOSE.JWK.to_map(jwk_set)
        RemoteJwksDiagnostics.record_healthy(client, source: :mtls)
        {:ok, %Client{client | jwks: jwks}}

      {:error, {:jwks_fetch_failed, reason}} ->
        RemoteJwksDiagnostics.record_fetch_failure(client, reason, source: :mtls)
        {:error, :client_jwks_fetch_failed}

      {:error, reason} ->
        RemoteJwksDiagnostics.record_fetch_failure(client, reason, source: :mtls)
        {:error, :client_jwks_fetch_failed}
    end
  end

  defp resolve_keys(%Client{}, _opts), do: {:error, :client_jwks_missing}

  defp jwks_contains_key?(%{"keys" => keys}, target_jwk) when is_list(keys) do
    {_modules, target_jwk_map} = JOSE.JWK.to_map(target_jwk)
    target_thumbprint = JOSE.JWK.thumbprint(JOSE.JWK.from_map(target_jwk_map))

    Enum.any?(keys, fn key ->
      JOSE.JWK.thumbprint(JOSE.JWK.from_map(key)) == target_thumbprint
    end)
  end

  defp jwks_contains_key?(_jwks, _target), do: false

  defp record_failure(reason, %Client{} = client, auth_method, _opts) do
    metadata = %{
      client_id: client.client_id,
      auth_method: auth_method,
      reason_code: reason
    }

    Observability.emit(:client_auth, :failed, %{}, metadata)
  end

  defp record_success(%Client{} = client, auth_method, _opts) do
    metadata = %{
      client_id: client.client_id,
      auth_method: auth_method
    }

    Observability.emit(:client_auth, :success, %{}, metadata)
  end
end
