---
phase: 134-architecture-topology
reviewed: 2026-08-27T18:15:00Z
depth: deep
files_reviewed: 64
files_reviewed_list:
  - docs/architecture.md
  - docs/code-walkthrough.md
  - lib/lockspire/admin/clients.ex
  - lib/lockspire/client_lifecycle.ex
  - lib/lockspire/client_metadata.ex
  - lib/lockspire/clients.ex
  - lib/lockspire/config.ex
  - lib/lockspire/discovery_routes.ex
  - lib/lockspire/plug/enforce_sender_constraints.ex
  - lib/lockspire/protocol/access_token_signer.ex
  - lib/lockspire/protocol/authorization_request.ex
  - lib/lockspire/protocol/discovery.ex
  - lib/lockspire/protocol/protected_resource_dpop.ex
  - lib/lockspire/protocol/protected_resource_error.ex
  - lib/lockspire/protocol/pushed_authorization_request.ex
  - lib/lockspire/protocol/refresh_exchange.ex
  - lib/lockspire/protocol/registration.ex
  - lib/lockspire/protocol/registration_management.ex
  - lib/lockspire/protocol/request_object.ex
  - lib/lockspire/protocol/request_object/result.ex
  - lib/lockspire/protocol/rfc8693_exchange.ex
  - lib/lockspire/protocol/token_endpoint_dpop.ex
  - lib/lockspire/protocol/token_exchange.ex
  - lib/lockspire/protocol/token_exchange/authorization_code_grant.ex
  - lib/lockspire/protocol/token_exchange/ciba_grant.ex
  - lib/lockspire/protocol/token_exchange/compatibility.ex
  - lib/lockspire/protocol/token_exchange/device_code_grant.ex
  - lib/lockspire/protocol/token_exchange/grant_support.ex
  - lib/lockspire/protocol/token_exchange/internal/access_token_signer.ex
  - lib/lockspire/protocol/token_exchange/internal/authorization_code_grant.ex
  - lib/lockspire/protocol/token_exchange/internal/ciba_grant.ex
  - lib/lockspire/protocol/token_exchange/internal/device_code_grant.ex
  - lib/lockspire/protocol/token_exchange/internal/grant_support.ex
  - lib/lockspire/protocol/token_exchange/internal/refresh_exchange.ex
  - lib/lockspire/protocol/token_exchange/internal/rfc8693_exchange.ex
  - lib/lockspire/protocol/token_exchange/internal/token_endpoint_dpop.ex
  - lib/lockspire/protocol/token_result.ex
  - lib/lockspire/protocol/userinfo.ex
  - lib/lockspire/security/policy.ex
  - lib/lockspire/storage/ecto/prefix.ex
  - lib/lockspire/storage/prefix.ex
  - lib/lockspire/web/controllers/discovery_controller.ex
  - mix.exs
  - scripts/ci/check_architecture_topology.sh
  - test/lockspire/architecture_fitness_test.exs
  - test/lockspire/client_lifecycle_test.exs
  - test/lockspire/clients_test.exs
  - test/lockspire/compatibility_baseline_contract_test.exs
  - test/lockspire/discovery_routes_test.exs
  - test/lockspire/documentation_contract_test.exs
  - test/lockspire/protocol/access_token_signer_test.exs
  - test/lockspire/protocol/discovery_test.exs
  - test/lockspire/protocol/protected_resource_dpop_test.exs
  - test/lockspire/protocol/refresh_exchange_test.exs
  - test/lockspire/protocol/request_object_test.exs
  - test/lockspire/protocol/rfc8693_exchange_test.exs
  - test/lockspire/protocol/token_endpoint_dpop_test.exs
  - test/lockspire/protocol/token_exchange_test.exs
  - test/lockspire/protocol/token_result_test.exs
  - test/lockspire/security/policy_test.exs
  - test/lockspire/storage/ecto/prefix_test.exs
  - test/lockspire/storage/prefix_test.exs
  - test/lockspire/web/discovery_controller_test.exs
  - test/support/architecture/public_compatibility_manifest.ex
findings:
  critical: 4
  warning: 0
  info: 0
  total: 4
status: resolved
---

# Phase 134: Code Review Report

**Reviewed:** 2026-08-27T18:15:00Z
**Depth:** deep
**Files Reviewed:** 64
**Status:** issues_found

## Summary

The graph command reports zero cycles and `mix qa.architecture` passes, but the
refactor changes two existing public result structs and the new fitness gate does
not cover the surface it claims to protect. It also retains a runtime protocol-to-
Phoenix delivery dependency behind a dynamic module reference. These are release
blocking for an architecture phase whose explicit contract is v1.x compatibility
and enforced inward-only dependency direction.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: `RequestObject.consume/3` changes its public error struct

**File:** `lib/lockspire/protocol/request_object.ex:27-34,310-312`
**Issue:** Before this refactor, each error returned by the public
`Lockspire.Protocol.RequestObject.consume/3` was a
`%Lockspire.Protocol.AuthorizationRequest.Error{}`. The new implementation
returns `%Lockspire.Protocol.RequestObject.Result{}` instead (including a new
`:disposition` key). Existing host applications can legitimately pattern-match
the documented/public `AuthorizationRequest.Error` result and will fail at
runtime after upgrading. The updated test at
`test/lockspire/protocol/request_object_test.exs:68-79` characterizes the new
incompatible value rather than preserving the old contract.

**Fix:** Keep `RequestObject.Result` internal, but translate it back to the
existing `%AuthorizationRequest.Error{}` at the public `RequestObject.consume/3`
boundary; or retain the old error struct as the public result and move only the
shared construction data inward. Restore the precise result typespec and add a
compatibility assertion that directly pattern-matches the old struct.

### CR-02: DPoP protected-resource APIs now leak a new internal result type

**File:** `lib/lockspire/protocol/protected_resource_dpop.ex:13-16,30-38`
**Issue:** `validate_access/2` and `validate_userinfo_access/2` formerly
returned `%Lockspire.Protocol.Userinfo.Error{}` on failure. They now return the
new `%Lockspire.Protocol.ProtectedResourceError{}`. That is an observable Elixir
API and breaks host-side pattern matches and typespec consumers; replacing the
typespec with `{:error, map()}` conceals rather than resolves the incompatibility.
The test was changed to assert the new struct at
`test/lockspire/protocol/protected_resource_dpop_test.exs:61-105,135-178`.

**Fix:** Treat `ProtectedResourceError` as neutral/internal only. Convert it to
the retained `%Userinfo.Error{}` in both public DPoP functions (the plug and
userinfo adapters can accept that stable shape), restore the exact typespec, and
add it to the literal compatibility result baseline.

### CR-03: The claimed permanent compatibility/ownership gate is materially incomplete

**File:** `test/support/architecture/public_compatibility_manifest.ex:4-41`
**Issue:** The Plan 11 contract requires a literal pre-refactor baseline for all
affected facades/helpers and nine structs. This manifest checks only 13 selected
function arities and 7 structs: it omits `AuthorizationRequest.Validated` and
`AuthorizationRequest.Error`, all of the explicitly listed token helper
facades/arities (such as `AccessTokenSigner`, `RefreshExchange`,
`Rfc8693Exchange`, `TokenEndpointDPoP`, and grant helpers), plus representative
result tuples. It therefore cannot catch CR-01 or CR-02, and `mix
qa.architecture` currently passes despite both regressions.

The ownership test is similarly only a substring assertion at
`test/lockspire/architecture_fitness_test.exs:69-77`; it does not enforce
delegation to `ClientMetadata`, reject duplicated metadata/audit transaction
logic, or scan the promised delivery source set. This leaves ARCH-03/ARCH-04
unenforced.

**Fix:** Generate the full literal manifest from commit `76cf872` as specified
by Plan 11, including every exported function/arity for every affected module,
all nine structs and their exact keys, and representative result values. Replace
the substring test with AST predicates that prove calls/delegation and reject
moved lifecycle/metadata implementations. Add synthetic violating-source tests
for each predicate.

### CR-04: Discovery's public protocol path still invokes Phoenix delivery at runtime

**File:** `lib/lockspire/protocol/discovery.ex:68-71,92-93`
**Issue:** The zero-arity public discovery functions call
`Lockspire.DiscoveryRoutes.paths/0`; that module is explicitly described as a
delivery-edge resolver and calls `Phoenix.Router.routes/1` at
`lib/lockspire/discovery_routes.ex:18-22`. `Module.concat/1` at line 31 merely
hides the Lockspire Web router from xref; it does not remove the runtime
protocol-to-delivery dependency. This violates ARCH-02/D-09's requirement that
protocol consume a neutral route capability supplied at the delivery/configuration
edge, and lets the AST check falsely report a clean architecture because it only
rejects literal `Lockspire.Web`/`Lockspire.Admin` aliases.

**Fix:** Have the web/configuration edge resolve the route collection and call
the existing `Discovery.openid_configuration/1` capability API. Preserve the
zero-arity compatibility method by obtaining a host-provided neutral route-path
callback/configuration value, not by importing a Phoenix-aware resolver into
`Lockspire.Protocol.Discovery`. Extend the fitness test to reject protocol
references to delivery capability modules (and exercise a synthetic indirect
delivery-edge violation).

---

_Reviewed: 2026-08-27T18:15:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_

## Resolution

All four blockers were resolved on 2026-08-27. Request-object and protected-resource
facades again return their v1.x public structs; neutral values stay below those
boundaries. The literal `76cf872` compatibility manifest now covers all affected
exports, all nine public structs, and representative public result owners. AST
fitness tests exercise direct and synthetic delivery/ownership violations. Discovery
zero-arity APIs now consume only configured neutral route capabilities, with Phoenix
route reflection installed and resolved at the delivery/configuration edge. The
topology script reports zero cycles and `mix qa.architecture`, focused protocol tests,
and docs verification pass.
