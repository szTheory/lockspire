# Phase 107 Route Journey Contract And IA Audit

Phase 107 is audit-only. It adds no admin routes, protocol behavior, operator authentication, tenant policy, layouts, branding, or product-specific authorization. Lockspire owns protocol and operator state after the host-mounted admin route is reached; the host app owns staff auth, MFA, role checks, tenant policy, layouts, branding, and product policy before the admin router.

This contract uses `lib/lockspire/web/admin_router.ex` as route truth and publishes mounted `/admin...` paths because the operator-visible surface is mounted under the embedded admin router. It also includes `/admin/clients/:client_id/edit?workflow=logout-propagation`, which is a query-driven workflow in `ClientsLive.Show`, not a separate Phoenix route.

No evidence note copies client secrets, raw token values, registration access token plaintext, or other copy-once material.

## Vocabulary Lock

- `DCR onboarding` means partner intake, initial access tokens, self-registered clients, and registration access token support.
- `DCR policy` means issuer registration posture and allowed registration methods.
- `post-logout redirect URIs` means browser destinations after logout completes.
- `logout propagation URIs` means RP cleanup endpoints used for back-channel and front-channel logout propagation.

## Route Journey Contract

| Route | Primary journey | Persona | JTBD | Entry point | Primary decision | Primary action | Empty state | Risk state | Follow-up route | Evidence |
|-------|-----------------|---------|------|-------------|------------------|----------------|-------------|------------|-----------------|----------|
| `/admin` | Orient | Provider operator | Understand attention-worthy provider state and choose the next workflow. | Host admin mount or overview redirect | Which provider area needs attention first? | Record overview routing | No attention items recorded; use journey cards to enter clients, security, support, or operations. | Warning and danger counts only | `/admin/clients` | `AdminRouter`, `OverviewLive.Index`, `tmp/admin-ui-polish/v128-overview-desktop.png`, `tmp/admin-ui-polish/v128-overview-mobile.png` |
| `/admin/overview` | Orient | Provider operator | Understand attention-worthy provider state and choose the next workflow. | Orient navigation | Which provider area needs attention first? | Record overview routing | No attention items recorded; use journey cards to enter clients, security, support, or operations. | Warning and danger counts only | `/admin/clients` | `AdminRouter`, `OverviewLive.Index`, `tmp/admin-ui-polish/v128-overview-desktop.png`, `tmp/admin-ui-polish/v128-overview-mobile.png` |
| `/admin/clients` | Configure | Provider operator | Find or create a client and inspect posture at inventory level. | Configure > Clients | Which client needs setup, review, or support? | Open client workspace | No clients yet; create a client or return after DCR onboarding. | Disabled client or policy exception | `/admin/clients/:client_id` | `AdminRouter`, `AdminLayoutLive`, `107-UI-SPEC.md` |
| `/admin/clients/:client_id` | Configure | Security/platform owner | Inspect one client's identity, credentials, endpoints, policy, DCR/RAT, and lifecycle state. | Client inventory, overview support pivot, or direct client link | Is this client healthy, risky, or ready for a specific mutation? | Review client posture | Client not found; return to client inventory. | Disabled, mixed-mode override, remote JWKS incident, credential action | `/admin/clients/:client_id/edit` | `ClientsLive.Show`, `tmp/admin-ui-polish/v128-client-workspace-desktop.png`, `tmp/admin-ui-polish/v128-client-workspace-mobile.png` |
| `/admin/clients/:client_id/edit` | Configure | Provider operator | Edit client identity and basic configuration without hiding risky endpoint or credential state. | Client workspace action group | Which basic client fields should change? | Save client settings | Client not found; return to client inventory. | Validation error or disabled client | `/admin/clients/:client_id` | `AdminRouter`, `ClientsLive.Show`, `FormComponent` |
| `/admin/clients/:client_id/redirects` | Configure | Security/platform owner | Maintain exact-match redirect URIs. | Client workspace endpoint action | Are browser callback destinations exact and current? | Save redirect URIs | No redirect URIs recorded; add exact browser callback destinations. | Invalid URI, missing required callback, mobile long URL wrapping | `/admin/clients/:client_id` | `AdminRouter`, `ClientsLive.Show`, `FormComponent` |
| `/admin/clients/:client_id/logout-uris` | Configure | Security/platform owner | Maintain browser post-logout redirect destinations. | Client workspace logout action | Which browser destinations may receive the user after logout? | Save post-logout redirect URIs | No post-logout redirect URIs recorded; add allowed browser destinations if RP-initiated logout uses them. | Invalid URI or ambiguous logout URI wording | `/admin/clients/:client_id/edit?workflow=logout-propagation` | `AdminRouter`, `ClientsLive.Show`, `docs/operator-admin.md` |
| `/admin/clients/:client_id/edit?workflow=logout-propagation` | Configure | Security/platform owner | Maintain RP logout cleanup endpoints separately from browser redirects. | Client workspace logout action | Which RP cleanup endpoints receive logout propagation? | Save logout propagation | No logout propagation URIs recorded; add back-channel or front-channel cleanup endpoints if the RP supports them. | Failed cleanup, best-effort front-channel, invalid URI | `/admin/logouts` | `ClientsLive.Show.resolve_form_mode/2`, `docs/operator-admin.md` |
| `/admin/clients/:client_id/par-policy` | Configure | Security/platform owner | Set client-specific PAR override and show effective posture. | Client workspace policy action | Should this client inherit or override the issuer PAR posture? | Save PAR override | No override recorded; client inherits global PAR policy. | Mixed policy posture or FAPI mismatch | `/admin/policies/par` | `AdminRouter`, `ClientsLive.Show`, `107-UI-SPEC.md` |
| `/admin/clients/:client_id/security-profile` | Configure | Security/platform owner | Set client security profile and show protocol impact. | Client workspace policy action | Should this client inherit, opt into, or opt out of stricter security? | Save security profile | No override recorded; client inherits global security profile. | Mixed-mode bypass, strict-readiness blocked | `/admin/policies/security-profile` | `AdminRouter`, `ClientsLive.Show`, `107-UI-SPEC.md` |
| `/admin/clients/:client_id/rotate-secret` | Configure | Security/platform owner | Rotate a confidential client secret with copy-once handling. | Client workspace credential action | Is this confidential client's secret ready to rotate? | Rotate client secret | Client is not confidential or not found; return to client workspace. | Copy-once secret exposure and confirmation required | `/admin/clients/:client_id` | `AdminRouter`, `ClientsLive.Show`, `RotateSecretComponent` |
| `/admin/clients/:client_id/rotate-registration-access-token` | Configure | Partner-onboarding operator | Rotate a self-registered client's management token. | Client workspace DCR/RAT action | Does this self-registered client need a new management token? | Rotate registration access token | Client is not self-registered or not found; return to client workspace. | Copy-once RAT exposure and prior token invalidation | `/admin/dcr` | `AdminRouter`, `ClientsLive.Show`, `RegistrationManagement.rotate_registration_access_token/1` |
| `/admin/policies` | Configure | Security/platform owner | Inspect issuer posture and exception pressure. | Configure > Security | Which issuer-level policy needs review first? | Review security posture | No policy exceptions visible; inspect detailed policy routes as needed. | FAPI readiness, DPoP/PAR exception pressure | `/admin/policies/par` | `AdminRouter`, `tmp/admin-ui-polish/v128-policies-desktop.png`, `tmp/admin-ui-polish/v128-policies-mobile.png` |
| `/admin/policies/par` | Configure | Security/platform owner | Decide global PAR requirement. | Security policy overview | Should pushed authorization requests be required globally? | Save global PAR policy | No override pressure; keep inherited/default posture. | FAPI conflict or direct authorization exception | `/admin/clients/:client_id/par-policy` | `AdminRouter`, `107-UI-SPEC.md` |
| `/admin/policies/security-profile` | Configure | Security/platform owner | Decide global security profile posture. | Security policy overview | Which issuer security profile should apply by default? | Save security profile | No strict profile selected; standard OIDC posture applies. | Strict profile readiness blocked or mixed-mode escape hatch | `/admin/clients/:client_id/security-profile` | `AdminRouter`, `107-UI-SPEC.md` |
| `/admin/policies/dpop` | Configure | Security/platform owner | Decide DPoP sender-constraint posture. | Security policy overview | Should DPoP be required, optional, or disabled by default? | Save DPoP policy | No DPoP posture change needed; keep current issuer setting. | Sender-constraint mismatch or incompatible clients | `/admin/policies` | `AdminRouter`, `107-UI-SPEC.md` |
| `/admin/policies/dcr` | Configure | Security/platform owner | Decide who may self-register and which auth methods are allowed. | Security policy overview or DCR onboarding | Which DCR policy safely gates partner registration? | Save global DCR policy | DCR disabled or no methods allowed; use DCR onboarding only after policy is set. | Open registration, unsupported auth method, broad registration posture | `/admin/dcr` | `AdminRouter`, `tmp/admin-ui-polish/v128-dcr-policy-desktop.png`, `tmp/admin-ui-polish/v128-dcr-policy-mobile.png` |
| `/admin/keys` | Configure | Security/platform owner | Maintain signing/encryption key readiness and lifecycle. | Configure > Keys | Are active, upcoming, and retiring keys ready for JWKS exposure? | Manage keys | No keys available; publish key material before relying on JWKS. | Retiring, missing active key, unsafe lifecycle transition | `/admin/keys/:id` | `AdminRouter`, `tmp/admin-ui-polish/v128-keys-desktop.png`, `tmp/admin-ui-polish/v128-keys-mobile.png` |
| `/admin/keys/:id` | Configure | Security/platform owner | Inspect one key's state and safe lifecycle transitions. | Key inventory | What lifecycle transition is safe for this key? | Review key lifecycle | Key not found; return to key inventory. | Retire/activate/publish confirmation, JWKS readiness | `/admin/keys` | `AdminRouter`, `107-UI-SPEC.md` |
| `/admin/dcr` | Configure | Partner-onboarding operator | Guide partner onboarding from policy to IATs to self-registered clients. | Configure > DCR | What is the next DCR onboarding step? | Mint initial access token | No self-registered clients yet; mint an IAT or edit DCR policy first. | Open registration, expired/used/revoked IATs, RAT rotation need | `/admin/iats/new` | `DcrLive.Index`, `tmp/admin-ui-polish/dcr-desktop.png`, `tmp/admin-ui-polish/v128-dcr-mobile.png` |
| `/admin/iats` | Configure | Partner-onboarding operator | Review initial access token inventory and intake state. | DCR onboarding | Which intake tokens are active, used, expired, or revoked? | Review initial access tokens | No initial access tokens; mint one for a bounded partner intake. | Active long-lived IAT, revoked/expired confusion, mobile long token metadata | `/admin/iats/new` | `AdminRouter`, `tmp/admin-ui-polish/v128-iats-desktop.png`, `tmp/admin-ui-polish/v128-iats-mobile.png` |
| `/admin/iats/new` | Configure | Partner-onboarding operator | Create a bounded intake token for partner onboarding. | IAT inventory or DCR onboarding CTA | What intake token constraints should be issued? | Create initial access token | No token draft yet; set expiry and scope for partner intake. | Copy-once plaintext token and overly broad intake | `/admin/iats` | `AdminRouter`, `DcrLive.Index`, `107-UI-SPEC.md` |
| `/admin/consents` | Support | Support engineer | Investigate remembered and revoked grants by account, client, and status. | Support > Consents or overview support queue | Which stored grants match the support case? | Filter consent grants | No consent grants match this view; adjust account, client, or status filter. | Revoked grant, long account/client IDs, raw-list density | `/admin/consents/:id` | `ConsentsLive.Index`, `tmp/admin-ui-polish/v128-consents-desktop.png`, `tmp/admin-ui-polish/v128-consents-mobile.png` |
| `/admin/consents/:id` | Support | Support engineer | Decide whether one stored grant is healthy or should be revoked. | Consent grant list | Should this durable grant remain active? | Review stored grant | Consent not found; return to filtered grant list. | Revoked, missing history context, destructive revoke confirmation | `/admin/consents` | `ConsentsLive.Show`, `107-PATTERNS.md` |
| `/admin/tokens` | Support | Support engineer | Investigate token and refresh-family state by account, client, and status. | Support > Tokens or overview support queue | Which token lifecycle records match the incident? | Filter tokens | No lifecycle tokens match this view; adjust account, client, or status filter. | Reuse detected, revoked, expired, long identifiers | `/admin/tokens/:id` | `TokensLive.Index`, `tmp/admin-ui-polish/v128-tokens-desktop.png`, `tmp/admin-ui-polish/v128-tokens-mobile.png` |
| `/admin/tokens/:id` | Support | Support engineer | Decide whether one token or refresh family needs revocation. | Token list | Is the safe action single-token revoke or family revoke? | Review token | Token not found; return to filtered token list. | Reuse detected, family-wide revocation, destructive confirmation | `/admin/tokens` | `TokensLive.Show`, `107-PATTERNS.md` |
| `/admin/interactions` | Operate | Support engineer | Inspect active authorization interaction queue state. | Operate > Interactions | Which pending login or consent interaction is waiting? | Review interactions | No active interactions; there are no interactions at this time. | Pending login, pending consent, stale created timestamps, raw-table density | `/admin/overview` | `InteractionsLive.Index`, `tmp/admin-ui-polish/v128-interactions-desktop.png`, `tmp/admin-ui-polish/v128-interactions-mobile.png` |
| `/admin/device_authorizations` | Operate | Support engineer | Inspect device authorization queue and expiry state. | Operate > Device Auth | Which device flow requests are pending or expiring? | Review device authorizations | No device authorizations; there are currently no device flow requests. | Expired, pending, long client IDs, mobile list wrapping | `/admin/overview` | `DeviceAuthorizationsLive.Index`, `tmp/admin-ui-polish/v128-device-authorizations-desktop.png`, `tmp/admin-ui-polish/v128-device-authorizations-mobile.png` |
| `/admin/logouts` | Operate | Support engineer | Inspect logout propagation delivery outcomes and retry/discard pressure. | Operate > Logouts or overview support queue | Which logout deliveries failed, retried, or discarded? | Review logout deliveries | No logout deliveries; there are no logout deliveries at this time. | Retryable, discarded, failed, attempts count, raw-table density | `/admin/clients/:client_id/edit?workflow=logout-propagation` | `LogoutDeliveriesLive.Index`, `tmp/admin-ui-polish/v128-logouts-desktop.png`, `tmp/admin-ui-polish/v128-logouts-mobile.png` |

## IA Audit Matrix

| Route | Desktop assessment | Mobile assessment | Priority | Audit notes |
|-------|--------------------|-------------------|----------|-------------|
| `/admin` | strong | strong | preserve | Overview already routes by client posture, issuer security, key readiness, support incidents, and live protocol work. Preserve as Orient baseline. |
| `/admin/overview` | strong | strong | preserve | Same cockpit evidence as `/admin`; do not reset this route in later polish. |
| `/admin/clients` | adequate | adequate | preserve | Inventory is a Configure entry point; later work should focus only if route-level proof finds mobile action pressure. |
| `/admin/clients/:client_id` | strong | adequate | prioritize action grouping | Client workspace separates identity, posture, credentials, endpoints, logout, DCR/RAT, and lifecycle, but action grouping is dense and mobile-sensitive. |
| `/admin/clients/:client_id/edit` | adequate | adequate | preserve | Safe edit workflow scopes fields to form mode; keep routine edits separate from risky credential and endpoint actions. |
| `/admin/clients/:client_id/redirects` | adequate | adequate | preserve | Endpoint edit workflow is bounded; audit later for long URI wrapping. |
| `/admin/clients/:client_id/logout-uris` | adequate | adequate | preserve | Copy distinguishes browser destinations; keep separate from logout propagation URIs. |
| `/admin/clients/:client_id/edit?workflow=logout-propagation` | strong | adequate | preserve | Existing copy explicitly separates logout propagation URIs from post-logout redirect URIs; later work can improve mobile form grouping without changing vocabulary. |
| `/admin/clients/:client_id/par-policy` | adequate | adequate | preserve | Effective posture language is already available in client workspace. |
| `/admin/clients/:client_id/security-profile` | adequate | adequate | preserve | Strict readiness and mixed-mode warnings are already explicit. |
| `/admin/clients/:client_id/rotate-secret` | strong | adequate | preserve | Confirmation and copy-once reveal are established; keep secret redaction. |
| `/admin/clients/:client_id/rotate-registration-access-token` | strong | adequate | preserve | RAT rotation has copy-once treatment and self-registered-client scope. |
| `/admin/policies` | strong | strong | preserve | Security posture overview is a strong v1.28 baseline. |
| `/admin/policies/par` | adequate | adequate | preserve | Policy route is focused; later design-system work may tighten consistency. |
| `/admin/policies/security-profile` | adequate | adequate | preserve | Global posture decision is focused; preserve strict-profile copy. |
| `/admin/policies/dpop` | adequate | adequate | preserve | DPoP policy route stays within issuer posture. |
| `/admin/policies/dcr` | strong | adequate | preserve | DCR policy screenshot evidence is strong enough to preserve; do not collapse it into DCR onboarding. |
| `/admin/keys` | strong | adequate | preserve | Key lifecycle is already a strong Configure surface; later work should retain publish/activate/retire safety. |
| `/admin/keys/:id` | adequate | adequate | preserve | Detail route should keep safe lifecycle transition framing. |
| `/admin/dcr` | strong | adequate | preserve | DCR onboarding already connects policy, IATs, self-registered clients, and RAT support. |
| `/admin/iats` | adequate | weak | prioritize weak spot | IAT inventory is central to DCR onboarding but likely needs stronger mobile and state grouping. |
| `/admin/iats/new` | adequate | weak | prioritize weak spot | Minting flow needs copy-once and constraint clarity proof on mobile. |
| `/admin/consents` | adequate | weak | prioritize weak spot | Filters exist, but support job and next safe action need stronger scanning and mobile behavior. |
| `/admin/consents/:id` | adequate | weak | prioritize weak spot | Detail route has revoke confirmation; later work should strengthen pivot context and mobile long-value readability. |
| `/admin/tokens` | adequate | weak | prioritize weak spot | Filters exist, but token/family investigation and long identifiers need stronger scanability. |
| `/admin/tokens/:id` | adequate | weak | prioritize weak spot | Corrective actions are clear; route still needs better incident-first hierarchy and mobile long-value proof. |
| `/admin/interactions` | weak | weak | prioritize weak spot | Raw table with ID, client, status, and created timestamp; needs operator decision and queue pressure context. |
| `/admin/device_authorizations` | weak | weak | prioritize weak spot | Simple list states client, status, and expiry; needs stronger queue, expiry, and mobile context. |
| `/admin/logouts` | weak | weak | prioritize weak spot | Raw delivery table with attempts and status; needs retry/discard pressure, pivot, and mobile improvements. |

## Weak-Spot Priority Set

Phase 109 should prioritize these weak or mobile-sensitive surfaces before re-polishing stronger baselines:

- `/admin/logouts`
- `/admin/device_authorizations`
- `/admin/interactions`
- `/admin/tokens`
- `/admin/tokens/:id`
- `/admin/consents`
- `/admin/consents/:id`
- `/admin/dcr`
- `/admin/iats`
- `/admin/iats/new`
- Client-detail action grouping across `/admin/clients/:client_id` and its edit/credential/logout workflows

## Requirement Coverage

| Requirement | Contract coverage |
|-------------|-------------------|
| JOURNEY-01 | Every route row has exactly one primary journey: Orient, Configure, Support, or Operate. |
| JOURNEY-02 | Every route row documents persona, JTBD, entry point, primary decision, primary action, empty state, risk state, follow-up route, and evidence. |
| JOURNEY-03 | `/admin` and `/admin/overview` are preserved as the task-and-urgency Orient cockpit. |
| JOURNEY-04 | Journey labels and vocabulary splits are locked for docs and tests. |
| JOURNEY-05 | `DCR onboarding`, `/admin/dcr`, `/admin/iats`, `/admin/iats/new`, RAT rotation, and `DCR policy` stay connected but distinct. |
| JOURNEY-06 | `post-logout redirect URIs` and `logout propagation URIs` stay separate across client detail, edit workflows, docs, and logout delivery audit notes. |
