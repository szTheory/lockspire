---
phase: 102-generated-host-scaffolding-telemetry-migration
plan: 02
subsystem: api
tags: [telemetry, verify_token, rfc9068, at+jwt, observability, plug]

# Dependency graph
requires:
  - phase: 098-plug-hardening
    provides: "Lockspire.Plug.VerifyToken front-edge opaque rejection + RFC 9068 do_verify_token/3 success path with verified claims"
  - phase: 099-signer-extraction-jwt-default-issuance
    provides: "JWT-default issuance so verified at+jwt is the common RS shape this counter measures"
provides:
  - "Direct :telemetry.execute/3 emission of [:lockspire, :rs, :token_format] at two VerifyToken sites (:jwt success + :\"opaque-rejected\")"
  - "Private emit_token_format/1 helper that bypasses Observability.emit/4 (no audit double-emit, no nil-metadata redaction drop)"
  - "verify_token_telemetry_test.exs: attach_many → assert_received capture for both sites + literal-atom contract"
affects: [102-migration-doc, 102-doctor-token-format, operator-telemetry-metrics-reporters]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Direct :telemetry.execute/3 from a plug for an observe-only per-request counter (deliberately NOT Observability.emit/4)"
    - "4-arg attach_many handler so numeric measurements (%{count: 1}) are assertable, vs the repo's prior 3-arg telemetry idiom"

key-files:
  created:
    - test/lockspire/plug/verify_token_telemetry_test.exs
  modified:
    - lib/lockspire/plug/verify_token.ex

key-decisions:
  - "Emit SITE A (:jwt) at format-confirmation time (claims in hand), before/independent of apply_restrictions/2, so :jwt and :\"opaque-rejected\" counts stay symmetric at format-decision time (Pitfall 4 / A2)"
  - "Single private emit_token_format/1 helper called at both sites — calls :telemetry.execute/3 directly; keeps each site's metadata shape inline at the call site"
  - "audience metadata sourced from Map.get(claims, \"aud\") — the AccessToken struct has no audience field (RESEARCH drift correction)"

patterns-established:
  - "Pattern: plug-level observe-only telemetry counter via direct :telemetry.execute/3 with %{count: 1} measurement and categorical value in metadata"
  - "Pattern: telemetry capture test using 4-arg attach_many handler + assert_received + on_exit detach (no async handler leaks)"

requirements-completed: [TELEMETRY-01]

# Metrics
duration: ~3min
completed: 2026-05-29
---

# Phase 102 Plan 02: RS token-format telemetry Summary

**`[:lockspire, :rs, :token_format]` emitted via direct `:telemetry.execute/3` at two `VerifyToken` sites — `:jwt` (claims-sourced metadata) on verified `at+jwt`, literal `:"opaque-rejected"` (all-nil metadata) on the opaque-reject branch — proven by a TDD RED→GREEN capture test.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-05-29T10:42:57Z
- **Completed:** 2026-05-29T10:44:36Z
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments
- Two direct `:telemetry.execute([:lockspire, :rs, :token_format], %{count: 1}, metadata)` emit sites in `verify_token.ex`, routed through one private `emit_token_format/1` helper.
- SITE A (JWT-success) fires at format-confirmation time with `%{token_format: :jwt, client_id, audience, binding_type}` read from verified claims (`audience` from `claims["aud"]`), independent of `apply_restrictions/2` outcome so the count is coherent with SITE B.
- SITE B (opaque-rejection) fires the literal hyphenated atom `:"opaque-rejected"` with all-`nil` `client_id`/`audience`/`binding_type` — and that all-nil metadata survives intact because the path skips `Observability.emit/4`'s redaction.
- New `verify_token_telemetry_test.exs` proves both sites + the literal-atom contract; followed strict TDD (RED with empty mailbox → GREEN), existing `verify_token_test.exs` still green (no verifier-behavior regression).

## Task Commits

1. **Task 1: Write failing telemetry capture test (RED)** - `656fa40` (test)
2. **Task 2: Emit the event at both verify_token.ex sites (GREEN)** - `bfddffc` (feat)

_TDD plan: RED `test(...)` commit precedes GREEN `feat(...)` commit. No REFACTOR commit needed — the emit helper was minimal as first written._

## Files Created/Modified
- `test/lockspire/plug/verify_token_telemetry_test.exs` - attach_many/4 (4-arg handler) capture test; mints a real signed `at+jwt` via active SigningKey + KeyCache refresh (mirrors `verify_token_test.exs` helper) and an opaque token; asserts `:jwt` + claims-sourced metadata and the literal `:"opaque-rejected"` + all-nil metadata; detaches handler in `on_exit`.
- `lib/lockspire/plug/verify_token.ex` - added `emit_token_format/1` (direct `:telemetry.execute/3`) and called it at the opaque-rejection branch (SITE B) and after `verify_signature_and_claims` succeeds in `do_verify_token/3` (SITE A).

## Decisions Made
- **SITE A emit point:** after the `with` confirms `claims`, before/independent of `apply_restrictions/2`. Rationale (Pitfall 4 / Assumption A2): a structurally-valid `at+jwt` that fails the route audience/scope check is still a `:jwt`-format verification; emitting here keeps the `:jwt` count symmetric with the structural-format-decision-time `:"opaque-rejected"` count.
- **One shared helper, inline metadata maps:** `emit_token_format/1` calls `:telemetry.execute/3` directly (D-03); each call site supplies its own four-key metadata map verbatim, keeping the `:jwt` vs `:"opaque-rejected"` shapes obvious at the site.
- **audience from claims, not the struct:** `Map.get(claims, "aud")` — the `Lockspire.AccessToken` struct has no `audience` field (RESEARCH/PATTERNS drift correction, re-verified against `lib/lockspire/access_token.ex`).

## Deviations from Plan

None - plan executed exactly as written.

## Threat Model Compliance
- **T-102-04 (Info Disclosure via metadata):** mitigated — emits exactly the four documented keys (`token_format`, `client_id`, `audience`, `binding_type`); never `token`, `claims`, `cnf`, or `jti`. The direct-execute path skips redaction, so the emit site is the redaction discipline.
- **T-102-05 (DoS / audit-log flooding):** mitigated — direct `:telemetry.execute/3` bypasses `Observability.emit/4`, so no `[:lockspire, :audit, :rs, :token_format]` copy is written per protected request.
- **T-102-06 (nil metadata silently dropped):** mitigated — no `Redaction.for_telemetry`; the opaque-rejection test asserts `binding_type: nil` (and all other nil fields) are present in the delivered metadata.
- **T-102-07 (future routing back through emit/4):** mitigated — the helper's doc comment forbids `Observability.emit/4` with the verified rationale; the capture test asserts the all-nil opaque metadata survives, so a regression to `emit/4` would fail the test.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required. Operators may optionally subscribe a `Telemetry.Metrics` reporter to `[:lockspire, :rs, :token_format]` (out of scope for this plan).

## TDD Gate Compliance
RED gate (`656fa40`, `test`) precedes GREEN gate (`bfddffc`, `feat`) in git history. Gate sequence satisfied.

## Next Phase Readiness
- TELEMETRY-01 satisfied and proven. The migration guide (MIGRATE-01) and doctor task (MIGRATE-02) plans in this phase are independent of this change.

---
*Phase: 102-generated-host-scaffolding-telemetry-migration*
*Completed: 2026-05-29*
