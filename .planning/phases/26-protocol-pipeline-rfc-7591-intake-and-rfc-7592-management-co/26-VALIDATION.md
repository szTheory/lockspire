---
phase: 26
slug: protocol-pipeline-rfc-7591-intake-and-rfc-7592-management-co
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-26
---

# Phase 26 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir/Phoenix) with `Lockspire.DataCase` and `Lockspire.RepoCase` for DB-backed tests |
| **Config file** | `mix.exs`, `test/test_helper.exs` (existing — no new framework install required) |
| **Quick run command** | `mix test test/lockspire/protocol/ --max-failures=1` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30s quick / ~3 min full (current baseline; verify in Wave 0) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/lockspire/protocol/ --max-failures=1`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds for quick scope

---

## Per-Task Verification Map

> The planner will populate concrete task IDs after PLAN.md generation. The contract below specifies the verification surfaces every task must map to.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 26-XX-XX | (intake validator)        | TBD | DCR-02 | T-26-INTAKE | rejects `jwks_uri`, `jwks+jwks_uri`, incoherent grants/responses; routes redirect_uris through `Lockspire.Clients.validate_redirect_uris/1` | unit (parametric) | `mix test test/lockspire/protocol/registration_test.exs` | ❌ W0 | ⬜ pending |
| 26-XX-XX | (RAT issuance)            | TBD | DCR-03 | T-26-RAT-LEAK | RAT plaintext returned once, hashed at rest via `Lockspire.Security.Policy` | unit | `mix test test/lockspire/protocol/registration_access_token_test.exs` | ❌ W0 | ⬜ pending |
| 26-XX-XX | (IAT atomic redemption)   | TBD | DCR-04 | T-26-IAT-RACE | expired/revoked/used → `{:error, :invalid_token}`; success marks used in same DB tx | unit + concurrent | `mix test test/lockspire/protocol/initial_access_token_test.exs` | ❌ W0 | ⬜ pending |
| 26-XX-XX | (RFC 7592 management)     | TBD | DCR-11 | T-26-MGMT-AUTHZ | GET/PUT/DELETE behavior verified via `RegistrationManagement` API; RAT-bearer authz proven by failing-fixture | unit | `mix test test/lockspire/protocol/registration_management_test.exs` | ❌ W0 | ⬜ pending |
| 26-XX-XX | (audit attribution)       | TBD | DCR-22 | T-26-ATTRIBUTION | DCR codepaths emit `actor_type: "dcr"` or `"self_registered_client"`; regression test fails on `"operator"` for any DCR write | regression | `mix test test/lockspire/protocol/dcr_audit_attribution_test.exs` | ❌ W0 | ⬜ pending |
| 26-XX-XX | (telemetry redaction)     | TBD | DCR-23 | T-26-TELEMETRY-LEAK | RAT/IAT/`client_secret` plaintext absent from `[:lockspire, :dcr, ...]` and `[:lockspire, :iat, ...]` events, audit rows, log lines | leak-test | `mix test test/lockspire/protocol/dcr_telemetry_redaction_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/lockspire/protocol/registration_test.exs` — parametric stubs for each RFC 7591 §2 validator rule (DCR-02)
- [ ] `test/lockspire/protocol/registration_access_token_test.exs` — RAT issuance + hash-at-rest stub (DCR-03)
- [ ] `test/lockspire/protocol/initial_access_token_test.exs` — atomic redemption stub including a concurrent-redemption case using `Task.async_stream` against the same IAT (DCR-04)
- [ ] `test/lockspire/protocol/registration_management_test.exs` — RFC 7592 GET/PUT/DELETE stubs (DCR-11)
- [ ] `test/lockspire/protocol/dcr_audit_attribution_test.exs` — regression stub: scan emitted audit rows for `actor_type` and fail on `"operator"` for any DCR write (DCR-22)
- [ ] `test/lockspire/protocol/dcr_telemetry_redaction_test.exs` — single-sweep `:telemetry.attach`-based test that captures every `[:lockspire, :dcr, ...]` and `[:lockspire, :iat, ...]` event, then asserts no string in the payload tree contains a known plaintext RAT/IAT/`client_secret` value (DCR-23)
- [ ] No new framework install needed — `Lockspire.DataCase` and `Lockspire.RepoCase` already exist

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| (none expected for this phase) | — | All success criteria are automatable through ExUnit + telemetry capture + DB tx assertions | — |

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (six stub files in plan 26-01 task 3)
- [x] No watch-mode flags
- [x] Feedback latency < 60s (`mix test test/lockspire/protocol/ --max-failures=1` ≈ 30s baseline)
- [x] `nyquist_compliant: true` set in frontmatter
- [x] Audit-attribution test path reconciled — both VALIDATION.md and plans cite `test/lockspire/protocol/dcr_audit_attribution_test.exs` (every Phase 26 test lives in `test/lockspire/protocol/`)

**Approval:** approved (post-revision 2026-04-26)
