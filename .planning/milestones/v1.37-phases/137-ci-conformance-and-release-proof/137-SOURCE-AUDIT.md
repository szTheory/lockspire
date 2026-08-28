# Phase 137 Plan Source Audit

| Source | ID | Feature / constraint | Plan(s) | Status | Notes |
|---|---|---|---|---|---|
| GOAL | — | Release carries reproducible security, coverage, conformance, and package-install evidence from immutable inputs | 01-10 | COVERED | Local policies precede workflow/release orchestration. |
| REQ | CI-01 | Explicit low-severity fail-closed scans of both routers | 01, 04 | COVERED | Script-owned policy, workflow-required invocation. |
| REQ | CI-02 | Once-per-fast/integration native aggregate >=84% | 02, 03, 04 | COVERED | Measured 78.03% closes with behavioral tests; no exclusions or duplicate runs. |
| REQ | CI-03 | Unused locks, compile-connected cycles, controlled demo updates/minimum fixture immutability | 01, 04 | COVERED | Existing lock ownership is retained and made required. |
| REQ | CONF-01 | Immutable OIDC/FAPI images, source, downloads, checksums | 05, 06, 07 | COVERED | Full commit, helper/archive SHA-256, three OCI digests, no fallback. |
| REQ | CONF-02 | Scheduled supplemental lane with redacted evidence | 06, 07 | COVERED | Allowlisted evidence precedes scheduled upload. |
| REQ | REL-01 | Prepublish built-artifact and postpublish exact-version clean-room HTTP proof | 08, 09, 10 | COVERED | Existing Phase 133 journey is adapted at package source only. |
| REQ | REL-02 | Hex checksum equality and redacted pinned-tool manifest | 09, 10 | COVERED | One tar identity crosses protected publication. |
| RESEARCH | — | Native Mix exported coverage; fast local threshold stays 73 | 02-04 | COVERED | Complete Mix partition is labeled separately from child-VM journey. |
| RESEARCH | — | Script-owned policy/workflow-owned orchestration | 01-02, 04-07, 09-10 | COVERED | Each workflow plan depends on tested script contracts. |
| RESEARCH | — | Immutable OIDF release-v5.1.43 lock with verified commit/checksums/digests | 05-07 | COVERED | Exact identities are embedded in Plan 05. |
| RESEARCH | — | Redact before artifact retention | 06-07, 09-10 | COVERED | Raw logs/configs stay ephemeral. |
| RESEARCH | — | Single-byte release chain | 08-10 | COVERED | Manifest binds source SHA, tar, Hex checksum, and journeys. |
| CONTEXT | — | No phase CONTEXT.md decisions exist | — | N/A | Assumptions/research and milestone constraints govern planning. |

## Deferred / excluded by source

- Formal OIDC/FAPI certification or a release-blocking conformance lane.
- New OAuth/OIDC grants, hosted auth, standalone service, SAML/LDAP, or CIAM breadth.
- Admin visual redesign.
- Coverage from the independently booted clean-room child VMs; it remains separate HTTP evidence.

## Pre-mortem controls

1. False-green coverage is caught early by Plans 02-03 requiring exact exports, same SHA, no aggregator test execution, and a measured >=84 report.
2. Pinned source with mutable images is caught by Plan 05's compose/image validator and digest-qualified overrides before Docker starts.
3. A release publishing different bytes is caught by Plans 09-10 at manifest creation, protected handoff, pre-publish byte comparison, Hex checksum verification, and exact-version journey.
