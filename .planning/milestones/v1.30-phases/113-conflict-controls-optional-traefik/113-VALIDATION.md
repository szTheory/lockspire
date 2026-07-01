---
phase: 113
slug: conflict-controls-optional-traefik
status: audited
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-04
audited: 2026-06-04
---

# Phase 113 - Validation Strategy

Per-phase validation contract for feedback sampling during execution and retroactive Nyquist audit.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus `docker compose config --format json` shell assertions |
| **Config file** | Existing `mix.exs`; Docker Compose contract assertions live in ExUnit |
| **Quick run command** | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` |
| **Full suite command** | `mix test.fast` |
| **Estimated runtime** | under 30 seconds for focused single-file quick feedback; under 10 seconds for current `mix test.fast` on this machine |

## Sampling Rate

- **After every task commit:** Run `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0`.
- **After every plan wave:** Run `mix test.fast` and the relevant `docker compose ... config --format json` proof commands.
- **Before `$gsd-verify-work`:** Full suite must be green, or any environmental blocker must be captured in the phase summary.
- **Max feedback latency:** under 30 seconds for focused single-file quick contract test feedback.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Test File | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-----------|--------|
| 113-01-T1 | 01 | 1 | CONFLICT-01 | T-113-01 | Default and overridden Compose project names render matching project-scoped volume names | contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | `test/lockspire/adoption_demo_docker_contract_test.exs` | COVERED |
| 113-01-T1/T2 | 01 | 1 | CONFLICT-02 | T-113-01 | Configured app port appears in host mapping, container `PORT`, base URL env, docs examples, and smoke command env | contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | `test/lockspire/adoption_demo_docker_contract_test.exs` | COVERED |
| 113-01-T1/T2 | 01 | 1 | CONFLICT-03 | T-113-02 | Default DB service has no host `ports`; opt-in config uses configured host port only | contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | `test/lockspire/adoption_demo_docker_contract_test.exs` | COVERED |
| 113-01-T3 | 01 | 1 | CONFLICT-04 | T-113-03 | Reset command targets only active project `db_data`, `deps_volume`, and `build_volume` | contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0`; `sh -n examples/adoption_demo/bin/docker-reset` | `test/lockspire/adoption_demo_docker_contract_test.exs` | COVERED |
| 113-02-T1/T2 | 02 | 2 | TRAEFIK-01 | T-113-05 | Default Compose model has no Traefik labels or external proxy network dependency | contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0`; `docker compose -f examples/adoption_demo/docker-compose.yml config --format json` | `test/lockspire/adoption_demo_docker_contract_test.exs` | COVERED |
| 113-02-T1/T2 | 02 | 2 | TRAEFIK-02 | T-113-06, T-113-07 | Optional Traefik mode renders configurable hostname, router, service, network labels, web-only proxy membership, and explicit service port | contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0`; Traefik override Compose render command | `test/lockspire/adoption_demo_docker_contract_test.exs` | COVERED |

## Automated Proof Commands

| Command | Result |
|---------|--------|
| `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | Passed on 2026-06-04: 11 tests, 0 failures |
| `docker compose -f examples/adoption_demo/docker-compose.yml config --format json >/tmp/lockspire-phase113-direct-validate.json` | Passed on 2026-06-04 |
| `LOCKSPIRE_DEMO_DB_HOST_PORT=15432 docker compose -f examples/adoption_demo/docker-compose.yml -f examples/adoption_demo/docker-compose.db-host.yml config --format json >/tmp/lockspire-phase113-db-host-validate.json` | Passed on 2026-06-04 |
| `LOCKSPIRE_DEMO_APP_PORT=4102 LOCKSPIRE_DEMO_BASE_URL=http://lockspire-alt.localhost LOCKSPIRE_DEMO_TRAEFIK_HOST=lockspire-alt.localhost LOCKSPIRE_DEMO_TRAEFIK_ROUTER=lockspire-alt-router LOCKSPIRE_DEMO_TRAEFIK_SERVICE=lockspire-alt-service LOCKSPIRE_DEMO_TRAEFIK_NETWORK=lockspire-alt-proxy docker compose -f examples/adoption_demo/docker-compose.yml -f examples/adoption_demo/docker-compose.traefik.yml config --format json >/tmp/lockspire-phase113-traefik-validate.json` | Passed on 2026-06-04 |
| `sh -n examples/adoption_demo/bin/docker-reset` | Passed on 2026-06-04 |
| `mix test.fast` | Passed on 2026-06-04: 1085 tests, 0 failures, 287 excluded |

## Gap Analysis

| Requirement | Coverage Status | Notes |
|-------------|-----------------|-------|
| CONFLICT-01 | COVERED | Tests assert default `lockspire-adoption-demo` and overridden project namespaces render matching volume names. |
| CONFLICT-02 | COVERED | Tests assert app port and `LOCKSPIRE_DEMO_BASE_URL` alignment, plus direct and Traefik smoke docs. |
| CONFLICT-03 | COVERED | Tests assert default DB has no host port and DB host exposure exists only through the opt-in override. |
| CONFLICT-04 | COVERED | Tests assert reset helper source scope and `sh -n` validates shell syntax. |
| TRAEFIK-01 | COVERED | Tests assert default Compose has no Traefik labels or `local-dev-proxy` dependency. |
| TRAEFIK-02 | COVERED | Tests assert configured Traefik labels, explicit backend service port, and web-only proxy network membership. |

No missing or partial automated coverage was found during this audit, so no additional test files were generated.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Optional Traefik browser smoke against a developer-owned external proxy network | TRAEFIK-01, TRAEFIK-02 | Local Traefik DNS/network state is developer-machine-specific and should not be required for CI | Follow the documented optional Traefik path, then run `LOCKSPIRE_DEMO_BASE_URL=http://lockspire-demo.localhost python3 scripts/demo/adoption_smoke.py` |

## Validation Audit 2026-06-04

| Metric | Count |
|--------|-------|
| Requirements audited | 6 |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Automated requirements covered | 6 |
| Manual-only behaviors retained | 1 |

## Validation Sign-Off

- [x] All tasks have automated verify commands or explicit manual-only rationale.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 draft placeholders were replaced with executed Plan 01/02 coverage.
- [x] No watch-mode flags.
- [x] Feedback latency under 30 seconds for focused single-file quick contract tests.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** audited 2026-06-04
