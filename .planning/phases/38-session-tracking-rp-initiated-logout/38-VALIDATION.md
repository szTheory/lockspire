---
phase: 38
slug: session-tracking-rp-initiated-logout
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-29
---

# Phase 38 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/lockspire/protocol/end_session_test.exs -x` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/lockspire/protocol/end_session_test.exs -x`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 38-01-01 | 01 | 0 | SLO-01 | — | N/A | unit | `mix test test/lockspire/protocol/end_session_test.exs -x` | ❌ W0 | ⬜ pending |
| 38-01-02 | 01 | 0 | SLO-02 | — | N/A | unit | `mix test test/lockspire/web/end_session_controller_test.exs -x` | ❌ W0 | ⬜ pending |
| 38-01-03 | 01 | 0 | SLO-01, SLO-02 | — | N/A | integration | `mix test test/integration/phase38_session_logout_e2e_test.exs` | ❌ W0 | ⬜ pending |
| 38-xx-sid-gen | 01 | 1 | SLO-01 | — | sid generated at interaction creation | unit | `mix test test/lockspire/protocol/authorization_flow_test.exs -x` | ✅ | ⬜ pending |
| 38-xx-sid-token | 01 | 1 | SLO-01 | — | sid denormalized onto issued tokens | unit | `mix test test/lockspire/storage/ecto/repository_test.exs -x` | ✅ | ⬜ pending |
| 38-xx-sid-claim | 01 | 1 | SLO-01 | — | sid emitted as OIDC claim in ID tokens | unit | `mix test test/lockspire/protocol/id_token_test.exs -x` | ✅ | ⬜ pending |
| 38-xx-revoke | 01 | 1 | SLO-01 | T-38-01 | revoke_by_sid/1 marks active tokens revoked | unit | `mix test test/lockspire/storage/ecto/repository_test.exs -x` | ✅ | ⬜ pending |
| 38-xx-methods | 02 | 1 | SLO-02 | — | /end_session accepts GET and POST | unit | `mix test test/lockspire/web/end_session_controller_test.exs -x` | ❌ W0 | ⬜ pending |
| 38-xx-hint | 02 | 1 | SLO-02 | T-38-02 | id_token_hint signature validated, expiry tolerated | unit | `mix test test/lockspire/protocol/end_session_test.exs -x` | ❌ W0 | ⬜ pending |
| 38-xx-redirect-uri | 02 | 1 | SLO-02 | T-38-03 | post_logout_redirect_uri exact match, open-redirect prevented | unit | `mix test test/lockspire/protocol/end_session_test.exs -x` | ❌ W0 | ⬜ pending |
| 38-xx-aud | 02 | 1 | SLO-02 | T-38-04 | client_id/aud mismatch rejected | unit | `mix test test/lockspire/protocol/end_session_test.exs -x` | ❌ W0 | ⬜ pending |
| 38-xx-host-redirect | 02 | 1 | SLO-02 | T-38-05 | host logout redirect issued to logout_path | unit | `mix test test/lockspire/web/end_session_controller_test.exs -x` | ❌ W0 | ⬜ pending |
| 38-xx-completion | 02 | 2 | SLO-02 | T-38-01 | completion endpoint triggers revoke_by_sid | unit | `mix test test/lockspire/web/end_session_controller_test.exs -x` | ❌ W0 | ⬜ pending |
| 38-xx-discovery | 02 | 2 | SLO-02 | — | end_session_endpoint in discovery JSON | unit | `mix test test/lockspire/protocol/discovery_test.exs -x` | ✅ | ⬜ pending |
| 38-xx-bcl-fcl | 02 | 2 | SLO-02 | — | BCL/FCL discovery flags are false | unit | `mix test test/lockspire/protocol/discovery_test.exs -x` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/lockspire/protocol/end_session_test.exs` — stubs for SLO-02 protocol validation (id_token_hint, redirect URI, aud check)
- [ ] `test/lockspire/web/end_session_controller_test.exs` — stubs for SLO-02 HTTP adapter (GET/POST, host redirect, completion)
- [ ] `test/integration/phase38_session_logout_e2e_test.exs` — end-to-end coverage for SLO-01 and SLO-02 full flow

*Existing files to extend: `authorization_flow_test.exs`, `repository_test.exs`, `id_token_test.exs`, `discovery_test.exs`*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Generator emits host logout route template | SLO-02 | Requires running mix task against a generated app | Run `mix lockspire.install` in a test app; verify host logout route stub is present in the generated router |
| "You have been signed out" fallback page renders correctly | SLO-02 | UI rendering check | Visit `/end_session` with no registered `post_logout_redirect_uri`; verify plain page renders with no redirect |
| Admin UI shows `sid` in token detail view | SLO-01 | LiveView UI rendering | Navigate to token detail in admin; verify sid field appears |
| Admin UI allows editing `post_logout_redirect_uris` | SLO-02 | LiveView form interaction | Edit a client; add a URI to `post_logout_redirect_uris`; save; verify stored |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
