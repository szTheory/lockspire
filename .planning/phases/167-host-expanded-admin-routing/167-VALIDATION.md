---
phase: "167"
slug: "host-expanded-admin-routing"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-22"
---

# Phase 167 — Validation Strategy

Planning contract; no new implementation test or forwarded-join reproduction is claimed by this file.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit, Phoenix.LiveViewTest, Phoenix Router introspection |
| Config file | mix.exs; config/test.exs |
| Runtime | ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec |
| Quick run command | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/web/live/admin/admin_route_integration_test.exs` |
| Existing baseline command | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/web/live/admin/admin_liveview_runtime_contract_test.exs` |
| Full suite command | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test.fast` |
| Final format command | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix format --check-formatted` |
| Estimated runtime | Measure during execution; focused feedback target under 30 seconds after compilation |

## Sampling Rate

- After every implementation task, run its focused automated checks; the new integration file must be created by its first owning task before it is invoked.
- After every wave, run the focused integration file and the existing admin runtime contract test; run `mix test.fast` before phase verification.
- Every runnable task command must have a following `<fails_when>` naming a non-zero exit or another observable failed assertion.
- Do not equate lifecycle test success with browser transport or exact supported-floor proof; those belong to Phase 170.

## Per-Task Verification Map

Final plan/task mapping. Every task has a real automated command followed immediately by its observable failure condition in the PLAN. These commands are planned execution gates, not claimed runtime results.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 167-01-01 | 167-01 | 1 | MNT-01, MNT-02, MNT-03, MNT-04 | T-167-01, T-167-02, T-167-03, T-167-04, T-167-SC | Fresh precise forward-only failure before replacement; actual native default connected tracer; immediate host HTTP/disconnected/connected hook rejection and required metadata | router/connected | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/web/live/admin/admin_route_integration_test.exs` | New; created by this task | pending |
| 167-01-02 | 167-01 | 1 | MNT-01, MNT-02, MNT-03, MNT-04 | T-167-01, T-167-02, T-167-03, T-167-04, T-167-SC | Compile-time required wiring, native option/session/hook order, scope composition, normalization and HTTP/on_mount config mismatch refusal | compile/config/integration | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/web/admin_routes_compile_test.exs test/lockspire/config_test.exs test/lockspire/web/live/admin/admin_route_integration_test.exs` | Compile test new in this task; others tracked or 167-01-01 | pending |
| 167-02-01 | 167-02 | 2 | MNT-01, MNT-02, MNT-03 | T-167-05, T-167-06, T-167-07, T-167-08, T-167-SC | Default/nested/root and both root config forms connect; fresh rejoin has distinct process and required current-identity hook | connected lifecycle | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/web/live/admin/admin_route_integration_test.exs` | Created by 167-01-01 | pending |
| 167-02-02 | 167-02 | 2 | MNT-01, MNT-02, MNT-03 | T-167-05, T-167-06, T-167-07, T-167-08, T-167-SC | All 29 routes connect at three effective mounts; links/queries/tasks/patches/redirects retain prefix; stable-config concurrent views remain separate | connected journeys | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/web/live/admin/admin_route_integration_test.exs` | Created by 167-01-01 | pending |
| 167-03-01 | 167-03 | 3 | MNT-01, MNT-03 | T-167-09, T-167-SC | Independent literal ordered 29-route baseline and every concrete route/view/action/session/pipeline/hook selection; boundaries and repetition/concurrency | compiled router | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/web/admin_route_inventory_test.exs test/lockspire/web/admin_router_test.exs` | Inventory test new in this task; router test tracked | pending |
| 167-03-02 | 167-03 | 3 | MNT-01, MNT-03, MNT-04 | T-167-10, T-167-11, T-167-SC | Admin-before-forward and independent anonymous public/host-consent access, including concurrent surface provenance; focused final gates | host integration | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/web/admin_route_separation_test.exs test/lockspire/web/admin_route_inventory_test.exs test/lockspire/web/admin_routes_compile_test.exs test/lockspire/web/live/admin/admin_route_integration_test.exs test/lockspire/web/live/admin/admin_liveview_runtime_contract_test.exs test/lockspire/config_test.exs` | Separation test new in this task; others earlier/tracked | pending |

ASVS 5.0.0 level L1; high/critical findings block. Threat IDs T-167-01 through T-167-11 are unique across plans; reserved T-167-SC is repeated intentionally. No package install, schema change or private Phoenix join patch is planned.

If the lifecycle file exceeds 30 seconds after compilation, execution must add deterministic mount/journey ExUnit tags, run each bounded selection and record the complete union. The final test.fast suite is a phase gate, outside the focused feedback budget. All final phase gates (format, test.fast and diff hygiene) are owned by 167-03-02 and must record actual outcomes.

## Wave 0 Requirements

- Task 167-01-01 creates `test/lockspire/web/live/admin/admin_route_integration_test.exs` and `test/support/lockspire/web/admin_route_host.ex` within the leading production-quality tracer; no expansion task starts before verified native success.
- Preserve a forward-only fixture and freshly record the expected connected failure before implementing the replacement; unrelated setup errors do not count as reproduction.
- Task 167-01-02 creates the compile contract file; 167-03-01 creates the independent inventory file; 167-03-02 creates the surface-separation file, each before its command is used.
- Use existing endpoint/session, RepoCase and LiveViewTest infrastructure; introduce no new test framework or runtime dependency.
- Serialize tests that change application mount configuration and restore it with on_exit.

## Probe and Assumption Ledger

- Spec-less fallback: 10 surfaced edge rows = 9 explicit must-have predicates + 1 flagged unresolved assumption. MNT-01 adjacency/empty/ordering and MNT-03 idempotency map to 167-01-02; MNT-03 empty/adjacency/ordering/concurrency to 167-03-01; MNT-04 concurrency to 167-03-02. MNT-02/unclassified remains A-167-MNT-02 in Plan 02, never falsely auto-resolved.
- Prohibition recall/precision: 2 retained bespoke items = 2 descriptor-less must_haves.prohibitions projections (host ownership in Plan 01; truthful evidence boundaries in Plan 02). Both remain flagged-unverified; no wired descriptor is invented. Canon security concerns refer to STRIDE/ASVS and the independent security workflow.
- Assumption-delta chosen/custom signal: primary identity remains the single configured host mount; decision no-change. No multi-mount/tenant/proxy expansion.
- UI gate: frontend:true, hasFrontendEvidence:false, block:false for routing-only scope. No UI-SPEC or subjective manual visual gate is required.

## Manual-Only Verifications

None required. Acceptance is mechanical and automated; no visual signoff. Full authorization denial behavior belongs to Phase 168; generated install/upgrade and diagnostic convergence to Phase 169; candidate package, browser transport and exact-version CI proof to Phase 170.

## Validation Sign-Off

- [ ] Every final task is mapped to its automated check and relevant threat IDs.
- [ ] No three consecutive tasks lack automated feedback.
- [ ] New test paths are created before first use; no watch-mode checks.
- [ ] Forwarded failure and canonical success are distinguished from transport proof.
- [ ] Final execution evidence is recorded; nyquist_compliant remains false until validated.

**Approval:** Planning contract only; implementation results pending.
