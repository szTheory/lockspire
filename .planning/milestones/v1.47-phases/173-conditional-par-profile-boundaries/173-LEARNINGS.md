---
phase: 173
phase_name: "Conditional PAR & Profile Boundaries"
project: "Lockspire"
generated: "2026-10-24"
counts:
  decisions: 2
  lessons: 3
  patterns: 2
  surprises: 1
missing_artifacts: ["173-UAT.md"]
---

# Phase 173 Learnings

## Decisions

### Keep stored PAR parameters authoritative

Remove the blanket outer-parameter rejection, reuse fresh stored-only reconstruction, and preserve current policy and bound one-use consumption. No merge abstraction or dependency is needed.

**Source:** 173-CONTEXT.md D-01–D-03; 173-01-SUMMARY.md; 173-SECURITY.md.

### Give reviewed prohibitions their actual verification tier

After scoped independent judgment exists, resolve the lifecycle to resolved/judgment. Retain prominent non-authoritative human-review recommendations under the documented autonomous soft-gate. Do not invent human confirmation, a mechanical test or universal proof.

**Source:** 173-DISPOSITIONS.md lifecycle resolution; preserved initial report commit fb22445b; 173-VERIFICATION.md; canonical prohibition-probe.md and verifier Step 2b.

## Lessons

### Positive controls need independent one-use references

The valid reference-only request must complete before a separately pushed conflicting candidate. Reusing the first consumed reference would create replay failure instead of reproducing parameter authority. Assert persisted client/scopes/state/nonce and an exact relative consent route.

**Source:** 173-01-PLAN.md; Phase15 integration regression; 173-01-SUMMARY.md.

### Compare the media type exactly, allowing parameters

JSON Content-Type may include charset; strict full-string equality is too narrow and a prefix check accepts application/jsonp. Split parameters and compare the base media type. Review caught this and the final 132-test run passed after selective test-identity audit.

**Source:** 173-REVIEW.md; 173-REVIEW-FIX.md; 173-01-SUMMARY.md.

### Favorable review evidence does not update a lifecycle enum

The first verifier correctly preserved unresolved prohibition items despite favorable scoped evidence. The smallest fix was a canonical resolved/judgment lifecycle with explicit autonomous flags, followed by independent report regeneration. A separate disposition document alone was insufficient. Adding another test framework or fabricating human approval would not solve the classification error honestly.

**Source:** 173-DISPOSITIONS.md; initial report fb22445b; lifecycle commit b586d20f; regenerated verification.

## Patterns

### Keep original observations and reviewed final inputs separate

Original identical-test RED/GREEN hashes remain intact when a later test assertion improves. Append only the owned test identity/digest audit and record final bytes separately. SDK completion's roadmap edits receive their own audit and verification-owner regeneration.

**Source:** 173-01-SUMMARY.md; 173-REVIEW-FIX.md; canonical171ledger input_manifest_audits.

### Classify the gate before asking for intervention

Distinguish a real behavioral human-only check from a non-authoritative judgment recommendation and from an unresolved automatic declaration. Resolve routine delegated choices through the documented mode-specific rule, retain flags and let the independent verifier own the verdict.

**Source:** 173-DISPOSITIONS.md; 173-VERIFICATION.md.

## Surprises

### Generic and autonomous routing prose can appear contradictory

The verifier contract's generic flagged-item route and specific autonomous judgment soft-gate initially produced a stop. Reading both the canonical lifecycle model and the mode-specific rule with the planner resolved it without changing runtime code or suppressing the review recommendation.

**Source:** 173-DISPOSITIONS.md; canonical prohibition-probe.md judgment tier; verifier Step 2b versus Step 9.
