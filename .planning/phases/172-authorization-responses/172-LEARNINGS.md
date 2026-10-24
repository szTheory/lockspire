---
phase: 172
phase_name: "Authorization Responses"
project: "Lockspire"
generated: "2026-10-24"
counts:
  decisions: 1
  lessons: 3
  patterns: 1
  surprises: 1
missing_artifacts: ["172-UAT.md"]
---

# Phase 172 Learnings

## Decisions

### Reuse the existing protocol disposition

One private unsupported-mode branch now selects browser_error/3. The existing controller and escaped HTML deliver HTTP 400, while PAR normalization retains JSON. No dependency or renderer abstraction was needed.

**Source:** 172-01-SUMMARY.md; 172-SECURITY.md; 172-VERIFICATION.md.

## Lessons

### Prove the neighboring valid request first

The controller fixture did not include openid. A scoped OIDC client and restored known-scopes value made the exact nonce/state/S256 request valid without changing the host resolver. Its query control passed before the candidate reproduced 302 versus required 400.

**Source:** 172-01-PLAN.md; 172-01-SUMMARY.md.

### JSON bytes alone do not establish a JSON response

The first PAR preservation test decoded the body but omitted Content-Type. Independent review caught the gap; the explicit application/json assertion passed in the 131-test regression run.

**Source:** 172-REVIEW.md; 172-REVIEW-FIX.md.

### Mutable planning metadata needs an explicit provenance step

The frozen roadmap selector includes plan counts and checkboxes. Planning and SDK completion each intentionally change its hash. Audit only reviewed entries and rerun the ledger contract; never refresh unrelated inputs. Completion's selective audit passed 22 ledger tests and requires verification-owner regeneration because covered input bytes changed.

**Source:** 172-01-SUMMARY.md; canonical 171-QUALIFICATION.json input_manifest_audits; 172-DISPOSITIONS.md.

## Patterns

### Source-bound RED/GREEN with unchanged historical qualification

Keep the original probe intact and record actual new source, test hashes, valid control, assertion failure and post-fix pass in the implementation summary. A temporary report-format adapter may translate actual evidence for a tool, while the raw assertion remains authoritative.

**Source:** 172-01-SUMMARY.md; 172-VERIFICATION.md.

## Surprises

### The generic RED classifier did not parse ExUnit console output

A temporary trace-to-TAP adapter classified the actual named failure. It added no persistent dependency or testing framework; raw ExUnit result and exact identities remain recorded.

**Source:** 172-01-SUMMARY.md.
