defmodule Lockspire.Protocol.DcrPolicy do
  @moduledoc """
  Resolves the effective DCR policy for an inbound RFC 7591 client registration request
  as the intersection of:

    1. ServerPolicy DCR allowlists (the operator-configured envelope)
    2. InitialAccessToken policy_overrides (when an IAT was redeemed; nil otherwise)
    3. Inbound RFC 7591 client metadata (what the registrant requested)

  Intersection-only: the resolver never widens any allowlist. IAT overrides are assumed
  already-narrowed to ⊆ server allowlist at IAT-mint time (Phase 28 admin path enforces
  this). If an out-of-allowlist override slips through (e.g. policy was tightened after
  IAT mint), `MapSet.intersection/2` naturally drops it — never widens.

  Returns:
    `{:ok, %Resolved{}}` — the effective policy bound to this request
    `{:error, :invalid_client_metadata, %{field, reason, allowed}}` — first inbound value
      not in the server allowlist; field names the offending axis (e.g. `:scope`,
      `:grant_types`, `:redirect_uri_scheme`, `:redirect_uri_host`,
      `:token_endpoint_auth_method`).

  Note on `redirect_uris` data carriage: the `Resolved` substruct exposes the deduplicated
  `allowed_redirect_uri_schemes` and `allowed_redirect_uri_hosts` axes (the resolver's
  job is bound-checking, not data carriage). The validated `redirect_uris` list itself is
  NOT carried on `Resolved.t()`. Phase 26's intake validator and Phase 27's controller
  take the original `inbound["redirect_uris"]` list directly once the resolver returns
  `:ok`.

  Mirrors `Lockspire.Protocol.ParPolicy` shape (the only existing resolver precedent in
  the repo).
  """

  alias Lockspire.Domain.ServerPolicy

  defmodule Resolved do
    @moduledoc false

    @type t :: %__MODULE__{
            allowed_scopes: [String.t()],
            allowed_grant_types: [String.t()],
            allowed_response_types: [String.t()],
            allowed_redirect_uri_schemes: [String.t()],
            allowed_redirect_uri_hosts: [String.t()],
            allowed_token_endpoint_auth_methods: [String.t()],
            default_client_lifetime_seconds: non_neg_integer() | nil,
            default_client_secret_lifetime_seconds: non_neg_integer() | nil,
            default_registration_access_token_lifetime_seconds: non_neg_integer() | nil
          }

    defstruct allowed_scopes: [],
              allowed_grant_types: [],
              allowed_response_types: [],
              allowed_redirect_uri_schemes: [],
              allowed_redirect_uri_hosts: [],
              allowed_token_endpoint_auth_methods: [],
              default_client_lifetime_seconds: nil,
              default_client_secret_lifetime_seconds: nil,
              default_registration_access_token_lifetime_seconds: nil
  end

  @type error_detail :: %{field: atom(), reason: atom(), allowed: list()}

  @spec resolve(ServerPolicy.t(), map() | nil, map()) ::
          {:ok, Resolved.t()} | {:error, :invalid_client_metadata, error_detail()}
  def resolve(%ServerPolicy{} = server_policy, iat_overrides, inbound_metadata)
      when (is_map(iat_overrides) or is_nil(iat_overrides)) and is_map(inbound_metadata) do
    with {:ok, scopes} <-
           intersect_axis(
             :scope,
             scope_inbound(inbound_metadata),
             server_policy.dcr_allowed_scopes,
             override_for(iat_overrides, "allowed_scopes")
           ),
         {:ok, grant_types} <-
           intersect_axis(
             :grant_types,
             list_inbound(inbound_metadata, "grant_types"),
             server_policy.dcr_allowed_grant_types,
             override_for(iat_overrides, "allowed_grant_types")
           ),
         {:ok, response_types} <-
           intersect_axis(
             :response_types,
             list_inbound(inbound_metadata, "response_types"),
             server_policy.dcr_allowed_response_types,
             override_for(iat_overrides, "allowed_response_types")
           ),
         {:ok, schemes, hosts} <-
           intersect_redirect_uris(
             list_inbound(inbound_metadata, "redirect_uris"),
             server_policy.dcr_allowed_redirect_uri_schemes,
             server_policy.dcr_allowed_redirect_uri_hosts,
             override_for(iat_overrides, "allowed_redirect_uri_schemes"),
             override_for(iat_overrides, "allowed_redirect_uri_hosts")
           ),
         {:ok, auth_methods} <-
           intersect_axis(
             :token_endpoint_auth_method,
             token_endpoint_auth_method_inbound(inbound_metadata),
             server_policy.dcr_allowed_token_endpoint_auth_methods,
             override_for(iat_overrides, "allowed_token_endpoint_auth_methods")
           ) do
      {:ok,
       %Resolved{
         allowed_scopes: scopes,
         allowed_grant_types: grant_types,
         allowed_response_types: response_types,
         allowed_redirect_uri_schemes: schemes,
         allowed_redirect_uri_hosts: hosts,
         allowed_token_endpoint_auth_methods: auth_methods,
         default_client_lifetime_seconds: server_policy.dcr_default_client_lifetime_seconds,
         default_client_secret_lifetime_seconds:
           server_policy.dcr_default_client_secret_lifetime_seconds,
         default_registration_access_token_lifetime_seconds:
           server_policy.dcr_default_registration_access_token_lifetime_seconds
       }}
    end
  end

  defp intersect_axis(field, requested_list, server_allowlist, iat_override_list) do
    requested = MapSet.new(requested_list || [])
    server_set = MapSet.new(server_allowlist || [])

    # Explicit nil check (not truthy) so that an IAT override like
    # `%{"allowed_scopes" => []}` correctly narrows the axis to the empty set rather than
    # being treated as "no override" — and so that a future change to `override_for/2`
    # which returns `[]` for "absent" cannot silently flip the meaning.
    iat_set =
      case iat_override_list do
        nil -> server_set
        list when is_list(list) -> MapSet.new(list)
      end

    case requested |> MapSet.difference(server_set) |> MapSet.to_list() do
      [] ->
        effective =
          requested
          |> MapSet.intersection(server_set)
          |> MapSet.intersection(iat_set)
          |> MapSet.to_list()

        {:ok, effective}

      [_offending | _] ->
        {:error, :invalid_client_metadata,
         %{field: field, reason: :not_in_allowlist, allowed: server_allowlist || []}}
    end
  end

  # RFC 3986 §3.1 (scheme) and §3.2.2 (host) declare both case-insensitive. We canonicalise
  # to lowercase on both sides of the intersection so operator allowlists like
  # `["partner.example.com"]` accept inbound `"https://Partner.Example.com/cb"`, and so an
  # operator who happens to seed mixed-case `"PARTNER.EXAMPLE.COM"` does not silently brick
  # the DCR endpoint for every correctly-lowercased registrant. Both lists must be downcased
  # — canonicalising only the inbound side perpetuates the bug when the operator stores
  # mixed case.
  defp intersect_redirect_uris(
         redirect_uris,
         server_schemes,
         server_hosts,
         iat_schemes,
         iat_hosts
       ) do
    parsed =
      redirect_uris
      |> List.wrap()
      |> Enum.map(&URI.parse/1)

    case Enum.find(parsed, fn uri -> is_nil(uri.scheme) or is_nil(uri.host) end) do
      %URI{} ->
        {:error, :invalid_client_metadata,
         %{field: :redirect_uris, reason: :unparseable, allowed: []}}

      nil ->
        requested_schemes = parsed |> Enum.map(&String.downcase(&1.scheme)) |> Enum.uniq()
        requested_hosts = parsed |> Enum.map(&String.downcase(&1.host)) |> Enum.uniq()

        with {:ok, schemes} <-
               intersect_axis(
                 :redirect_uri_scheme,
                 requested_schemes,
                 downcase_list(server_schemes),
                 downcase_list(iat_schemes)
               ),
             {:ok, hosts} <-
               intersect_axis(
                 :redirect_uri_host,
                 requested_hosts,
                 downcase_list(server_hosts),
                 downcase_list(iat_hosts)
               ) do
          {:ok, schemes, hosts}
        end
    end
  end

  defp downcase_list(nil), do: nil
  defp downcase_list(list) when is_list(list), do: Enum.map(list, &String.downcase/1)

  defp scope_inbound(%{"scope" => scope}) when is_binary(scope),
    do: String.split(scope, " ", trim: true)

  defp scope_inbound(_inbound), do: []

  defp token_endpoint_auth_method_inbound(%{"token_endpoint_auth_method" => method})
       when is_binary(method),
       do: [method]

  defp token_endpoint_auth_method_inbound(_inbound), do: []

  defp list_inbound(inbound, key) when is_map(inbound) and is_binary(key) do
    case Map.get(inbound, key) do
      nil -> []
      value when is_list(value) -> value
      value when is_binary(value) -> [value]
      _other -> []
    end
  end

  defp override_for(nil, _key), do: nil

  defp override_for(overrides, key) when is_map(overrides) and is_binary(key) do
    case Map.get(overrides, key) do
      nil -> nil
      value when is_list(value) -> value
      _other -> nil
    end
  end
end
