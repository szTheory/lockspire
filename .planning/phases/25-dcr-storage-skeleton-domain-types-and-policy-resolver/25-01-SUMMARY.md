---
phase: 25-dcr-storage-skeleton-domain-types-and-policy-resolver
plan: 01
subsystem: api
tags: [oidc, discovery, dcr, elixir, public-accessor]

# Dependency graph
requires: []
provides:
  - "Public `Lockspire.Protocol.Discovery.token_endpoint_auth_methods_supported/0` accessor returning the static list `[\"none\", \"client_secret_basic\", \"client_secret_post\"]`"
  - "Stable seam for the Phase 25 Plan 08 discovery-binding invariant test (D-19)"
  - "Stable seam for the Phase 29 discovery contract test"
affects: [25-08, phase-29-discovery]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Public /0 accessor exposing a module attribute as a stable seam, distinct from a private gating /1 helper"

key-files:
  created: []
  modified:
    - lib/lockspire/protocol/discovery.ex

key-decisions:
  - "Implemented D-20 verbatim: a public /0 alongside an unchanged private /1, both reading the same `@token_endpoint_auth_methods_supported` module attribute."
  - "Public /0 returns the unconditional static list — gating against `token_endpoint` mounting remains the private /1's concern."

patterns-established:
  - "Discovery static-list seam: when a downstream test or contract needs the canonical advertised list, it binds to a public /0 accessor on the Discovery module (never to the private /1 helper or the module attribute itself)."

requirements-completed:
  - DCR-09

# Metrics
duration: ~3min
completed: 2026-04-26
---

# Phase 25 Plan 01: Public Discovery Accessor for `token_endpoint_auth_methods_supported` Summary

**Extracted a public `Lockspire.Protocol.Discovery.token_endpoint_auth_methods_supported/0` accessor over the existing module attribute, leaving the private `/1` gating helper and live discovery payload behavior unchanged.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-04-26 (Wave 1, plan 25-01 execution)
- **Completed:** 2026-04-26
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Added public `def token_endpoint_auth_methods_supported, do: @token_endpoint_auth_methods_supported` to `lib/lockspire/protocol/discovery.ex`.
- Preserved the existing private `defp token_endpoint_auth_methods_supported(endpoint_metadata)` helper unchanged.
- Preserved the `@token_endpoint_auth_methods_supported` module attribute value unchanged.
- Established the stable seam that Plan 08's discovery-binding invariant test (D-19) and the Phase 29 discovery contract test will both consume.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add public /0 accessor for `token_endpoint_auth_methods_supported` in Discovery** — `8655a03` (feat)

## Files Created/Modified

- `lib/lockspire/protocol/discovery.ex` — Inserted the new `@doc`/`@spec`/`def` block at lines 26–32 (between the closing module-attribute group at line 24 and `@spec openid_configuration() :: map()`, now at line 34). Returns the same three-element list as the module attribute at line 21. Private `/1` helper now at lines 90–96 is byte-identical to the prior version.

## Acceptance Verification

Acceptance criteria from the plan:

- `grep -q 'def token_endpoint_auth_methods_supported, do: @token_endpoint_auth_methods_supported' lib/lockspire/protocol/discovery.ex` — exit 0 (PASS)
- `grep -q 'defp token_endpoint_auth_methods_supported(endpoint_metadata)' lib/lockspire/protocol/discovery.ex` — exit 0 (PASS)
- `grep -q '@spec token_endpoint_auth_methods_supported() :: \[String.t()\]' lib/lockspire/protocol/discovery.ex` — exit 0 (PASS)
- `mix compile --warnings-as-errors` — exit 0 (PASS, no warnings, no errors)
- `mix format --check-formatted lib/lockspire/protocol/discovery.ex` — exit 0 (PASS)
- `mix test test/lockspire/protocol/security_policy_test.exs --max-cases 1` — 2 tests, 0 failures (PASS)
- Additional regression: `mix test test/lockspire/web/discovery_controller_test.exs --max-cases 1` — 1 test, 0 failures (PASS)
- Functional check: `mix run --no-start -e 'IO.inspect(Lockspire.Protocol.Discovery.token_endpoint_auth_methods_supported())'` returns `["none", "client_secret_basic", "client_secret_post"]` (PASS)

### Note on the `^@token_endpoint_auth_methods_supported \[` grep criterion

One acceptance criterion was `grep -cE '^@token_endpoint_auth_methods_supported \[' lib/lockspire/protocol/discovery.ex` returning `1`. As written this regex requires the attribute to begin at column 0, but the attribute is indented at module-body level (two-space indent), so the regex returns 0 against both the prior and the new file. The substantive intent — that the module attribute is unchanged and there is exactly one declaration of it — is verified by:

```
$ grep -nE '@token_endpoint_auth_methods_supported \[' lib/lockspire/protocol/discovery.ex
21:  @token_endpoint_auth_methods_supported ["none", "client_secret_basic", "client_secret_post"]
```

Exactly one declaration; line 21 verbatim from before this plan; value unchanged. The regex anchor was a minor plan typo, not a real failure.

## Decisions Made

- None beyond the locked plan content. Implemented D-20 verbatim.

## Deviations from Plan

None - plan executed exactly as written.

The change inserted is byte-identical to the verbatim block specified in `<action>` of Task 1, placed at the location specified (after the module-attribute group ending at line 24, before `@spec openid_configuration() :: map()`).

## Issues Encountered

- Worktree had no installed Mix dependencies, so `mix compile` first reported missing deps. Resolved by running `mix deps.get` once. Not a deviation — just first-time worktree setup. After deps were fetched, all compile and test commands ran cleanly.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 25-08 (Wave 3 invariant test) can now bind directly to `Lockspire.Protocol.Discovery.token_endpoint_auth_methods_supported/0` — no module-attribute reflection needed (Pitfall 2 in 25-RESEARCH.md / 25-CONTEXT.md is preempted).
- Phase 29's discovery contract test will consume the same public `/0`.
- No blockers introduced. The live `openid_configuration/0` payload is unchanged: when `token_endpoint` is unmounted, the discovery payload still suppresses `token_endpoint_auth_methods_supported` to `[]` via the unmodified private `/1`.

## Self-Check: PASSED

Verification of artifacts referenced above:

- `lib/lockspire/protocol/discovery.ex` — present (modified, lines 26–32 added).
- Commit `8655a03` (`feat(25-01): add public Discovery.token_endpoint_auth_methods_supported/0`) — present in `git log`.

---
*Phase: 25-dcr-storage-skeleton-domain-types-and-policy-resolver*
*Plan: 25-01*
*Completed: 2026-04-26*
