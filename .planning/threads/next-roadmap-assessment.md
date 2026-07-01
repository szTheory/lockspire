# Next Roadmap Assessment

**Date:** 2026-05-27  
**Status:** Active cross-session context  
**Purpose:** Preserve the post-`1.1.0` roadmap assessment so the next milestone starts from repo-local truth instead of re-deriving the same product judgment.

## Current Judgment

Lockspire is roughly `88-92%` done for its intended embedded Phoenix OAuth/OIDC provider scope. It is strong enough that broad protocol work is now likely diminishing-return, but not so "done" that we should ignore maintenance truth, host integration recipes, or operator boundary clarity.

## Evidence From Repo Inspection

- Install and onboarding are real: generator, verify task, onboarding docs, generated-host proof, and release-readiness contract tests exist.
- Protocol coverage is broad and repo-proven: auth code + PKCE, discovery/JWKS/userinfo, revocation, introspection, refresh rotation, PAR/JAR, DCR/RFC 7592, device flow, DPoP, FAPI, Token Exchange, CIBA, RAR, Resource Indicators, `private_key_jwt`, `client_secret_jwt`, mTLS, and protected Phoenix route support.
- Operator/admin surfaces are real for clients, consents, keys, tokens, policies, and logout propagation.
- Main CI regressed after PR #31 because root-mount integration tests leaked global Lockspire app env into back-channel logout worker tests. This must be fixed before any release or roadmap work can be trusted.
- Public-truth drift remains narrow but real: CIBA discovery appears narrower than shipped Ping/Push runtime support, JAR/request-object docs lag actual by-value support, and some JTBD wording undersells shipped protected-route/onboarding proof.

## Recommended Sequence

1. Done: merge the green-main env-isolation patch.
2. Done: ship the patch-truth cleanup for CIBA discovery and JAR docs/runtime truth in `1.1.2`.
3. Open `v1.26 Host Integration & Operator Boundary Hardening` only if feature work is justified beyond sustaining maintenance.
4. Consider doctor/support-console expansion after v1.26 only if concrete support drag remains.

## Recommended v1.26 Shape

Done enough for `v1.26` means a Phoenix SaaS developer can see how to wire realistic accounts/claims, create the first real partner client, protect admin routes explicitly, and operate common clients/consents/tokens/keys without source-diving.

Do not turn `v1.26` into hosted auth, a generic gateway, a service mesh, SAML/LDAP, certification-breadth chasing, or auth-method parity.

## Graduation Candidates

- Adopter-first "done" lens: judge next work by Phoenix SaaS adoption friction, not phase count or protocol checklists.
- Support-truth before feature breadth: close doc/discovery/runtime drift before opening a new milestone.
- Milestone PR discipline: large feature work uses one `milestone/vNEXT-short-slug` branch and one PR to `main`; patch work stays narrow and release-train friendly.

## 2026-06-27 Refresh

**Status:** Implemented narrow admin coherence pass outside a formal GSD milestone.

**Current judgment:** Lockspire is now roughly `90-93%` done for the intended embedded Phoenix OAuth/OIDC provider scope. The remaining high-leverage work is narrow admin/operator product quality and proof, not protocol breadth or platform expansion.

**Implemented wedge:**
- Client detail lifecycle safety now uses an explicit confirmation form for enable/disable instead of a one-click `phx-click`, while preserving the existing `toggle_client` event and Admin API calls.
- DCR policy now has a compact decision-summary layer for registration gate, allowlists, token auth methods, and lifetime posture before the long policy form.
- Logout deliveries now render more scan-oriented read-only queue rows with channel, endpoint, attempts, last activity, status pressure, and support notes.
- A new internal `decision_summary` admin primitive is covered by CSS, component inventory, and stress-surface guardrails.

**Verified:**
- `mix test test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs --max-failures 3`
- `mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 5`
- `mix test test/lockspire/web/live/admin --max-failures 5`

**Next recommendation:** Do not open a broad admin redesign. If more work is justified, make it release/proof oriented: current browser/manual evidence, docs screenshots if needed, and one last adoption walkthrough. Avoid public theming, required Storybook/PhoenixStorybook, visual snapshot tooling, and logout retry/discard controls unless adopter evidence or domain APIs justify them.

**Graduation candidates:**
- Page-first admin polish is now the default pattern: fix the highest-pressure workflow, then generalize only proven primitives.
- Dangerous admin lifecycle actions should use confirmation forms, not immediate click handlers.
- Policy pages benefit from a compact decision summary before detailed controls.
