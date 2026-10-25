---
phase: 171
phase_name: "Accepted Baseline & Finding Qualification"
project: "Lockspire"
generated: "2026-10-24T22:15:15.496116+00:00"
counts:
  decisions: 2
  lessons: 4
  patterns: 2
  surprises: 2
missing_artifacts: ["171-UAT.md"]
---

# Phase 171 Learnings

## Decisions

### Preserve one exact acceptance authority

Reuse the original accepted-main receipt and keep baseline, source-host, package and external-suite identities distinct.

**Rationale:** Later ledger or metadata edits cannot reconstruct earlier acceptance or justify another identical expensive authority run.
**Source:** 171-01-SUMMARY.md; 171-VERIFICATION.md.

### Let cases determine correction scope

Retain only A171-003 and P171-005 as correction inputs; carry ten already-proven cases forward.

**Rationale:** Historical suite labels and missing infrastructure do not establish product defects or justify invented implementation work.
**Source:** 171-02-SUMMARY.md; 171-03-SUMMARY.md; 171-QUALIFICATION-DECISIONS.md.

## Lessons

### Follow the normative reference chain

Review incorporated clauses before calling a behavior discretionary policy.

**Context:** The initial PAR reject-versus-ignore description missed RFC 9126's reference to RFC 9101. The dated interpretation now identifies the chain and preserves plain form-encoded PAR.
**Source:** 171-QUALIFICATION-DECISIONS.md; 171-03-SUMMARY.md.

### Separate counterexample execution from protocol success

An observation task can complete with deliberate normative RED; a green-tracer expansion gate cannot represent that result honestly.

**Context:** Positive controls and the exact final assertion distinguish the two real failures from fixture/runtime errors. They remain correction inputs rather than passes.
**Source:** 171-03-PLAN.md; 171-03-SUMMARY.md; 171-REVIEW-FIX.md.

### Validate shapes before traversal and run the applicable lint gate

Nested malformed values need specific rejection fixtures; passing happy-path artifact checks does not establish validator quality.

**Context:** Independent review found crash paths and nine complexity violations. Guards, cohesive helpers, meaningful RED/GREEN fixtures and strict Credo closed all five findings without suppression or dependencies.
**Source:** 171-REVIEW-FIX.md; 171-REVIEW-FIX.iter2.md; 171-REVIEW-DISPOSITION.md.

### Claim only events actually observed

Unlaunched profiles cannot prove automatic overlap, interruption or cleanup behavior.

**Context:** The current claim was narrowed to the sequential operator procedure, the broader guarantee remains unverified, and a draft fixture rejects an impossible interrupted/unlaunched record.
**Source:** 171-04-SUMMARY.md; 171-02-PLAN.md; 171-VERIFICATION.md.

## Patterns

### Preserve an old observation before appending a new one

Keep original bytes, source and hashes in a dated archive; append a distinct new observation after a probe changes.

**When to use:** Tightening a qualification harness or repeating the same condition. Never relabel old execution with new source bytes.
**Source:** 171-REVIEW-FIX.md; 171-QUALIFICATION-PROBE-20261024T204101Z.json; 171-QUALIFICATION.json.

### Isolate semantic rejection from manifest drift

Use a draft fixture and require the specific validation error when testing malformed evidence; review final metadata before refreshing only affected hashes.

**When to use:** Self-checking evidence with an immutable manifest, including later intentional test changes. A generic nonempty error caused by stale hashes cannot prove the new predicate.
**Source:** 171-04-PLAN.md; 171-04-SUMMARY.md; 171-VALIDATION.md.

## Surprises

### Setup preflight did not establish the exact runner closure

The Mix preflight exited zero even though the separately checked exact Python interpreter and locked distributions were unavailable.

**Impact:** Both wrapper results remain null and no profile process or receipt is invented; environment readiness and protocol evidence remain separate.
**Source:** 171-02-SUMMARY.md.

### A plausible path was not a safe consent origin

The original probe recognized host consent by path prefix alone and could accept an off-origin URL.

**Impact:** Exact relative-route classification, interaction-fetch gating and synthetic hostile-origin checks were added before the fresh controlled observation.
**Source:** 171-REVIEW-FIX.md; 171-QUALIFICATION-PROBE.json.
