---
phase: "154"
slug: "responsive-theme-route-proof"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-15"
audited: "2026-10-15"
---

# Phase 154 — Validation Strategy

> Per-phase validation contract. Audited after execution. Browser-only proof (rendered layout, keyboard focus, reduced motion, final captures) is evidence-based and manual by design: agent-browser never runs in CI (D-05).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Phoenix.LiveViewTest + LazyHTML) and `node --test` (Node stdlib, no browser) |
| **Config file** | `mix.exs` aliases (`test.fast`); no Node config |
| **Env** | `HEX_HOME=/private/tmp/lockspire-hex MIX_ENV=test ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1` |
| **Quick run command** | `mix test test/lockspire/web/live/admin/design_system` |
| **Full suite command** | `mix test.fast && node --test test/browser/admin_multi_value_test.mjs test/browser/admin_route_proof_test.mjs` |
| **Estimated runtime** | ~90 seconds |

---

## Sampling Rate

- **After every task commit:** Run the quick command (or the task's own suite below)
- **After every plan wave:** Run the full suite command
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 154 seconds

---

## Per-Task Verification Map

Commands assume the env above. "evidence" means a deterministic local check over a tracked phase doc or git state; it is not in CI because planning-doc pins are excluded from CI (D-05).

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 154-01-01 | 01 | 1 | PROOF-01 | SAFE-01 privacy | Denylist scan of text, field values, and data-* attrs before save | unit (node) | `node --test test/browser/admin_route_proof_test.mjs` | ✅ | ✅ green |
| 154-01-02 | 01 | 1 | PROOF-01 | SAFE-01 safety | Harness never clicks, types, or submits beyond the synthetic login; keys limited to Tab/Escape | unit (node) | `node --test test/browser/admin_route_proof_test.mjs` (no-click source scan, added in audit) | ✅ | ✅ green |
| 154-01-02 | 01 | 1 | PROOF-01 | — | Harness route templates equal `RouteScorecards.expected_routes/0` (30) | unit (ExUnit) | `mix test test/lockspire/web/live/admin/design_system/page_contract_test.exs` (added in audit) | ✅ | ✅ green |
| 154-01-03 | 01 | 1 | PROOF-01 | SAFE-01 privacy | BrowserEvidence accepts phase widths, rejects 641px, sensitive values, pass-with-overflow | unit (ExUnit) | `mix test test/lockspire/web/live/admin/design_system/proof_artifact_contract_test.exs` | ✅ | ✅ green |
| 154-02-01 | 02 | 1 | UI-07 | — | `--ls-border-control` meets 3:1 on panel/page/muted, light and dark | unit (ExUnit) | `mix test test/lockspire/web/live/admin/design_system/css_contract_test.exs` | ✅ | ✅ green |
| 154-02-02 | 02 | 1 | UI-07 | — | Text 4.5:1, status/accent/primary 4.5:1, focus ring 3:1 in both themes; brandbook token present | unit (ExUnit) | `mix test test/lockspire/web/live/admin/design_system` | ✅ | ✅ green |
| 154-03-01 | 03 | 1 | UI-07, PROOF-01 | — | Page contract rejects 0/2 h1, duplicate ids, dangling ARIA targets, href-less links, token-like text (with LiveView plumbing stripped), unlabeled controls; accepts wrapped labels | unit (ExUnit) | `mix test test/lockspire/web/live/admin/overview_live_test.exs test/lockspire/web/live/admin/design_system/page_contract_test.exs` | ✅ | ✅ green |
| 154-03-02 | 03 | 2 | UI-07, PROOF-01 | SAFE-01 | Contract on client inventory, new, edit, logout-propagation; redaction/copy-once assertions kept | integration (LiveView) | `mix test test/lockspire/web/live/admin/clients_live_test.exs` | ✅ | ✅ green |
| 154-03-03 | 03 | 2 | UI-07, PROOF-01 | SAFE-01 | Contract on 9 client detail task routes; rotate pages checked pre-submit only | integration (LiveView) | `mix test test/lockspire/web/live/admin/clients_live/show_test.exs` | ✅ | ✅ green |
| 154-04-01 | 04 | 2 | UI-07, PROOF-01 | — | Contract on 5 policy pages | integration (LiveView) | `mix test test/lockspire/web/live/admin/policies_live` | ✅ | ✅ green |
| 154-04-02 | 04 | 2 | UI-07, PROOF-01, SAFE-01 | SAFE-01 privacy | Contract on dcr, iats, iats/new, keys, keys/:id; copy-once and key redaction kept | integration (LiveView) | `mix test test/lockspire/web/live/admin/dcr_live_test.exs test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/keys_live_test.exs` | ✅ | ✅ green |
| 154-04-03 | 04 | 2 | SAFE-01 | — | keys_live/index.ex compiles warning-free; next-step text pinned | build + integration | `mix compile --force 2>&1 \| grep -c lib/lockspire/web/` (expect 0); `mix test test/lockspire/web/live/admin/keys_live_test.exs` | ✅ | ✅ green |
| 154-05-01 | 05 | 2 | UI-07, PROOF-01, SAFE-01 | SAFE-01 | Contract on consents and tokens; distinct revocation scopes kept | integration (LiveView) | `mix test test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/tokens_live_test.exs` | ✅ | ✅ green |
| 154-05-02 | 05 | 2 | UI-07, SAFE-01 | SAFE-01 | Queues stay read-only (no controls/forms) and pass the contract | integration (LiveView) | `mix test test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs test/lockspire/web/live/admin/design_system/route_contract_test.exs` | ✅ | ✅ green |
| 154-05-03 | 05 | 2 | SAFE-01 | — | Device filter clauses grouped; pending/all/unknown filters unchanged | build + integration | `mix test test/lockspire/web/live/admin/device_authorizations_live_test.exs` | ✅ | ✅ green |
| 154-06-01 | 06 | 3 | UI-07 | — | Tracer sweep rows parse as BrowserEvidence | evidence | `mix run --no-start -e '...BrowserEvidence.parse!(File.read!(".../154-RESPONSIVE-SWEEP.md"))'` (42 rows) | ✅ | ✅ green |
| 154-06-02 | 06 | 3 | UI-07 | — | 630-cell width x theme matrix, reduced motion, keyboard focus, 200%/400% reflow | manual (agent-browser) + evidence | see Manual-Only; rows recorded in `154-RESPONSIVE-SWEEP.md` | ✅ | ✅ green (evidence) |
| 154-06-03 | 06 | 3 | UI-07, SAFE-01 | SAFE-01 | Each sweep fix guarded by CSS contract: F-01 nav wrap at 800px, F-02 root scroll-padding, F-03 inventory badge wrap at 640px; reduced-motion 0.01ms | unit (ExUnit) | `mix test test/lockspire/web/live/admin/design_system/css_contract_test.exs` | ✅ | ✅ green |
| 154-07-01 | 07 | 4 | PROOF-01 | — | Final evidence parses (681 rows >= 630) | evidence | `mix run --no-start -e '...BrowserEvidence.parse!(File.read!(".../154-BROWSER-EVIDENCE.md"))'` | ✅ | ✅ green |
| 154-07-02 | 07 | 4 | PROOF-01 | SAFE-01 privacy | 30 final captures + 72 changed-page images, eye-reviewed, redaction-safe | manual + evidence | see Manual-Only; `154-FINAL-CAPTURES.md` | ✅ | ✅ green (evidence) |
| 154-07-03 | 07 | 4 | SAFE-01 | SAFE-01 | 13-path security set, test.fast, format, protected diff = PR #123 allowlist, phase-local protected diff empty, no private keys, CI runs only admin_multi_value_test | integration + evidence | commands (a)-(j) in `154-SAFE-GATE.md` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Requirement coverage

| Requirement | Automated (CI) | Evidence / manual |
|-------------|----------------|-------------------|
| UI-07 | Contrast pairs and control boundary (both themes, system via dark block); reduced-motion and focus CSS contracts; F-01/F-02/F-03 regression guards; page contract (one h1, labels, ARIA targets) on all 30 paths | 630-cell matrix (overflow, clipped, unlabeled), keyboard and reduced-motion rows, 1100px spot check; native zoom not observed, 640/320px emulation stands in (D-02) |
| PROOF-01 | Page contract on all 30 paths; BrowserEvidence validator; harness route parity with router | 30 final captures beside 153 baselines; 681 evidence rows; node harness tests (local) |
| SAFE-01 | 13-path security/admin set; read-only queue and revocation-scope tests; CI-workflow contract; architecture fitness | Protected-path diff allowlist, private-key grep, no-click harness scan (local node test) |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Rendered layout: no document overflow, clipped content, or unlabeled control at 7 widths x 3 themes on 30 paths | UI-07, PROOF-01 | Needs a real browser; agent-browser is local-only (D-05) | Start the demo, then `node test/browser/admin_route_proof.mjs --matrix --out tmp/...`; parse rows with `BrowserEvidence.parse!/1` |
| Keyboard focus visible and in viewport; Escape closes disclosures | UI-07 | Computed focus rings and scroll position need a browser | `node test/browser/admin_route_proof.mjs --keyboard --route <path> --width 1280` |
| Reduced motion computes <= 0.01ms durations | UI-07 | Computed styles under emulated media | `--motion reduced-motion` rows; CSS rule itself is CI-guarded |
| 200% zoom / 400% reflow | UI-07 | CDP Chrome ignores native zoom keys | 640px and 320px viewport rows stand in (D-02); native zoom recorded "not observed" |
| Final captures redaction-safe and eye-reviewed; card-edge escapes | PROOF-01, SAFE-01 | Visual judgment (F-03 was only caught by eye) | Review images listed in `154-FINAL-CAPTURES.md` |

---

## Validation Audit 2026-10-15

| Metric | Count |
|--------|-------|
| Gaps found | 3 |
| Resolved | 3 |
| Escalated | 0 |

Gaps filled:
1. Page contract negative cases beyond h1 (duplicate ids, dangling `aria-describedby`/`labelledby`/`controls`, href-less links, token text surviving LiveView-plumbing strip, unlabeled control, dangling `label[for]`, wrapped-label acceptance): `test/lockspire/web/live/admin/design_system/page_contract_test.exs`.
2. Harness route list vs router parity was a one-off plan verify; now a CI ExUnit test that reads the harness source as text (no Node, no browser): same file.
3. "Harness never clicks or submits" was judgment-only; now a static source scan in `test/browser/admin_route_proof_test.mjs` (local node test).

Caveat (WARNING): the no-click scan is static. It pins the agent-browser verbs, keys, and the single `requestSubmit`, but cannot prove what arbitrary `eval` scripts do at runtime beyond the `.click(`/`dispatchEvent(`/`.submit()` patterns it rejects.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 154s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-10-15
