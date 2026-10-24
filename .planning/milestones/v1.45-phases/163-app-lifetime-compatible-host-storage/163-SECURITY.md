---
phase: "163"
slug: app-lifetime-compatible-host-storage
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-20"
audited_head: 27417748685f8fdadc810ead0a16216d8e6b1471
---

# Phase 163 Security

Independent typed security auditor verified all 38 unique planned mitigations at ASVS L1 (33 high,5 medium). This is mitigation-presence verification, not release approval or replacement for goal/code review. Scope: credential/adapter-to-protocol, current-row authority, durable writes/audits and package upgrade boundaries.

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|---|---|---|---|---|---|---|
| T-163-01 | E | Registration constructor and current app decision | high | mitigate | Validate version and duration, retain provenance and reject equality; registration runtime tests prove it. Evidence: 163-01-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-02 | T | Legacy schema expansion | high | mitigate | Add nullable fields with constant v0 default and preserve historical/shipped migration bytes. Evidence: 163-01-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-SC | Tampering | Dependency installation | high | mitigate | D-23 prohibits new dependencies; preserve mix.lock. Any newly proposed install must first satisfy the package-legitimacy gate. Evidence: 163-01-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-05 | E | Custom client storage adaptation | high | mitigate | Reject absent/unsupported declaration and malformed round-trip state before protocol work. Evidence: 163-02-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-06 | T | Cross-store transactions | high | mitigate | Require matching declared authority and failure-injection conformance that detects escaped writes. Evidence: 163-02-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-09 | S | Client authentication and verified identity | high | mitigate | Bind the actual verified credential/configuration and reject app expiry for all supported methods. Evidence: 163-03-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-10 | I | Credential fingerprints | high | mitigate | Keep fingerprints internal and redacted; server errors do not disclose credential material. Evidence: 163-03-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-13 | E | Authorization resume and PAR use | high | mitigate | Re-read current app at intake/use and guard every code persistence after all locks. Evidence: 163-04-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-14 | D | JARM response and remote JWKS | high | mitigate | Commit code/interaction transitions before any network-dependent redirect construction. Evidence: 163-04-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-15 | I | Authorization error redirect | high | mitigate | Retain validated URI trust and original state; fail locally before trust. Evidence: 163-04-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-17 | E | Device delayed approval | high | mitigate | Guard current client and request, then sample time and persist approval atomically. Evidence: 163-05-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-18 | E | CIBA host approval | high | mitigate | Reload app state after ordered locks; retained queued request is not authorization. Evidence: 163-05-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-19 | D | Host callbacks during approval | medium | mitigate | Keep remote host work outside row-lock lifetime and revalidate before mutation. Evidence: 163-05-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-21 | E | Final code redemption | high | mitigate | Lock current app and code, then sample time and compare verified identity before consumption. Evidence: 163-06-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-22 | T | Code/token/audit atomicity | high | mitigate | One outer transaction explicitly rolls back every failed write and required audit. Evidence: 163-06-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-23 | E | Signed expiry recomputation | high | mitigate | Use the same effective expiry in row, access JWT and expires_in. Evidence: 163-06-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-25 | E | Refresh current state | high | mitigate | Check current app and verified identity after ordered grant/family locks. Evidence: 163-07-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-26 | T | Refresh replay and audit outcome | high | mitigate | Preserve family-wide reuse revocation and rollback required audit/write failure. Evidence: 163-07-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-27 | E | Refresh token cap | high | mitigate | Use separate ordinary access/refresh TTL under the same finite app cap. Evidence: 163-07-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-29 | E | Approved polling grants and queued push | high | mitigate | Reload current app/request and sample after all locks before consumption/issuance. Evidence: 163-08-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-30 | D | CIBA push network delivery | high | mitigate | Release transaction locks before delivery and preserve existing retry/idempotence. Evidence: 163-08-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-33 | E | Subject and actor issuer eligibility | high | mitigate | Check current issuing apps independently before host validation and again under final locks. Evidence: 163-09-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-34 | D | Multi-client lock order | high | mitigate | Deduplicate and sort all client IDs before token/grant locks. Evidence: 163-09-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-35 | T | Exchange standalone persistence | high | mitigate | Move output token and audit into one declared transaction with rollback. Evidence: 163-09-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-37 | I | Introspection token ownership | high | mitigate | Preserve ownership check before current issuer observation and emit only active:false for inactive owned targets. Evidence: 163-10-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-38 | E | UserInfo host claims boundary | high | mitigate | Resolve current issuing app through declared adapter before account/claims callbacks. Evidence: 163-10-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-39 | I | Revocation unknown-token response | medium | mitigate | Require eligible caller and preserve non-disclosing response semantics. Evidence: 163-10-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-41 | E | Management expired/disabled state | high | mitigate | Separate valid-credential expired GET/DELETE from forbidden PUT and disabled denial. Evidence: 163-11-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-42 | S | Management preverified token | high | mitigate | Bind presented verified hash and URL to locked current row before mutation. Evidence: 163-11-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-43 | T | Legacy promotion and stale whole-client replacement | high | mitigate | Apply current-row deltas, canonicalize all unrelated legacy dates and atomically persist audit. Evidence: 163-11-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-45 | E | Unobserved or wrong lock race | high | mitigate | Require exact PID blocker relation and explicit barrier before time/holder transition. Evidence: 163-12-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-46 | T | Partial transaction result | high | mitigate | Failure injection compares complete durable artifacts for every issuance family and promotion. Evidence: 163-12-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-47 | D | Leaked test sessions | medium | mitigate | Bound barriers and always terminate/rollback tasks plus clean committed fixtures. Evidence: 163-12-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-49 | T | Packaged migration integrity | high | mitigate | Actual installer/checksum path preserves shipped assets and validates both prefix schemas. Evidence: 163-13-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-50 | D | Expansion DDL locks | high | mitigate | Observe actual holder/contender lock, bounded lock_timeout failure and successful retry in disposable DB. Evidence: 163-13-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-51 | E | Unsafe old-code rollback after v1 | high | mitigate | Stop every old writer before v1; retain authoritative schema/state and forbid old protocol traffic afterward. Evidence: 163-13-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-53 | I | Upgrade and offline claims | medium | mitigate | Bind guidance to executed package/runtime observations and explicitly state offline limits. Evidence: 163-14-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |
| T-163-54 | R | Completion evidence | medium | mitigate | Record commands, exact test cases, durable observations and nonzero package events for each source item. Evidence: 163-14-PLAN.md; corresponding runtime/test files mapped in 163-COVERAGE.md and 163-SOURCE-AUDIT.md. | closed |

## Accepted Risks

None. No planned threat was accepted or transferred. No runtime dependencies were added; mix.exs/mix.lock and historical migration bytes are unchanged.

## Audit Trail

2026-10-20: independent gsd-security-auditor; 38 closed,0 open. Fresh package receipt validation verified both prefixes,37 historical migration checksums and retained authoritative state.

## Review Handoff

Auditor separately identified correctness/proof concerns for mandatory code review: fractional default decision clocks may reject eligible finite apps; dropped-state negative adapter fixtures may reject invalid declarations before exercising field loss. These do not imply phase approval and must be resolved or dispositioned before completion. Finite secret/management credential requirements remain164/165.

Review handoff resolved: CR-01/WR-01 fixed and independently re-reviewed closed; current focused auth/conformance plus realPGwait/rollback31tests0failures. No new planned threat scope.

## Current-source refresh (2026-10-22)

Independent typed gsd-security-auditor rechecked all 38 planned mitigations against current source at `27417748685f8fdadc810ead0a16216d8e6b1471`: 38 closed (33 high, 5 medium), 0 open, ASVS L1. Current selected client/transaction stores, matching authority checks, guarded issuance, atomic rollback/audit, credential redaction, online consumers and management gates remain present. All 37 historical migrations and mix.lock were compared directly with release commit `d04be402`; no dependency changes were found. At that audit, source, tests, package scripts, docs and CI inputs were identical to candidate `0bd4070d862c53cb3e8dfc4d1cf25535b232aaed`.

This refresh checks mitigation presence; runtime/package results above remain historical. A-EDGE-16/17/19 and the two descriptor-less prohibitions retain their explicit unresolved/flagged limits. Historical TDD limitations remain unchanged. No new threats, accepted risks or implementation changes were introduced.

## Security Audit 2026-10-22

| Metric | Count |
|---|---|
| Threats found | 38 |
| Closed | 38 |
| Open | 0 |

The subsequent D-24 correction changes only the upgrade-guide proof paragraph and its existing documentation assertions. It does not change a runtime mitigation or claim that the old CI run includes the later text.

## Frozen-candidate L1 delta revalidation (2026-10-22)

The existing 38 planned mitigations remain closed. This bounded revalidation inspected the sole covered runtime delta, final_exchange_time, after the independent Phase 164 guard re-review/security closure. The new DateTime guard executes after input-token locks and before token checks, app/identity eligibility, signing, writes and audit; malformed time now returns controlled server_error. Client/issuer authority checks, lock order and atomic transaction boundaries are unchanged, preserving T-163-33/34/35 and the earlier 38-mitigation closure. This applies the documented ASVS L1 closed-register short circuit; it is not a new full threat audit or runtime run. No new dependency or accepted risk is introduced.

Frozen source candidate is f8dd7712af7f3ef906305db549c6312284339dba; independent post-guard 27/0 and root's fresh RFC/guidance 19/0 evidence are recorded in the delta receipt. New CI run 39816801430 is handled by root; the old 0bd4070d CI/package proof remains historical. Existing evidence limits remain unchanged.
