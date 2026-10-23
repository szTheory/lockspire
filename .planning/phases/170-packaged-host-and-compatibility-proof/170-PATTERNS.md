# Phase 170 — Implementation Patterns

Inline mapping at acda9da47b141978a2a05c2ac795058257f93888. Read the named analog before editing; this mapping is not runtime evidence.

| New/modified file | Closest existing analog | Reuse / data flow |
|---|---|---|
| scripts/acceptance/clean_room_admin_journey.py | clean_room_saas_journey.py; clean_room/processes.py | prepare_package → prepare_provider → migrate/start → browser → strict safe receipt → owned cleanup; separate runner keeps OAuth journey unchanged |
| scripts/acceptance/clean_room/admin_receipts.py | clean_room/lifetime_receipts.py | exact schema/case sets, source/candidate binding, atomic output and strict independent validation |
| test/clean_room/provider_host/admin_proof.exs | provider_host operator deny seam; examples/adoption_demo host endpoint/root/JS; test/support/lockspire/web/admin_route_host.ex | explicit host-owned synthetic policy/counters; root layout + dependency assets; install emitted helper once; test support analogy must never be imported by packaged child |
| scripts/acceptance/clean_room/build_provider.py | existing prepare_provider, write_host_runtime, audit_boundary | opt-in keyword parameters; retain default deny behavior, immutable vendor inventory, compile binding and check-locked resolution |
| test/browser/packaged_admin_proof.mjs + _test.mjs | admin_route_proof.mjs + _test.mjs | Node built-ins, local-only target, bounded child commands, allowlisted observations; replace screenshot workflow with CDP connection assertions |
| test/clean_room/test_admin_journey.py | Python self-test patterns exercised by clean_room_release_source_contract_test.exs | standard-library unittest for receipt/provenance/cleanup/failure paths; no live secrets printed |
| compatibility/.../mix.exs + mix.lock | existing exact floor fixture; provider_host/mix.exs | exact pins, reused Bandit/lazy_html only, isolated build/deps paths and immutable verification locks |
| compatibility/.../test/test_helper.exs + admin_host_runtime_test.exs | root test/test_helper.exs and existing route/integration tests | require the same four root tests plus narrow support modules under the floor runtime; do not copy tests or claim package proof |
| scripts/ci/run_host_integration_proof.sh | scripts/ci/run_test_matrix.sh | set -euo pipefail, explicit modes, finite commands, independent receipt validation, preserve exit status |
| .github/workflows/ci.yml | current Integration Checks and Minimum Supported Elixir/OTP | retain required jobs/triggers, pinned actions/Postgres; add exact pair invocation and validated SHA-bound receipt upload |
| docs/supported-surface.md; docs/maintainer-release.md | existing evidence-type and release boundary descriptions | exact commands, matrix, evidence limits, separate local/remote outcomes; no public API/copy redesign |

## Interfaces to preserve

- `prepare_provider(..., package_root=..., candidate_identity=...)` remains keyword-compatible with every existing caller. New proof options default to inactive.
- `verify_candidate_host` runs before Mix loads a reusable child; `bind_compiled_candidate` binds compiled bytes after final host setup. Proof overlays never modify vendor library bytes.
- `lockspire_routes/0` emitted by the package remains the only integration entry point. Native route inventory belongs to `Lockspire.Web.AdminRoutes`.
- Default generated OperatorAuthorization always denies. Successful proof is a deliberately configured disposable host implementation, never a generator change.
- Node sees only loopback origin + fixture control capability; receipts contain counts/enums/version/hash identity, not the underlying signed sessions or frames.
- All receipts cross the same Python validator before retention/upload. Node raw observations are transient inputs, not an independently uploadable artifact format.
