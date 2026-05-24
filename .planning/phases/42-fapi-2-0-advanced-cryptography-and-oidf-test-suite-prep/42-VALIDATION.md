---
phase: 42
slug: fapi-2-0-advanced-cryptography-and-oidf-test-suite-prep
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-01
---

# Phase 42 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test --stale` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test --stale`
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 45 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 42-01-01 | 01 | 1 | FAPI-04 | T-42-01 | Canonical signing algorithm policy returns only `ES256` / `PS256` for FAPI-effective paths and is reused by key-compliance checks | unit | `mix test test/lockspire/protocol/security_profile_test.exs test/lockspire/protocol/security_policy_test.exs` | ✅ | ⬜ pending |
| 42-01-02 | 01 | 1 | FAPI-04 | T-42-02 | FAPI-effective key generation, activation, and active/publishable selection fail fast on non-compliant algorithms or weak key posture | unit | `mix test test/lockspire/admin/keys_test.exs test/lockspire/protocol/security_policy_test.exs` | ✅ | ⬜ pending |
| 42-02-01 | 02 | 2 | FAPI-04 | T-42-04 | FAPI-effective JAR verification consumes the canonical allow-list and rejects `RS256` / `EdDSA` request objects | unit | `mix test test/lockspire/protocol/jar_test.exs` | ✅ | ⬜ pending |
| 42-02-02 | 02 | 2 | FAPI-04 | T-42-05 | FAPI-effective ID token signing enforces the canonical signer policy and rejects non-compliant key algorithms before JOSE signing | unit | `mix test test/lockspire/protocol/id_token_test.exs` | ✅ | ⬜ pending |
| 42-03-01 | 03 | 2 | FAPI-04 | T-42-07 | Global FAPI enablement fails fast when there is no compliant active/publishable signing posture and explains the next fix | unit | `mix test test/lockspire/admin/server_policy_test.exs test/lockspire/storage/repository_test.exs` | ✅ | ⬜ pending |
| 42-03-02 | 03 | 2 | FAPI-04 | T-42-08 | Admin client updates reject incompatible FAPI metadata or missing signing readiness while preserving mixed-mode `:none` storage | unit | `mix test test/lockspire/admin/clients_test.exs test/lockspire/storage/ecto/client_record_test.exs test/lockspire/storage/repository_test.exs` | ✅ | ⬜ pending |
| 42-07-01 | 07 | 2 | FAPI-04 | T-42-19 | Logout token signing and end-session hint verification remove hardcoded `RS256` assumptions and use the canonical FAPI allow-list | unit | `mix test test/lockspire/protocol/logout_token_test.exs test/lockspire/protocol/end_session_test.exs` | ✅ | ⬜ pending |
| 42-07-02 | 07 | 2 | FAPI-04 | T-42-21 | DPoP verification and validator truth reject `RS256` / `EdDSA` under FAPI-effective behavior while preserving non-FAPI legacy behavior | unit | `mix test test/lockspire/protocol/dpop_test.exs` | ✅ | ⬜ pending |
| 42-05-01 | 05 | 3 | FAPI-04 | T-42-13 | Discovery and JWKS publication surfaces advertise only the algorithms and keys the runtime actually supports under the resolved profile | unit | `mix test test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs test/lockspire/web/jwks_controller_test.exs` | ✅ | ⬜ pending |
| 42-05-02 | 05 | 3 | FAPI-04 | T-42-15 | DPoP challenge publication advertises only the validator-supported algorithms for the effective profile | unit | `mix test test/lockspire/protocol/dpop_test.exs` | ✅ | ⬜ pending |
| 42-06-01 | 06 | 3 | FAPI-04 | T-42-16 | DCR and registration-management protocol paths reuse the same FAPI readiness/remediation contract as the admin client path | unit | `mix test test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs` | ✅ | ⬜ pending |
| 42-06-02 | 06 | 3 | FAPI-04 | T-42-17 | Registration HTTP responses surface the same remediation-friendly FAPI errors as the protocol/admin path | unit | `mix test test/lockspire/web/controllers/registration_controller_test.exs` | ✅ | ⬜ pending |
| 42-04-01 | 04 | 4 | FAPI-04 | T-42-10 | The integration lane proves algorithm lockdown and release-contract tests pin preparatory-only OIDF wording and unsupported-surface truth | integration / contract | `mix test test/integration/phase41_fapi_2_0_e2e_test.exs test/lockspire/release_readiness_contract_test.exs` | ✅ | ⬜ pending |
| 42-04-02 | 04 | 4 | FAPI-04 | T-42-11 | The repo-native OIDF prep lane exposes one deterministic docs/script/workflow/mix contract with an executable smoke path | integration / contract | `mix test test/lockspire/release_readiness_contract_test.exs && LOCKSPIRE_BASE_URL=https://example.test LOCKSPIRE_CLIENT_ID=dry-run mix lockspire.oidf_conformance --validate-env` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] No Wave 0 bootstrap plan is required; every Phase 42 task now declares a direct `<automated>` verification command.
- [x] Existing ExUnit infrastructure already covers the revised seven-plan set without any `MISSING` verification placeholders.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| OIDF conformance container run against a live mounted Lockspire instance | FAPI-04 preparatory harness truth | Requires a running server, client credentials, and external container execution; Phase 42 only needs the workflow/documentation lane pinned, not a final certification claim | 1. Boot a host app or sample instance with `security_profile = :fapi_2_0_security` and compliant signing key posture. 2. Run the documented `mix`/script entrypoint from `docs/maintainer-conformance.md`. 3. Confirm expected artifacts are produced and attached/stored as documented. 4. Record failures for Phase 43 behavior closure rather than changing Phase 42 support claims. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 45s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ready for execution
