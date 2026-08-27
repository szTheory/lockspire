---
phase: 134-architecture-topology
plan: 03
subsystem: discovery-topology
tags: [oauth, oidc, discovery, phoenix, xref]
requires: []
provides:
  - Delivery-edge mounted-route capability for OIDC discovery
  - Route-input-driven protocol discovery metadata
affects: [web-discovery, architecture-fitness]
tech-stack:
  added: []
  patterns: [neutral route capability, legacy configuration compatibility]
key-files:
  created:
    - lib/lockspire/discovery_routes.ex
    - test/lockspire/discovery_routes_test.exs
  modified:
    - lib/lockspire/protocol/discovery.ex
    - lib/lockspire/web/controllers/discovery_controller.ex
    - test/lockspire/protocol/discovery_test.exs
    - test/lockspire/web/discovery_controller_test.exs
decisions:
  - Protocol discovery accepts mounted path input while zero-arity APIs retain their behavior through the delivery-edge capability.
  - The legacy :discovery_router option remains a fallback behind :discovery_route_paths during v1 compatibility.
metrics:
  duration: 5m
  completed: 2026-08-27
status: complete
---

# Phase 134 Plan 03: Route-Driven Discovery Summary

OIDC discovery now derives public endpoint metadata from a neutral mounted-path capability, preserving current APIs and legacy router overrides while removing the discovery/controller/router Mix cycle.

## Completed Work

- Added `Lockspire.DiscoveryRoutes` as the Phoenix reflection and compatibility edge. It resolves `:discovery_route_paths` before the retained `:discovery_router` fallback.
- Added `Discovery.openid_configuration/1` and `published_token_endpoint_auth_methods_supported/1` for neutral route inputs; zero-arity public APIs remain available and use the edge capability.
- Updated the discovery controller to provide actual route paths, retaining its HTTP status, cache header, and JSON behavior.
- Characterized explicit path sets, legacy override behavior, configured capability precedence, default delivery behavior, and unmounted metadata truth.

## Verification

- `mix test test/lockspire/discovery_routes_test.exs test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs` — 48 tests, 0 failures.
- `mix xref graph --format cycles` — 4 remaining cycles; the former Discovery/DiscoveryController/Router cycle is absent.
- Confirmed `lib/lockspire/protocol/discovery.ex` contains no `Lockspire.Web` or `Phoenix.Router` reference.

## Commits

- `a7635fd` — test(134-03): characterize route-driven discovery
- `ea8a00b` — feat(134-03): inject neutral discovery route paths
- `249f791` — feat(134-03): resolve discovery routes in web delivery

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test fixture] Corrected the alternate router's fully-qualified module reference.**
- **Found during:** Task 1 focused verification.
- **Issue:** The nested router fixture was resolved as a nonexistent top-level `AlternateRouter` module.
- **Fix:** Configured its fully-qualified test module name.
- **Files modified:** `test/lockspire/discovery_routes_test.exs`
- **Commit:** `ea8a00b`

No security-relevant surface was added: route reflection remains at the existing Phoenix delivery boundary and unsupported configured capability values fail closed to an empty path set.

## Self-Check: PASSED

- Created capability and test files exist.
- All three task commits are present in git history.
