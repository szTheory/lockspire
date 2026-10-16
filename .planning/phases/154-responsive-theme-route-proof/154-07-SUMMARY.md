---
phase: 154-responsive-theme-route-proof
plan: "07"
subsystem: admin-ui-proof
tags: [final-captures, browser-evidence, redaction, safe-gate, responsive, theme]
requires: ["154-06"]
provides:
  - "154-FINAL-CAPTURES.md: 154-FINAL-01..30 desktop manifest beside the 153 baselines, plus 72 mobile/reflow/zoom/theme images for the 12 changed pages"
  - "154-BROWSER-EVIDENCE.md: 681 BrowserEvidence rows (630-cell matrix, 30 desktop-size, 7 reduced-motion, 14 keyboard), all pass"
  - "154-SAFE-GATE.md: SAFE-01 command outcomes (a)-(j), PR #123 allowlist, invariant map"
affects: [phase-154-verification, milestone-v1.42-audit]
tech-stack:
  added: []
  patterns: ["Two-control redaction: DOM denylist before save, eye review after", "Card-edge escape scan as a check the document-overflow check cannot do"]
key-files:
  created:
    - .planning/phases/154-responsive-theme-route-proof/154-FINAL-CAPTURES.md
    - .planning/phases/154-responsive-theme-route-proof/154-BROWSER-EVIDENCE.md
    - .planning/phases/154-responsive-theme-route-proof/154-SAFE-GATE.md
  modified:
    - .planning/phases/154-responsive-theme-route-proof/154-RESPONSIVE-SWEEP.md
key-decisions:
  - "Desktop finals use 1261x900 at DPR 2 so final images match the 2522 px baseline width"
  - "Locked-console capture uses --disable-gpu-vsync and --disable-frame-rate-limit (frame pacing only, no layout effect)"
  - "Captures taken before the F-03 fix are kept apart in final-prefix-stale/ and never mixed into the manifest"
requirements-completed: [UI-07, PROOF-01, SAFE-01]
status: complete
duration: 95 min
completed: 2026-10-15
commits: 5
plan_head_before: 768b3a61b6aab032705f511e07ad86e7c95cf9c3
plan_head_after: 77945913266fe9be55cbd379e7e5ed944fee6c36
actuals:
  tokens: 60000
  tasks: 3
  commits: 5
---

# Phase 154 Plan 07: Final Route Proof and SAFE-01 Gate Summary

All 30 admin paths now have final captures that are safe to share. The 12 changed pages also have phone, reflow, zoom, and theme images. Every capture comes from source `d3b2fec2` on a restarted demo. The 681 evidence rows all pass, and the SAFE-01 gate is green. The final eye review caught one real defect (F-03, a badge escaping its card at 320 px), which was fixed before the captures were retaken.

## Accomplishments

- **Tracer:** `/admin/clients/new` was captured through image, manifest row, and validated evidence row. A desktop size of 1261x900 at DPR 2 reproduces the 2522 px baseline width.
- **F-03 found:** in the first final pass, the eye review spotted the "Registered through API" badge on `/admin/clients` crossing its card edge by 14 px at 320 px. The harness had passed it because the document did not overflow. Plan 07 stopped without editing source. The orchestrator fixed it in `d3b2fec2` under Plan 06 rules, with a `CssAssertions` guard.
- **Re-run on the fixed source:**
  - re-froze the source, regenerated `source-sha256.json`, restarted the container, and passed the smoke test;
  - recaptured 44 desktop images (30 full pages plus 14 section slices) and 72 changed-page images;
  - checked by eye all 102 full-page images, all Pass;
  - the DOM denylist found 0 hits across 103 page loads;
  - a card-edge scan of all 30 paths at all 7 widths found 0 escapes.
- **Evidence:** all 681 rows pass, with 0 fail and 0 blocked. That is 630 of 630 matrix cells, 30 of 30 at the desktop capture size, 7 of 7 reduced-motion, and 14 of 14 keyboard rows. Every keyboard stop shows a focus indicator, and 0 stops are offscreen.
- **SAFE-01:**
  - 13-path security/admin set: 518 passed.
  - `mix test.fast`: 1554 passed, 6 skipped.
  - Format and `git diff --check` are clean.
  - The compile has 0 warnings in `lib/lockspire/web/`.
  - Node tests: 15 of 15 pass.
  - The protected/dependency diff since `e67a4898` equals exactly the PR #123 allowlist, and the phase-local protected diff is empty.
  - No private key text was found.
  - CI runs only `admin_multi_value_test.mjs` from `test/browser/`.

## Task Commits

1. **Task 1: tracer:** `d36d67de`
2. **Task 2 (first pass stopped on F-03):** `9fac8e74`
3. **F-03 fix (orchestrator, Plan 06 rules, not a Plan 07 commit):** `d3b2fec2`
4. **Task 2: final captures and evidence on fixed source:** `dc4257f2`
5. **Task 3: SAFE-01 gate:** `77945913`

`commits: 5` is measured from the ledger and includes `d3b2fec2`. Plan 07 itself made 4 commits.

## Verification

- `BrowserEvidence.parse!/1` on `154-BROWSER-EVIDENCE.md` returns 681 rows, at least the `--matrix-size` of 630. Exit 0.
- The manifest has 30 distinct 154-FINAL rows, matching the `--list-templates` count. Every referenced PNG exists and is non-empty. Exit 0.
- Image counts: mobile390 12, reflow320 12, zoom200 12, themes 36, baselines 30. `| fail |` rows: 0.
- All five Task 3 verify commands exit 0 (see `154-SAFE-GATE.md`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Screenshots hung while the console was locked**
- **Found during:** Task 1
- **Issue:** `Page.captureScreenshot` timed out and `requestAnimationFrame` never fired, because the compositor's vsync clock stops when the macOS console is locked.
- **Fix:** run every browser session with `AGENT_BROWSER_ARGS=--disable-gpu-vsync,--disable-frame-rate-limit`. These flags change frame pacing only. They are recorded in the manifest and the evidence doc.

**2. [Rule 3 - Blocking] The harness cannot set a device scale**
- **Found during:** Task 1
- **Issue:** the tracked harness's `set viewport` call has no DPR argument, so it could not reproduce the 2522 px baseline width.
- **Fix:** an untracked scratch driver imports the harness's own helpers (`scanSensitive`, `collectScanText`, `concretePath`, `sectionPlan`) for the image captures. All evidence rows still come from the tracked harness. No tracked test or source file changed.

**3. [Rule 1 - Doc hygiene] Trailing blank line in 154-RESPONSIVE-SWEEP.md**
- **Found during:** Task 3, step (d)
- **Issue:** a trailing blank line committed in Plan 06 made `git diff --check ef6043ec` fail.
- **Fix:** removed it while adding the F-03 note (`dc4257f2`). The rerun is clean.

### Stopped for a real defect

**F-03 (badge escapes its card at 320 px):** reported as a checkpoint instead of fixed, per the plan's no-source rule. It was fixed in `d3b2fec2` and every capture was retaken. The F-03 ID is local to the final manifest, because `154-RESPONSIVE-SWEEP.md` already uses F-03 for the allowed small-target note. Both docs cross-reference each other.

## Known Stubs

None.

## Non-blocking observations

- The "Secret and signing keys" card on app details stretches to its row partner's height. This is a pre-existing layout issue, noted only.
- Dates show the headless browser locale ("15 oct. 2026"). This is not product copy.
- Six compile warnings outside the admin web layer predate this phase. They are listed in `154-SAFE-GATE.md` (D-04).

## Threat Flags

None. No source, endpoint, auth path, or schema was touched by this plan.

## Self-Check: PASSED

154-FINAL-CAPTURES.md, 154-BROWSER-EVIDENCE.md, and 154-SAFE-GATE.md exist. Commits d36d67de, 9fac8e74, d3b2fec2, dc4257f2, and 77945913 are ancestors of HEAD.
