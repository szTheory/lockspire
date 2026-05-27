---
phase: 97-contract-docs-first
plan: 01
subsystem: testing
tags:
  - phase-97
  - wave-1
  - test-support
  - substring-contract
  - phase-92-extension
  - tdd-red

# Dependency graph
requires:
  - phase: 92-advanced-setup-support-truth
    provides: "Substring-contract helper pattern (assert_includes_all/2 + assert_protected_routes_guide!/1 + assert_advanced_setup_support_contract!/1) at test/support/advanced_setup_support_truth.ex"
provides:
  - "Six Phase 97 D-06/D-07 substrings now asserted inside assert_protected_routes_guide!/1 (RFC 9068 contract lead + forward-reference caveat parts)"
  - "Eight Phase 97 D-09 substrings now asserted inside assert_advanced_setup_support_contract!/1 (four non-goal patterns + four rejection-rationale clauses)"
  - "Failing RED state on test/lockspire/release_readiness_contract_test.exs:642 — the success signal Plans 02/03 turn GREEN"
affects:
  - 97-02 (rewrites docs/protect-phoenix-api-routes.md to GREEN the D-06/D-07 substrings)
  - 97-03 (adds DOCS-02 non-goals subsection to docs/supported-surface.md to GREEN the D-09 substrings)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Substring-contract helper extension (Phase 92 idiom): append-only edits to assert_includes_all/2 lists; never alter helper signatures, never invalidate prior substrings"
    - "Inline comment separator '# Phase 97 extensions (D-XX)' inside list literals marks the extension boundary for future readers"

key-files:
  created:
    - .planning/phases/97-contract-docs-first/97-01-SUMMARY.md
  modified:
    - test/support/advanced_setup_support_truth.ex (assert_protected_routes_guide!/1 + second list in assert_advanced_setup_support_contract!/1; +18 lines, -2 lines)

key-decisions:
  - "Append the new substrings AFTER existing Phase 92 entries inside the same list literal (preserve Phase 92 D-05 'extension, not invalidation' invariant)"
  - "Use inline '# Phase 97 extensions (D-06, D-07)' and '# Phase 97 extensions (D-09 four non-goal patterns)' comment markers as the only structural change beyond appended strings"
  - "Use partial-match D-07 caveat substring ('the runtime narrowing and the default-issuance flip land in v1.27' + 'opaque tokens may still be silently accepted on these routes') rather than the full caveat sentence, to give Plan 02 latitude on comma/period positioning while keeping the contract pinned"

patterns-established:
  - "Phase 97 RED-first gate: helper-only edit in Wave 1 lands the failing test before any doc edit in Wave 2 — the failure message names exactly which Phase 97 substring is the next thing Plans 02/03 must satisfy"

requirements-completed: []  # DOCS-01 and DOCS-02 are only PARTIALLY mechanized by this plan (the helpers now assert the new substrings, but the docs that satisfy them ship in Plans 02 and 03). Per .planning/REQUIREMENTS.md traceability table, DOCS-01/DOCS-02 stay "Pending" until 97-02 and 97-03 complete.

# Metrics
duration: ~6min
completed: 2026-05-27
---

# Phase 97 Plan 01: Phase 92 Helper Extension Summary

**Append 14 new D-06/D-07/D-09 substrings to the Phase 92 substring-contract helpers, landing the RED failure on `release_readiness_contract_test.exs:642` that Plans 02 and 03 will turn GREEN by editing the docs.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-05-27T21:46:00Z (approx — first verification call)
- **Completed:** 2026-05-27T21:52:12Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Extended `assert_protected_routes_guide!/1` with the six D-06/D-07 substrings (RFC 9068 default-issuance contract sentence + non-interchangeable opaque-token claim + admin-page opt-out pointer + forward-reference caveat parts).
- Extended the second `assert_includes_all/2` list inside `assert_advanced_setup_support_contract!/1` with the eight D-09 substrings (four non-goal patterns + four rejection-rationale clauses, each pulled verbatim from `.planning/REQUIREMENTS.md:103-110`).
- Confirmed Phase 92 substrings survive verbatim: all 22 prior substrings still present (`grep -c` returns `1` for representative entries like `"no-op for unconstrained bearer tokens"` and `"proves front-channel logout success remotely"`).
- Confirmed `mix compile --force --warnings-as-errors` exits 0 (no new warnings introduced).
- Confirmed the planned RED state: `mix test test/lockspire/release_readiness_contract_test.exs:642` now fails with `(RuntimeError) expected content to include "no introspection-at-the-RS as the host-API seam"` — the first Phase 97 substring the helper checks against `docs/supported-surface.md`, which Plan 03 will satisfy.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend Phase 92 helpers with Phase 97 contract substrings (D-06, D-07, D-09)** — `54ba4e7` (test)

_Plan metadata commit (this SUMMARY.md) will be made in a follow-up commit after this file is written._

## Files Created/Modified

- `test/support/advanced_setup_support_truth.ex` — appended Phase 97 D-06/D-07 substrings to `assert_protected_routes_guide!/1` and Phase 97 D-09 substrings to `assert_advanced_setup_support_contract!/1`. Helper signatures unchanged; `assert_includes_all/2` body unchanged.

## Exact Substrings Added

### A. Six D-06 / D-07 substrings appended to `assert_protected_routes_guide!/1`

(After existing eight Phase 92 substrings; comment separator `# Phase 97 extensions (D-06, D-07)`.)

1. `"Lockspire issues RFC 9068 \`at+jwt\` access tokens by default."` (D-06 sentence 1)
2. `` "`Lockspire.Plug.VerifyToken` accepts JWT bearer tokens for host Phoenix API routes." `` (D-06 sentence 2)
3. `` "Lockspire-owned `/userinfo` and `/introspect` use stored opaque tokens; those are not interchangeable." `` (D-06 sentence 3)
4. `"To opt a client back to opaque, see the admin Client Detail page."` (D-06 sentence 4)
5. `"the runtime narrowing and the default-issuance flip land in v1.27"` (D-07 caveat midphrase — partial match)
6. `"opaque tokens may still be silently accepted on these routes"` (D-07 caveat tail)

### B. Eight D-09 substrings appended to the second list in `assert_advanced_setup_support_contract!/1`

(After existing five Phase 92 out-of-scope substrings; comment separator `# Phase 97 extensions (D-09 four non-goal patterns)`. Each non-goal pattern is paired with its rejection-rationale clause per `.planning/REQUIREMENTS.md:103-110`.)

1. `"no introspection-at-the-RS as the host-API seam"`
2. `"recreates gateway/CIAM productization the canon explicitly rejects"`
3. `"no auto-detection of token shape"`
4. `"documented ecosystem footgun"`
5. `"no dual-verifier dispatcher"`
6. `"hides operator-visible complexity inside the library"`
7. `"no RAR enforcement at the RS plug"`
8. `` "RAR claims surface via `conn.assigns.access_token` for host-owned enforcement" ``

## RED State (the success signal of Plan 01)

- **Test that now RED-fails:** `test/lockspire/release_readiness_contract_test.exs:642` — `test "advanced-setup support contract stays pinned semantically across canonical and derived docs"`.
- **First substring named in the failure message:** `"no introspection-at-the-RS as the host-API seam"` — Plan 03 (the `docs/supported-surface.md` DOCS-02 non-goals subsection) is the planned satisfier.
- **Failure mechanism:** `assert_advanced_setup_support_contract!(supported_surface)` invokes `assert_includes_all/2` which iterates the substring list in order; the first substring absent from `docs/supported-surface.md` becomes the named substring in `inspect/1`'s output. The current docs do not yet carry any D-09 phrase, so the first D-09 substring is the first to fail.
- **Order of subsequent GREENing (informational, not enforced by this plan):**
  - Plan 03 lands the D-09 phrases in `docs/supported-surface.md` (8 substrings → list 2 of `assert_advanced_setup_support_contract!/1` goes GREEN; failure pivots to D-06/D-07 in `docs/protect-phoenix-api-routes.md`).
  - Plan 02 lands the D-06 lead + D-07 caveat in `docs/protect-phoenix-api-routes.md` (6 substrings → `assert_protected_routes_guide!/1` goes GREEN).
  - After both plans complete, line 642 is back to fully GREEN with all 36 substrings asserted (22 Phase 92 + 14 Phase 97).

## Decisions Made

- **Substring placement (within-list append, not new helper):** Followed the Phase 92 D-05 idiom — extend the existing `assert_includes_all/2` lists rather than introducing a parallel `assert_phase_97_*!/1` helper. Keeps the failure message's "named substring" pointing directly at content the operator can paste-grep into the docs.
- **Partial-match for D-07 caveat:** Asserted two non-overlapping caveat sub-phrases (`"the runtime narrowing and the default-issuance flip land in v1.27"` and `"opaque tokens may still be silently accepted on these routes"`) rather than the full single sentence. This is intentional latitude for Plan 02's exact-wording discretion under D-07 — the contract is pinned but the comma/period boundaries are not.
- **Comment-only structural change beyond appends:** Added two one-line `# Phase 97 extensions (...)` markers inside the list literals. No new public functions, no helper-private refactor, no new dependencies.

## Deviations from Plan

None — plan executed exactly as written. The action specified two mechanical list-literal appends with verbatim substring lists; both landed as specified. All acceptance criteria checks (`grep -c` counts, total line growth, compile-clean, RED state) passed on first run.

## Issues Encountered

- **Dependencies needed fetching before the baseline verify could run.** The first `mix test test/lockspire/release_readiness_contract_test.exs:642` invocation reported `the dependency is not available, run "mix deps.get"` for multiple Hex packages. Ran `mix deps.get` once (one-time worktree setup cost) and the Phase 92 baseline came back GREEN on retry. Not a Rule-1/2/3 deviation — first-run cost of a fresh worktree.

## User Setup Required

None — no external service configuration required. (This plan touches one test-support file; no runtime path, no schema change, no env var, no secret.)

## Threat Flags

(none — Phase 97 introduces no new attack surface per `.planning/phases/97-contract-docs-first/97-RESEARCH.md` `## Security Domain`; this plan edits only a test-support module.)

## Next Phase Readiness

- **Plan 02 (`docs/protect-phoenix-api-routes.md` rewrite) is unblocked.** It can run in parallel with Plan 03 because the failure cascade resolves whichever set of substrings (D-06/D-07 or D-09) lands first; the substring lists in this commit are disjoint between the two helpers.
- **Plan 03 (`docs/supported-surface.md` DOCS-02 non-goals subsection) is unblocked.** Plan 03's "done" criterion is now machine-checkable: the second `assert_includes_all/2` list inside `assert_advanced_setup_support_contract!/1` must go GREEN, which means the eight D-09 phrases (verbatim) must appear in `supported-surface.md`.
- **Plan 04/05 (the four-file content-hash clause and adoption-recipe cross-link replacement) are unaffected by this plan** — they live in different parts of the test file and a different doc, respectively.
- **No blockers for Wave 2.**

## Self-Check: PASSED

- File `test/support/advanced_setup_support_truth.ex` exists at the expected path and contains all 14 new substrings (`grep -c` representative checks returned `1` for both `"Lockspire issues RFC 9068"` and `"no introspection-at-the-RS as the host-API seam"`).
- Commit `54ba4e7` exists in `git log --all --oneline` (verified via direct `git rev-parse --short HEAD` immediately after commit).
- Compile is clean under `--warnings-as-errors`.
- Test line 642 RED-fails with a Phase 97 substring named in `expected content to include "..."`.

---
*Phase: 97-contract-docs-first*
*Completed: 2026-05-27*
