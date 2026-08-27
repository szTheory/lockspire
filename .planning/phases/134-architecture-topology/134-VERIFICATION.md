---
phase: 134-architecture-topology
verified: 2026-08-27T18:21:46Z
status: gaps_found
score: 2/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "DCR and operator lifecycle workflows use one neutral client metadata and lifecycle service."
    status: failed
    reason: "The facades retain repository mutation and lifecycle/audit composition instead of delegating each lifecycle write to Lockspire.ClientLifecycle."
    artifacts:
      - path: "lib/lockspire/admin/clients.ex"
        issue: "Direct Repository.update_client/2, Repository.set_client_active/3, and Repository.rotate_client_secret/4 calls remain in the operator facade."
      - path: "lib/lockspire/protocol/registration_management.ex"
        issue: "rotate_registration_access_token/1 calls Repository.rotate_registration_access_token/3 directly."
      - path: "lib/lockspire/client_lifecycle.ex"
        issue: "It exposes only DCR create/replace/disable, direct persistence, and a generic transaction helper; it does not own the promised operator update/enable/secret-rotation or RAT-rotation operations."
    missing:
      - "Move every lifecycle write and its audit composition into explicit Lockspire.ClientLifecycle operations, leaving Admin.Clients and RegistrationManagement as boundary translators."
  - truth: "Architecture fitness tests reject dependency-direction, public/internal-boundary, and topology regressions."
    status: failed
    reason: "The ownership predicate only checks that each facade has at least one ClientLifecycle call and forbids Repository.transact/1 or append_audit_event/1. It accepts the current direct repository writes above, so it does not enforce the required neutral-lifecycle ownership boundary."
    artifacts:
      - path: "test/lockspire/architecture_fitness_test.exs"
        issue: "registration facades delegate writes inward test does not reject Repository.update_client/2, set_client_active/3, rotate_client_secret/4, or rotate_registration_access_token/3 in facades."
    missing:
      - "Add AST predicates and synthetic/production-source checks that reject direct lifecycle repository writes and duplicated mutation/audit composition in all four public facades."
---

# Phase 134: Architecture Topology Verification Report

**Phase Goal:** Lockspire's public module structure remains compatible while its runtime dependencies have an explicit, enforceable direction.
**Verified:** 2026-08-27T18:21:46Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Maintainers can run a dependency check that reports no runtime/export cycles while existing nested public module names continue working. | ✓ VERIFIED | `sh scripts/ci/check_architecture_topology.sh` and direct `mix xref graph --format cycles` both report `No cycles found`; `CompatibilityBaselineContractTest` passes against the literal `76cf872` export/struct baseline. |
| 2 | Protocol code reaches only neutral core/application and storage ports, never Phoenix delivery or operator-admin code. | ✓ VERIFIED | All protocol production sources passed the AST outer-reference check. Manual dynamic-edge review found only configured neutral route capability invocation and internal public-result adapters; no runtime Web/Admin/DiscoveryRoutes target is constructed. |
| 3 | DCR and operator workflows use one neutral client metadata and lifecycle service without changing public result shapes or security behavior. | ✗ FAILED | Public shapes/security tests pass, but `Admin.Clients` and `RegistrationManagement` still directly mutate `Repository`; `ClientLifecycle` does not own all promised lifecycle operations. |
| 4 | Fitness tests reject dependency-direction, public/internal-boundary, and topology regressions. | ✗ FAILED | The topology, public-surface, and outer-direction portions are executable and green, but the ownership test admits the direct lifecycle writes in the current production facades. |

**Score:** 2/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/ci/check_architecture_topology.sh` | Deterministic zero-cycle command | ✓ VERIFIED | Runs `mix xref graph --format cycles`, prints its output, and fails on reported cycles. |
| `test/lockspire/architecture_fitness_test.exs` | Permanent direction/ownership invariants | ⚠️ PARTIAL | Direction and cycle-adjacent invariants work; ownership enforcement is incomplete. |
| `test/support/architecture/public_compatibility_manifest.ex` | Literal public compatibility baseline | ✓ VERIFIED | Enumerates affected facades/helpers and nine exact structs; test compares loaded functions/keys rather than deriving expected values. |
| `lib/lockspire/client_metadata.ex` | Neutral metadata operations | ✓ VERIFIED | Both direct/DCR and admin/registration callers use shared logout/readiness primitives without exposing it as a supported surface. |
| `lib/lockspire/client_lifecycle.ex` | Neutral lifecycle ownership | ✗ PARTIAL | Owns DCR create/replace/delete and a generic transaction helper, but not the operator/RAT write operations claimed by Plan 02. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| `Registration` | `ClientLifecycle` | DCR creation | ✓ WIRED | `ClientLifecycle.create_dcr/1` is called after policy/metadata processing. |
| `RegistrationManagement` | `ClientLifecycle` | DCR replace/delete | ✓ WIRED | `replace_dcr/3` and `disable_dcr/1` are called; RAT-only rotation still bypasses it. |
| `Admin.Clients` | `ClientLifecycle` | Operator lifecycle commands | ⚠️ PARTIAL | Calls the generic transaction helper and DCR create, but retains direct repository mutation for update, enable, secret rotation, and disable. |
| Web discovery controller | `Protocol.Discovery` | Resolved path collection | ✓ WIRED | The controller supplies route paths; public zero-arity discovery resolves a configured neutral capability. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Zero runtime/export cycles | `sh scripts/ci/check_architecture_topology.sh` | `No cycles found` | ✓ PASS |
| Architecture and compatibility fitness | `mix qa.architecture` | 12 tests, 0 failures | ✓ PASS |
| Lifecycle/public contract characterization | `mix test test/lockspire/client_lifecycle_test.exs test/lockspire/admin/clients_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/compatibility_baseline_contract_test.exs` | 76 tests, 0 failures | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| ARCH-01 | 03–11 | Executable zero-cycle check with retained public names | ✓ SATISFIED | Topology script and literal export/struct test pass. |
| ARCH-02 | 01–06, 11 | Protocol only depends inward, not on Web/Admin | ✓ SATISFIED | Production AST scan and manual dynamic-edge trace are clear. |
| ARCH-03 | 01–02, 11 | One neutral metadata/lifecycle owner for DCR and operator workflows | ✗ BLOCKED | Facades still own direct lifecycle persistence operations. |
| ARCH-04 | 11 | Fitness rejects topology/direction/boundary regressions | ✗ BLOCKED | Ownership gate has a false negative on current production source. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| `lib/lockspire/admin/clients.ex` | 149, 224, 793, 811 | Direct lifecycle repository writes | 🛑 Blocker | Violates the neutral ownership boundary. |
| `lib/lockspire/protocol/registration_management.ex` | 138 | Direct RAT-rotation repository write | 🛑 Blocker | Leaves a DCR lifecycle mutation outside the neutral owner. |
| `test/lockspire/architecture_fitness_test.exs` | 58–85 | Facade ownership check too weak | 🛑 Blocker | CI accepts the architecture regression it is meant to prevent. |

### Gaps Summary

The graph work, public compatibility baseline, and protocol delivery-direction work are real and passing. The phase cannot complete because its central neutral-lifecycle ownership promise is only partially extracted and its permanent fitness test fails to detect that fact. This is not deferred: ARCH-03 and ARCH-04 are explicit Phase 134 requirements.

---

_Verified: 2026-08-27T18:21:46Z_
_Verifier: the agent (gsd-verifier)_
