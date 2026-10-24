# Phase 162 Scope and Coverage

## Applicability

Phase 162 specifies existing OAuth protocol and storage contracts. It performs no external API integration, runtime or UI change, database schema push, deployment, dependency installation, or public/operator documentation update. The protocol/storage nouns in the API detector describe the subject of this design contract; they do not imply an endpoint integration task. The contract is phase-local; Phase 166 owns synchronization into public/operator documentation after behavior is proven.

All contract and fixture statements describe expected design behavior. They do not show that current Lockspire code enforces a deadline. The Python validator checks design consistency only. Independent semantic verification is separate and must compare selected context against these artifacts.

## Seven fallback probes

| Requirement / category | Disposition | Evidence and owner |
|---|---|---|
| DCR-02 / adjacency | Resolved, explicit | C-POL-08 through C-POL-10 enforce strict before/equality/after boundaries; C-RACE-06 checks a lock wait crossing equality. Phase 163 verifies app boundaries; Phase 166 owns the cross-phase clock journey. |
| DCR-02 / empty | Resolved, explicit | C-POL-02 and C-POL-05 define null/zero as unlimited and no-secret as inapplicable; C-POL-06/07 reject malformed policy/state. Phase 163 covers app policy; Phase 164 covers shared-secret policy. |
| DCR-02 / ordering | Resolved, explicit | C-POL-03/04/12 preserve issuance snapshots and use post-lock time. Phases 163–165 cover focused operations; Phase 166 proves final ordering. |
| DCR-03 / adjacency | Resolved, explicit | C-APP-14/15 and C-MGMT-04 allow GET/DELETE for a valid token on an expired enabled app while equality blocks PUT and issuance. Phase 165 tests management; Phase 166 owns cross-phase proof. |
| DCR-03 / empty | Resolved, explicit | C-MGMT-08/09 distinguish missing Bearer, invalid credential, unknown target and disabled state while retaining non-disclosure. Phase 165 tests endpoint outcomes; Phase 166 includes scoped security review. |
| DCR-03 / ordering | Resolved, explicit | C-RACE-01–06 cover current-row authorization, one-winner PUT, stale credentials and post-wait time. Phase 165 covers management races; Phase 166 owns PostgreSQL race proof. |
| DCR-04 / unclassified — A-162-01 | Classified by explicit coverage review; no new product policy | C-LEG-01–08 cover historical dates, legacy promotion and adapter declaration/failure; C-DEP-01–04 cover prefix-aware additive migration, old-writer drain, cutover, mixed serving, and pre/post-first-v1-write rollback. The complete validator checks these design predicates. Phase 166 independently verifies packaged legacy/custom-store hosts, real PostgreSQL behavior and deployment/security evidence. Keep A-162-01 visible until that review passes. |

## Design-to-implementation handoff

| Phase | Required evidence |
|---|---|
| 163 | Focused app lifetime/storage tests, including enabled state, deadlines, equality, artifact completion and state retention. |
| 164 | Basic, post and secret-JWT shared-secret expiry tests; preserve assertion expiry, algorithm and replay rules. |
| 165 | Management GET/PUT/DELETE, recovery, wire metadata, endpoint errors, current-row serialization and audit atomicity tests. |
| 166 | Cross-phase clock-boundary journeys, real PostgreSQL races/rollback, fresh/legacy/custom-store packaged hosts, required CI, scoped security review, observed expiry/rotation/recovery telemetry with redaction, and truthful public/operator copy. |

The phase verifier must independently inspect the conflict pairs listed in `162-VALIDATION.md`, verify every D-01–D-27 and DCR-02/03/04 mapping against normative content and case references, and report that result apart from validator output. It must retain this phase's design-only evidence boundary and A-162-01 disposition. No requirement checkbox is completed by this artifact; Phase 166 retains final proof ownership.
