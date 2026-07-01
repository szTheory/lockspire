---
phase: 100-sender-constraint-end-to-end-proof
plan: "01"
subsystem: auth
tags: [elixir, plug, oauth2, dpop, mtls, sender-constraint, security]

# Dependency graph
requires:
  - phase: 98-plug-hardening
    provides: VerifyToken RFC 9068 enforcement, WWW-Authenticate challenge taxonomy, DPoP/mTLS binding struct fields
  - phase: 99-signer-extraction-jwt-default-issuance
    provides: AccessTokenSigner with cnf carry-through, JWT-default issuance
provides:
  - binding_verified: false fail-closed field on AccessToken struct (D-01)
  - EnforceSenderConstraints marks binding_verified: true on all binding-validated success paths (D-02)
  - RequireToken fail-closed guard for bound-but-unverified tokens, emitting 403 with binding-derived challenge (D-03)
  - Plug-unit proof for all three (struct default, positive set, negative reject, bearer pass-through)
affects:
  - 100-02 (integration test will consume the binding_verified breadcrumb end-to-end)
  - Any future plan touching the VerifyToken -> EnforceSenderConstraints -> RequireToken pipeline

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "binding_verified breadcrumb: fail-closed field on AccessToken struct, set only on binding-validated success, read as guard in RequireToken"
    - "mark_binding_verified/1 helper reads current struct from conn.assigns (not closed-over param) so it picks up the token the success path returned"
    - "handle_sender_constraint_bypass/2: 403 handler mirrored verbatim on handle_insufficient_scope/2 — challenge-aware routing with ProtectedResourceChallenge.put_dpop_challenge for DPoP, www_authenticate for mTLS"
    - "sender_constraint_bypass_error/1: derives :dpop/:bearer challenge from binding_requirements — %{dpop_jkt: _} -> :dpop, else -> :bearer"

key-files:
  created: []
  modified:
    - lib/lockspire/access_token.ex
    - lib/lockspire/plug/enforce_sender_constraints.ex
    - lib/lockspire/plug/require_token.ex
    - test/lockspire/access_token_test.exs
    - test/lockspire/plug/enforce_sender_constraints_test.exs
    - test/lockspire/plug/require_token_test.exs

key-decisions:
  - "Used mark_binding_verified/1 shared helper in EnforceSenderConstraints rather than inline re-assigns at each success site — reads from conn.assigns so it picks up the verified token regardless of closed-over variable scope"
  - "D-03 guard gated on error: nil so it never intercepts verify_token_test.exs error-carrying bound tokens — they carry error != nil and continue to existing error clauses"
  - "handle_sender_constraint_bypass/2 is a new private function rather than routing through handle_structured_error/2 to avoid altering the existing 401 sender-constraint path used by EnforceSenderConstraints failures"

patterns-established:
  - "binding_verified breadcrumb: default false in struct, set true on binding-validated success only, fail-closed guard in RequireToken"
  - "403 bypass handler mirrored on handle_insufficient_scope/2 pattern — challenge-aware routing + send_json(403)"

requirements-completed: [BIND-03]

# Metrics
duration: 5min
completed: 2026-05-28
---

# Phase 100 Plan 01: Sender-Constraint End-to-End Proof Summary

**BIND-03 runtime fail-closed guard: binding_verified breadcrumb (D-01/D-02/D-03) closes RFC 9449 §7.2 sender-constraint bypass with 403 + binding-derived challenge, proven by 25 passing plug-unit tests**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-05-28T19:54:52Z
- **Completed:** 2026-05-28T19:59:35Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added `binding_verified: false` as 8th fail-closed field on `AccessToken` struct — a token is "not verified until something proves otherwise" (D-01)
- `EnforceSenderConstraints` now sets `binding_verified: true` on every binding-validated success path (DPoP-only, mTLS, dual-bound) via shared `mark_binding_verified/1` helper; unbound no-op and all failure arms are untouched (D-02)
- `RequireToken` gains a fail-closed clause ordered before the pass-through that halts bound-but-unverified tokens with 403 and a binding-derived `WWW-Authenticate` challenge; bearer (unbound) tokens pass unchanged; error-carrying tokens bypass the guard via the `error: nil` gate (D-03)
- Full test suite (1036 tests) stays green; `mix compile --warnings-as-errors` clean

## Task Commits

Each task was committed atomically:

1. **Task 1: Add binding_verified: false to AccessToken struct (D-01)** - `6f1d704` (feat)
2. **Task 2: Set binding_verified: true on EnforceSenderConstraints success paths (D-02)** - `720fbec` (feat)
3. **Task 3: Add RequireToken bound-but-unverified fail-closed clause (D-03)** - `14c22c9` (feat)

## Files Created/Modified

- `lib/lockspire/access_token.ex` - Added `binding_verified: false` to defstruct (8th field, kw-form after bare atoms) and `binding_verified: boolean()` to @type
- `lib/lockspire/plug/enforce_sender_constraints.ex` - Added `mark_binding_verified/1` helper; routed mtls-success `with` body and DPoP-only-success catch-all through it
- `lib/lockspire/plug/require_token.ex` - Added fail-closed `call/2` clause, `handle_sender_constraint_bypass/2` (403), and `sender_constraint_bypass_error/1`
- `test/lockspire/access_token_test.exs` - Renamed defaults test, added `binding_verified == false` assertion
- `test/lockspire/plug/enforce_sender_constraints_test.exs` - Added `binding_verified == true` assertions to 3 success-path tests; `binding_verified == false` to no-op test
- `test/lockspire/plug/require_token_test.exs` - Added 3 BIND-03 clauses: DPoP-bound->403, mTLS-bound->403, bearer->pass

## Decisions Made

- `mark_binding_verified/1` reads from `conn.assigns[:access_token]` (not the closed-over `access_token` param) so it picks up the verified token returned by `maybe_validate_mtls/4` — the anchor note from PATTERNS.md confirmed this is necessary
- `error: nil` gate on the D-03 `call/2` clause is non-negotiable: prevents intercepting `verify_token_test.exs:947-1037` error-carrying bound tokens (those carry `error != nil` and must continue to existing error clauses)
- New `handle_sender_constraint_bypass/2` rather than routing through `handle_structured_error/2` to keep the existing 401 sender-constraint path (used by `EnforceSenderConstraints` failures) completely untouched

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The worktree lacked `deps/` and `_build/` directories (normal for git worktrees). Created symlinks to the main project's shared `deps` and `_build` so `mix test` could run from the worktree. All tests ran successfully from the worktree after symlinking.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- BIND-03 runtime guard is proven: bound-but-unverified -> 403, bearer -> pass, success-path -> `binding_verified: true`, struct default -> `false`
- Full test suite green (1036 tests, 0 failures), compile clean
- Phase 100 Plan 02 (integration test / release-readiness contract) can proceed

---
*Phase: 100-sender-constraint-end-to-end-proof*
*Completed: 2026-05-28*
