# PAR Milestone Research: Stack

**Project:** Lockspire  
**Milestone:** v1.2 PAR Foundation  
**Researched:** 2026-04-24  
**Confidence:** HIGH

## Existing Stack to Keep

- Phoenix `1.8.5` and Plug routing remain the right delivery surface for the PAR endpoint and discovery metadata.
- Ecto/Postgres remain the right durable path for stored pushed requests because PAR introduces server-issued references, expiry, and single-use semantics that should not live in transient process state.
- Existing client authentication patterns at the token edge should be reused for PAR where Lockspire already supports `none`, `client_secret_basic`, and `client_secret_post`.
- Existing test layers should carry the protocol proof: controller tests for endpoint truth, protocol/service tests for validation, and integration tests for full PAR-to-authorize flow.

## New Capability Additions

- Add a durable pushed-authorization-request record or equivalent storage adapter contract for:
  - `request_uri`
  - bound `client_id`
  - validated request payload
  - expiry timestamp
  - single-use / consumed state
- Extend authorization-request validation so `/authorize` can resolve a PAR-issued `request_uri` instead of rejecting it outright.
- Extend discovery metadata generation to publish `pushed_authorization_request_endpoint` only when PAR is actually enabled.

## Release Tooling Constraint

- The repository currently pins `googleapis/release-please-action@16a9c90856f42705d54a6fda1823352bdc62cf38` in `.github/workflows/release.yml`, annotated as `v4.4.0`.
- GitHub announced Node 20 runner deprecation on **2025-09-19**, so the milestone should preserve a release workflow that no longer depends on deprecated action runtime behavior.
- Research implication: treat release-tooling work as an outcome requirement, not as a blind version-bump requirement. If upgrading the action tag is insufficient, the milestone should still close only when the warning is gone and the trusted preview release path remains aligned with docs.

## What Not to Add

- No hosted auth service topology
- No new frontend stack
- No queueing or async orchestration requirement for the PAR core path
- No dynamic client registration dependency
- No JAR-by-value requirement for this milestone

## Primary Sources

- RFC 9126: OAuth 2.0 Pushed Authorization Requests — https://www.rfc-editor.org/rfc/rfc9126
- RFC 8414: OAuth 2.0 Authorization Server Metadata — https://www.rfc-editor.org/rfc/rfc8414.html
- OpenID Connect Discovery 1.0 — https://openid.net/specs/openid-connect-discovery-1_0-final.html
- `googleapis/release-please-action` repository — https://github.com/googleapis/release-please-action
- GitHub changelog: Node 20 deprecation on Actions runners — https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/

---
*Research completed: 2026-04-24*
