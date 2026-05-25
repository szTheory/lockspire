defmodule Lockspire.Protocol.ProtectedResourceDPoP do
  @moduledoc """
  Validates DPoP-bound access token use on Lockspire-owned protected resources.
  """

  alias Lockspire.Config
  alias Lockspire.Domain.DpopReplay
  alias Lockspire.Domain.Token
  alias Lockspire.Observability
  alias Lockspire.Protocol.DPoP
  alias Lockspire.Protocol.DPoPNonce
  alias Lockspire.Protocol.SecurityProfile
  alias Lockspire.Protocol.Userinfo.Error

  @spec validate_access(map(), map()) :: {:ok, DPoP.t()} | {:error, Error.t()}
  def validate_access(binding_source, request) when is_map(binding_source) and is_map(request) do
    security_profile =
      Keyword.get(request_options(request), :security_profile, %SecurityProfile.Resolved{})

    with :ok <- validate_authorization_scheme(request),
         {:ok, raw_access_token} <- fetch_access_token(request),
         {:ok, target_uri} <- fetch_target_uri(request),
         {:ok, proof} <- validate_proof(request, security_profile, target_uri),
         :ok <- validate_ath(proof, raw_access_token),
         :ok <- validate_token_binding(binding_source, proof),
         :ok <- record_dpop_proof_use(proof, request) do
      {:ok, proof}
    else
      {:error, %Error{} = error} ->
        emit_failure(binding_source, error)
        {:error, error}
    end
  end

  @spec validate_userinfo_access(Token.t(), map()) :: {:ok, DPoP.t()} | {:error, Error.t()}
  def validate_userinfo_access(%Token{} = token, request) when is_map(request) do
    request
    |> Map.put_new(:target_uri, userinfo_endpoint_uri())
    |> then(&validate_access(token, &1))
  end

  defp validate_authorization_scheme(request) do
    case Map.get(request, :authorization_scheme, Map.get(request, "authorization_scheme")) do
      "DPoP" ->
        :ok

      _other ->
        {:error,
         invalid_token(
           "DPoP-bound access token requires Authorization: DPoP",
           :invalid_dpop_authorization_scheme
         )}
    end
  end

  defp fetch_access_token(request) do
    case Map.get(request, :access_token, Map.get(request, "access_token")) do
      token when is_binary(token) and token != "" ->
        {:ok, token}

      _other ->
        {:error, invalid_token("DPoP-bound access token is invalid", :invalid_access_token)}
    end
  end

  defp validate_proof(request, security_profile, target_uri) do
    case normalize_optional_string(Map.get(request, :dpop, Map.get(request, "dpop"))) do
      nil ->
        {:error, invalid_token("A valid DPoP proof is required", :missing_dpop_proof)}

      proof ->
        case DPoP.validate_proof(
               proof,
               method: request_method(request),
               target_uri: target_uri,
               now: now(request),
               max_age: Keyword.get(request_options(request), :dpop_max_age, 300),
               clock_skew: Keyword.get(request_options(request), :dpop_clock_skew, 30),
               security_profile: security_profile,
               nonce_purpose: :resource_server,
               secret_key_base: Keyword.get(request_options(request), :secret_key_base),
               nonce_max_age: Keyword.get(request_options(request), :dpop_nonce_max_age, 300)
             ) do
          {:ok, %DPoP{} = validated_proof} ->
            {:ok, validated_proof}

          {:error, reason} when reason in [:missing_dpop_nonce, :invalid_dpop_nonce] ->
            {:error, use_dpop_nonce_error(reason, request)}

          {:error, reason} when is_atom(reason) ->
            {:error, invalid_token("The DPoP proof is invalid", reason)}
        end
    end
  end

  defp validate_ath(%DPoP{claims: claims}, raw_access_token) when is_map(claims) do
    case Map.get(claims, "ath") do
      ath when is_binary(ath) and ath != "" ->
        if ath == DPoP.access_token_ath(raw_access_token) do
          :ok
        else
          {:error,
           invalid_token("The DPoP proof access token hash is invalid", :invalid_dpop_ath)}
        end

      _other ->
        {:error, invalid_token("The DPoP proof must include ath", :missing_dpop_ath)}
    end
  end

  defp validate_token_binding(binding_source, %DPoP{jkt: actual_jkt})
       when is_binary(actual_jkt) do
    case expected_jkt(binding_source) do
      {:ok, expected_jkt} ->
        validate_expected_jkt(expected_jkt, actual_jkt)

      :error ->
        {:error,
         invalid_token("The DPoP-bound access token is invalid", :invalid_access_token_binding)}
    end
  end

  defp validate_expected_jkt(expected_jkt, actual_jkt)
       when is_binary(expected_jkt) and is_binary(actual_jkt) do
    if expected_jkt == actual_jkt do
      :ok
    else
      {:error,
       invalid_token(
         "The DPoP proof key does not match the access token binding",
         :dpop_binding_mismatch
       )}
    end
  end

  defp validate_expected_jkt(_expected_jkt, _actual_jkt), do: :error

  defp record_dpop_proof_use(%DPoP{} = validated_proof, request) do
    with {:ok, %DpopReplay{} = replay} <- build_dpop_replay(validated_proof, request),
         {:ok, result} <- dpop_replay_store(request).record_dpop_proof(replay) do
      case result do
        :accepted ->
          :ok

        :replay ->
          {:error, invalid_token("The DPoP proof has already been used", :dpop_proof_replayed)}
      end
    else
      {:error, %Error{} = error} ->
        {:error, error}

      {:error, _reason} ->
        {:error, invalid_token("The DPoP proof is invalid", :invalid_dpop_proof)}
    end
  end

  defp build_dpop_replay(%DPoP{claims: claims, jkt: jkt}, request)
       when is_map(claims) and is_binary(jkt) do
    with {:ok, htm} <- fetch_dpop_claim(claims, "htm"),
         {:ok, htu} <- fetch_dpop_claim(claims, "htu"),
         {:ok, jti} <- fetch_dpop_claim(claims, "jti"),
         {:ok, iat} <- fetch_dpop_iat(claims),
         {:ok, expires_at} <- dpop_replay_expiration(iat, request) do
      normalized_htm = String.upcase(htm)
      normalized_htu = canonical_dpop_htu(htu)

      {:ok,
       %DpopReplay{
         replay_key: dpop_replay_key(jkt, jti, normalized_htm, normalized_htu),
         jti: jti,
         htm: normalized_htm,
         htu: normalized_htu,
         jkt: jkt,
         seen_at: now(request),
         expires_at: expires_at
       }}
    else
      _other -> {:error, invalid_token("The DPoP proof is invalid", :invalid_dpop_proof)}
    end
  end

  defp fetch_dpop_claim(claims, key) do
    case Map.get(claims, key) do
      value when is_binary(value) and value != "" -> {:ok, value}
      _other -> :error
    end
  end

  defp fetch_dpop_iat(claims) do
    case Map.get(claims, "iat") do
      value when is_integer(value) -> {:ok, value}
      _other -> :error
    end
  end

  defp dpop_replay_expiration(iat, request) when is_integer(iat) do
    max_age = Keyword.get(request_options(request), :dpop_max_age, 300)
    clock_skew = Keyword.get(request_options(request), :dpop_clock_skew, 30)

    case DateTime.from_unix((iat + max_age + clock_skew) * 1_000_000, :microsecond) do
      {:ok, expires_at} -> {:ok, expires_at}
      {:error, _reason} -> {:error, :invalid_dpop_expiration}
    end
  end

  defp dpop_replay_key(jkt, jti, htm, htu) do
    [jkt, jti, htm, htu]
    |> Enum.join("\n")
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.url_encode64(padding: false)
  end

  defp canonical_dpop_htu(uri) do
    %URI{scheme: scheme, host: host} = parsed = URI.parse(uri)

    if is_nil(scheme) or is_nil(host) do
      raise ArgumentError, "invalid absolute URI"
    end

    normalized_host = String.downcase(host)
    port = normalized_dpop_port(parsed)
    path = if parsed.path in [nil, ""], do: "/", else: parsed.path

    authority =
      if is_nil(port),
        do: normalized_host,
        else: normalized_host <> ":" <> Integer.to_string(port)

    scheme <> "://" <> authority <> path
  end

  defp normalized_dpop_port(%URI{scheme: "https", port: 443}), do: nil
  defp normalized_dpop_port(%URI{scheme: "http", port: 80}), do: nil
  defp normalized_dpop_port(%URI{port: port}), do: port

  defp userinfo_endpoint_uri do
    issuer = URI.parse(Config.issuer!())
    path = Path.join(issuer.path || "/", "userinfo")

    issuer
    |> Map.put(:path, path)
    |> Map.put(:query, nil)
    |> Map.put(:fragment, nil)
    |> URI.to_string()
  end

  defp fetch_target_uri(request) do
    case Map.get(request, :target_uri, Map.get(request, "target_uri")) do
      target_uri when is_binary(target_uri) and target_uri != "" ->
        {:ok, target_uri}

      _other ->
        {:error, invalid_token("The DPoP proof target URI is invalid", :invalid_dpop_target_uri)}
    end
  end

  defp expected_jkt(%{binding_requirements: %{dpop_jkt: jkt}})
       when is_binary(jkt) and jkt != "",
       do: {:ok, jkt}

  defp expected_jkt(%Token{cnf: %{"jkt" => jkt}}) when is_binary(jkt) and jkt != "",
    do: {:ok, jkt}

  defp expected_jkt(%{"jkt" => jkt}) when is_binary(jkt) and jkt != "", do: {:ok, jkt}
  defp expected_jkt(_binding_source), do: :error

  defp emit_failure(binding_source, %Error{reason_code: reason}) do
    metadata =
      %{
        client_id: Map.get(binding_source, :client_id),
        account_id: Map.get(binding_source, :account_id),
        reason: reason
      }

    Observability.emit(:dpop, :failed, %{}, metadata)
  end

  defp dpop_replay_store(request),
    do:
      Keyword.get_lazy(request_options(request), :dpop_replay_store, fn ->
        Keyword.get(request_options(request), :token_store, Config.repo!())
      end)

  defp request_method(request) do
    request
    |> Map.get(:method, Map.get(request, "method", "GET"))
    |> to_string()
    |> String.upcase()
  end

  defp request_options(request), do: Map.get(request, :opts, Map.get(request, "opts", []))

  defp now(request),
    do:
      request
      |> request_options()
      |> Keyword.get_lazy(:now, fn -> &DateTime.utc_now/0 end)
      |> then(& &1.())

  defp normalize_optional_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp normalize_optional_string(_value), do: nil

  defp invalid_token(description, reason_code) do
    %Error{
      status: 401,
      error: "invalid_token",
      error_description: description,
      reason_code: reason_code,
      dpop_nonce: nil
    }
  end

  defp use_dpop_nonce_error(reason_code, request) do
    %Error{
      status: 401,
      error: "use_dpop_nonce",
      error_description: "Resource server requires nonce in DPoP proof",
      reason_code: reason_code,
      dpop_nonce: DPoPNonce.issue(:resource_server, secret_key_base: secret_key_base(request))
    }
  end

  defp secret_key_base(request) do
    Keyword.get(request_options(request), :secret_key_base)
  end
end
