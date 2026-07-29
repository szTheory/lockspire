---
phase: 126-adopter-path-walk-defect-ledger
verified: 2026-07-28T22:35:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 126: Adopter Path Walk & Defect Ledger Verification Report

**Phase Goal:** A maintainer can run one command that walks the entire documented adopter path
against a stock Phoenix app and gets an attributable verdict plus a written record of every defect
the walk surfaced. This phase deliberately does not fix what it finds — its deliverables are a
working harness and evidence.

**Verified:** 2026-07-28T22:35:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

**Important framing carried into this verification (per phase instructions):** the walk is
*expected* to come back RED. A red walk with a complete ledger is defined as the passing outcome
for this phase. This report does not penalize the 12 recorded FAILs or the 17-entry ledger — it
verifies that the harness is real, the ledger is real and reconciled, and nothing was silently
fixed in `lib/`, `priv/`, `docs/`, or `examples/`.

### Observable Truths (Roadmap Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Single command walks generate→install→wire→migrate→boot→register→authorize-code+PKCE, ending in one verdict | ✓ VERIFIED | `mix adopter.walk` alias in `mix.exs:99` runs `scripts/maintainer/adopter_path_walk.sh`, which sequences all steps (`step-00b-phx-new` … `step-06c-token-proof`) and prints a single `Summary:`/`Result:` verdict (`adopter_path_walk.sh:1468-1479`). Re-ran the boot/drive portion live (`--from-step 06`) and independently reproduced `Summary: 9 PASS, 0 FAIL` / `Result: adopter path is GREEN` for that segment against the persisted host app. |
| 2 | Stock `phx.new` app — Ecto and HTML included, no stripped variant | ✓ VERIFIED | `mix phx.new host_app --database postgres --install` (`adopter_path_walk.sh:393`), no `--no-ecto/--no-html/--no-assets/--no-mailer` flag anywhere in the script (`grep` confirms zero matches); `--install` is required precisely so asset binaries aren't skipped (comment at line 387-390). |
| 3 | On failure, output names the documented step and error; maintainer can inspect/resume without re-running earlier steps | ✓ VERIFIED | Every `record_result` call carries a `§N` guide-section-labelled detail plus the first captured error line (e.g. `adopter_path_walk.sh:526` for ADOPT-D15). `.walk/steps/<id>.done` markers plus `--from-step` let a maintainer resume; confirmed live — `--from-step 06` skipped all completed steps and only re-ran the boot/drive/flow block. |
| 4 | Walk fails when the flow doesn't yield a *usable* token — token exercised against a token-consuming endpoint, not just observed | ✓ VERIFIED | `scripts/maintainer/adopter_path_flow.py:310-341` (`exercise_token_proof`) asserts `<mount>/userinfo` 200 with real claims, an anonymous request to the protected host route returns 401 (asserted *before* the bearer case), and a bearer request to the protected host route returns 200 with `subject`/`scope` echoed back. Live re-run of this exact code path reproduced both PASS lines against a real booted server. An absent/empty `access_token` fails the step (`adopter_path_flow.py:302-303`). |
| 5 | Committed defect ledger records every break, attributed to real source and owning phase | ✓ VERIFIED | `.planning/phases/126-adopter-path-walk-defect-ledger/126-DEFECT-LEDGER.md`, committed at `84c569a`, 17 entries (D01-D11, D13-D16, D18, D19), each with all six D-37 fields. `mix test test/lockspire/maintainer/defect_ledger_contract_test.exs` (6 tests) passes, mechanically enforcing field completeness, allowed source/owning-phase vocabulary, and two-way marker↔ledger reconciliation. |
| 6 (SC5) | Any harness workaround is recorded in the ledger as a defect, never left silent | ✓ VERIFIED | `grep -rn LOCKSPIRE_WALK_WORKAROUND scripts/maintainer/` yields 14 unique `ADOPT-Dnn` marker IDs; the ledger's 3 "workaround: none" entries (D01, D11, D13) are genuinely markerless (documentation-only or residual-nondeterminism defects, not harness fixes). `defect_ledger_contract_test.exs`'s two reconciliation tests (marker→ledger and ledger→marker) both pass, proving set equality in both directions. |

**Score:** 5/5 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scripts/maintainer/adopter_path_walk.sh` | Full step harness, D-14/D-16/D-20 compliant | ✓ VERIFIED | 1518 lines; `bash -n` passes; contains all `step-00a`…`step-08` IDs; single `trap cleanup EXIT INT TERM` that only kills the walk's own server pid, never deletes the workdir |
| `scripts/maintainer/adopter_path_flow.py` | Stdlib-only PKCE driver + two-layer proof | ✓ VERIFIED | 439 lines; `python3 -m py_compile` passes; imports are all stdlib (`argparse, base64, hashlib, http.client, json, os, re, sys, time, http.cookies, urllib.parse`); no third-party import |
| `test/lockspire/maintainer/adopter_walk_contract_test.exs` | ADOPT-03 step↔guide mapping gate | ✓ VERIFIED | 509 lines; part of the 58-test maintainer suite, 0 failures |
| `test/lockspire/maintainer/adopter_flow_driver_contract_test.exs` | ADOPT-04 driver contract | ✓ VERIFIED | 137 lines; passes |
| `test/lockspire/maintainer/defect_ledger_contract_test.exs` | Ledger completeness + reconciliation | ✓ VERIFIED | 239 lines; 6 assertions, all passing, including secret-absence checks |
| `.planning/phases/126-adopter-path-walk-defect-ledger/126-DEFECT-LEDGER.md` | Committed defect ledger | ✓ VERIFIED | Committed (`84c569a`), 17 entries, no raw tokens/passwords (`grep` for the seeded password literal and a bearer-token-shaped string both return nothing) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `adopter_path_walk.sh` | `docs/install-and-onboard.md` | `step-0N` IDs ↔ `§N` guide sections | ✓ WIRED | Enforced by `adopter_walk_contract_test.exs`'s structural + semantic + uniqueness assertions over the union of shell `record_result` calls and Python result-line literals |
| `adopter_path_walk.sh` | `adopter_path_flow.py` | boots host in background, invokes driver, folds `[PASS]`/`[FAIL]` lines into `RESULTS` | ✓ WIRED | `adopter_path_walk.sh:1392-1454`; live re-run confirmed the fold — `step-06b-flow`/`step-06c-token-proof` appeared in the harness's own printed report with counts reflected in `Summary:` |
| `adopter_path_walk.sh` protected route | `adopter_path_flow.py --protected-path` | both name `/api/walk/summary` | ✓ WIRED | `grep` confirms byte-identical path in both files |
| `scripts/maintainer/*` workaround markers | `126-DEFECT-LEDGER.md` | `ADOPT-Dnn` IDs | ✓ WIRED | Verified programmatically (contract test) and manually (marker ID set vs. ledger heading set) |

### Data-Flow Trace (Level 4)

Not applicable in the conventional sense (no rendered UI component), but the phase's core "data flow" claim — that a real access token is exercised against a real consuming endpoint — was independently reproduced live in this verification session:

```
Summary: 9 PASS, 0 FAIL
Result: adopter path is GREEN
```
(for the `--from-step 06` segment, against the previously-wired generated host app, driving a real HTTP authorization-code + PKCE exchange and a real bearer-token protected-route call.)

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Harness shell syntax valid | `bash -n scripts/maintainer/adopter_path_walk.sh` | exit 0 | ✓ PASS |
| Driver compiles | `python3 -m py_compile scripts/maintainer/adopter_path_flow.py` | exit 0 | ✓ PASS |
| No stripping flags to `phx.new` | `grep -E -- '--no-(ecto\|html\|assets\|mailer)' adopter_path_walk.sh` | no match | ✓ PASS |
| `phx_new` pinned + isolated archives | `grep -Fq 'phx_new 1.8.9'` / `grep -Fq 'MIX_ARCHIVES'` | both found | ✓ PASS |
| Maintainer test suite | `mix test test/lockspire/maintainer/` | 58 tests, 0 failures | ✓ PASS |
| Marker↔ledger reconciliation | `mix test .../defect_ledger_contract_test.exs` | 6 tests, 0 failures | ✓ PASS |
| Live re-run of §6 flow + token proof | `bash scripts/maintainer/adopter_path_walk.sh --from-step 06` | `Summary: 9 PASS, 0 FAIL`, `Result: adopter path is GREEN` | ✓ PASS |
| `lib/priv/docs/examples` untouched across the whole phase | `git diff --stat f774d5e~1..HEAD -- lib/ priv/ docs/ examples/` | empty | ✓ PASS |

### Probe Execution

No `scripts/*/tests/probe-*.sh`-shaped probes are declared by this phase's PLAN/SUMMARY files; the phase's own verification mechanism is the contract-test suite plus a live walk run, both exercised above. Skipped — no conventional probes apply.

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|--------------|----------------|--------------|--------|----------|
| ADOPT-01 | 126-01, 126-02, 126-03, 126-05 | One command, one verdict | ✓ SATISFIED | `mix adopter.walk` alias; single `print_report` exit path |
| ADOPT-02 | 126-01 | Stock `phx.new` defaults | ✓ SATISFIED | No stripping flags; Ecto/HTML/LiveView/mailer/assets all present |
| ADOPT-03 | 126-02, 126-04, 126-05 | Step-attributed failure + resume | ✓ SATISFIED | `§N`-labelled results, `.walk/steps` markers, `--from-step`, contract-test-enforced mapping |
| ADOPT-04 | 126-03, 126-04 | Token exercised at a consuming endpoint | ✓ SATISFIED | Two-layer proof (userinfo + host route), anonymous-401-before-bearer-200 ordering, live-reproduced |

No orphaned requirements found in REQUIREMENTS.md for Phase 126 beyond these four, and REQUIREMENTS.md's own tracking table (lines 83-86) marks all four `Complete`, consistent with the evidence above.

### Anti-Patterns Found

None blocking. Scanned `scripts/maintainer/adopter_path_walk.sh`, `scripts/maintainer/adopter_path_flow.py`, all three new test files, and `126-DEFECT-LEDGER.md` for `TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER` — zero matches. The one incidental match for the string "placeholder" is a factual description of an observed defect (the installer's placeholder issuer value), not a stub marker.

### Human Verification Required

None. All must-haves resolved through static analysis, the existing automated test suite, and a live re-execution of the flow-driving portion of the walk performed during this verification session.

### Gaps Summary

No gaps. All five roadmap success criteria are verified with direct evidence: a working, wired `mix adopter.walk` command; a stock, uncapped `phx.new` generation; step-and-error-attributed, resumable failure reporting; a two-layer, order-enforced token-usability proof (independently re-run live and confirmed GREEN for that segment); and a committed, mechanically-reconciled 17-entry defect ledger with zero silent workarounds. `git diff` across the phase's full commit range confirms no changes leaked into `lib/`, `priv/`, `docs/`, or `examples/`, honoring the phase's "evidence, not fixes" boundary. The RED overall verdict (19 PASS / 12 FAIL) and the non-empty ledger are the phase's intended, passing outcome, not a defect.

---

_Verified: 2026-07-28T22:35:00Z_
_Verifier: Claude (gsd-verifier)_
