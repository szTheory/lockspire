defmodule Lockspire.Protocol.Discovery do
  @moduledoc """
  Builds truth-based OIDC discovery metadata from Lockspire config and mounted routes.
  """

  alias Lockspire.Config
  alias Lockspire.Protocol.DPoP

  @endpoint_paths %{
    "authorization_endpoint" => "/authorize",
    "device_authorization_endpoint" => "/device/code",
    "end_session_endpoint" => "/end_session",
    "pushed_authorization_request_endpoint" => "/par",
    "registration_endpoint" => "/register",
    "token_endpoint" => "/token",
    "userinfo_endpoint" => "/userinfo",
    "jwks_uri" => "/jwks",
    "revocation_endpoint" => "/revoke",
    "introspection_endpoint" => "/introspect"
  }

  @response_types_supported ["code"]
  @response_modes_supported ["query"]
  @grant_types_supported [
    "authorization_code",
    "refresh_token",
    "urn:ietf:params:oauth:grant-type:device_code"
  ]
  @token_endpoint_auth_methods_supported ["none", "client_secret_basic", "client_secret_post"]
  @code_challenge_methods_supported ["S256"]
  @subject_types_supported ["public"]

  @doc """
  Returns the **static** module attribute list of `token_endpoint_auth_method` values this
  issuer can advertise — the maximum set, irrespective of mounted-route truthfulness.

  This is what the DCR invariant test (Phase 25) pins against because it must remain a
  pure 0-arity (no router lookup, no DB). It is the upper bound: the actually-published
  discovery document at `/.well-known/openid-configuration` may publish `[]` instead when
  the host app does not mount the `token_endpoint` route. Use
  `published_token_endpoint_auth_methods_supported/0` for the truth-based set; that is
  what Phase 27's HTTP DCR surface MUST filter the resolver's accepted methods through.
  """
  @spec token_endpoint_auth_methods_supported() :: [String.t()]
  def token_endpoint_auth_methods_supported, do: @token_endpoint_auth_methods_supported

  @doc """
  Returns the truth-based list of `token_endpoint_auth_method` values this issuer's
  `openid-configuration` document actually publishes — i.e., `[]` when the
  `token_endpoint` route is not mounted, otherwise the full static list.

  Phase 27's HTTP DCR surface MUST filter the resolver's accepted
  `allowed_token_endpoint_auth_methods` through this set (e.g.,
  `MapSet.intersection(_, MapSet.new(published_token_endpoint_auth_methods_supported()))`)
  to avoid accepting methods the discovery document does not advertise.
  """
  @spec published_token_endpoint_auth_methods_supported() :: [String.t()]
  def published_token_endpoint_auth_methods_supported do
    token_endpoint_auth_methods_supported(mounted_endpoint_metadata())
  end

  defp mounted_endpoint_metadata do
    issuer = Config.issuer!()

    mounted_route_paths()
    |> Enum.reduce(%{}, fn path, acc ->
      case endpoint_metadata_entry(issuer, path) do
        nil -> acc
        {key, value} -> Map.put(acc, key, value)
      end
    end)
  end

  @spec openid_configuration() :: map()
  def openid_configuration do
    issuer = Config.issuer!()
    endpoint_metadata = mounted_endpoint_metadata()

    %{
      "issuer" => issuer,
      "scopes_supported" => scopes_supported(),
      "response_types_supported" => @response_types_supported,
      "response_modes_supported" => @response_modes_supported,
      "grant_types_supported" => grant_types_supported(endpoint_metadata),
      "token_endpoint_auth_methods_supported" =>
        token_endpoint_auth_methods_supported(endpoint_metadata),
      "code_challenge_methods_supported" => code_challenge_methods_supported(endpoint_metadata),
      "subject_types_supported" => @subject_types_supported,
      "id_token_signing_alg_values_supported" => id_token_signing_alg_values_supported()
    }
    |> Map.merge(endpoint_metadata)
    |> maybe_put_dpop_metadata(endpoint_metadata)
    |> put_bcl_fcl_metadata()
  end

  defp id_token_signing_alg_values_supported do
    profile =
      case Lockspire.Storage.Ecto.Repository.get_server_policy() do
        {:ok, policy} -> policy.security_profile
        _ -> :none
      end

    Lockspire.Protocol.SecurityProfile.allowed_signing_algorithms(profile)
  end

  defp mounted_route_paths do
    discovery_router()
    |> Phoenix.Router.routes()
    |> Enum.map(& &1.path)
    |> MapSet.new()
  end

  defp discovery_router do
    Application.get_env(:lockspire, :discovery_router, Lockspire.Web.Router)
  end

  defp endpoint_metadata_entry(issuer, path) do
    Enum.find_value(@endpoint_paths, fn {key, route_path} ->
      if route_path == path do
        if key == "registration_endpoint" and
             registration_disabled?() do
          nil
        else
          {key, issuer_url(issuer, route_path)}
        end
      end
    end)
  end

  defp registration_disabled? do
    case Lockspire.Storage.Ecto.Repository.get_server_policy() do
      {:ok, policy} -> policy.registration_policy == :disabled
      # Safe fallback
      _ -> true
    end
  end

  defp scopes_supported do
    ["openid" | Config.known_scopes()]
    |> Enum.uniq()
  end

  defp grant_types_supported(endpoint_metadata) do
    if Map.has_key?(endpoint_metadata, "token_endpoint") do
      @grant_types_supported
    else
      []
    end
  end

  defp token_endpoint_auth_methods_supported(endpoint_metadata) do
    if Map.has_key?(endpoint_metadata, "token_endpoint") do
      @token_endpoint_auth_methods_supported
    else
      []
    end
  end

  defp code_challenge_methods_supported(endpoint_metadata) do
    if Map.has_key?(endpoint_metadata, "authorization_endpoint") and
         Map.has_key?(endpoint_metadata, "token_endpoint") do
      @code_challenge_methods_supported
    else
      []
    end
  end

  defp maybe_put_dpop_metadata(metadata, endpoint_metadata) do
    if dpop_supported_surface_mounted?(endpoint_metadata) do
      Map.put(
        metadata,
        "dpop_signing_alg_values_supported",
        DPoP.signing_alg_values_supported()
      )
    else
      metadata
    end
  end

  defp dpop_supported_surface_mounted?(endpoint_metadata) do
    Map.has_key?(endpoint_metadata, "token_endpoint") and
      Map.has_key?(endpoint_metadata, "userinfo_endpoint")
  end

  defp put_bcl_fcl_metadata(metadata) do
    Map.merge(metadata, %{
      "backchannel_logout_supported" => true,
      "backchannel_logout_session_supported" => true,
      "frontchannel_logout_supported" => true,
      "frontchannel_logout_session_supported" => true
    })
  end

  defp issuer_url(issuer, path) do
    issuer
    |> URI.parse()
    |> Map.update!(:path, fn issuer_path ->
      Path.join(issuer_path || "/", String.trim_leading(path, "/"))
    end)
    |> URI.to_string()
  end
end
