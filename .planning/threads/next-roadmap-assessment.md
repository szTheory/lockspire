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

1. Merge the green-main env-isolation patch.
2. Run a patch-truth cleanup for CIBA discovery, JAR docs/runtime truth, and JTBD wording.
3. Open `v1.26 Host Integration & Operator Boundary Hardening` only after the patch train is clean.
4. Consider doctor/support-console expansion after v1.26 only if concrete support drag remains.

## Recommended v1.26 Shape

Done enough for `v1.26` means a Phoenix SaaS developer can see how to wire realistic accounts/claims, create the first real partner client, protect admin routes explicitly, and operate common clients/consents/tokens/keys without source-diving.

Do not turn `v1.26` into hosted auth, a generic gateway, a service mesh, SAML/LDAP, certification-breadth chasing, or auth-method parity.

## Graduation Candidates

- Adopter-first "done" lens: judge next work by Phoenix SaaS adoption friction, not phase count or protocol checklists.
- Support-truth before feature breadth: close doc/discovery/runtime drift before opening a new milestone.
- Milestone PR discipline: large feature work uses one `milestone/vNEXT-short-slug` branch and one PR to `main`; patch work stays narrow and release-train friendly.
