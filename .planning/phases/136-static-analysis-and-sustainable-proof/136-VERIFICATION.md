---
phase: 136-static-analysis-and-sustainable-proof
verified: 2026-08-27T21:45:25Z
status: gaps_found
score: 2/4 must-haves verified
behavior_unverified: 1
overrides_applied: 0
gaps:
  - truth: "Admin and release proof expresses capabilities and behavior without giant injected macros, assertion-count contracts, or obsolete phase history."
    status: failed
    reason: "An active admin stress-proof suite still carries Phase 124/125 terminology in its public test metadata, helper names, source-path list, rendered attributes, and test names. The new inventory predicate only scans three small contract suites, so it does not enforce the roadmap contract across active admin proof."
    artifacts:
      - path: test/lockspire/web/live/admin/design_system_component_stress_test.exs
        issue: "Lines 16, 45, 53, 149, 156, 163, 371, 395, 494, and 583 retain @phase_124/@phase_125 identifiers and Phase 124 labels in active proof."
      - path: test/lockspire/quality/proof_quality_baseline_test.exs
        issue: "The permanent proof scan recognizes only File.read!(@phase_...) archaeology, not phase-numbered identifiers or labels in active admin/release proof."
    missing:
      - "Rename the stress-proof helpers, fixture classifications, test labels, and rendered data attributes around present capabilities rather than historical phase numbers."
      - "Extend permanent proof fitness to reject phase-numbered APIs/labels throughout the active admin and release proof scope, not only three contract suites."
behavior_unverified_items:
  - truth: "Focused integration proof remains green during structural work."
    test: "Run MIX_ENV=test mix test.integration with a test PostgreSQL instance that accepts new connections."
    expected: "The integration suite completes successfully after test.setup, without the external database-capacity failure."
    why_human: "This audit's isolated invocation failed before test execution because PostgreSQL returned FATAL 53300 (too_many_connections); source inspection cannot establish the runtime integration result."
---

# Phase 136: Static Analysis and Sustainable Proof Verification Report

**Phase Goal:** Maintainers can trust concise, behavior-focused quality evidence and read the codebase without avoidable noise or archaeology.
**Verified:** 2026-08-27T21:45:25Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Credo evaluates every library source file, and each remaining suppression is local, named, and justified. | ✓ VERIFIED | `mix test` quality/architecture fitness passed (14 tests); `bash scripts/ci/run_credo.sh` analyzed 554 sources with no findings. The current eight `lib/` directives are all `disable-for-next-line`, name one check, and have an adjacent invariant comment. |
| 2 | Admin and release proof expresses current capabilities without giant injected macros, assertion-count contracts, or obsolete phase history. | ✗ FAILED | The macro/count contract is removed from the extracted admin/release suites, but active `design_system_component_stress_test.exs` still contains phase-numbered API and presentation archaeology. |
| 3 | Successful routine test runs have no KeyCache startup errors, Ecto query flood, or local telemetry-handler warnings while failure and redaction assertions still work. | ✓ VERIFIED | `bash scripts/ci/check_test_runtime_noise.sh --focused` passed. It executes KeyCache, repository, JARM, device authorization, and DCR redaction tests and rejects all three forbidden diagnostic classes. `KeyCache` explicitly defers only a not-ready repository and still reports ready-repository storage failures. |
| 4 | Compilation, strict Credo, zero-warning Dialyzer, ExDoc, package build, and focused integration proof remain green. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Compilation, `mix qa`, zero-warning `mix qa.dialyzer`, `mix docs.verify`, and `mix package.build` passed in this audit. The required integration command could not start because the shared PostgreSQL server rejected connections with `FATAL 53300 (too_many_connections)`. |

**Score:** 2/4 truths verified (1 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `test/support/quality_baseline.ex` | Source/proof/runtime classifier | ✓ VERIFIED | Substantive structured scans for Credo directives, proof constructs, Dialyzer output, and runtime diagnostics; imported by all three quality suites. Its archaeology predicate is too narrow, which is recorded as the blocking gap. |
| `lib/lockspire/protocol/dpop/proof_parser.ex` | Cohesive DPoP parsing | ✓ VERIFIED | 94-line parser is imported and called by the public DPoP coordinator for decode, header JWK, and thumbprint boundaries. |
| `lib/lockspire/protocol/dpop/proof_verifier.ex` | DPoP verification | ✓ VERIFIED | 164-line verifier supplies typ, signature, claim, nonce, and sender-binding checks through the public coordinator. |
| `test/support/lockspire/web/admin_proof/*.ex` | Small admin capability helpers | ⚠️ PARTIAL | Helpers are substantive and explicitly aliased by current CSS/route/redaction suites, but the active stress proof retains phase-numbered archaeology outside their fitness scope. |
| `test/support/lockspire/release_proof/*.ex` | Small release capability helpers | ✓ VERIFIED | Workflow, package, and documentation helpers are substantive and explicitly called by the three release contract suites. |
| `test/support/telemetry_capture.ex` | Remote telemetry capture lifecycle | ✓ VERIFIED | Uses a unique handler ID, module-qualified callback, and `on_exit` detach; DCR source calls `TelemetryCapture.attach_many`. |
| `scripts/ci/check_test_runtime_noise.sh` | Routine-run noise gate | ✓ VERIFIED | Runs focused or fast suites through a private temp file, fails on the three noise categories, redacts failure output, and cleans up with a trap. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `DPoP` | `ProofParser` / `ProofVerifier` | Explicit aliases and calls in `validate_proof/2` | ✓ WIRED | Parser result flows into typ/JWK/signature/claim verification before the public `%DPoP{}` result is constructed. |
| Request-object coordinator | `Jar`, `Retrieval`, `Claims` | Explicit aliases and typed pipeline | ✓ WIRED | Retrieval → decrypt → decode/verify → validate → project is connected in `consume/3`. |
| Admin CSS/route/redaction suites | Capability helpers | Explicit aliases/calls | ✓ WIRED | Contract tests call `CssAssertions`, `RouteAssertions`, and `RedactionAssertions` directly; no injected macro remains. |
| Release suites | Capability helpers | Explicit aliases/calls | ✓ WIRED | Release automation, hygiene, and supported-surface tests call workflow, package, and documentation helpers directly. |
| Quality source policy | Strict Credo script | Shared repository scans plus CI script | ✓ WIRED | Quality fitness passed, then `run_credo.sh` independently parsed all 554 configured sources. |
| `Application` | `KeyCache` | Child spec with configured options | ✓ WIRED | Application starts `KeyCache`; cache state receives repository/readiness/loader options and schedules only deferred bootstrap refreshes. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Permanent source/proof/noise/architecture fitness | `mix test test/lockspire/quality/source_quality_baseline_test.exs test/lockspire/quality/proof_quality_baseline_test.exs test/lockspire/quality/runtime_noise_baseline_test.exs test/lockspire/architecture_fitness_test.exs` | 14 tests, 0 failures | ✓ PASS |
| Strict Credo visibility | `bash scripts/ci/run_credo.sh` | 554 sources, no issues | ✓ PASS |
| Quiet focused runtime while negative evidence runs | `bash scripts/ci/check_test_runtime_noise.sh --focused` | Passed | ✓ PASS |
| Compile, QA, Dialyzer, docs, package | `mix compile --warnings-as-errors && mix qa && mix qa.dialyzer && mix docs.verify && HEX_API_KEY= mix package.build` | Passed; Dialyzer: `Total errors: 0, Skipped: 0, Unnecessary Skips: 0` | ✓ PASS |
| Focused integration | `MIX_ENV=test mix test.integration` | Failed before suite start: PostgreSQL `FATAL 53300 (too_many_connections)` | ? ENVIRONMENT BLOCKED |

### Probe Execution

No Phase-136 probe was declared and no conventional `scripts/*/tests/probe-*.sh` file exists.

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
| --- | --- | --- | --- |
| QUAL-01 | 01, 02, 03, 11 | ✓ SATISFIED | Full Credo source visibility and local named/reasoned directives are proven by quality fitness plus the strict 554-source Credo run. |
| QUAL-02 | 01, 04, 05, 06, 11 | ✗ BLOCKED | Current helper extraction is real, but Phase 124/125 archaeology remains in an active admin proof suite and the permanent scanner misses it. |
| QUAL-03 | 01, 10, 11 | ✓ SATISFIED | The focused successful-run script passed while exercising KeyCache and redaction/telemetry paths. |
| QUAL-04 | 01, 02, 03, 07, 08, 09, 10, 11 | ? NEEDS HUMAN | All static/document/package gates passed; the only missing runtime evidence is the integration suite, which was prevented by database capacity rather than a test assertion. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `test/lockspire/web/live/admin/design_system_component_stress_test.exs` | 16, 45, 53, 149, 156, 163, 371, 395, 494, 583 | `@phase_124` / `@phase_125` names and Phase 124 labels in active stress proof | 🛑 BLOCKER | Retains obsolete phase archaeology in the exact admin proof area QUAL-02 promises to make capability-oriented. |
| `test/lockspire/quality/proof_quality_baseline_test.exs` | 34-37 | Synthetic scan covers only `File.read!(@phase_...)` archaeology | ⚠️ WARNING | The permanent gate falsely passes despite phase-numbered active proof because its predicate does not cover that form. |

### Human Verification Required

### 1. Focused integration after database capacity is available

**Test:** Run `MIX_ENV=test mix test.integration` after freeing or increasing the shared test PostgreSQL connection capacity.

**Expected:** The suite creates the test repository and completes green.

**Why human:** The verifier observed an external `too_many_connections` refusal before integration tests ran; static code inspection cannot replace runtime integration evidence.

### Gaps Summary

Phase 136 does not meet its roadmap goal yet. The extracted helpers and all major static gates are real, but the active admin stress proof still exposes exactly the historical phase archaeology the phase says it removes. The current zero-tolerance scanner is a misleading passing test because it scans only a limited representation of archaeology. Repair the active stress proof and widen the permanent proof predicate, then rerun verification after PostgreSQL capacity permits the integration suite.

---

_Verified: 2026-08-27T21:45:25Z_
_Verifier: the agent (gsd-verifier)_
