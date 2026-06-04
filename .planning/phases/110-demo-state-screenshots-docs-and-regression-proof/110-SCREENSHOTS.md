# Phase 110 Screenshot Inventory

**Captured:** 2026-06-04 with `agent-browser` against the seeded adoption demo at `http://127.0.0.1:4100`
**Source state:** `examples/adoption_demo/priv/repo/seeds.exs`
**Evidence directory:** `tmp/admin-ui-polish/`

Screenshots are milestone evidence only. Runtime code and operator docs must not depend on these files.

## Coverage Matrix

| Journey | Route | Desktop | Mobile | Demo state | Browser note |
|---------|-------|---------|--------|------------|--------------|
| Orient | `/admin` | `tmp/admin-ui-polish/phase110-overview-root-desktop.png` | `tmp/admin-ui-polish/phase110-overview-root-mobile.png` | Healthy, warning, incident, DCR, key, support, and operations summary state | Captured via `/lockspire/admin`; 390px overflow=false. |
| Orient | `/admin/overview` | `tmp/admin-ui-polish/phase110-overview-desktop.png` | `tmp/admin-ui-polish/phase110-overview-mobile.png` | Same overview cockpit state as `/admin` | Captured via `/lockspire/admin/overview`; 390px overflow=false. |
| Configure | `/admin/clients` | `tmp/admin-ui-polish/phase110-clients-desktop.png` | `tmp/admin-ui-polish/phase110-clients-mobile.png` | Public, confidential, disabled, self-registered, and long-value clients | Captured via `/lockspire/admin/clients`; 390px overflow=false. |
| Configure | `/admin/clients/:client_id` | `tmp/admin-ui-polish/phase110-client-workspace-desktop.png` | `tmp/admin-ui-polish/phase110-client-workspace-mobile.png` | Self-registered client with strict posture, logout URIs, contacts, RAT context, and long values | Captured with `northstar-dcr-self-registered`; 390px no-page-overflow returned false. |
| Configure | `/admin/clients/:client_id/edit` | `tmp/admin-ui-polish/phase110-client-edit-desktop.png` | `tmp/admin-ui-polish/phase110-client-edit-mobile.png` | Routine client settings and disabled-client context | Captured without saving mutations; 390px no-page-overflow returned false. |
| Configure | `/admin/clients/:client_id/redirects` | `tmp/admin-ui-polish/phase110-client-redirects-desktop.png` | `tmp/admin-ui-polish/phase110-client-redirects-mobile.png` | Exact-match redirect URI long-value state | Captured without saving mutations; 390px no-page-overflow returned false. |
| Configure | `/admin/clients/:client_id/logout-uris` | `tmp/admin-ui-polish/phase110-client-logout-uris-desktop.png` | `tmp/admin-ui-polish/phase110-client-logout-uris-mobile.png` | Browser post-logout redirect URI state | Captured without saving mutations; 390px no-page-overflow returned false. |
| Configure | `/admin/clients/:client_id/edit?workflow=logout-propagation` | `tmp/admin-ui-polish/phase110-client-logout-propagation-desktop.png` | `tmp/admin-ui-polish/phase110-client-logout-propagation-mobile.png` | Back-channel/front-channel logout propagation URI state | Captured without saving mutations; 390px no-page-overflow returned false. |
| Configure | `/admin/clients/:client_id/par-policy` | `tmp/admin-ui-polish/phase110-client-par-policy-desktop.png` | `tmp/admin-ui-polish/phase110-client-par-policy-mobile.png` | Effective PAR posture and override state | Captured without saving mutations; 390px no-page-overflow returned false. |
| Configure | `/admin/clients/:client_id/security-profile` | `tmp/admin-ui-polish/phase110-client-security-profile-desktop.png` | `tmp/admin-ui-polish/phase110-client-security-profile-mobile.png` | Strict profile and mixed posture state | Captured without saving mutations; 390px no-page-overflow returned false. |
| Configure | `/admin/clients/:client_id/rotate-secret` | `tmp/admin-ui-polish/phase110-client-rotate-secret-desktop.png` | `tmp/admin-ui-polish/phase110-client-rotate-secret-mobile.png` | Copy-once client secret panel state | Captured pre-confirmation only; 390px no-page-overflow returned false. |
| Configure | `/admin/clients/:client_id/rotate-registration-access-token` | `tmp/admin-ui-polish/phase110-client-rotate-rat-desktop.png` | `tmp/admin-ui-polish/phase110-client-rotate-rat-mobile.png` | Self-registered client and RAT copy-once state | Captured pre-confirmation only; 390px no-page-overflow returned false. |
| Configure | `/admin/policies` | `tmp/admin-ui-polish/phase110-policies-desktop.png` | `tmp/admin-ui-polish/phase110-policies-mobile.png` | PAR, DPoP, security profile, and DCR policy posture | Captured via `/lockspire/admin/policies`; 390px overflow=false. |
| Configure | `/admin/policies/par` | `tmp/admin-ui-polish/phase110-policies-par-desktop.png` | `tmp/admin-ui-polish/phase110-policies-par-mobile.png` | Global PAR policy state | Captured without saving mutations; 390px overflow=false. |
| Configure | `/admin/policies/security-profile` | `tmp/admin-ui-polish/phase110-policies-security-profile-desktop.png` | `tmp/admin-ui-polish/phase110-policies-security-profile-mobile.png` | Global security profile state | Captured without saving mutations; 390px overflow=false. |
| Configure | `/admin/policies/dpop` | `tmp/admin-ui-polish/phase110-policies-dpop-desktop.png` | `tmp/admin-ui-polish/phase110-policies-dpop-mobile.png` | Global DPoP policy state | Captured without saving mutations; 390px overflow=false. |
| Configure | `/admin/policies/dcr` | `tmp/admin-ui-polish/phase110-policies-dcr-desktop.png` | `tmp/admin-ui-polish/phase110-policies-dcr-mobile.png` | DCR policy allowlist and registration posture | Captured via `/lockspire/admin/policies/dcr`; 390px overflow=false. |
| Configure | `/admin/keys` | `tmp/admin-ui-polish/phase110-keys-desktop.png` | `tmp/admin-ui-polish/phase110-keys-mobile.png` | Active, upcoming, retiring, retired, and long key IDs | Captured via `/lockspire/admin/keys`; 390px overflow=false. |
| Configure | `/admin/keys/:id` | `tmp/admin-ui-polish/phase110-key-detail-desktop.png` | `tmp/admin-ui-polish/phase110-key-detail-mobile.png` | Key detail and lifecycle confirmation state | Captured key id 1 without executing irreversible action; 390px overflow=false. |
| Configure | `/admin/dcr` | `tmp/admin-ui-polish/phase110-dcr-desktop.png` | `tmp/admin-ui-polish/phase110-dcr-mobile.png` | DCR onboarding, IAT handoff, self-registered clients, and RAT context | Captured via `/lockspire/admin/dcr`; 390px overflow=false. |
| Configure | `/admin/iats` | `tmp/admin-ui-polish/phase110-iats-desktop.png` | `tmp/admin-ui-polish/phase110-iats-mobile.png` | Active, used, revoked, and expired IATs | Captured via `/lockspire/admin/iats`; 390px overflow=false. |
| Configure | `/admin/iats/new` | `tmp/admin-ui-polish/phase110-iat-new-desktop.png` | `tmp/admin-ui-polish/phase110-iat-new-mobile.png` | Copy-once IAT minting state | Captured form state only; no plaintext IAT persisted; 390px overflow=false. |
| Support | `/admin/consents` | `tmp/admin-ui-polish/phase110-consents-desktop.png` | `tmp/admin-ui-polish/phase110-consents-mobile.png` | Remembered and revoked grants, long scopes, client/account pivots | Captured via `/lockspire/admin/consents`; 390px overflow=false. |
| Support | `/admin/consents/:id` | `tmp/admin-ui-polish/phase110-consent-detail-desktop.png` | `tmp/admin-ui-polish/phase110-consent-detail-mobile.png` | Stored grant detail and revoke confirmation state | Captured consent id 1 without executing revoke; 390px overflow=false. |
| Support | `/admin/tokens` | `tmp/admin-ui-polish/phase110-tokens-desktop.png` | `tmp/admin-ui-polish/phase110-tokens-mobile.png` | Active, revoked, expired, reuse-detected, and long token-family states | Captured via `/lockspire/admin/tokens`; 390px overflow=false. |
| Support | `/admin/tokens/:id` | `tmp/admin-ui-polish/phase110-token-detail-desktop.png` | `tmp/admin-ui-polish/phase110-token-detail-mobile.png` | Token detail and family revocation confirmation state | Captured token id 2 without executing revoke; 390px overflow=false. |
| Operate | `/admin/interactions` | `tmp/admin-ui-polish/phase110-interactions-desktop.png` | `tmp/admin-ui-polish/phase110-interactions-mobile.png` | Pending login, pending consent, denied, expired, and long identifiers | Captured via `/lockspire/admin/interactions`; 390px overflow=false. |
| Operate | `/admin/device_authorizations` | `tmp/admin-ui-polish/phase110-device-authorizations-desktop.png` | `tmp/admin-ui-polish/phase110-device-authorizations-mobile.png` | Pending, approved, denied, consumed, expired, and redacted user-code-adjacent state | Captured via `/lockspire/admin/device_authorizations`; 390px overflow=false. |
| Operate | `/admin/logouts` | `tmp/admin-ui-polish/phase110-logouts-desktop.png` | `tmp/admin-ui-polish/phase110-logouts-mobile.png` | Pending, retryable, rendered, succeeded, discarded, and long endpoint URLs | Captured via `/lockspire/admin/logouts`; 390px overflow=false. |

## Verification Notes

- Fresh Phase 110 screenshots exist locally under `tmp/admin-ui-polish/`.
- Client workspace and client workflow mobile captures were rerun at 390px; `document.documentElement.scrollWidth > document.documentElement.clientWidth` returned `false` for every listed route.
- Runtime source under `lib/` must not reference `tmp/admin-ui-polish/`.
