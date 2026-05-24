---
phase: 74
slug: fapi-2-0-message-signing-strict-mode
status: planned
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-08
---

# Phase 74 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix LiveView tests, Phoenix.ConnTest, and Ecto sandbox |
| **Quick run command** | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/security_profile_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/security_profile_test.exs test/lockspire/storage/ecto/server_policy_record_test.exs test/lockspire/storage/ecto/client_record_test.exs test/lockspire/protocol/message_signing_profile_test.exs test/lockspire/admin/server_policy_test.exs test/lockspire/admin/clients_test.exs test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs test/lockspire/web/live/admin/policies_live/security_profile_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/integration/phase41_fapi_2_0_e2e_test.exs test/lockspire/release_readiness_contract_test.exs` |
| **Estimated runtime** | ~90 seconds |

## Sampling Rate

- After every task commit: run the task-local `<automated>` command from the active plan
- After every plan wave: run the full verification command for all plans in that wave
- Before `$gsd-verify-work`: run the full Phase 74 suite above

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 74-01-01 | 01 | 1 | ENF-01 | unit | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/storage/ecto/server_policy_record_test.exs test/lockspire/storage/ecto/client_record_test.exs` | ⬜ pending |
| 74-01-02 | 01 | 1 | ENF-01 | unit | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/security_profile_test.exs` | ⬜ pending |
| 74-02-01 | 02 | 2 | ENF-01 | unit | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/message_signing_profile_test.exs` | ⬜ pending |
| 74-02-02 | 02 | 2 | ENF-01 | integration | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/admin/server_policy_test.exs test/lockspire/admin/clients_test.exs test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs` | ⬜ pending |
| 74-03-01 | 03 | 3 | ENF-01 | unit | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/authorization_request_test.exs` | ⬜ pending |
| 74-03-02 | 03 | 3 | ENF-01 | unit | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/authorization_request_test.exs` | ⬜ pending |
| 74-04-01 | 04 | 3 | ENF-01 | unit | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs` | ⬜ pending |
| 74-04-02 | 04 | 3 | ENF-01 | unit | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/web/introspection_controller_test.exs` | ⬜ pending |
| 74-05-01 | 05 | 4 | ENF-01 | liveview | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/web/live/admin/policies_live/security_profile_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs` | ⬜ pending |
| 74-05-02 | 05 | 4 | ENF-01 | integration | `MIX_ENV=test mix test --warnings-as-errors test/integration/phase41_fapi_2_0_e2e_test.exs test/lockspire/release_readiness_contract_test.exs` | ⬜ pending |

## Wave 0 Requirements

- [x] Existing ExUnit, Phoenix, and LiveView infrastructure is sufficient
- [x] Every plan has at least one automated verification command
- [x] External-surface proof exists for authorization, introspection, admin UX, and support-truth closure

## Validation Sign-Off

- [x] Nyquist artifact present
- [x] All plans have automated verification
- [x] No watch-mode flags
- [x] Feedback latency stays below the current phase suite runtime

**Approval:** planned
