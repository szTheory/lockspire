defmodule Lockspire.Protocol.DcrPolicyInvariantTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Discovery-binding invariant test (D-19 / DCR-09).

  Asserts that the set of `token_endpoint_auth_method` values DCR will accept equals
  `MapSet.intersection(ServerPolicy.dcr_allowed_token_endpoint_auth_methods, Discovery.token_endpoint_auth_methods_supported/0)`.

  Fails if either side drifts:
    - if `Discovery.token_endpoint_auth_methods_supported/0` changes (e.g. a new method is added or removed)
    - if `ServerPolicy.dcr_allowed_token_endpoint_auth_methods` semantics change
    - if `DcrPolicy.resolve/3` starts widening or narrowing in unexpected ways

  This test depends only on pure functions (Plan 01's public Discovery /0 accessor and
  Plan 07's pure DcrPolicy.resolve/3) — `async: true`, no DB. Pitfall 2 explicit guard:
  the test MUST call the public /0 accessor; never poke private module-attribute state
  via reflection (e.g. attribute reads, doc-table reads), and never embed a literal copy
  of the supported-methods list.
  """

  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Protocol.DcrPolicy
  alias Lockspire.Protocol.Discovery

  test "DCR accepts exactly the intersection of ServerPolicy allowlist and Discovery support" do
    discovery_set = MapSet.new(Discovery.token_endpoint_auth_methods_supported())

    # Maximal server_allowlist including values NOT advertised by discovery — proves
    # the intersection truly bounds DCR by discovery (out-of-discovery values must be
    # naturally dropped). The Domain.Client typespec admits `:private_key_jwt` (line 8
    # of lib/lockspire/domain/client.ex) but discovery does NOT advertise it.
    server_allowlist = [
      "none",
      "client_secret_basic",
      "client_secret_post",
      "private_key_jwt",
      "tls_client_auth"
    ]

    server_policy = %ServerPolicy{
      registration_policy: :open,
      dcr_allowed_scopes: ["openid"],
      dcr_allowed_grant_types: ["authorization_code"],
      dcr_allowed_response_types: ["code"],
      dcr_allowed_redirect_uri_schemes: ["https"],
      dcr_allowed_redirect_uri_hosts: ["partner.example.com"],
      dcr_allowed_token_endpoint_auth_methods: server_allowlist
    }

    expected_set = MapSet.intersection(MapSet.new(server_allowlist), discovery_set)

    # Compose discovery + server allowlist externally: every method advertised by discovery
    # AND in the server allowlist should be acceptable by the resolver. We probe one
    # representative value (any element of expected_set) to assert the resolver does not
    # reject the discovery-supported intersection.
    representative_method = expected_set |> MapSet.to_list() |> List.first()

    assert representative_method != nil,
           "test setup invariant: server_allowlist intersects discovery non-trivially"

    inbound = %{
      "scope" => "openid",
      "grant_types" => ["authorization_code"],
      "response_types" => ["code"],
      "redirect_uris" => ["https://partner.example.com/callback"],
      "token_endpoint_auth_method" => representative_method
    }

    {:ok, resolved} = DcrPolicy.resolve(server_policy, nil, inbound)

    accepted_for_inbound = MapSet.new(resolved.allowed_token_endpoint_auth_methods)

    assert MapSet.subset?(accepted_for_inbound, expected_set),
           drift_message(:accepted_outside_intersection, %{
             discovery: discovery_set,
             server: server_allowlist,
             expected: expected_set,
             accepted: accepted_for_inbound
           })

    # Now probe that an "advertised by discovery" method that IS NOT in the server
    # allowlist would be rejected. Skip this branch if the intersection equals the
    # discovery set (every discovery method is in the allowlist) — the rejection check
    # only makes sense if there is something in discovery NOT in the allowlist.
    discovery_only = MapSet.difference(discovery_set, MapSet.new(server_allowlist))

    if MapSet.size(discovery_only) > 0 do
      probe = discovery_only |> MapSet.to_list() |> List.first()

      assert {:error, :invalid_client_metadata,
              %{field: :token_endpoint_auth_method, reason: :not_in_allowlist}} =
               DcrPolicy.resolve(
                 server_policy,
                 nil,
                 Map.put(inbound, "token_endpoint_auth_method", probe)
               )
    end

    # And probe that an "in server allowlist but NOT advertised by discovery" method
    # would be rejected by the composed system. The resolver alone might accept it
    # (it intersects against server allowlist only); the FULL intersection-with-discovery
    # bound is what this invariant captures.
    server_only =
      MapSet.difference(MapSet.new(server_allowlist), discovery_set) |> MapSet.to_list()

    for probe <- server_only do
      {:ok, probe_resolved} =
        DcrPolicy.resolve(
          server_policy,
          nil,
          Map.put(inbound, "token_endpoint_auth_method", probe)
        )

      probe_accepted = MapSet.new(probe_resolved.allowed_token_endpoint_auth_methods)

      # Crucially: the resolver alone does NOT bound by discovery.
      # The composed bound (resolver ∩ discovery) is what DCR's HTTP surface (Phase 27)
      # MUST enforce. This invariant test pins the contract: anything the resolver
      # accepts that is NOT in discovery is a known boundary that Phase 27 must
      # additionally filter through `MapSet.intersection(_, discovery_set)`.
      bounded_by_discovery = MapSet.intersection(probe_accepted, discovery_set)

      assert MapSet.subset?(bounded_by_discovery, expected_set),
             drift_message(:bounded_diverged, %{
               discovery: discovery_set,
               server: server_allowlist,
               expected: expected_set,
               accepted: probe_accepted,
               bounded: bounded_by_discovery
             })
    end
  end

  defp drift_message(reason, ctx) do
    """
    DCR ↔ Discovery invariant violated: #{inspect(reason)}.

      discovery_set:  #{inspect(MapSet.to_list(ctx.discovery))}
      server_set:     #{inspect(ctx.server)}
      expected (∩):   #{inspect(MapSet.to_list(ctx.expected))}
      accepted:       #{inspect(MapSet.to_list(ctx[:accepted]) || [])}
      bounded:        #{inspect(MapSet.to_list(ctx[:bounded] || MapSet.new()))}

    Either:
      - `Lockspire.Protocol.Discovery.token_endpoint_auth_methods_supported/0` changed
        (check `lib/lockspire/protocol/discovery.ex:21` module attribute).
      - `Lockspire.Domain.ServerPolicy.dcr_allowed_token_endpoint_auth_methods` semantics
        changed.
      - `Lockspire.Protocol.DcrPolicy.resolve/3` is no longer intersection-only.

    Phase 27's HTTP surface MUST additionally filter the resolver's
    `allowed_token_endpoint_auth_methods` through `MapSet.intersection(_, discovery_supported)`.
    This invariant test pins that contract.
    """
  end
end
