# v1.26 Requirements

## Host Integration & Operator Boundary Hardening

- [x] **HOST-01:** Generated account resolver guidance helps a Phoenix host wire signed-in account lookup and narrow claims without implying Lockspire owns accounts, tenant policy, or product authorization.
- [x] **ADMIN-01:** Generated router guidance gives hosts a concrete `Lockspire.Web.AdminRouter` mount behind their operator-auth pipeline while preserving the public OAuth/OIDC router.
- [x] **CLIENT-01:** First-client bootstrap guidance makes the CLI-created client usable for a real authorization-code + PKCE proof and reminds maintainers that printed secrets are copy-once.
- [x] **DOCS-01:** Public docs include a compact SaaS adoption recipe from install through first client and protected route, with Sigra kept optional and host-owned.
- [x] **PROOF-01:** Generator, CLI, router, and release-readiness tests fail if the adopter-facing boundary drifts.

## Out of Scope

- Lockspire-owned operator authentication, staff MFA, role checks, or IP allowlists.
- Hosted auth, CIAM, SAML, LDAP, or developer portal UI.
- New protocol endpoints or wider support claims.
- Compile-time Sigra dependency.
