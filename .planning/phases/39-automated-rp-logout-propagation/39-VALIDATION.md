---
phase: 39
slug: automated-rp-logout-propagation
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-29
---

# Phase 39 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.ConnTest + Ecto SQL Sandbox |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/lockspire/protocol/logout_propagation_test.exs -x` |
| **Full suite command** | `MIX_ENV=test mix test` |
| **Estimated runtime** | ~45 seconds for targeted Phase 39 checks |

## Sampling Rate

- **After every task commit:** run the narrowest targeted phase command for the touched seam.
- **After every plan wave:** run the phase-targeted command set below.
- **Before `/gsd-verify-work`:** Phase 39 targeted integration proof plus full suite must be green.
- **Max feedback latency:** < 45 seconds for task-level checks.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 39-01-01 | 01 | 0 | SLO-03 | — | Wave 0 worker/protocol/integration scaffolds compile and describe required behaviors | unit/integration | `MIX_ENV=test mix test test/lockspire/protocol/logout_propagation_test.exs test/lockspire/workers/backchannel_logout_delivery_worker_test.exs test/integration/phase39_logout_propagation_e2e_test.exs --exclude skip` | ❌ W0 | ⬜ pending |
| 39-01-02 | 01 | 0 | SLO-04 | — | Discovery/front-channel proof stubs exist and compile | unit | `MIX_ENV=test mix test test/lockspire/protocol/discovery_test.exs --exclude skip` | ✅ existing file | ⬜ pending |
| 39-02-metadata | 02 | 1 | SLO-03, SLO-04 | T-39-01 | Client logout metadata validates strict URI/session-required rules | unit | `MIX_ENV=test mix test test/lockspire/admin/clients_test.exs -x` | ✅ | ⬜ pending |
| 39-02-dcr | 02 | 1 | SLO-03 | T-39-03 | DCR rejects all four logout fields as unsupported in slice | unit | `MIX_ENV=test mix test test/lockspire/protocol/registration_test.exs -x` | ✅ | ⬜ pending |
| 39-03-store | 03 | 2 | SLO-03, SLO-04 | T-39-02 | Logout event/delivery rows persist durably without raw logout artifacts | unit | `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_logout_propagation_test.exs -x` | ❌ W0 | ⬜ pending |
| 39-03-snapshot | 03 | 2 | SLO-03 | T-39-02 | Target clients are snapshotted from durable token history before revocation | unit | `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_logout_propagation_test.exs -x` | ❌ W0 | ⬜ pending |
| 39-04-startup | 04 | 3 | SLO-03 | T-39-04 | Missing/invalid Oban config fails fast; startup wires Lockspire-owned queue correctly | unit | `MIX_ENV=test mix test test/lockspire/application_test.exs -x` | ❌ W0 | ⬜ pending |
| 39-04-worker | 04 | 3 | SLO-03 | T-39-05, T-39-06 | Worker posts logout_token, classifies retryable vs terminal outcomes, and redacts sensitive payloads | unit | `MIX_ENV=test mix test test/lockspire/workers/backchannel_logout_delivery_worker_test.exs -x` | ❌ W0 | ⬜ pending |
| 39-04-events | 04 | 3 | SLO-03 | T-39-05 | Audit/telemetry distinguish requested, enqueued, attempted, succeeded, failed/discarded | unit | `MIX_ENV=test mix test test/lockspire/protocol/logout_propagation_test.exs -x` | ❌ W0 | ⬜ pending |
| 39-05-complete | 05 | 4 | SLO-03 | T-39-04 | `/end_session/complete` persists snapshot state and enqueues within the transactional completion path | unit/controller | `MIX_ENV=test mix test test/lockspire/protocol/logout_propagation_test.exs test/lockspire/web/end_session_controller_test.exs -x` | ❌ W0 | ⬜ pending |
| 39-05-idempotent | 05 | 4 | SLO-03 | T-39-04 | Duplicate completion hits do not strand or duplicate deliveries | unit/controller | `MIX_ENV=test mix test test/lockspire/protocol/logout_propagation_test.exs test/lockspire/web/end_session_controller_test.exs -x` | ❌ W0 | ⬜ pending |
| 39-06-frontchannel | 06 | 5 | SLO-04 | T-39-07 | Front-channel page renders iframe rows, best-effort copy, and bounded continue fallback only | integration | `MIX_ENV=test mix test --include integration test/integration/phase39_logout_propagation_e2e_test.exs` | ❌ W0 | ⬜ pending |
| 39-06-discovery | 06 | 5 | SLO-03, SLO-04 | T-39-08 | Discovery publishes all four logout booleans together | unit | `MIX_ENV=test mix test test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs -x` | ✅ | ⬜ pending |
| 39-06-admin | 06 | 5 | SLO-03, SLO-04 | T-39-09 | Dedicated admin workflow persists and displays typed logout propagation fields | LiveView | `MIX_ENV=test mix test test/lockspire/web/live/admin/clients_live_test.exs -x` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

- [ ] `test/lockspire/protocol/logout_propagation_test.exs`
- [ ] `test/lockspire/workers/backchannel_logout_delivery_worker_test.exs`
- [ ] `test/lockspire/storage/ecto/repository_logout_propagation_test.exs`
- [ ] `test/lockspire/application_test.exs`
- [ ] `test/integration/phase39_logout_propagation_e2e_test.exs`
- [ ] Extend `test/lockspire/protocol/discovery_test.exs` with Phase 39 boolean stubs

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Front-channel page copy stays truthful | SLO-04 | Requires UX wording review | Render the page and confirm it says best effort, not verified remote logout |
| Docs match shipped surface | SLO-03, SLO-04 | Requires prose review across guides | Check `docs/install-and-onboard.md`, `docs/operator-admin.md`, and `docs/supported-surface.md` for identical support claims |
| Host Oban config instructions are clear | SLO-03 | Installation/operator guidance check | Follow the documented Oban setup path in a generated host app and confirm startup failure is understandable when config is missing |

## Validation Sign-Off

- [x] All planned seams have automated verification paths
- [x] Wave 0 covers all missing Phase 39 test files
- [x] Sampling continuity stays below 3 tasks without automation
- [x] No watch-mode flags
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
