# Phase 167 — Execution Gates

## Wave 1

- Source: `43a838b1` (after the compatibility and compiled-route assertion repair).
- Plan task commits: `f8648603`, `866baa35`; summary: `c80e40ee`; bounded regression repair: `43a838b1`.
- Focused repair selection: 39 tests passed (executor evidence in 167-01-SUMMARY.md).
- Broad gate: `LOCKSPIRE_TEST_DB_NAME=lockspire_phase167_20261022_1754 ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test.fast`.
- Broad gate result: exit 0, 154.0 seconds; **1945 passed (2 properties, 1943 tests), 6 skipped, 497 excluded**.
- The first sandboxed broad attempt was stopped after observed failures; nested `mix hex.info` could not persist `/Users/jon/.hex/cache.ets` (`:eaccess`). The rerun used normal cache access.
- A completed run on the pre-existing shared test database had 13 count/empty-state failures, consistently showing two additional apps. The fresh phase-specific database run above passed without deleting or changing the shared database. No claim is made that the contaminated shared-database run passed.
- Wave hooks: schema drift false; no codebase map to compare (advisory skipped); UI safety gate reports no UI files/spec requirement and block false.
- First two created artifacts exist; summary has no failed self-check marker; plan-scoped commits are reachable on the existing branch; original `.planning/state.json` bytes verified unchanged.

The execution uses one temporary phase-specific test database for reproducible later gates. No browser transport, package or exact supported-floor evidence is claimed; those remain Phase 170.

## Wave 2

- Plan commits: `b8c101c2`, `2305106b` (RED), `680d33c3` (GREEN), `55f2f7ff`; summary: `d3bda9dc`.
- Focused connected lifecycle file: 12 tests passed; combined compile/config/integration/unchanged-runtime checks: 34 tests passed (executor evidence in 167-02-SUMMARY.md).
- Default, nested and root mount entry, root aliases, trailing separators, action/task navigation and fresh distinct-process joins are covered.
- Observed guard bugs required plan-owned source extensions: descendant routes were mistaken for the admin base; ambiguous suffix `/policies/dcr` selected `/dcr`. The regression records the latter RED before the longest-matching-suffix GREEN correction.
- Schema/UI wave hooks remain nonblocking with no drift or design requirement; no codebase map exists to compare. Plan-scoped commits and summary were reconciled on the original branch; original state.json bytes preserved.
- The serial broad test gate is repeated after the final plan; this wave's immediate feedback is the bounded 34-test selection.

## Wave 3 and Security Proof Repair

- Task commits: `3b5ea0e1`, `090661cc` (RED), `7e242aee` (GREEN); summary `8104bdb9`.
- Independent full ordered 29-route parity and actual selection, public/admin/consent precedence, connected callback isolation and concurrent surface checks passed.
- Focused phase union: 43 tests passed; format and diff checks passed.
- Final broad suite at source `7e242aee`: exit 0, 114.1 seconds; **1961 passed (2 properties, 1959 tests), 6 skipped, 497 excluded** using the same isolated database/runtime.
- Security audit found one narrow evidence gap in planned T-167-01: a LiveViewTest denial during disconnected rendering did not independently prove host-hook denial with a connected socket. Test-only commit `a45dc1ee` adds explicitly disconnected/connected callback assertions for missing and deleted identities, halt/sign-in redirect, observer and mount-sentinel behavior; integration file **13 tests passed**. This is not a real transport claim.
- Security re-audit at `a45dc1ee`: **12/12 planned threats closed; threats_open: 0**. No production code changed after the successful final broad suite.

## Post-Execution Audits

- Nyquist validation: all four requirements and six task checks are implemented and green; no missing automated requirement coverage. VALIDATION.md is validated and compliant.
- Security: independent L1 re-audit closed all twelve planned threats at a45dc1ee; no accepted risks were inferred.
- Standard code review: all thirteen changed source/test files reviewed, including compatibility manifest and legacy assertion repairs; zero critical, warning or info findings.
- UI review: not applicable to this phase's explicit routing-only scope; no UI files, design deliverable or subjective signoff. Deterministic UI safety gates returned block false.
- Prior-phase regression selection: this is the first phase in v1.46. Historical active-directory Phase 142/143 evidence is not a prior phase in this milestone and was not reopened. The broad test.fast result above supplies repository-wide regression evidence.
- The custom historical finalizer predicate passes for Phase 167 without running the Phase 139 finalizer.
