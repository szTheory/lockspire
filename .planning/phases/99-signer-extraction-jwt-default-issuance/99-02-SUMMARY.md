---
phase: 99-signer-extraction-jwt-default-issuance
plan: 02
subsystem: protocol-discovery
tags: [oidc, discovery, metadata, at+jwt, DISCOVERY-01]
requires: []
provides:
  - "access_token_signing_alg_values_supported literal in openid_configuration/0"
affects:
  - lib/lockspire/protocol/discovery.ex
tech-stack:
  added: []
  patterns:
    - "Static module-attribute literal for truthful, profile-independent discovery metadata"
key-files:
  created: []
  modified:
    - lib/lockspire/protocol/discovery.ex
    - test/lockspire/protocol/discovery_test.exs
decisions:
  - "Publish access_token_signing_alg_values_supported as a bare literal triple [\"RS256\",\"ES256\",\"PS256\"], NOT derived from SecurityProfile.allowed_signing_algorithms/1 (which returns the none/EdDSA superset and the FAPI ES256/PS256 subset) — per D-11 / Pitfall 4."
  - "Publish the key unconditionally (static map slot), mirroring the always-present id_token_signing_alg_values_supported sibling; not gated on token_endpoint mounting."
metrics:
  duration: ~6m
  completed: 2026-05-28
  tasks: 1
  files: 2
  commits: 2
---

# Phase 99 Plan 02: Advertise access_token_signing_alg_values_supported Summary

Discovery's `openid_configuration/0` now advertises `access_token_signing_alg_values_supported: ["RS256", "ES256", "PS256"]` as a static, unconditionally-published literal (DISCOVERY-01), truthful because every Phase 99 grant path can mint `at+jwt`.

## What Was Built

- Added the `@access_token_signing_alg_values_supported ["RS256", "ES256", "PS256"]` module attribute to `lib/lockspire/protocol/discovery.ex`, sitting alongside the other static `@...supported` attributes.
- Wired that attribute into the static map returned by `openid_configuration/0`, immediately after the always-present `id_token_signing_alg_values_supported` key — so the new key is published unconditionally and is never gated on `token_endpoint` route mounting.
- Used a bare literal rather than `SecurityProfile.allowed_signing_algorithms/1`, deliberately excluding `none` and `EdDSA` and refusing the FAPI-only `["ES256","PS256"]` subset, so the advertised set matches the algs the active access-token signing key actually uses.

## Tasks Completed

| Task | Name | Commits | Files |
| ---- | ---- | ------- | ----- |
| 1 | Publish access_token_signing_alg_values_supported as a static literal (TDD) | b1172ef (test/RED), 62b43d3 (feat/GREEN) | lib/lockspire/protocol/discovery.ex, test/lockspire/protocol/discovery_test.exs |

## TDD Cycle

- **RED** (`b1172ef`): Added a new `describe` block with three assertions — the literal triple, profile-independence (`:none` and `:fapi_2_0_security` both yield the same triple), and unconditional presence under a `token_endpoint`-only router. Confirmed 3 failures (`left: nil`), 35 existing tests still green.
- **GREEN** (`62b43d3`): Added the module attribute and static-map key. All 38 tests pass.
- **REFACTOR**: Not needed — the implementation is a single literal addition; nothing to clean up.

## Verification

- `mix test test/lockspire/protocol/discovery_test.exs` — 38 tests, 0 failures (including the new triple assertions and the unchanged `id_token_signing_alg_values_supported` profile tests).
- `mix compile --warnings-as-errors` — clean (no warnings, satisfies the project's warnings-as-errors release posture).
- `grep -n "access_token_signing_alg_values_supported" lib/lockspire/protocol/discovery.ex` — exactly two occurrences (attribute definition + static-map reference), zero calls to `SecurityProfile.allowed_signing_algorithms` for this key.

## Acceptance Criteria

- [x] `Discovery.openid_configuration()["access_token_signing_alg_values_supported"] == ["RS256", "ES256", "PS256"]` (order significant).
- [x] One literal occurrence; no reuse of `SecurityProfile.allowed_signing_algorithms`.
- [x] Key present unconditionally, regardless of endpoint-mounting branch (asserted under `TokenOnlyRouter`).
- [x] Existing `id_token_signing_alg_values_supported` alg-list assertions stay green.

## Deviations from Plan

None — plan executed exactly as written.

## Environment Note (not a deviation)

The worktree was spawned without `deps/` or `_build/`. To run `mix test`/`mix compile`, `deps/` was symlinked from the main checkout (`/Users/jon/projects/lockspire/deps`) while `_build/` was kept local to the worktree to avoid cross-worktree compilation contamination. Both paths are gitignored (`/deps/`, `/_build/`) and were never staged; the symlink is a runtime convenience only and does not affect committed source.

## Known Stubs

None. The added value is a fixed literal; there is no placeholder/empty-data path.

## Threat Flags

None. No new network surface, auth path, or schema change was introduced — only a static metadata literal. The threat register's T-99-04 mitigation (truthful only because Plans 03/04/05 make every grant path mint `at+jwt`) holds: this plan adds no opaque-only behavior and excludes `none`/`EdDSA`.

## Self-Check: PASSED

- FOUND: lib/lockspire/protocol/discovery.ex (modified)
- FOUND: test/lockspire/protocol/discovery_test.exs (modified)
- FOUND: commit b1172ef (test/RED)
- FOUND: commit 62b43d3 (feat/GREEN)
