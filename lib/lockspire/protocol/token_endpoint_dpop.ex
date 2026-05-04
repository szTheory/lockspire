defmodule Lockspire.Protocol.TokenEndpointDPoP do
  @moduledoc """
  Resolves shared DPoP issuance context for token-endpoint exchanges.
  """

  alias Lockspire.Config
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DpopReplay
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.DPoP
  alias Lockspire.Protocol.DpopPolicy
  alias Lockspire.Protocol.SecurityProfile
  alias Lockspire.Protocol.TokenExchange.Error

  @type issuance_context :: %{
          mode: :bearer | :dpop,
          proof: DPoP.t() | nil,
          jkt: String.t() | nil,
          cnf: map() | nil,
          token_type: String.t(),
          security_profile: SecurityProfile.Resolved.t()
        }

  @spec resolve_context(Client.t(), map()) ::
          {:ok, issuance_context()} | {:error, Error.t()}
  def resolve_context(%Client{} = client, request) do
    with {:ok, resolved_dpop_policy} <- resolve_policy(client, request),
         {:ok, resolved_security_profile} <- resolve_security_profile(client, request) do
      effective_dpop_required =
        resolved_dpop_policy.dpop_required? or resolved_security_profile.fapi_2_0_security?

      effective_mode =
        if effective_dpop_required, do: :dpop, else: resolved_dpop_policy.effective_policy

      with {:ok, proof} <- validate_proof_with_flag(effective_dpop_required, request),
           :ok <- record_dpop_proof_use(proof, request) do
        {:ok, issuance_context(effective_mode, proof, resolved_security_profile)}
      end
    end
  end

  defp validate_proof_with_flag(true, request),
    do: validate_proof(%{dpop_required?: true}, request)

  defp validate_proof_with_flag(false, request),
    do: validate_proof(%{dpop_required?: false}, request)

  @spec resolve_refresh_context(Client.t(), Token.t(), map()) ::
          {:ok, issuance_context()} | {:error, Error.t()}
  def resolve_refresh_context(%Client{} = client, %Token{} = presented_refresh_token, request) do
    with {:ok, resolved_security_profile} <- resolve_security_profile(client, request),
         {:ok, expected_cnf} <- refresh_binding_cnf(presented_refresh_token),
         {:ok, proof} <- validate_refresh_proof(expected_cnf, resolved_security_profile, request),
         :ok <- record_dpop_proof_use(proof, request) do
      effective_mode =
        if resolved_security_profile.fapi_2_0_security? or
             refresh_binding_mode(expected_cnf) == :dpop,
           do: :dpop,
           else: :bearer

      {:ok, issuance_context(effective_mode, proof, resolved_security_profile)}
    end
  end

  defp resolve_policy(%Client{} = client, request) do
    with {:ok, server_policy} <- server_policy_store(request).get_server_policy(),
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

  defp resolve_security_profile(%Client{} = client, request) do
    with {:ok, server_policy} <- server_policy_store(request).get_server_policy() do
      {:ok, SecurityProfile.resolve_effective_profile(server_policy, client)}
    else
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

  defp validate_proof(%{dpop_required?: false}, request) do
    case normalize_optional_string(Map.get(request, :dpop, Map.get(request, "dpop"))) do
      nil -> {:ok, nil}
      proof -> validate_proof_value(proof, request)
    end
  end

  defp validate_proof(%{dpop_required?: true}, request) do
    case normalize_optional_string(Map.get(request, :dpop, Map.get(request, "dpop"))) do
      nil -> {:error, invalid_dpop_proof("A valid DPoP proof is required", :missing_dpop_proof)}
      proof -> validate_proof_value(proof, request)
    end
  end

  defp validate_proof_value(proof, request) do
    case DPoP.validate_proof(
           proof,
           method: request_method(request),
           target_uri: token_endpoint_uri(),
           now: now(request),
           max_age: Keyword.get(request_options(request), :dpop_max_age, 300),
           clock_skew: Keyword.get(request_options(request), :dpop_clock_skew, 30)
         ) do
      {:ok, %DPoP{} = validated_proof} ->
        {:ok, validated_proof}

      {:error, reason} when is_atom(reason) ->
        {:error, invalid_dpop_proof("The DPoP proof is invalid", reason)}
    end
  end

  defp validate_refresh_proof(expected_cnf, resolved_security_profile, request) do
    cond do
      resolved_security_profile.fapi_2_0_security? ->
        # FAPI 2.0 requires DPoP for all token requests, even if the refresh token was bearer.
        case normalize_optional_string(Map.get(request, :dpop, Map.get(request, "dpop"))) do
          nil ->
            {:error, invalid_dpop_proof("A valid DPoP proof is required", :missing_dpop_proof)}

          proof ->
            validate_proof_value(proof, request)
        end

      is_nil(expected_cnf) ->
        {:ok, nil}

      match?(%{"jkt" => jkt} when is_binary(jkt), expected_cnf) ->
        case normalize_optional_string(Map.get(request, :dpop, Map.get(request, "dpop"))) do
          nil ->
            {:error, invalid_dpop_proof("A valid DPoP proof is required", :missing_dpop_proof)}

          proof ->
            validate_proof_value(proof, request)
        end

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

  defp record_dpop_proof_use(nil, _request), do: :ok

  defp record_dpop_proof_use(%DPoP{} = validated_proof, request) do
    with {:ok, %DpopReplay{} = replay} <- build_dpop_replay(validated_proof, request),
         {:ok, result} <- dpop_replay_store(request).record_dpop_proof(replay) do
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

  defp issuance_context(:dpop, %DPoP{} = proof, security_profile) do
    %{
      mode: :dpop,
      proof: proof,
      jkt: proof.jkt,
      cnf: %{"jkt" => proof.jkt},
      token_type: "DPoP",
      security_profile: security_profile
    }
  end

  defp issuance_context(_mode, _proof, security_profile) do
    %{
      mode: :bearer,
      proof: nil,
      jkt: nil,
      cnf: nil,
      token_type: "Bearer",
      security_profile: security_profile
    }
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

  defp refresh_binding_cnf(%Token{cnf: nil}), do: {:ok, nil}
  defp refresh_binding_cnf(%Token{cnf: %{"jkt" => jkt} = cnf}) when is_binary(jkt), do: {:ok, cnf}

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
  defp refresh_binding_mode(_cnf), do: :dpop

  defp invalid_dpop_proof(description, reason_code) do
    oauth_error(400, "invalid_dpop_proof", description, reason_code)
  end

  defp oauth_error(status, error, description, reason_code) do
    %Error{
      status: status,
      error: error,
      error_description: description,
      reason_code: reason_code
    }
  end

  defp server_policy_store(request),
    do:
      Keyword.get_lazy(request_options(request), :server_policy_store, fn ->
        Keyword.get(request_options(request), :client_store, Config.repo!())
      end)

  defp dpop_replay_store(request),
    do:
      Keyword.get_lazy(request_options(request), :dpop_replay_store, fn ->
        Keyword.get(request_options(request), :client_store, Config.repo!())
      end)

  defp now(request),
    do:
      request
      |> request_options()
      |> Keyword.get_lazy(:now, fn -> &DateTime.utc_now/0 end)
      |> then(& &1.())

  defp request_options(request) do
    Map.get(request, :opts, Map.get(request, "opts", []))
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
