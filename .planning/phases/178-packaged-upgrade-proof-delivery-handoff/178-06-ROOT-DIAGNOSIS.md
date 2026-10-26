# Plan 178-06: Root HTTP Diagnosis and Continuation

**Status:** Undefined HTTP-call blocker resolved; full recovery/issuance remains unaccepted.
**Fix:** `55f3f134288f9a463f32832a1e240faff5f2f594`

## Confirmed cause

The maintainer provider host used `:httpc` without declaring its OTP application, `:inets`. Mix pruned the undeclared application's code paths. Dynamic `Application.ensure_all_started(:inets)` did not establish the complete usable runtime. The actual installed host raised `UndefinedFunctionError` at exactly `:http_util.timestamp/0`, called by OTP 28.5's `httpc.erl` `handle_request` implementation. This is host-fixture setup, not a Lockspire age-policy or protocol defect.

The root audit created one owned installed host and exercised the actual extracted fixture HTTP helper repeatedly. A finite dictionary of compiled import/export identifiers allowed classification without exposing exception arguments/messages, request data or raw logs. The missing target was confirmed with an exact source-backed boolean for `{:http_util, :timestamp, 0}`. All four harmless loopback statuses and the mounted call failed there.

Changing only that owned host's `extra_applications` from `[:logger]` to `[:logger, :inets]` made the same helper handle 200, 400, 401 and 500 correctly. A mounted invalid-client request then returned 401 normally. That mounted result is an invalid-client diagnostic, not the expired-credential scenario's accepted status.

The same one-line declaration is now in `test/clean_room/provider_host/mix.exs`, with no Lockspire runtime dependency, configuration, schema or authentication-policy change.

## Regression and evidence qualification

- `e566fee1` preserves the preliminary reduced regression and RED record. Its first minimal fixture omitted the real host's existing TLS application context; it is historical, not the qualified regression authority.
- `d7c9a76a` qualifies the reduced fixture with `:ssl`, already supplied by the full host's HTTP dependencies, and fixed safe startup/transport markers.
- The final regression runs a real no-dependency Mix project using the actual provider template's OTP application declaration. A harmless owned loopback server returns 200/400/401/500. No child output is forwarded on failure.
- With the original logger-only declaration: six tests ran, one intended failure, `safe_failure=startup`. Adding only `:inets`: six tests passed. The declaration was reverted and reconfirmed before the fix commit.
- Full acceptance after the final fix/format: 110 tests, zero failures, 0.883 seconds. `mix format --check-formatted test/clean_room/provider_host/mix.exs` and `git diff --check` passed.
- Qualified RED: `178-06-ROOT-HTTP-RED-QUALIFIED.json`. Keep both RED histories distinct.

## Actual diagnostic recovery outcome

After adding the declaration to the owned installed host, the real recovery function completed and returned all four case objects. This was a diagnostic-only run with no receipt, not source-bound package acceptance. Its captured output was reduced to fixed allowed case/field names and booleans; arbitrary child bytes remained withheld.

False observations still requiring correction/proof:

| Case | False fields |
|---|---|
| Preservation | None |
| Retry/reconciliation | `interruption_not_ready`, `partial_not_ready` |
| Restore/rotate | `missing_key_rejected` |
| Expired migration | `expired_http_auth_rejected`, `deadline_preserved` |

No assertion may be relaxed to force acceptance. Fresh committed-source full matrix and actual issuance proof remain required.

## Source-audit leads for the continuation

These are source-backed hypotheses, not executed proof:

- `partial_is_not_ready?(:builtin)` demands `scan_complete?: false` after an exclusive cursor. An empty remaining traversal can legitimately be scan-complete while remaining ineligible for custody readiness. Preserve the frozen separation of traversal completion, progress and fresh-check readiness.
- `interrupt_before_rewrap!` waits for the delegated `Store` callback even in a built-in-store cell. That callback may never execute. Use an actual supported built-in interruption witness or the explicitly scoped delegated fault evidence; do not mislabel the storage composition. `Task.async` is linked, so killing its child also needs truthful parent/cleanup handling.
- Missing-key recovery selects only `verifier-new` after the row has already been rewrapped under `verifier-new`; that is the protecting key, not a missing key. Also, changing application environment does not change the immutable startup context. Use actual staged/configuration-context evidence with exact labels; preserve authenticated failure and one-time authorized recovery contracts.
- Expired metadata compares entire `inspect_custody` results. Classification/key ID are expected to change on custody rewrap. Require successful authenticated inspection on both sides and compare the exact age-kind/original timestamp/deadline, with independent rejection afterward. Do not accidentally accept equal error tuples.
- The expired HTTP assertion hardcodes 400 without an observed status for that actual scenario. Diagnose its actual protocol error using fixed status/error categories and the frozen source contract, not the harmless invalid-client diagnostic above.
- Issuance computes `effects(client_id)` for same-JTI replay only after the fresh retry has already issued a token. Capture the after-replay state before fresh retry so the observations describe their actual stages.
- Verify backend PID observations are bound to their actual transaction/checkouts. Do not require distinct PIDs for separate nonoverlapping pool operations without a causal reason or relabel an out-of-transaction probe as an insertion backend. The maintenance/current-row-guard concurrency must still use independent PostgreSQL authority.

## Resource custody and privacy

The only root-audit database and temporary host were created by this audit. Cleanup independently confirmed the exact database and root absent; its child commands exited, and its session/serialized ephemeral configuration file was deleted. No unknown database, process, worktree or earlier receipt was touched.

The harmless diagnostic scripts remain explicitly under `/private/tmp/lockspire178-root-*` for reproducibility. They contain no generated credential values. The installed directory `/private/tmp/lockspire178-root-audit-gixv7cdh` and its key-bearing session file no longer exist. Static API dictionaries contain compiled identifiers only, not exception data.

Three earlier harness disclosure incidents remain historical truth for Plan 07/security review. The root audit opened no raw child logs or stack traces and returned only fixed safe facts. Corrected future behavior does not erase earlier tool-output exposure.

## Next action

Resume the existing execution workflow with a fresh typed executor from this committed fix, preserve the original Plan 06 checkpoint/TDD history, correct the remaining fixture semantics without policy expansion, and run the actual recovery/issuance matrix. Continue local implementation/tests/reviews/commits under the owner's explicit authorization. Return a concrete exact-SHA checkpoint before any remote write; merge/publication remain separate.
