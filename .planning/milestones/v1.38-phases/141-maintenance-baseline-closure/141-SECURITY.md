---
phase: "141"
slug: "maintenance-baseline-closure"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-05"
---

# Phase 141 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Phase 140 receipt and hosted CI to Phase 141 baseline | Prior-phase private receipt and source-native workflow outcomes become durable maintainer claims only after exact-SHA identity and terminal status are checked. | Full Git SHAs, run IDs, pass/no-publish statuses, safe source links |
| Hex and GitHub public records to release-train prose | Mutable public package, tag, workflow, and checksum records establish publication truth only when re-queried at closure time. | Package version, tag/source SHA, run identities, checksum, observation time |
| Private receipts and supplemental conformance logs to tracked planning records | Only bounded identifiers and redacted status summaries cross into the public repository. | Allowlisted hashes, statuses, and direct source links |
| GSD lifecycle records to the maintainer handoff | Completion and deferred-item claims are written only after receipt, baseline, and cross-record review agree. | Phase status, requirement IDs, commit identities, recheck triggers |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-141-01 | Tampering / Information disclosure | `141-BASELINE.md` evidence join | high | mitigate | Baseline ties CI-06/07, local gates, seven required jobs, and Release no-publish result to accepted source SHA `877a0f758aa0bbd5433cbe3d70f1476fa0e12223`; it distinguishes the Task 1 report commit and links the receipt/verifier and same-SHA runs. | closed |
| T-141-02 | Spoofing / Repudiation | PROJECT and RELEASE-TRAIN publication prose | high | mitigate | Current public Hex records, GitHub release/tag, canonical CI, protected publication run, and checksum are recorded as a separate 1.5.0 publication chain on source SHA `5d10ce2219c2e687cf9573c8b280abfb118a47d8`; Phase 141 and the no-publish run are explicitly not called a release. | closed |
| T-141-03 | Tampering / Repudiation | GSD lifecycle status | high | mitigate | BASE-04/05 and v1.38 completion are linked to the dated baseline; the execution summary records distinct full Task 1 and Task 3 commit SHAs and states that Phase 140 receipt authority does not transfer to documentation commits. | closed |
| T-141-04 | Elevation of privilege | Release/ref ownership | medium | mitigate | The user-approved branch is local and unpushed; the plan limits changes to its setup and the three task commits. No merge, push, tag, protected release dispatch, or package publication occurred. | closed |

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-05 | 4 | 4 | 0 | Codex execute-phase orchestrator |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-05

## Evidence

- [Phase 141 baseline](./141-BASELINE.md)
- [Phase 141 execution summary](./141-01-SUMMARY.md)
- [Phase 141 plan threat model](./141-01-PLAN.md)
