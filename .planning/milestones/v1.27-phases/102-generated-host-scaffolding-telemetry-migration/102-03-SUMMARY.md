---
phase: 102-generated-host-scaffolding-telemetry-migration
plan: 03
subsystem: docs + build/test
tags: [migration, documentation, contract-test, access-token-format, v1.27]
requires:
  - "Phase 99: runtime ServerPolicy.access_token_format default :jwt + put_access_token_format/1"
  - "102-01: SCAFFOLD clauses + path constants in release_readiness_contract_test.exs"
provides:
  - "docs/upgrading/v1.27.md migration guide (issuance flip + honest runtime opt-out + nil-inherit affected set)"
  - "@upgrading_v1_27_path constant + MIGRATE-01 pin clause in release_readiness_contract_test.exs"
affects:
  - "operators upgrading v1.26 -> v1.27"
tech-stack:
  added: []
  patterns:
    - "Contract-test drift fence: File.read! the doc + assert/refute over its bytes"
key-files:
  created:
    - docs/upgrading/v1.27.md
  modified:
    - test/lockspire/release_readiness_contract_test.exs
decisions:
  - "D-08/D-09/D-10/D-11 honored verbatim: net-new docs/upgrading/ dir, honest runtime opt-out, nil-inherit naming, contract-test pin."
metrics:
  duration: ~6min
  completed: 2026-05-29
---

# Phase 102 Plan 03: v1.27 Migration Guide + Contract Pin Summary

Net-new `docs/upgrading/v1.27.md` documents the opaque->`:jwt` issuance-default flip with the HONEST runtime opt-out (`ServerPolicy.put_access_token_format(:opaque)`, explicitly NOT a `config :lockspire` key) and the `nil`-inherit affected-client set, fenced by a `release_readiness_contract_test.exs` clause that fails if the prose drifts from shipped behavior.

## What Was Built

**Task 1 (`12e6c33`):** Created the net-new `docs/upgrading/` directory and `docs/upgrading/v1.27.md`. The guide:
- Explains the server-wide default `access_token_format` flipped from opaque to `:jwt` (AC/refresh/device/CIBA now mint RFC 9068 `at+jwt` by default).
- Documents the one-line runtime opt-out `Lockspire.Admin.ServerPolicy.put_access_token_format(:opaque)` and states explicitly there is NO `config :lockspire` key (a config edit is a silent no-op because the format is durable runtime `ServerPolicy` state, Phase 99 D-04).
- Names affected clients as exactly "every client whose `access_token_format` is `nil`" (they inherit the new `:jwt` default); states explicit-`:opaque` clients are unaffected.
- Cross-references the precedence from `AccessTokenSigner.resolve_format/2` (per-client override -> server default -> `:jwt`).

**Task 2 (`2468c2a`):** Added `@upgrading_v1_27_path` constant beside the other doc path constants and a MIGRATE-01 pin clause asserting the honest opt-out, the `~r/access_token_format.{0,40}nil/` naming, the opaque/`:jwt` flip, and refuting any `config :lockspire ... access_token_format` phantom key.

## Verification

- `test -f docs/upgrading/v1.27.md && grep -q "put_access_token_format(:opaque)"` -> OK; all Task 1 acceptance greps pass (nil-inherit, jwt+opaque, no phantom config key).
- `mix test test/lockspire/release_readiness_contract_test.exs` -> 34 tests, 0 failures (exit 0).
- Mutation check: removing `put_access_token_format(:opaque)` from the guide makes the new clause FAIL (1 failure at line 807); restoring returns to 34/0. Confirms the pin has teeth.

## Deviations from Plan

None - plan executed exactly as written. No auto-fixes, no auth gates, no architectural decisions.

## Threat Surface Scan

No new security-relevant surface. T-102-08 (false-security no-op config key) and T-102-09 (affected-client drift) are mitigated as designed by the honest runtime opt-out prose plus the `refute config :lockspire` and `nil`-inherit asserts in the pin clause.

## Self-Check: PASSED

- FOUND: docs/upgrading/v1.27.md
- FOUND: test/lockspire/release_readiness_contract_test.exs (modified, @upgrading_v1_27_path present)
- FOUND commit: 12e6c33 (Task 1)
- FOUND commit: 2468c2a (Task 2)
