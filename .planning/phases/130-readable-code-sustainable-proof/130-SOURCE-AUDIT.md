# Phase 130 Source Coverage Audit

| Source | ID | Feature / requirement | Plan | Status | Notes |
|--------|----|-----------------------|------|--------|-------|
| GOAL | — | Repository is a joy to read and quality proof is cheaper to maintain without deleting evidence | 130-01..08 | COVERED | Green baseline, capability splits, measured CI, readability, docs, and evidence policy close the outcome. |
| REQ | TEST-01 | Shared DB/config isolation helpers replace repeated setup | 130-02 | COVERED | Adds DataCase/ConfigCase and migrates three materially different suites. |
| REQ | TEST-02 | Split oversized token, release, and admin contracts without losing coverage | 130-03, 130-04, 130-05 | COVERED | One capability split per oversized proof domain with old-to-new inventories. |
| REQ | CI-02 | Remove duplicate test work only with timing evidence | 130-06 | COVERED | Measures current matrix, proves membership, then edits default CI. |
| REQ | READ-01 | Remove runtime planning archaeology while retaining durable rationale | 130-07 | COVERED | Normalizes Phase 129 filenames and rewrites comments/copy under a source fitness test. |
| REQ | READ-02 | Keep docs/walkthrough synchronized with code and public structs | 130-08 | COVERED | Replaces brittle source anchors with loaded-module/function/struct checks. |
| REQ | CLEAN-01 | Remove obsolete scratch and document retained visual evidence | 130-08 | COVERED | Deletes the approved list and protects screenshots with explicit policy/contracts. |
| RESEARCH | — | Current full-suite Docker reset contract misses explicitly named db volume | 130-01 | COVERED | Parser repaired without changing correct cleanup behavior. |
| RESEARCH | — | Compatibility fixture creates root test discovery warning | 130-01 | COVERED | Standalone project moves outside `test/` while CI proof remains exact. |
| RESEARCH | — | Phase 129 facade and GrantSupport filenames are inverted | 130-07 | COVERED | Files move to paths matching their modules without public behavior change. |
| CONTEXT | — | Preserve public behavior and OAuth/OIDC security defaults | 130-01..08 | COVERED | Plans are test/docs/CI/internal refactors with explicit no-drift acceptance and threat models. |
| CONTEXT | — | Retain `tmp/admin-ui-polish` screenshots; do not delete | 130-08 | COVERED | Explicit retention lifecycle and executable path/package/runtime checks. |

## Exclusions

- New OAuth/OIDC flows, endpoints, schemas, public APIs, and host-owned UX/policy are outside this phase.
- Screenshot refresh is not required; this phase governs and verifies the existing evidence inventory.
- No dependency installation is planned, so the package legitimacy gate does not apply.
