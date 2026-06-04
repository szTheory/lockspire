# Phase 110 Browser Evidence

**Status:** Pending Phase 110 browser capture
**Seed state:** `examples/adoption_demo/priv/repo/seeds.exs`
**Screenshot inventory:** `110-SCREENSHOTS.md`

Browser evidence is milestone proof only. It must use artificial demo data, preserve copy-once redaction, and avoid executing irreversible production-like actions.

## Overview-Start Click-Through

Start at `/lockspire/admin` or `/admin` overview, then navigate through these route groups:

| Group | Routes | Status | Browser note |
|-------|--------|--------|--------------|
| Orient | `/admin`, `/admin/overview` | Not captured - pending Phase 110 browser capture | Confirm overview journey cards and attention-worthy state. |
| Configure | `/admin/clients`, client workflows, policies, keys, DCR, IATs | Not captured - pending Phase 110 browser capture | Use read-only navigation or stop at confirmation/copy-once panels. |
| Support | `/admin/tokens`, `/admin/tokens/:id`, `/admin/consents`, `/admin/consents/:id` | Not captured - pending Phase 110 browser capture | Review support pivots and confirmation panels without confirming revoke actions. |
| Operate | `/admin/interactions`, `/admin/device_authorizations`, `/admin/logouts` | Not captured - pending Phase 110 browser capture | Review queue state, retryable/discarded pressure, and long-value wrapping. |

## 390px Mobile no-page-overflow

Check every route group at 390px width.

| Group | Status | Notes |
|-------|--------|-------|
| Orient | Not captured - pending Phase 110 mobile proof | Verify nav, journey cards, and metrics do not overflow. |
| Configure | Not captured - pending Phase 110 mobile proof | Verify long URIs, action groups, forms, key IDs, and copy-once panels wrap. |
| Support | Not captured - pending Phase 110 mobile proof | Verify token/consent rows, long IDs, filters, and confirmations do not overlap. |
| Operate | Not captured - pending Phase 110 mobile proof | Verify queue rows, timestamps, endpoints, and badges avoid page-level horizontal scrolling. |

## Confirmation Workflow Notes

- Read-only click-through may open risky confirmation panels.
- Do not confirm destructive or irreversible production-like actions during proof capture.
- Record consent revoke, token revoke/family revoke, IAT revoke, key lifecycle, logout discard/retry, client secret rotation, and RAT rotation as confirmation or copy-once proof states only.

## Copy-Once And Redaction Notes

- Copy-once proof may use artificial demo values immediately after IAT minting, client secret rotation, or RAT rotation.
- Do not persist plaintext IATs, RATs, client secrets, user codes, verifier material, access tokens, refresh tokens, or token hashes in this evidence log.
- Later screenshots and notes should show redacted or non-secret durable handles.

## Final Verification Commands

- `MIX_ENV=test mix compile --warnings-as-errors`
- `git diff --check`
- `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1`
- `mix test test/lockspire/web/live/admin --max-failures 1`
- `mix test`

## Evidence Status

Not captured - pending Phase 110 browser capture and final verification.
