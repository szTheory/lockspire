---
phase: 125-browser-proof-docs-adversarial-ratchet
plan: "04"
status: complete
subsystem: admin-ui-proof-tests
tags:
  - browser-proof
  - admin-ui
  - configure
  - oauth-oidc
  - redaction
dependency_graph:
  requires:
    - 125-01
    - 125-02
    - 125-03
    - 124-admin-ui-visual-proof
  provides:
    - PROOF-01
    - PROOF-02
  affects:
    - test/lockspire/web/live/admin/clients_live_test.exs
    - test/lockspire/web/live/admin/clients_live/show_test.exs
    - test/lockspire/web/live/admin/iat_live_test.exs
    - test/lockspire/web/live/admin/keys_live_test.exs
    - test/lockspire/web/live/admin/policies_live/dcr_test.exs
tech_stack:
  added: []
  patterns:
    - Phoenix LiveView focused route proof
    - HtmlAssertions semantic HTML/redaction checks
    - Direct LiveView rendered fragments for durable redaction proof
key_files:
  created:
    - .planning/phases/125-browser-proof-docs-adversarial-ratchet/125-04-SUMMARY.md
  modified:
    - test/lockspire/web/live/admin/clients_live_test.exs
    - test/lockspire/web/live/admin/clients_live/show_test.exs
    - test/lockspire/web/live/admin/iat_live_test.exs
    - test/lockspire/web/live/admin/keys_live_test.exs
    - test/lockspire/web/live/admin/policies_live/dcr_test.exs
decisions:
  - Kept Plan 04 proof-only; no runtime, schema, route, docs, or dependency changes were made.
  - Used direct LiveView render fragments for durable token-like redaction checks where Phoenix LiveView wrapper transport would add unrelated session/static tokens.
  - Proved unsupported controls by explicit negative assertions instead of broad product expansion.
metrics:
  started_at: 2026-06-30T16:17:46Z
  completed_at: 2026-06-30T16:28:08Z
  duration: 10m22s
  tasks_completed: 2
  files_changed: 5
---

# Phase 125 Plan 04: Browser-Proof Docs Adversarial Ratchet Summary

Plan 04 ratcheted Configure proof tests for client, logout, DCR/IAT, keys, and global DCR policy admin surfaces without changing runtime code.

## Tasks Completed

| Task | Name | Commit | Files |
| --- | --- | --- | --- |
| 125-04-01 | Ratchet client and logout-propagation Configure proof | 343fd03 | clients index/detail tests |
| 125-04-02 | Ratchet DCR/IAT, key, and DCR policy proof | 3286156 | IAT, keys, and DCR policy tests |

## What Changed

- Added client inventory proof for empty, disabled, long-value, count, copy-once secret, and durable redaction states.
- Added client detail proof that rotated secrets and RAT/hash/verifier material remain copy-once or absent from durable surfaces.
- Added logout propagation proof for long backchannel/frontchannel URLs and confirmation-backed persistence.
- Added IAT inventory proof for active, expired, used, revoked, long creator, revoke confirmation, plaintext secret, and token hash redaction states.
- Added key lifecycle proof for index posture, confirmation-backed publish/activate/retire states, retired public-only detail, and absence of private key export/fetch/force-publish controls.
- Added global DCR policy proof for long allowlists, one grouped future-only form, private_key_jwt/client_secret_jwt posture copy, and absence of unsupported credential/client mutation controls.

## Verification

| Command | Result |
| --- | --- |
| `MIX_ENV=test mix test test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs --max-failures 1` | Passed, 32 tests, 0 failures |
| `MIX_ENV=test mix test test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs --max-failures 1` | Passed, 16 tests, 0 failures |
| `MIX_ENV=test mix test test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs --max-failures 1` | Passed, 48 tests, 0 failures |
| `mix format --check-formatted test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs` | Passed |

Verification runs emitted the existing non-fatal KeyCache startup log before the test repo starts, then completed successfully.

## Deviations from Plan

None - plan executed as proof-only test ratchet work.

## Auto-Fixed Issues

None in runtime code. During test construction, overly broad assertions were corrected to match existing security boundaries: copy-once extraction was anchored to rendered secret panels, durable token-like checks used direct LiveView fragments, and raw key IDs were asserted absent where the admin UI intentionally renders redacted handles.

## Known Stubs

None found in files created or modified by this plan.

## Threat Flags

None. This plan modified tests only and introduced no new network endpoint, auth path, file access path, schema boundary, or runtime trust boundary.

## Auth Gates

None.

## Self-Check: PASSED

- Found `test/lockspire/web/live/admin/clients_live_test.exs`
- Found `test/lockspire/web/live/admin/clients_live/show_test.exs`
- Found `test/lockspire/web/live/admin/iat_live_test.exs`
- Found `test/lockspire/web/live/admin/keys_live_test.exs`
- Found `test/lockspire/web/live/admin/policies_live/dcr_test.exs`
- Found commit `343fd03`
- Found commit `3286156`
