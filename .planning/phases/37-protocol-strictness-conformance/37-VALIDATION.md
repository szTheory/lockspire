---
phase: 37
slug: protocol-strictness-conformance
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-28
---

# Phase 37 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with repo-level integration tagging |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test.fast` |
| **Full suite command** | `mix ci` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test.fast`
- **After every plan wave:** Run `mix test.integration && mix test.phase3`
- **Before `$gsd-verify-work`:** `mix ci` plus the Phase 37 OIDF harness lane must be green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 37-01-01 | 01 | 1 | CONF-01 | T-37-02 / T-37-03 | ID token `iat`, `exp`, and optional `auth_time` are emitted as integers and invalid `auth_time` is rejected | unit | `mix test test/lockspire/protocol/id_token_test.exs` | ❌ Wave 0 | ⬜ pending |
| 37-01-02 | 01 | 1 | CONF-01 | T-37-01 | Host claim material cannot override protocol-owned `auth_time` | unit | `mix test test/lockspire/host/claims_test.exs test/lockspire/protocol/id_token_test.exs` | ❌ Wave 0 | ⬜ pending |
| 37-01-03 | 01 | 1 | CONF-01 | T-37-03 | Token-facing DPoP / token endpoint paths reject non-integer `iat` without coercion | unit + controller | `mix test test/lockspire/protocol/dpop_test.exs test/lockspire/protocol/token_endpoint_dpop_test.exs test/lockspire/web/token_controller_test.exs` | ✅ | ⬜ pending |
| 37-02-01 | 02 | 1 | CONF-02, CONF-03 | T-37-04 / T-37-05 | Authorization request parsing preserves exact redirect matching and strict `prompt=none`, `max_age`, `nonce`, and claims validation | unit | `mix test test/lockspire/protocol/authorization_request_test.exs` | ✅ | ⬜ pending |
| 37-02-02 | 02 | 1 | CONF-02, CONF-03 | T-37-04 / T-37-06 | Controller surfaces keep invalid authorize requests on the correct redirect-safe vs browser-safe paths | controller | `mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/web/authorize_controller_test.exs` | ✅ | ⬜ pending |
| 37-03-01 | 03 | 2 | CONF-03 | T-37-07 / T-37-08 | Durable interaction state persists `auth_time`, `max_age`, and `auth_time_requested` exactly once and round-trips through Ecto storage | unit + storage | `mix test test/lockspire/protocol/authorization_flow_test.exs test/lockspire/storage/ecto/interaction_record_test.exs` | ❌ Wave 0 | ⬜ pending |
| 37-03-02 | 03 | 2 | CONF-01, CONF-03 | T-37-09 / T-37-10 | Silent authorization uses durable freshness truth and token exchange emits required `auth_time` while preserving `nonce` | unit + integration | `mix test test/lockspire/protocol/authorization_flow_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/web/authorize_controller_test.exs` | ✅ | ⬜ pending |
| 37-04-01 | 04 | 3 | CONF-04 | T-37-13 | Repo-native generated-host strictness proof exists and remains truthful to supported-surface docs | integration | `mix test --include integration test/integration/phase37_protocol_strictness_e2e_test.exs` | ❌ Wave 0 | ⬜ pending |
| 37-04-02 | 04 | 3 | CONF-04 | T-37-11 / T-37-12 / T-37-14 | The repo-native conformance lane is wired, exposes the Phase 37 E2E proof before the OIDF suite, and is locked by a release-readiness contract | integration / preflight | `bash -n scripts/conformance/run_phase37_suite.sh && python3 -m json.tool scripts/conformance/phase37-plan.json >/dev/null && MIX_ENV=test mix run -e 'aliases = Mix.Project.config()[:aliases]; unless Keyword.has_key?(aliases, :"conformance.phase37"), do: raise("missing conformance.phase37 alias")' && MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs` | ❌ Wave 0 | ⬜ pending |
| 37-04-03 | 04 | 3 | CONF-04 | T-37-11 / T-37-13 | The actual repo-native OIDF lane runs successfully and saves proof artifacts for maintainer inspection | integration / external | `MIX_ENV=test mix conformance.phase37` | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky / missing*

---

## Wave 0 Requirements

- [ ] `test/lockspire/protocol/id_token_test.exs` and `test/lockspire/host/claims_test.exs` created by Tasks `37-01-01` and `37-01-02`
- [ ] Freshness-focused migration and auth-time fixtures created by Task `37-03-01`
- [ ] `test/integration/phase37_protocol_strictness_e2e_test.exs` created by Task `37-04-01`
- [ ] `scripts/conformance/run_phase37_suite.sh`, `scripts/conformance/phase37-plan.json`, `.artifacts/conformance/phase37`, and `.github/workflows/oidf-conformance.yml` created by Task `37-04-02`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Hosted or staging OIDF suite run against a publicly reachable Lockspire fixture | CONF-04 | This is an optional maintainer lane, not an every-PR requirement | Stand up the generated host in a reachable environment, run the hosted suite profile, and archive the resulting report alongside the local lane artifacts |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing verification references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s for quick checks
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-28
