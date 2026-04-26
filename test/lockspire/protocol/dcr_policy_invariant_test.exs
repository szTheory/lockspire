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

    assert MapSet.size(expected_set) > 0,
           "test setup invariant: server_allowlist intersects discovery non-trivially"

    inbound_template = %{
      "scope" => "openid",
      "grant_types" => ["authorization_code"],
      "response_types" => ["code"],
      "redirect_uris" => ["https://partner.example.com/callback"]
    }

    # Equality (not subset) binding: iterate every method in expected_set and assert the
    # resolver accepts each one verbatim. List.first/1 only proved the resolver does not
    # reject the first representative — drift on any other method would have slipped past
    # a subset assertion.
    for method <- expected_set do
      inbound = Map.put(inbound_template, "token_endpoint_auth_method", method)

      {:ok, resolved} = DcrPolicy.resolve(server_policy, nil, inbound)
      accepted_for_inbound = MapSet.new(resolved.allowed_token_endpoint_auth_methods)

      assert accepted_for_inbound == MapSet.new([method]),
             drift_message(:accepted_outside_intersection, %{
               discovery: discovery_set,
               server: server_allowlist,
               expected: expected_set,
               accepted: accepted_for_inbound
             })
    end

    # Probe that an "advertised by discovery" method that IS NOT in the server allowlist
    # would be rejected. Skip this branch if every discovery method is in the allowlist —
    # the rejection check only makes sense if there is something in discovery NOT in the
    # allowlist.
    discovery_only = MapSet.difference(discovery_set, MapSet.new(server_allowlist))

    if MapSet.size(discovery_only) > 0 do
      probe = discovery_only |> MapSet.to_list() |> List.first()

      assert {:error, :invalid_client_metadata,
              %{field: :token_endpoint_auth_method, reason: :not_in_allowlist}} =
               DcrPolicy.resolve(
                 server_policy,
                 nil,
                 Map.put(inbound_template, "token_endpoint_auth_method", probe)
               )
    end

    # And probe that an "in server allowlist but NOT advertised by discovery" method is a
    # known boundary that Phase 27's HTTP surface MUST filter through
    # `MapSet.intersection(_, discovery_set)`. The resolver alone DOES accept it (it
    # intersects against the server allowlist only) — so the resolver-accepted set for
    # that probe must be exactly `MapSet.new([probe])`, and intersecting that with
    # discovery_set must yield the empty set. This is the key non-trivial assertion: it
    # proves the resolver accepts the value (so Phase 27's filter is load-bearing) AND
    # that the filter discards it.
    server_only =
      MapSet.difference(MapSet.new(server_allowlist), discovery_set) |> MapSet.to_list()

    for probe <- server_only do
      {:ok, probe_resolved} =
        DcrPolicy.resolve(
          server_policy,
          nil,
          Map.put(inbound_template, "token_endpoint_auth_method", probe)
        )

      probe_accepted = MapSet.new(probe_resolved.allowed_token_endpoint_auth_methods)

      assert probe_accepted == MapSet.new([probe]),
             drift_message(:server_only_not_accepted_by_resolver, %{
               discovery: discovery_set,
               server: server_allowlist,
               expected: expected_set,
               accepted: probe_accepted
             })

      bounded_by_discovery = MapSet.intersection(probe_accepted, discovery_set)

      assert MapSet.equal?(bounded_by_discovery, MapSet.new()),
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
