# Phase 136 Plan Check

**Checked:** 2026-08-27  
**Verdict:** PASSED after one planning correction

## Goal-backward result

Phase 136 succeeds only if four observable conditions hold: all library code stays inside strict Credo with only explained local exceptions; active admin/release proof checks current capabilities rather than historical macro/count archaeology; ordinary successful tests are quiet without suppressing explicit failure/redaction proof; and compile, QA/Credo, Dialyzer, ExDoc, package, and integration gates converge together.

The eleven plans cover those conditions end-to-end:

| Requirement | Covering plans | Executable end-state proof |
|---|---|---|
| QUAL-01 | 01–03, 11 | source classifier with synthetic violations, strict Credo, and zero-tolerance directive fitness |
| QUAL-02 | 01, 04–06, 11 | explicit `AdminProof`/`ReleaseProof` suites plus macro/history/count fitness |
| QUAL-03 | 01, 10–11 | readiness-aware KeyCache tests, telemetry lifecycle tests, and a successful-run noise checker |
| QUAL-04 | 01–03, 07–11 | warning-as-error compile, QA, zero-warning Dialyzer, ExDoc, package build, quiet fast run, and test integration |

## Planning correction applied

The initial convergence plan required an adjacent invariant reason for **every** remaining named Credo exception, but no task owned four existing named directives outside the JAR/DPoP cleanup paths. That would have made the permanent zero-violation fitness either fail or be weakened. Plan 11 now owns the complete residual named-directive audit and lists the five possible source locations; it must add the reason or remove a now-unnecessary directive before turning the predicate on.

The research open questions were also resolved at the planning boundary: test bootstrap deferral is determined by configured-repo process registration before the loader runs, never by classifying rescued storage exceptions; no project Dialyzer warning is permitted to become an ignore/suppression baseline.

## Dependency and wiring check

- The graph is acyclic: baseline (01) precedes parallel Credo/proof/runtime/lifecycle work; admin and token follow their owning seams; final convergence follows all producers.
- Same-wave `files_modified` sets are disjoint. Deliberate shared files are serialized (`AdminContractHelpers` 04 -> 05, token RFC 8693 03 -> 08, and runtime checker 10 -> 11).
- The security-sensitive refactors retain direct behavior proof: DPoP/JAR/request-object preserve literal public errors and fail-closed ordering; lifecycle/token repairs retain audit, atomicity, reuse revocation, and redaction; KeyCache defers only an unregistered configured repo and logs every ready-repo failure.
- Phase 137 work is explicitly excluded from both helper migration and convergence: no CI workflow restructuring, router-wide Sobelow policy, coverage aggregation, conformance inputs, published-artifact proof, or checksum work is planned.

## Nyquist check

All 22 implementation tasks include automated verification. Wave 1 creates the source/proof/runtime classifiers before dependent cleanup; later waves include focused behavioral tests at each protocol/storage/admin seam, and Plan 11 runs the complete converged command. No watch-mode command or suppressed-error comparison is planned.

## Non-blocking scope notes

- Plan 08 modifies eleven closely related token-grant files. Its three tasks are ordered from public facade to dead compatibility paths to issuance/refresh contracts, and it has prerequisite architecture/characterization proof; keep commits task-sized.
- Plan 11 now modifies eleven files. Its source changes are limited to explanatory comments or removal of stale directives, with the remaining work confined to permanent fitness and the final gate.

## Result

All requirements are represented in plan frontmatter and concrete tasks; task structure is valid; the responsibility map places source fixes in library/tooling, proof work in test helpers, and runtime quietness in test configuration/support; and no cross-plan data transformation conflict is present. Execution may proceed.
