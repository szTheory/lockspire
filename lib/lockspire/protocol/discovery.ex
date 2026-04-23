defmodule Lockspire.Protocol.Discovery do
  @moduledoc """
  Builds truth-based OIDC discovery metadata from Lockspire config and mounted routes.
  """

  alias Lockspire.Config

  @endpoint_paths %{
    "authorization_endpoint" => "/authorize",
    "token_endpoint" => "/token",
    "userinfo_endpoint" => "/userinfo",
    "jwks_uri" => "/jwks",
    "revocation_endpoint" => "/revoke",
    "introspection_endpoint" => "/introspect"
  }

  @response_types_supported ["code"]
  @response_modes_supported ["query"]
  @grant_types_supported ["authorization_code"]
  @token_endpoint_auth_methods_supported ["none", "client_secret_basic", "client_secret_post"]
  @code_challenge_methods_supported ["S256"]
  @subject_types_supported ["public"]
  @id_token_signing_alg_values_supported ["RS256"]

  @spec openid_configuration() :: map()
  def openid_configuration do
    issuer = Config.issuer!()

    endpoint_metadata =
      mounted_route_paths()
      |> Enum.reduce(%{}, fn path, acc ->
        case endpoint_metadata_entry(issuer, path) do
          nil -> acc
          {key, value} -> Map.put(acc, key, value)
        end
      end)

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
      "id_token_signing_alg_values_supported" => @id_token_signing_alg_values_supported
    }
    |> Map.merge(endpoint_metadata)
  end

  defp mounted_route_paths do
    Lockspire.Web.Router
    |> Phoenix.Router.routes()
    |> Enum.map(& &1.path)
    |> MapSet.new()
  end

  defp endpoint_metadata_entry(issuer, path) do
    Enum.find_value(@endpoint_paths, fn {key, route_path} ->
      if route_path == path do
        {key, issuer_url(issuer, route_path)}
      end
    end)
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

  defp issuer_url(issuer, path) do
    issuer
    |> URI.parse()
    |> Map.update!(:path, fn issuer_path ->
      Path.join(issuer_path || "/", String.trim_leading(path, "/"))
    end)
    |> URI.to_string()
  end
end
