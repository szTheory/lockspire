---
phase: 154-responsive-theme-route-proof
plan: "01"
subsystem: admin-ui-proof
tags: [browser-proof, evidence, redaction, node-test]
requires: []
provides:
  - "Local route-proof CLI (test/browser/admin_route_proof.mjs)"
  - "BrowserEvidence widths 640/720/1119/1120/1261/1280"
affects: [154-02, 154-07]
tech-stack:
  added: []
  patterns: ["Node stdlib + agent-browser CLI, local-only (not in CI)"]
key-files:
  created:
    - test/browser/admin_route_proof.mjs
    - test/browser/admin_route_proof_test.mjs
  modified:
    - test/support/lockspire/web/admin_proof/browser_evidence.ex
    - test/lockspire/web/live/admin/design_system/proof_artifact_contract_test.exs
key-decisions:
  - "Redaction scan covers visible text, every field value and every data-* attribute value before any screenshot is saved"
  - "Harness never clicks; only the synthetic login form is submitted; keyboard sweep uses Tab and Escape"
requirements-completed: [PROOF-01, UI-07]
status: complete
duration: 25 min
completed: 2026-10-15
commits: 3
plan_head_before: 715995360c3665094c15ec026f4cf968a4dcffcb
plan_head_after: 1c750318a7303f0a686513f2827f48a8ec9c8b21
actuals:
  tokens: 14000
  tasks: 3
  commits: 3
---

# Phase 154 Plan 01: Local Route Proof Harness Summary

A local Node CLI drives agent-browser against the synthetic demo to produce BrowserEvidence-valid, redaction-scanned rows and screenshots for any of the 30 admin paths, and BrowserEvidence now accepts the widths this phase needs.

## Accomplishments

- `admin_route_proof.mjs`: single-path flow (login as `ops`, viewport, theme via `lockspire-admin-theme`, motion, DOM sweep for overflow, clipped elements, unlabeled controls, small targets), denylist scan mirrored from BrowserEvidence, screenshots under git-ignored `tmp/`, 14-column evidence rows.
- Full matrix mode (`--matrix`, 30 routes x 7 widths x 3 themes = 630), `--keyboard` Tab/Escape sweep, section slices for tall pages, `--list-templates`, `--list-changed`, `--matrix-size`.
- `admin_route_proof_test.mjs`: 8 `node --test` cases, no browser, including field-value-only and data-attribute-only redaction hits.
- BrowserEvidence `@allowed_viewports` extended; new contract test also asserts 641px is rejected.

## Verification

- Tracer row for `/admin/overview` at 390px light printed, PNG saved, and parsed by `BrowserEvidence.parse!/1` (1 row).
- `node --test` 8 pass, 0 fail. `--list-templates` diff against `RouteScorecards.expected_routes/0` empty (30 lines). `--matrix-size` 630, `--list-changed` 12.
- `proof_artifact_contract_test.exs` and `inventory_contract_test.exs`: 9 passed.
- No `"Enter"`/`"Space"` in the script; `ci.yml` still has only the `admin_multi_value_test.mjs` browser step.
- Live smoke also run for keyboard mode (`/admin/clients` 1280 dark: 22 tab stops, 22 with indicator) and a 2-route system-theme matrix.

## Deviations from Plan

None - plan executed exactly as written. The template-diff `mix run --no-start` variant worked without change.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

Created files exist; commits ec132cdd, 0b64d1d3, 1c750318 are on HEAD.
