# Phase 106 Screenshot Inventory

**Captured:** 2026-06-03
**Source state:** `examples/adoption_demo/priv/repo/seeds.exs`
**Evidence directory:** `tmp/admin-ui-polish/`

Screenshots are milestone evidence only. Runtime code must not depend on these files.

## Coverage Matrix

| Journey | Route | Desktop | Mobile | Seed state exercised | Notes |
|---------|-------|---------|--------|----------------------|-------|
| Overview | `/lockspire/admin` | `tmp/admin-ui-polish/v128-overview-desktop.png` | `tmp/admin-ui-polish/v128-overview-mobile.png` | Mixed client, key, support, DCR, and operations state | Current v1.28 overview evidence. |
| Clients | `/lockspire/admin/clients` | `tmp/admin-ui-polish/v128-clients-desktop.png` | `tmp/admin-ui-polish/v128-clients-mobile.png` | Public, confidential, self-registered, and disabled clients | Client list has long names and DCR provenance. |
| Client workspace | `/lockspire/admin/clients/northstar-dcr-self-registered` | `tmp/admin-ui-polish/v128-client-workspace-desktop.png` | `tmp/admin-ui-polish/v128-client-workspace-mobile.png` | Self-registered DCR client with logout, RAT, strict posture, contacts, and long URIs | Canonical dense client workspace proof. |
| Security overview | `/lockspire/admin/policies` | `tmp/admin-ui-polish/v128-policies-desktop.png` | `tmp/admin-ui-polish/v128-policies-mobile.png` | Global PAR, DPoP, security profile, and DCR policy state | Policy overview journey. |
| DCR policy | `/lockspire/admin/policies/dcr` | `tmp/admin-ui-polish/v128-dcr-policy-desktop.png` | `tmp/admin-ui-polish/v128-dcr-policy-mobile.png` | DCR allowlist and registration policy state | Nested DCR policy route. |
| DCR onboarding | `/lockspire/admin/dcr` | `tmp/admin-ui-polish/dcr-desktop.png` | `tmp/admin-ui-polish/v128-dcr-mobile.png` | Self-registered client plus IAT handoff | Partner onboarding journey. |
| Initial Access Tokens | `/lockspire/admin/iats` | `tmp/admin-ui-polish/v128-iats-desktop.png` | `tmp/admin-ui-polish/v128-iats-mobile.png` | Active, revoked, and used IATs | DCR onboarding token handoff route. |
| Keys | `/lockspire/admin/keys` | `tmp/admin-ui-polish/v128-keys-desktop.png` | `tmp/admin-ui-polish/v128-keys-mobile.png` | Active, upcoming, retiring, and retired keys | Key lifecycle safety journey. |
| Tokens | `/lockspire/admin/tokens` | `tmp/admin-ui-polish/v128-tokens-desktop.png` | `tmp/admin-ui-polish/v128-tokens-mobile.png` | Active access, active refresh, reuse-detected refresh, revoked, and expired tokens | Support investigation route. |
| Consents | `/lockspire/admin/consents` | `tmp/admin-ui-polish/v128-consents-desktop.png` | `tmp/admin-ui-polish/v128-consents-mobile.png` | Remembered and revoked consent grants | Support investigation route. |
| Interactions | `/lockspire/admin/interactions` | `tmp/admin-ui-polish/v128-interactions-desktop.png` | `tmp/admin-ui-polish/v128-interactions-mobile.png` | Pending login, pending consent, and denied interactions | Operations queue route. |
| Device authorizations | `/lockspire/admin/device_authorizations` | `tmp/admin-ui-polish/v128-device-authorizations-desktop.png` | `tmp/admin-ui-polish/v128-device-authorizations-mobile.png` | Pending, approved, and expired device authorizations | Operations queue route. |
| Logout deliveries | `/lockspire/admin/logouts` | `tmp/admin-ui-polish/v128-logouts-desktop.png` | `tmp/admin-ui-polish/v128-logouts-mobile.png` | Back-channel succeeded, back-channel retryable, and front-channel rendered deliveries | Operations queue route. |

## Verification Notes

- Existing and newly captured screenshots cover the main cockpit, client list, canonical client workspace, security overview, DCR policy, DCR onboarding, IATs, key lifecycle, support queues, and operations queues.
- Desktop and mobile evidence exists for every route in the matrix.
- Screenshot paths intentionally remain under `tmp/admin-ui-polish/`; they are not referenced by runtime source.
