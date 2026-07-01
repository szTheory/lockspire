---
phase: 102-generated-host-scaffolding-telemetry-migration
plan: 04
subsystem: migration
tags: [mix-task, doctor, access-token-format, diagnostic, v1.27]

requires:
  - phase: 99-signer-extraction-jwt-default-issuance
    provides: AccessTokenSigner.resolve_format/2 precedence + per-client/server-default access_token_format
provides:
  - Read-only `mix lockspire.doctor token_format` diagnostic subtask reporting each client's effective access-token format
  - Dispatcher routing + fallback-help line for the token_format subcommand
affects: [migration, operator-tooling, v1.27-issuance-flip]

tech-stack:
  added: []
  patterns:
    - "Doctor subtask mirror: use Mix.Task + @requirements [\"app.config\"] + strict OptionParser + --help branch + line-list -> Mix.shell().info"
    - "Comment-anchored private-precedence reproduction: copy a defp's clauses inline with a byte-equivalence comment pointing to the authority module:lines"

key-files:
  created:
    - lib/mix/tasks/lockspire.doctor.token_format.ex
    - test/mix/tasks/lockspire_doctor_token_format_test.exs
  modified:
    - lib/mix/tasks/lockspire.doctor.ex

key-decisions:
  - "Reproduced AccessTokenSigner.resolve_format/2 inline as private effective_format/2 rather than promoting the signer fn to public (A1: lowest blast radius, no public-surface widening)"
  - "Diagnostic-only contract: no Mix.raise in the report path, no non-zero exit, {:error,_} from admin reads surfaced calmly via Mix.shell().info"

patterns-established:
  - "token_format doctor flags ONLY access_token_format: nil clients (inherited default changed to :jwt); explicit-:opaque clients are never flagged"

requirements-completed: [MIGRATE-02]

duration: ~12min
completed: 2026-05-29
---

# Phase 102 Plan 04: TokenFormat Doctor Subtask Summary

**Read-only `mix lockspire.doctor token_format` diagnostic that reports each client's effective access-token format using the signer's exact precedence and flags every `access_token_format: nil` client whose inherited default flipped to `:jwt`.**

## Performance

- **Duration:** ~12 min
- **Completed:** 2026-05-29
- **Tasks:** 2
- **Files modified:** 3 (2 created, 1 modified)

## Accomplishments
- New `Mix.Tasks.Lockspire.Doctor.TokenFormat` subtask: enumerates all clients via `Clients.list_clients/1`, reads the server default via `ServerPolicy.get_server_policy/0`, and prints one line per client with its effective format plus a `[CHANGED ...]` marker on every `nil`-format client.
- Reproduced the PRIVATE `AccessTokenSigner.resolve_format/2` three-clause precedence inline as `effective_format/2`, comment-anchored to `access_token_signer.ex:88-98` for byte-equivalence (the signer fn is `defp` and cannot be called).
- Wired the dispatcher: added `run(["token_format" | rest])` before the fallback, and added `mix lockspire.doctor token_format` to the fallback's "Supported commands:" help block so the help no longer lies.
- Strictly read-only/diagnostic: no mutation, no `Mix.raise` in the report path, no non-zero exit; `{:error, _}` from admin reads is reported calmly.

## Task Commits

1. **Task 1: TokenFormat subtask + dispatcher wiring** - `ab52780` (feat)
2. **Task 2: Doctor subtask test (diagnostic, parity, dispatch/help)** - `fdc0b87` (test)

## Files Created/Modified
- `lib/mix/tasks/lockspire.doctor.token_format.ex` - Read-only per-client effective-format diagnostic subtask.
- `lib/mix/tasks/lockspire.doctor.ex` - `run(["token_format" | rest])` dispatch clause + fallback-help line.
- `test/mix/tasks/lockspire_doctor_token_format_test.exs` - Diagnostic, nil-only flagging, precedence-parity, and dispatcher/help coverage.

## Decisions Made
- **A1 — reproduce inline, do not promote:** Copied `resolve_format/2`'s clauses into a private `effective_format/2` instead of widening the Phase-99 signer's public surface. Lowest blast radius; honors the "do not promote without explicit confirmation" guard.
- **Diagnostic-only enforcement:** Only the OptionParser invalid-opts guard may `Mix.raise`; flagged clients never raise and never trigger a non-zero exit (protects operator CI — T-102-10).

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## Threat Mitigations Applied
- **T-102-10 (Tampering/DoS):** Read-only report path, no mutation, no `Mix.raise`/`System.halt` on flagged clients; test asserts the run returns normally (no raise).
- **T-102-11 (Repudiation — "lying doctor"):** Precedence reproduced byte-equivalent to the signer and comment-anchored; parity test flips the server default via `put_access_token_format(:opaque)` and asserts the `nil` client's report tracks it.
- **T-102-12 (Info Disclosure):** Report prints only `client_id` + effective format atom; no secrets or token material read/printed.
- **T-102-13 (DoS on `{:error,_}`):** Both admin reads pattern-matched on `{:ok, _}` with a calm `{:error, reason}` else branch.

## Verification
- `mix compile --warnings-as-errors` → exit 0 (no private-function call).
- `mix test test/mix/tasks/lockspire_doctor_token_format_test.exs` → 5 tests, 0 failures.
- Grep confirms no `AccessTokenSigner.resolve_format` call (only the citing comment) and no `Mix.raise`/`System.halt` in the report path.

## Next Phase Readiness
- MIGRATE-02 satisfied. The doctor diagnostic is the operator-facing read-only view of the v1.27 issuance flip; no blockers.

## Self-Check: PASSED

All created/modified files present on disk; task commits `ab52780` and `fdc0b87` confirmed in git log.

---
*Phase: 102-generated-host-scaffolding-telemetry-migration*
*Completed: 2026-05-29*
