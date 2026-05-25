---
phase: 87
slug: support-truth-and-milestone-closure
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
---

# Phase 87 — Validation Strategy

> Per-phase validation contract for support-truth closure, DCR logout metadata documentation accuracy, and milestone-close release proof.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + ExDoc verification |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix docs.verify && mix test test/lockspire/release_readiness_contract_test.exs test/lockspire/web/controllers/registration_controller_test.exs test/lockspire/protocol/registration_management_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~45-120 seconds |

---

## Sampling Rate

- **After every task commit:** Run the quick command above.
- **After every plan wave:** Run `mix test`.
- **Before `$gsd-verify-work`:** `mix docs.verify` and the full suite must be green.
- **Max feedback latency:** under 3 minutes for the quick path.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 87-01-01 | 01 | 1 | PROOF-02 | T-87-01 | Canonical support truth says DCR/RFC 7592 manage the existing logout propagation metadata. | docs | `mix docs.verify` | ✅ | ✅ green |
| 87-01-02 | 01 | 1 | PROOF-02 | T-87-02 | The support page stops claiming DCR logout metadata is unsupported and states the durable back-channel vs best-effort front-channel asymmetry without widening the runtime claim. | docs | `mix docs.verify && rg -n "four existing logout propagation metadata fields|back-channel.*durable|front-channel.*best effort only|does not add a new logout runtime" docs/supported-surface.md` | ✅ | ✅ green |
| 87-01-03 | 01 | 1 | PROOF-02 | T-87-02 | The canonical support page stays terse and does not absorb lifecycle examples or redirect-vs-propagation workflow detail that belongs in adjacent guides. | docs | `mix docs.verify && ! rg -n "PUT /oauth/register|registration_access_token replaces|client_secret replaces|post-logout redirect URIs are browser destinations" docs/supported-surface.md` | ✅ | ✅ green |
| 87-02-01 | 02 | 2 | PROOF-02 | T-87-03 | The DCR guide includes one explicit lifecycle section for create/read/update of the four logout metadata fields. | docs | `mix docs.verify` | ✅ | ✅ green |
| 87-02-02 | 02 | 2 | PROOF-02 | T-87-03 | The DCR guide states full-replace, omission-clears, RAT replacement, and client-secret replacement semantics plainly. | docs | `mix docs.verify && rg -n "full-replace|omitted.*clear|registration_access_token.*replaces|client_secret.*replaces" docs/dynamic-registration.md` | ✅ | ✅ green |
| 87-02-03 | 02 | 2 | PROOF-02 | T-87-04 | DCR examples stay aligned with shipped controller/protocol truth and keep logout propagation separate from post-logout redirects. | docs/integration | `mix docs.verify && mix test test/lockspire/web/controllers/registration_controller_test.exs test/lockspire/protocol/registration_management_test.exs` | ✅ | ✅ green |
| 87-03-01 | 03 | 2 | PROOF-02 | T-87-05 | Operator docs say DCR can manage the same existing logout propagation metadata while preserving durable back-channel, best-effort front-channel wording, and redirect-vs-propagation separation. | docs | `mix docs.verify && rg -n "self-service clients|Back-channel logout is the reliable path|Front-channel logout is best effort only|Post-logout redirect URIs|Logout propagation" docs/operator-admin.md` | ✅ | ✅ green |
| 87-03-02 | 03 | 2 | PROOF-02 | T-87-06 | Maintainer release docs continue to defer to the canonical support page instead of creating a second support matrix. | docs | `mix docs.verify && rg -n "canonical support contract|docs/supported-surface.md|does not define a second public support contract|Public release claims stay anchored to `docs/supported-surface.md`" docs/maintainer-release.md` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All phase work should be provable through `mix docs.verify`, the existing repo-native DCR/protocol tests, and targeted grep checks against the affected docs. No new automated doc-drift contract tests are added in this phase because that work is explicitly deferred in `87-CONTEXT.md`.

---

## Validation Sign-Off

- [x] All tasks have automated verification coverage.
- [x] Sampling continuity: no three consecutive tasks without an automated check.
- [x] Wave 0 coverage is already present.
- [x] No watch-mode flags.
- [x] Feedback latency stays within the quick-run target.
- [x] `nyquist_compliant: true` is set when execution proof is complete.

**Approval:** passed
