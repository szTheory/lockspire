# Phase 110 Browser Evidence

**Status:** Gaps
**Captured:** 2026-06-04 with `agent-browser` against `http://127.0.0.1:4100`
**Seed state:** `examples/adoption_demo/priv/repo/seeds.exs`
**Screenshot inventory:** `110-SCREENSHOTS.md`

Browser evidence is milestone proof only. It uses artificial demo data, preserves copy-once redaction, and avoids executing irreversible production-like actions.

## Overview-Start Click-Through

Started from `/lockspire/admin` after signing in as the seeded `ops` operator, then directly opened each approved admin route group with the same authenticated browser session.

| Group | Routes | Status | Browser note |
|-------|--------|--------|--------------|
| Orient | `/admin`, `/admin/overview` | Captured | Overview, journey cards, attention-worthy state, and navigation were reachable from the mounted admin overview. |
| Configure | `/admin/clients`, client workflows, policies, keys, DCR, IATs | Gaps | All Configure routes were reachable and captured. Client workspace/workflow routes report 390px page-level overflow. Policy, key, DCR, and IAT routes report no 390px page-level overflow. |
| Support | `/admin/tokens`, `/admin/tokens/:id`, `/admin/consents`, `/admin/consents/:id` | Captured | Support indexes and detail routes were reachable and captured without confirming revoke actions. |
| Operate | `/admin/interactions`, `/admin/device_authorizations`, `/admin/logouts` | Captured | Operations queues were reachable and captured with pending/terminal/long-value demo state visible. |

## 390px Mobile No-Page-Overflow

Checked every route at 390px width with:

```js
document.documentElement.scrollWidth > document.documentElement.clientWidth
```

| Group | Status | Notes |
|-------|--------|-------|
| Orient | Passed | `/admin` and `/admin/overview` returned `false`. |
| Configure | Gaps | `/admin/clients/:client_id` and the client edit, redirects, logout URI, logout propagation, PAR policy, security profile, rotate secret, and rotate RAT workflow routes returned `true`. `/admin/clients`, policies, policy subroutes, keys, key detail, DCR, IATs, and IAT new returned `false`. |
| Support | Passed | Consent index/detail and token index/detail returned `false`. |
| Operate | Passed | Interactions, device authorizations, and logouts returned `false`. |

## Confirmation Workflow Notes

- read-only click-through opened risky routes directly and stopped before any irreversible production-like action.
- Client secret rotation and RAT rotation were captured at pre-confirmation/copy-once workflow entry state only.
- Consent revoke, token revoke/family revoke, IAT minting, key lifecycle, and logout operations were not confirmed during proof capture.

## Copy-Once And Redaction Notes

- Copy-once proof used artificial demo state only.
- Do not persist plaintext IATs, RATs, client secrets, user codes, verifier material, access tokens, refresh tokens, or token hashes in this evidence log.
- Screenshot notes refer to durable handles such as route, client id, consent id, token id, and key id; they do not record secret plaintext.

## Final Verification Commands

- `MIX_ENV=test mix compile --warnings-as-errors`
- `git diff --check`
- `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1`
- `mix test test/lockspire/web/live/admin --max-failures 1`
- `mix test`

## Evidence Status

Gaps - fresh screenshot inventory and browser click-through evidence were captured, but 390px no-page-overflow proof failed for the client workspace and client workflow routes listed above.
