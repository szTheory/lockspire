# Phase 110 Screenshot Inventory

**Captured:** Pending Phase 110 browser capture
**Source state:** `examples/adoption_demo/priv/repo/seeds.exs`
**Evidence directory:** `tmp/admin-ui-polish/`

Screenshots are milestone evidence only. Runtime code and operator docs must not depend on these files.

## Coverage Matrix

| Journey | Route | Desktop | Mobile | Demo state | Browser note |
|---------|-------|---------|--------|------------|--------------|
| Orient | `/admin` | `tmp/admin-ui-polish/v128-overview-desktop.png` | `tmp/admin-ui-polish/v128-overview-mobile.png` | Healthy, warning, incident, DCR, key, support, and operations summary state | Baseline overview proof; refresh if Phase 109 changes are not visible. |
| Orient | `/admin/overview` | `tmp/admin-ui-polish/v128-overview-desktop.png` | `tmp/admin-ui-polish/v128-overview-mobile.png` | Same overview cockpit state as `/admin` | Same LiveView as root overview route. |
| Configure | `/admin/clients` | `tmp/admin-ui-polish/v128-clients-desktop.png` | `tmp/admin-ui-polish/v128-clients-mobile.png` | Public, confidential, disabled, self-registered, and long-value clients | Client inventory baseline proof. |
| Configure | `/admin/clients/:client_id` | `tmp/admin-ui-polish/v128-client-workspace-desktop.png` | `tmp/admin-ui-polish/v128-client-workspace-mobile.png` | Self-registered client with strict posture, logout URIs, contacts, RAT context, and long values | Canonical dense client workspace proof. |
| Configure | `/admin/clients/:client_id/edit` | Not captured - pending Phase 110 browser capture for routine client edit workflow | Not captured - pending Phase 110 browser capture for routine client edit workflow at 390px | Routine client settings and disabled-client context | Capture without saving mutations. |
| Configure | `/admin/clients/:client_id/redirects` | Not captured - pending Phase 110 browser capture for redirect URI workflow | Not captured - pending Phase 110 browser capture for redirect URI workflow at 390px | Exact-match redirect URI long-value state | Capture without saving mutations. |
| Configure | `/admin/clients/:client_id/logout-uris` | Not captured - pending Phase 110 browser capture for post-logout redirect URI workflow | Not captured - pending Phase 110 browser capture for post-logout redirect URI workflow at 390px | Browser post-logout redirect URI state | Capture without saving mutations. |
| Configure | `/admin/clients/:client_id/edit?workflow=logout-propagation` | Not captured - pending Phase 110 browser capture for logout propagation URI workflow | Not captured - pending Phase 110 browser capture for logout propagation URI workflow at 390px | Back-channel/front-channel logout propagation URI state | Special query-driven workflow from Phase 107 route contract. |
| Configure | `/admin/clients/:client_id/par-policy` | Not captured - pending Phase 110 browser capture for client PAR policy workflow | Not captured - pending Phase 110 browser capture for client PAR policy workflow at 390px | Effective PAR posture and override state | Capture without saving mutations. |
| Configure | `/admin/clients/:client_id/security-profile` | Not captured - pending Phase 110 browser capture for client security profile workflow | Not captured - pending Phase 110 browser capture for client security profile workflow at 390px | Strict profile and mixed posture state | Capture without saving mutations. |
| Configure | `/admin/clients/:client_id/rotate-secret` | Not captured - pending Phase 110 browser capture for copy-once client secret rotation workflow | Not captured - pending Phase 110 browser capture for copy-once client secret rotation workflow at 390px | Copy-once client secret panel state | Capture confirmation/copy-once flow with artificial demo secret only. |
| Configure | `/admin/clients/:client_id/rotate-registration-access-token` | Not captured - pending Phase 110 browser capture for copy-once RAT rotation workflow | Not captured - pending Phase 110 browser capture for copy-once RAT rotation workflow at 390px | Self-registered client and RAT copy-once state | Capture confirmation/copy-once flow with artificial demo RAT only. |
| Configure | `/admin/policies` | `tmp/admin-ui-polish/v128-policies-desktop.png` | `tmp/admin-ui-polish/v128-policies-mobile.png` | PAR, DPoP, security profile, and DCR policy posture | Security overview baseline proof. |
| Configure | `/admin/policies/par` | Not captured - pending Phase 110 browser capture for global PAR policy route | Not captured - pending Phase 110 browser capture for global PAR policy route at 390px | Global PAR policy state | Capture without saving mutations. |
| Configure | `/admin/policies/security-profile` | Not captured - pending Phase 110 browser capture for global security profile route | Not captured - pending Phase 110 browser capture for global security profile route at 390px | Global security profile state | Capture without saving mutations. |
| Configure | `/admin/policies/dpop` | Not captured - pending Phase 110 browser capture for global DPoP policy route | Not captured - pending Phase 110 browser capture for global DPoP policy route at 390px | Global DPoP policy state | Capture without saving mutations. |
| Configure | `/admin/policies/dcr` | `tmp/admin-ui-polish/v128-dcr-policy-desktop.png` | `tmp/admin-ui-polish/v128-dcr-policy-mobile.png` | DCR policy allowlist and registration posture | DCR policy baseline proof. |
| Configure | `/admin/keys` | `tmp/admin-ui-polish/v128-keys-desktop.png` | `tmp/admin-ui-polish/v128-keys-mobile.png` | Active, upcoming, retiring, retired, and long key IDs | Key lifecycle inventory proof. |
| Configure | `/admin/keys/:id` | Not captured - pending Phase 110 browser capture for key detail route | Not captured - pending Phase 110 browser capture for key detail route at 390px | Key detail and lifecycle confirmation state | Capture confirmation without executing irreversible action. |
| Configure | `/admin/dcr` | `tmp/admin-ui-polish/dcr-desktop.png` | `tmp/admin-ui-polish/v128-dcr-mobile.png` | DCR onboarding, IAT handoff, self-registered clients, and RAT context | DCR onboarding baseline proof. |
| Configure | `/admin/iats` | `tmp/admin-ui-polish/v128-iats-desktop.png` | `tmp/admin-ui-polish/v128-iats-mobile.png` | Active, used, revoked, and expired IATs | IAT inventory proof. |
| Configure | `/admin/iats/new` | Not captured - pending Phase 110 browser capture for IAT minting route | Not captured - pending Phase 110 browser capture for IAT minting route at 390px | Copy-once IAT minting state | Capture artificial copy-once result only; do not persist plaintext in notes. |
| Support | `/admin/consents` | `tmp/admin-ui-polish/v128-consents-desktop.png` | `tmp/admin-ui-polish/v128-consents-mobile.png` | Remembered and revoked grants, long scopes, client/account pivots | Consent support inventory proof. |
| Support | `/admin/consents/:id` | Not captured - pending Phase 110 browser capture for consent detail route | Not captured - pending Phase 110 browser capture for consent detail route at 390px | Stored grant detail and revoke confirmation state | Capture confirmation without executing revoke. |
| Support | `/admin/tokens` | `tmp/admin-ui-polish/v128-tokens-desktop.png` | `tmp/admin-ui-polish/v128-tokens-mobile.png` | Active, revoked, expired, reuse-detected, and long token-family states | Token support inventory proof. |
| Support | `/admin/tokens/:id` | Not captured - pending Phase 110 browser capture for token detail route | Not captured - pending Phase 110 browser capture for token detail route at 390px | Token detail and family revocation confirmation state | Capture confirmation without executing revoke. |
| Operate | `/admin/interactions` | `tmp/admin-ui-polish/v128-interactions-desktop.png` | `tmp/admin-ui-polish/v128-interactions-mobile.png` | Pending login, pending consent, denied, expired, and long identifiers | Interaction queue proof. |
| Operate | `/admin/device_authorizations` | `tmp/admin-ui-polish/v128-device-authorizations-desktop.png` | `tmp/admin-ui-polish/v128-device-authorizations-mobile.png` | Pending, approved, denied, consumed, expired, and redacted user-code-adjacent state | Device authorization queue proof. |
| Operate | `/admin/logouts` | `tmp/admin-ui-polish/v128-logouts-desktop.png` | `tmp/admin-ui-polish/v128-logouts-mobile.png` | Pending, retryable, rendered, succeeded, discarded, and long endpoint URLs | Logout delivery queue proof. |

## Verification Notes

- Existing v1.28 screenshot files are baseline evidence and should be refreshed when they do not show final Phase 109 polish.
- `Not captured - ...` cells are explicit gaps for Plan 110-04 to close or retain with a concrete blocker.
- Runtime source under `lib/` must not reference `tmp/admin-ui-polish/`.
