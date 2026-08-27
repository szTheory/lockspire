defmodule Lockspire.Protocol.TokenExchange.Internal.TokenEndpointDPoP do
  @moduledoc """
  Resolves shared DPoP issuance context for token-endpoint exchanges.
  """

  alias Lockspire.Config
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DpopReplay
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.DPoP
  alias Lockspire.Protocol.DPoPNonce
  alias Lockspire.Protocol.DpopPolicy
  alias Lockspire.Protocol.MTLSTokenBinding
  alias Lockspire.Protocol.TokenExchange.Internal.Dependencies
  alias Lockspire.Protocol.TokenExchange.Internal.LegacyOptions
  alias Lockspire.Protocol.SecurityProfile
  alias Lockspire.Protocol.TokenResult.Error

  @type issuance_context :: %{
          mode: :bearer | :dpop,
          proof: DPoP.t() | nil,
          jkt: String.t() | nil,
          cnf: map() | nil,
          token_type: String.t(),
          security_profile: struct()
        }

  @spec resolve_context(Client.t(), map()) ::
          {:ok, issuance_context()} | {:error, struct()}
  @spec resolve_context(Client.t(), map(), Dependencies.t()) ::
          {:ok, issuance_context()} | {:error, struct()}
  def resolve_context(%Client{} = client, request, %Dependencies{} = dependencies),
    do: resolve_context_with_dependencies(client, request, dependencies)

  def resolve_context(%Client{} = client, request) do
    with {:ok, dependencies} <- LegacyOptions.from_request(request) do
      resolve_context(client, request, dependencies)
    end
  end

  defp resolve_context_with_dependencies(%Client{} = client, request, dependencies) do
    with {:ok, resolved_dpop_policy} <- resolve_policy(client, dependencies),
         {:ok, resolved_security_profile} <- resolve_security_profile(client, dependencies) do
      effective_dpop_required =
        resolved_dpop_policy.dpop_required? or resolved_security_profile.fapi_2_0_security?

      effective_mode =
        if effective_dpop_required, do: :dpop, else: resolved_dpop_policy.effective_policy

      with {:ok, proof} <-
             validate_proof_with_flag(effective_dpop_required, request, dependencies),
           :ok <- record_dpop_proof_use(proof, request, dependencies) do
        {:ok, issuance_context(effective_mode, proof, resolved_security_profile, dependencies)}
      end
    end
  end

  defp validate_proof_with_flag(true, request, dependencies),
    do: validate_proof(%{dpop_required?: true}, request, dependencies)

  defp validate_proof_with_flag(false, request, dependencies),
    do: validate_proof(%{dpop_required?: false}, request, dependencies)

  @spec resolve_refresh_context(Client.t(), Token.t(), map()) ::
          {:ok, issuance_context()} | {:error, struct()}
  @spec resolve_refresh_context(Client.t(), Token.t(), map(), Dependencies.t()) ::
          {:ok, issuance_context()} | {:error, struct()}
  def resolve_refresh_context(
        %Client{} = client,
        %Token{} = token,
        request,
        %Dependencies{} = dependencies
      ),
      do: resolve_refresh_context_with_dependencies(client, token, request, dependencies)

  def resolve_refresh_context(%Client{} = client, %Token{} = presented_refresh_token, request) do
    with {:ok, dependencies} <- LegacyOptions.from_request(request) do
      resolve_refresh_context(client, presented_refresh_token, request, dependencies)
    end
  end

  defp resolve_refresh_context_with_dependencies(
         %Client{} = client,
         %Token{} = presented_refresh_token,
         request,
         dependencies
       ) do
    with {:ok, resolved_security_profile} <- resolve_security_profile(client, dependencies),
         {:ok, expected_cnf} <- refresh_binding_cnf(presented_refresh_token),
         {:ok, expected_cnf} <- validate_mtls_binding(expected_cnf, dependencies),
         {:ok, proof} <-
           validate_refresh_proof(expected_cnf, resolved_security_profile, request, dependencies),
         :ok <- record_dpop_proof_use(proof, request, dependencies) do
      effective_mode =
        if resolved_security_profile.fapi_2_0_security? or
             refresh_binding_mode(expected_cnf) == :dpop,
           do: :dpop,
           else: :bearer

      {:ok, issuance_context(effective_mode, proof, resolved_security_profile, dependencies)}
    end
  end

  defp resolve_policy(%Client{} = client, %Dependencies{} = dependencies) do
    with {:ok, server_policy} <- dependencies.server_policy_store.get_server_policy(),
         {:ok, resolved_policy} <- DpopPolicy.resolve_effective_policy(server_policy, client) do
      {:ok, resolved_policy}
    else
      {:error, _reason} ->
        {:error,
         oauth_error(
           500,
           "server_error",
           "Unable to resolve DPoP policy",
           :dpop_policy_unavailable
         )}
    end
  end

  defp resolve_security_profile(%Client{} = client, %Dependencies{} = dependencies) do
    case dependencies.server_policy_store.get_server_policy() do
      {:ok, server_policy} ->
        {:ok, SecurityProfile.resolve_effective_profile(server_policy, client)}

      {:error, _reason} ->
        {:error,
         oauth_error(
           500,
           "server_error",
           "Unable to resolve security profile",
           :security_profile_unavailable
         )}
    end
  end

  defp validate_proof(%{dpop_required?: false}, request, dependencies) do
    case normalize_optional_string(Map.get(request, :dpop, Map.get(request, "dpop"))) do
      nil -> {:ok, nil}
      proof -> validate_proof_value(proof, request, dependencies)
    end
  end

  defp validate_proof(%{dpop_required?: true}, request, dependencies) do
    case normalize_optional_string(Map.get(request, :dpop, Map.get(request, "dpop"))) do
      nil -> {:error, invalid_dpop_proof("A valid DPoP proof is required", :missing_dpop_proof)}
      proof -> validate_proof_value(proof, request, dependencies)
    end
  end

  defp validate_mtls_binding(expected_cnf, %Dependencies{} = dependencies) do
    case {expected_cnf, dependencies.mtls_cert} do
      {%{"x5t#S256" => expected_thumbprint}, cert} ->
        if MTLSTokenBinding.confirmation_matches?(expected_thumbprint, cert) do
          {:ok, expected_cnf}
        else
          {:error,
           oauth_error(
             400,
             "invalid_request",
             "Client certificate missing or thumbprint mismatch",
             :invalid_client_certificate
           )}
        end

      _ ->
        {:ok, expected_cnf}
    end
  end

  defp validate_proof_value(proof, request, %Dependencies{} = dependencies) do
    case DPoP.validate_proof(
           proof,
           method: request_method(request),
           target_uri: token_endpoint_uri(),
           now: dependencies.now.(),
           max_age: dependencies.dpop_max_age,
           clock_skew: dependencies.dpop_clock_skew,
           nonce_purpose: :authorization_server,
           secret_key_base: dependencies.secret_key_base,
           nonce_max_age: dependencies.dpop_nonce_max_age
         ) do
      {:ok, %DPoP{} = validated_proof} ->
        {:ok, validated_proof}

      {:error, reason} when reason in [:missing_dpop_nonce, :invalid_dpop_nonce] ->
        {:error, use_dpop_nonce_error(reason, dependencies)}

      {:error, reason} when is_atom(reason) ->
        {:error, invalid_dpop_proof("The DPoP proof is invalid", reason)}
    end
  end

  defp validate_refresh_proof(expected_cnf, resolved_security_profile, request, dependencies) do
    cond do
      resolved_security_profile.fapi_2_0_security? ->
        # FAPI 2.0 requires DPoP for all token requests, even if the refresh token was bearer.
        require_and_validate_dpop(request, dependencies)

      is_nil(expected_cnf) or not Map.has_key?(expected_cnf, "jkt") ->
        {:ok, nil}

      Map.has_key?(expected_cnf, "jkt") and is_binary(Map.get(expected_cnf, "jkt")) ->
        require_and_validate_dpop(request, dependencies)

      true ->
        {:error,
         oauth_error(
           500,
           "server_error",
           "Stored refresh token binding is invalid",
           :invalid_refresh_token_binding
         )}
    end
  end

  defp require_and_validate_dpop(request, dependencies) do
    case normalize_optional_string(Map.get(request, :dpop, Map.get(request, "dpop"))) do
      nil ->
        {:error, invalid_dpop_proof("A valid DPoP proof is required", :missing_dpop_proof)}

      proof ->
        validate_proof_value(proof, request, dependencies)
    end
  end

  defp record_dpop_proof_use(nil, _request, _dependencies), do: :ok

  defp record_dpop_proof_use(%DPoP{} = validated_proof, _request, dependencies) do
    with {:ok, %DpopReplay{} = replay} <- build_dpop_replay(validated_proof, dependencies),
         {:ok, result} <- dependencies.dpop_replay_store.record_dpop_proof(replay) do
      case result do
        :accepted ->
          :ok

        :replay ->
          {:error,
           invalid_dpop_proof("The DPoP proof has already been used", :dpop_proof_replayed)}
      end
    else
      {:error, %Error{} = error} ->
        {:error, error}

      {:error, _reason} ->
        {:error,
         oauth_error(
           500,
           "server_error",
           "Unable to evaluate DPoP replay state",
           :dpop_replay_store_failed
         )}
    end
  end

  defp issuance_context(:dpop, %DPoP{} = proof, security_profile, dependencies) do
    cnf = %{"jkt" => proof.jkt} |> maybe_add_x5t_cnf(dependencies)

    %{
      mode: :dpop,
      proof: proof,
      jkt: proof.jkt,
      cnf: cnf,
      token_type: "DPoP",
      security_profile: security_profile
    }
  end

  defp issuance_context(_mode, _proof, security_profile, dependencies) do
    cnf = maybe_add_x5t_cnf(nil, dependencies)

    %{
      mode: :bearer,
      proof: nil,
      jkt: nil,
      cnf: cnf,
      token_type: "Bearer",
      security_profile: security_profile
    }
  end

  defp maybe_add_x5t_cnf(cnf, %Dependencies{} = dependencies) do
    MTLSTokenBinding.maybe_put_confirmation(cnf, dependencies.mtls_cert)
  end

  defp token_endpoint_uri do
    issuer = URI.parse(Config.issuer!())
    path = Path.join(issuer.path || "/", "token")

    issuer
    |> Map.put(:path, path)
    |> Map.put(:query, nil)
    |> Map.put(:fragment, nil)
    |> URI.to_string()
  end

  defp request_method(request) do
    request
    |> Map.get(:method, Map.get(request, "method", "POST"))
    |> to_string()
    |> String.upcase()
  end

  defp build_dpop_replay(%DPoP{claims: claims, jkt: jkt}, dependencies)
       when is_map(claims) and is_binary(jkt) do
    with {:ok, htm} <- fetch_dpop_claim(claims, "htm"),
         {:ok, htu} <- fetch_dpop_claim(claims, "htu"),
         {:ok, jti} <- fetch_dpop_claim(claims, "jti"),
         {:ok, iat} <- fetch_dpop_iat(claims),
         {:ok, expires_at} <- dpop_replay_expiration(iat, dependencies) do
      normalized_htm = String.upcase(htm)
      normalized_htu = canonical_dpop_htu(htu)

      {:ok,
       %DpopReplay{
         replay_key: dpop_replay_key(jkt, jti, normalized_htm, normalized_htu),
         jti: jti,
         htm: normalized_htm,
         htu: normalized_htu,
         jkt: jkt,
         seen_at: dependencies.now.(),
         expires_at: expires_at
       }}
    else
      _other ->
        {:error, invalid_dpop_proof("The DPoP proof is invalid", :invalid_dpop_proof)}
    end
  end

  defp build_dpop_replay(_proof, _request) do
    {:error, invalid_dpop_proof("The DPoP proof is invalid", :invalid_dpop_proof)}
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

  defp dpop_replay_expiration(iat, %Dependencies{} = dependencies) when is_integer(iat) do
    max_age = dependencies.dpop_max_age
    clock_skew = dependencies.dpop_clock_skew

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

  defp refresh_binding_cnf(%Token{cnf: nil}), do: {:ok, nil}

  defp refresh_binding_cnf(%Token{cnf: %{} = cnf}) do
    if Map.has_key?(cnf, "jkt") or Map.has_key?(cnf, "x5t#S256") do
      {:ok, cnf}
    else
      {:error,
       oauth_error(
         500,
         "server_error",
         "Stored refresh token binding is invalid",
         :invalid_refresh_token_binding
       )}
    end
  end

  defp refresh_binding_cnf(%Token{}) do
    {:error,
     oauth_error(
       500,
       "server_error",
       "Stored refresh token binding is invalid",
       :invalid_refresh_token_binding
     )}
  end

  defp refresh_binding_mode(nil), do: :bearer
  defp refresh_binding_mode(%{"jkt" => _}), do: :dpop
  defp refresh_binding_mode(_cnf), do: :bearer

  defp invalid_dpop_proof(description, reason_code) do
    oauth_error(400, "invalid_dpop_proof", description, reason_code)
  end

  defp use_dpop_nonce_error(reason_code, %Dependencies{} = dependencies) do
    %Error{
      status: 400,
      error: "use_dpop_nonce",
      error_description: "Authorization server requires nonce in DPoP proof",
      reason_code: reason_code,
      dpop_nonce:
        DPoPNonce.issue(:authorization_server, secret_key_base: dependencies.secret_key_base)
    }
  end

  defp oauth_error(status, error, description, reason_code) do
    %Error{
      status: status,
      error: error,
      error_description: description,
      reason_code: reason_code,
      dpop_nonce: nil
    }
  end

  defp normalize_optional_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp normalize_optional_string(_value), do: nil
end
