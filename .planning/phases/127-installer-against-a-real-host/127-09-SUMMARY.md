# Plan 127-09 Summary

**Plan:** Retire six harness workarounds, record all twelve ledger dispositions, run the walk
**Tasks:** 3/3
**Status:** Complete

## What was built

**Task 1 (`df853bb`)** — Retired the six workarounds Phase 127's fixes made obsolete
(ADOPT-D02, D03, D08, D09, D15, D16), leaving seven in `adopter_path_walk.sh` and two in
`adopter_path_flow.py`, reconciled two-way against the ledger. Repaired the three harness couplings
this phase broke:

- `extract_lockspire_routes_body()` rewritten from a heredoc-delimiter scan to a `quote do`/`end`
  block scan, matching 127-05's macro-shaped template.
- `step-03a-config-import`'s substitutions split so each is guarded by whether its own value still
  needs replacing, rather than by one now-always-present key. The old single guard would have
  silently skipped the issuer substitution the walk still needs.
- ADOPT-D18 narrowed: the harness now patches only the `on_mount:` value into the generated helper's
  own `live_session :lockspire_consent`, rather than wrapping a second one of its own.

**Task 2 (`ec372e0`)** — A disposition sentence for all twelve owned defects, a "Future candidates"
section (installer injection, migration redesign, session-backed resume, the 127-01 manifest version
field), and `COVERAGE.md` declaring no external API integration.

**Task 3 (`dcf6468`)** — The blocking checkpoint, discharged.

## The checkpoint

Task 3 was a `checkpoint:human-verify` gate: run the walk, confirm the six retired workarounds now
stand on their own, record the PASS/FAIL delta. Rather than have a human read the report, plan
127-10 built the instrumentation to adjudicate it mechanically — a machine-readable report, a
baseline committed *before* the run so the run could refute it, and a comparator.

**Result: 22 PASS / 6 FAIL, still correctly RED**, against Phase 126's 19 PASS / 12 FAIL. Verifier
exit 0. Full delta recorded in `126-DEFECT-LEDGER.md`; report archived at
`127-WALK-REPORT-20260729.json`.

## Deviations

**The first run refuted the prediction on one row.** `step-03b-router-paste` was expected to PASS and
observed FAIL — `attempting to redefine live_session :lockspire_consent`. Task 1 had flipped that
step's expectation to PASS on the reasoning that ADOPT-D02 was closed, without noticing that
`step-03b-router-call` leaves a `lockspire_routes()` call in the router; since 127-05 that call
injects the whole route table, so pasting the body alongside it defined the live_session twice.

This was a harness defect, not an adopter-path regression. Per the plan's own instruction — "do not
re-add a removed marker if a step regresses; report the regression instead" — it was fixed in the
harness (`fd25a5a`), which now pastes *in place of* the call exactly as the step's doc comment always
claimed. The re-run matches the baseline exactly.

This is the checkpoint working as designed: a falsifiable prediction, committed in advance, refuted
by a real run, with the claim corrected rather than the expectation quietly adjusted.

## Verification

- `mix test test/lockspire/maintainer/` — 68 tests, 0 failures
- `mix test.fast` — 1308 tests, 0 failures
- `mix test.integration` — 306 tests, 0 failures
- One real from-scratch `mix adopter.walk` against a fresh generated host, fresh PostgreSQL database,
  and a real booted server
- `adopter_walk_verify.py` — exit 0 against the committed baseline

## Self-Check: PASSED
