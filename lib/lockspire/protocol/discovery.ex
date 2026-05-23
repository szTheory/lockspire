defmodule Lockspire.Protocol.Discovery do
  @moduledoc """
  Builds truth-based OIDC discovery metadata from Lockspire config and mounted routes.
  """

  alias Lockspire.Config
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Protocol.Discovery.AuthorizationResponseCapabilities
  alias Lockspire.Protocol.DPoP
  alias Lockspire.Protocol.SecurityProfile

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
    "introspection_endpoint" => "/introspect",
    "backchannel_authentication_endpoint" => "/bc-authorize"
  }

  @response_types_supported ["code"]
  @grant_types_supported [
    "authorization_code",
    "refresh_token",
    "urn:ietf:params:oauth:grant-type:device_code",
    "urn:openid:params:grant-type:ciba"
  ]
  @code_challenge_methods_supported ["S256"]
  @subject_types_supported ["public"]
  @introspection_supported_auth_methods [
    "client_secret_basic",
    "client_secret_post",
    "private_key_jwt"
  ]

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
  def token_endpoint_auth_methods_supported, do: ClientAuth.supported_auth_method_names()

  @doc """
  Returns the truth-based list of `token_endpoint_auth_method` values this issuer's
  `openid-configuration` document actually publishes — i.e., `[]` when the
  `token_endpoint` route is not mounted, otherwise the subset the current runtime can
  truthfully verify on the token endpoint.
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

    authorization_response_capabilities =
      AuthorizationResponseCapabilities.metadata(endpoint_metadata, global_security_profile())

    %{
      "issuer" => issuer,
      "scopes_supported" => scopes_supported(),
      "response_types_supported" => @response_types_supported,
      "grant_types_supported" => grant_types_supported(endpoint_metadata),
      "token_endpoint_auth_methods_supported" =>
        token_endpoint_auth_methods_supported(endpoint_metadata),
      "code_challenge_methods_supported" => code_challenge_methods_supported(endpoint_metadata),
      "subject_types_supported" => @subject_types_supported,
      "id_token_signing_alg_values_supported" => id_token_signing_alg_values_supported()
    }
    |> Map.merge(authorization_response_capabilities)
    |> Map.merge(endpoint_metadata)
    |> put_endpoint_auth_metadata(endpoint_metadata)
    |> maybe_put_dpop_metadata(endpoint_metadata)
    |> maybe_put_ciba_metadata(endpoint_metadata)
    |> maybe_put_resource_indicators_metadata(endpoint_metadata)
    |> maybe_put_authorization_details_metadata(endpoint_metadata)
    |> maybe_put_mtls_endpoint_aliases(endpoint_metadata)
    |> put_bcl_fcl_metadata()
    |> put_iss_parameter_metadata()
    |> maybe_put_par_required_metadata()
  end

  defp maybe_put_mtls_endpoint_aliases(metadata, endpoint_metadata) do
    case Config.mtls_issuer() do
      mtls_issuer when is_binary(mtls_issuer) ->
        mtls_endpoints = [
          "token_endpoint",
          "revocation_endpoint",
          "introspection_endpoint",
          "device_authorization_endpoint",
          "pushed_authorization_request_endpoint",
          "userinfo_endpoint",
          "backchannel_authentication_endpoint"
        ]

        aliases =
          endpoint_metadata
          |> Map.take(mtls_endpoints)
          |> Enum.map(fn {key, _url} ->
            path = Map.fetch!(@endpoint_paths, key)
            {key, issuer_url(mtls_issuer, path)}
          end)
          |> Map.new()

        if map_size(aliases) > 0 do
          Map.put(metadata, "mtls_endpoint_aliases", aliases)
        else
          metadata
        end

      _ ->
        metadata
    end
  end

  defp maybe_put_ciba_metadata(metadata, endpoint_metadata) do
    if Map.has_key?(endpoint_metadata, "backchannel_authentication_endpoint") do
      Map.merge(metadata, %{
        "backchannel_token_delivery_modes_supported" => ["poll"],
        "backchannel_user_code_parameter_supported" => false
      })
    else
      metadata
    end
  end

  defp id_token_signing_alg_values_supported do
    SecurityProfile.allowed_signing_algorithms(global_security_profile())
  end

  defp global_security_profile do
    case Lockspire.Storage.Ecto.Repository.get_server_policy() do
      {:ok, policy} -> policy.security_profile
      _ -> :none
    end
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
      published_direct_client_auth_methods()
    else
      []
    end
  end

  defp put_endpoint_auth_metadata(metadata, endpoint_metadata) do
    metadata
    |> maybe_put_endpoint_auth_methods(
      "token_endpoint_auth_methods_supported",
      token_endpoint_auth_methods_supported(endpoint_metadata)
    )
    |> maybe_put_endpoint_auth_signing_algorithms(
      "token_endpoint_auth_methods_supported",
      "token_endpoint_auth_signing_alg_values_supported"
    )
    |> maybe_put_endpoint_auth_methods(
      "revocation_endpoint_auth_methods_supported",
      revocation_endpoint_auth_methods_supported(endpoint_metadata)
    )
    |> maybe_put_endpoint_auth_signing_algorithms(
      "revocation_endpoint_auth_methods_supported",
      "revocation_endpoint_auth_signing_alg_values_supported"
    )
    |> maybe_put_endpoint_auth_methods(
      "introspection_endpoint_auth_methods_supported",
      introspection_endpoint_auth_methods_supported(endpoint_metadata)
    )
    |> maybe_put_endpoint_auth_signing_algorithms(
      "introspection_endpoint_auth_methods_supported",
      "introspection_endpoint_auth_signing_alg_values_supported"
    )
  end

  defp maybe_put_endpoint_auth_methods(metadata, _key, []), do: metadata

  defp maybe_put_endpoint_auth_methods(metadata, key, methods),
    do: Map.put(metadata, key, methods)

  defp maybe_put_endpoint_auth_signing_algorithms(metadata, methods_key, algorithms_key) do
    if "private_key_jwt" in Map.get(metadata, methods_key, []) do
      Map.put(
        metadata,
        algorithms_key,
        SecurityProfile.allowed_signing_algorithms(global_security_profile())
      )
    else
      metadata
    end
  end

  defp revocation_endpoint_auth_methods_supported(endpoint_metadata) do
    if Map.has_key?(endpoint_metadata, "revocation_endpoint") do
      published_direct_client_auth_methods()
    else
      []
    end
  end

  defp introspection_endpoint_auth_methods_supported(endpoint_metadata) do
    if Map.has_key?(endpoint_metadata, "introspection_endpoint") do
      published_direct_client_auth_methods()
      |> Enum.filter(&(&1 in @introspection_supported_auth_methods))
    else
      []
    end
  end

  defp published_direct_client_auth_methods do
    ClientAuth.supported_auth_method_names()
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

  defp maybe_put_resource_indicators_metadata(metadata, endpoint_metadata) do
    if authorization_code_surface_mounted?(endpoint_metadata) do
      Map.put(metadata, "resource_indicators_supported", true)
    else
      metadata
    end
  end

  defp maybe_put_authorization_details_metadata(metadata, endpoint_metadata) do
    case {authorization_code_surface_mounted?(endpoint_metadata), Config.rar_types_supported()} do
      {true, [_ | _] = rar_types_supported} ->
        Map.put(metadata, "authorization_details_types_supported", rar_types_supported)

      _ ->
        metadata
    end
  end

  defp authorization_code_surface_mounted?(endpoint_metadata) do
    Map.has_key?(endpoint_metadata, "authorization_endpoint") and
      Map.has_key?(endpoint_metadata, "token_endpoint")
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

  defp put_iss_parameter_metadata(metadata) do
    Map.put(metadata, "authorization_response_iss_parameter_supported", true)
  end

  defp maybe_put_par_required_metadata(metadata) do
    if global_security_profile() in [:fapi_2_0_security, :fapi_2_0_message_signing] do
      Map.put(metadata, "require_pushed_authorization_requests", true)
    else
      metadata
    end
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
