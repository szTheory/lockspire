---
phase: 97-contract-docs-first
plan: 03
subsystem: docs
tags:
  - phase-97
  - docs-02
  - supported-surface
  - saas-recipe-cross-link
  - recipe-01-deference
  - canonical-contract-doc

# Dependency graph
requires:
  - phase: 97-01
    provides: "assert_advanced_setup_support_contract!/1 helper extended with 8 D-09 substrings (the substrings this plan's Task 1 satisfies in docs/supported-surface.md)"
provides:
  - "docs/supported-surface.md carries a new `## Explicit non-goals for host-API route protection` H2 subsection (lines 139-147) with four bullets pairing each D-09 rejected pattern with its rejection rationale"
  - "docs/saas-adoption-recipe.md:50 replaces the three-plug-name restatement (Lockspire.Plug.VerifyToken / EnforceSenderConstraints / RequireToken) with a one-line markdown cross-link to docs/protect-phoenix-api-routes.md (per D-11)"
  - "Silent fifth-restatement drift class closed: pipeline definition now lives in one canonical doc (after Plan 02 lands), with saas-adoption-recipe routing to it instead of restating"
  - "All eight D-09 substrings asserted by Plan 01's helper extension now live verbatim in docs/supported-surface.md"
  - "All five Phase 92 substrings in the existing out-of-scope list of docs/supported-surface.md are preserved unchanged (insertion was strictly AFTER L138)"
affects:
  - "97-02 (parallel in Wave 2): together with 97-03, makes `mix test test/lockspire/release_readiness_contract_test.exs:642` turn GREEN"
  - "98-* (Plug Hardening): the four D-09 non-goals now form the public-contract anchor that the hardened plug must respect; no auto-detection, no dispatcher, no introspection-at-the-RS, no RAR enforcement at the plug"
  - "Future doc revisions to the pipeline contract: edit in docs/protect-phoenix-api-routes.md only; docs/saas-adoption-recipe.md is now a pure cross-link consumer"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pattern: docs canonical-anchor + cross-link consumers. Adjacent docs that previously restated pipeline content now cross-link to the canonical contract page. Eliminates the N-restatements-to-keep-in-sync drift class."
    - "Pattern: support-contract non-goals as a first-class H2 subsection. Out-of-scope items live INSIDE docs/supported-surface.md (the Phase 92 D-01 canonical authority for the public support contract), not in a parallel claim elsewhere."

key-files:
  created: []
  modified:
    - "docs/supported-surface.md - inserted the `## Explicit non-goals for host-API route protection` subsection between the existing out-of-scope list (ends L137) and `## Trust posture` (moved from L139 to L149)"
    - "docs/saas-adoption-recipe.md - replaced L50 plug-name restatement with cross-link to docs/protect-phoenix-api-routes.md"

key-decisions:
  - "Used the long em-dash character `—` (U+2014) as the bullet separator, matching the existing supported-surface.md prose style (verified at the original L137)."
  - "Bullet 4's inline-code span uses real Markdown backticks around `conn.assigns.access_token` so the helper's case-sensitive String.contains?/2 substring assertion matches the literal bytes including the backticks."
  - "Cross-link uses an inline-code link text `[docs/protect-phoenix-api-routes.md](protect-phoenix-api-routes.md)` per existing doc cross-link style; the target is a bare relative filename since both docs sit in the same docs/ directory."
  - "Lead paragraph above the four bullets is human-prose only (not asserted) and uses the v1.27-anchored phrasing per the plan's recommendation: `These are explicitly out of scope for the Lockspire-owned host-API protected-route seam under v1.27.`"

patterns-established:
  - "Pattern: when a public-contract assertion adds new required substrings, those substrings land in the canonical doc named by Phase 92 D-01 (docs/supported-surface.md), inside a new H2 subsection that does not modify any pre-existing substring."
  - "Pattern: adjacent recipe-style docs that previously restated pipeline names now route to docs/protect-phoenix-api-routes.md via Markdown link, never via copy-paste of the plug names."

requirements-completed:
  - DOCS-02
  - RECIPE-01

# Metrics
duration: ~2min
completed: 2026-05-27
---

# Phase 97 Plan 03: DOCS-02 non-goals subsection + RECIPE-01 cross-link Summary

**Landed the v1.27 public-contract non-goals as a first-class H2 subsection in docs/supported-surface.md, and converted the saas-adoption-recipe pipeline restatement into a cross-link to the canonical contract page — closing the silent fifth-restatement drift class without touching any Phase 92 substring.**

## Performance

- **Duration:** ~2 min (Task 1 commit 21:57:06Z, Task 2 commit 21:58:13Z)
- **Started:** 2026-05-27T21:55:00Z (approx; worktree HEAD-reset preceded first read)
- **Completed:** 2026-05-27T21:58:24Z
- **Tasks:** 2 / 2
- **Files modified:** 2

## Accomplishments

- docs/supported-surface.md carries a new H2 subsection `## Explicit non-goals for host-API route protection` (L139) that lists the four D-09 rejected patterns with paired rejection-rationale clauses, sitting between the existing out-of-scope list and the `## Trust posture` section.
- docs/saas-adoption-recipe.md:50 now cross-links to docs/protect-phoenix-api-routes.md instead of restating the three plug names — the silent fifth-restatement drift class is closed.
- All eight Phase 97 / D-09 substrings asserted by Plan 01's helper extension (`assert_advanced_setup_support_contract!/1`, second `assert_includes_all/2` call, lines 28-37 of test/support/advanced_setup_support_truth.ex) are now present verbatim in docs/supported-surface.md.
- All five Phase 92 substrings already in the out-of-scope list (helper lines 22-27) are preserved unchanged.

## Task Commits

Each task was committed atomically:

1. **Task 1: Insert the DOCS-02 non-goals subsection into docs/supported-surface.md** - `b5d5501` (docs)
2. **Task 2: Replace plug-name restatement at docs/saas-adoption-recipe.md:50 with canonical cross-link** - `438928e` (docs)

_(No plan-metadata commit is created from this worktree; the orchestrator owns the final SUMMARY/STATE/ROADMAP commit after both Wave 2 plans complete.)_

## Files Created/Modified

- `docs/supported-surface.md` — +9 lines. Insertion at L138 (the previous blank line above `## Trust posture`); the new subsection occupies L139-147, and `## Trust posture` moves from L139 to L149.
- `docs/saas-adoption-recipe.md` — 1 line replaced at L50. Net delta: zero lines (one out, one in).

## Exact post-edit content (required by plan `<output>` spec)

### docs/supported-surface.md — new subsection (verbatim)

Inserted between the existing out-of-scope final bullet (L137) and `## Trust posture` (now L149). Exact post-edit content of L138-149:

```
                                          ← L138 (blank line, pre-existing)
## Explicit non-goals for host-API route protection   ← L139 (new)
                                          ← L140 (blank)
These are explicitly out of scope for the Lockspire-owned host-API protected-route seam under v1.27.   ← L141 (new lead paragraph)
                                          ← L142 (blank)
- no introspection-at-the-RS as the host-API seam — recreates gateway/CIAM productization the canon explicitly rejects   ← L143 (D-09 bullet 1)
- no auto-detection of token shape — documented ecosystem footgun (Ory oathkeeper #257 class)   ← L144 (D-09 bullet 2)
- no dual-verifier dispatcher — hides operator-visible complexity inside the library   ← L145 (D-09 bullet 3)
- no RAR enforcement at the RS plug — RAR claims surface via `conn.assigns.access_token` for host-owned enforcement   ← L146 (D-09 bullet 4)
                                          ← L147 (blank)
## Trust posture                          ← L149 (pre-existing, moved from L139)
```

Bullet wording — each bullet pairs the verbatim D-09 non-goal phrase + em-dash (U+2014) + rejection-rationale clause:

1. `- no introspection-at-the-RS as the host-API seam — recreates gateway/CIAM productization the canon explicitly rejects`
2. `- no auto-detection of token shape — documented ecosystem footgun (Ory oathkeeper #257 class)`
3. `- no dual-verifier dispatcher — hides operator-visible complexity inside the library`
4. `- no RAR enforcement at the RS plug — RAR claims surface via `` ` ``conn.assigns.access_token`` ` `` for host-owned enforcement` (real Markdown backticks around `conn.assigns.access_token` so the helper's literal substring match — including backticks — passes)

### docs/saas-adoption-recipe.md — exact replacement at L50

Pre-edit L50:

```
- If exposing API routes, protect one host route with `Lockspire.Plug.VerifyToken`, `Lockspire.Plug.EnforceSenderConstraints`, and `Lockspire.Plug.RequireToken`.
```

Post-edit L50:

```
- If exposing API routes, follow the canonical pipeline in [`docs/protect-phoenix-api-routes.md`](protect-phoenix-api-routes.md).
```

## Grep invariant confirmations (required by plan `<output>` spec)

### Task 1 — `docs/supported-surface.md`

All eleven `grep -c` assertions defined in Task 1 `<acceptance_criteria>` return exactly `1`. Verified post-commit:

| Substring | Expected | Actual |
| --- | --- | --- |
| `## Explicit non-goals for host-API route protection` | 1 | 1 |
| `no introspection-at-the-RS as the host-API seam` | 1 | 1 |
| `recreates gateway/CIAM productization the canon explicitly rejects` | 1 | 1 |
| `no auto-detection of token shape` | 1 | 1 |
| `documented ecosystem footgun` | 1 | 1 |
| `no dual-verifier dispatcher` | 1 | 1 |
| `hides operator-visible complexity inside the library` | 1 | 1 |
| `no RAR enforcement at the RS plug` | 1 | 1 |
| `RAR claims surface via .conn.assigns.access_token. for host-owned enforcement` | 1 | 1 |
| `Generic API gateway, service-mesh, or third-party issuer protected-resource middleware remains out of scope` (Phase 92) | 1 | 1 |
| `proves front-channel logout success remotely` (Phase 92) | 1 | 1 |
| `## Trust posture` | 1 | 1 |

Additional fixed-string (`grep -F`) checks confirm all five Phase 92 substrings in helper L22-27 survive:

- `Generic API gateway, service-mesh, or third-party issuer protected-resource middleware remains out of scope` ✓
- `` broader resource-server integration beyond Lockspire-owned `/token`, Lockspire-owned protected resources, and the shipped Phoenix plug pipeline `` ✓
- `` Arbitrary custom `Lockspire.MTLS.Extractor` implementations are not first-class peers `` ✓
- `Dynamic Client Registration does not add a new logout runtime; it only manages the existing logout propagation metadata` ✓
- `proves front-channel logout success remotely` ✓

### Task 2 — `docs/saas-adoption-recipe.md`

| Check | Expected | Actual |
| --- | --- | --- |
| `grep -n "If exposing API routes" docs/saas-adoption-recipe.md` returns exactly one line, contains `protect-phoenix-api-routes.md`, contains none of the three plug names | yes | yes (L50, has cross-link, no plug names) |
| `grep -c "protect-phoenix-api-routes.md" docs/saas-adoption-recipe.md` | ≥ 1 | 1 |
| `grep -cE 'Lockspire\.Plug\.VerifyToken.*Lockspire\.Plug\.EnforceSenderConstraints.*Lockspire\.Plug\.RequireToken' docs/saas-adoption-recipe.md` | 0 | 0 |

## Release-readiness contract test status (required by plan `<output>` spec)

`mix test test/lockspire/release_readiness_contract_test.exs:642` was **not executed in this worktree** for two reasons that the plan explicitly anticipates:

1. **Wave 2 isolation:** Plan 03 runs in parallel with Plan 02 in Wave 2; Plan 02's edits to `docs/protect-phoenix-api-routes.md` (D-06/D-07 substring set asserted by `assert_protected_routes_guide!`) are not visible in this worktree. The plan's Task 2 acceptance criteria explicitly states that GREEN status is achievable only after both Wave 2 plans land — *"After this task plus Task 1 plus Plan 02, `mix test test/lockspire/release_readiness_contract_test.exs:642` exits 0."*

2. **Worktree deps:** This worktree shares source with the main checkout but uses its own `deps/` and `_build/` directories. `mix test` reports `the dependency is not available, run "mix deps.get"` for every Hex dependency. The orchestrator merges all Wave 2 worktrees back to the main branch before running the contract test, so the canonical green/red status is decided in the post-merge environment, not here.

**Expected status post-merge:** GREEN. Plan 03 fully satisfies the `assert_advanced_setup_support_contract!/1` slice this plan owns (the D-09 substring set on `docs/supported-surface.md`, plus preservation of all Phase 92 substrings). Plan 02 owns the `assert_protected_routes_guide!` slice. Together they close every substring failure mode in the L642 test.

**Substring-failure isolation guarantee:** If the post-merge test fails, the failure must cite a D-06 or D-07 substring in `docs/protect-phoenix-api-routes.md` (Plan 02 territory). It must NOT cite a D-09 substring in `docs/supported-surface.md` (all 8 verified above) and must NOT cite a substring in `docs/saas-adoption-recipe.md` (no substring assertions touch that file under L642).

## Decisions Made

- Em-dash separator is the long em-dash `—` (U+2014), matching the existing pre-edit style in docs/supported-surface.md (e.g., original L137 `— Lockspire does not treat ...`).
- Lead paragraph is one short sentence anchoring the v1.27 scope explicitly. The helper does not assert this line; it exists for human readers entering the canonical contract page for the first time.
- Bullet 4 uses real Markdown inline-code backticks around `conn.assigns.access_token` rather than the YAML-escaped form used in the plan's `<interfaces>` block. The Plan 01 helper assertion uses real backticks; only verbatim-with-backticks satisfies `String.contains?/2`.
- Cross-link target is the bare relative path `protect-phoenix-api-routes.md` (not `./protect-phoenix-api-routes.md` and not a fully-qualified path), matching the existing intra-`docs/` cross-link style verified at `docs/protect-phoenix-api-routes.md:62`.

## Deviations from Plan

None — plan executed exactly as written. Both task `<action>` blocks specified recommended verbatim wording, and that wording was adopted as-is (planner's discretion was not exercised in a way that changed any load-bearing substring).

## Issues Encountered

None during execution. Two non-issues worth recording:

- `mix test` cannot run in this worktree (missing `deps/`); see "Release-readiness contract test status" above for why this is expected and how the plan accommodates it. No action needed — orchestrator resolves the test status post-merge.
- The plan's Task 1 `<action>` lists "Line A: blank line" through "Line K" — the implementation produced L138 (blank, pre-existing) through L149 (`## Trust posture`, pre-existing), with the new content sitting at L139-147. The structure matches the plan's intent exactly (1 blank ✱ heading ✱ blank ✱ lead-para ✱ blank ✱ 4 bullets ✱ blank ✱ next heading).

## User Setup Required

None.

## Next Phase Readiness

- **Wave 2 status:** Plan 03 worktree complete. Orchestrator can merge Plan 02 + Plan 03 together to unblock the L642 contract test and Wave 3.
- **Public contract anchor:** The four D-09 non-goals now form a first-class section of the canonical public support contract. Phases 98 (Plug Hardening), 99 (Signer Extraction + JWT-Default Issuance), and 100 (Sender-Constraint End-to-End Proof) must respect these as runtime non-goals — no introspection-at-the-RS, no auto-detection, no dual-verifier dispatcher, no RAR enforcement at the plug.
- **Drift surface reduction:** docs/saas-adoption-recipe.md no longer carries the pipeline names; any future edit to the canonical pipeline (in docs/protect-phoenix-api-routes.md) propagates by cross-link rather than copy-paste.

## Self-Check: PASSED

- `docs/supported-surface.md` exists and contains the new subsection — verified via `grep -n "^## Explicit non-goals for host-API route protection$" docs/supported-surface.md` (returns L139).
- `docs/saas-adoption-recipe.md` L50 carries the cross-link — verified via `sed -n '50p' docs/saas-adoption-recipe.md`.
- Commit `b5d5501` exists in `git log --oneline -3` — confirmed.
- Commit `438928e` exists in `git log --oneline -3` — confirmed.
- All 11 Task 1 grep-count assertions return exactly 1 — confirmed.
- All 3 Task 2 grep assertions hold — confirmed.
- All 5 Phase 92 substrings preserved via fixed-string grep — confirmed.

---
*Phase: 97-contract-docs-first*
*Plan: 03*
*Completed: 2026-05-27*
