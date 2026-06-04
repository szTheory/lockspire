---
phase: 113
slug: conflict-controls-optional-traefik
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 113 - Validation Strategy

Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus `docker compose config --format json` shell assertions |
| **Config file** | Existing `mix.exs`; no dedicated Compose test config exists |
| **Quick run command** | `mix test test/lockspire/adoption_demo_docker_contract_test.exs` |
| **Full suite command** | `mix test.fast` |
| **Estimated runtime** | ~60 seconds quick, existing project-dependent full suite |

## Sampling Rate

- **After every task commit:** Run `mix test test/lockspire/adoption_demo_docker_contract_test.exs`
- **After every plan wave:** Run `mix test.fast` and at least one relevant `docker compose ... config --format json` proof command
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds for quick contract test feedback

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 113-W0-01 | 01 | 0 | CONFLICT-01 | T-113-01 | Configured project name changes rendered resource names without touching unrelated projects | contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | No - W0 | pending |
| 113-W0-02 | 01 | 0 | CONFLICT-02 | T-113-02 | Configured app port appears in host mapping, `PORT`, docs examples, and smoke command env | contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | No - W0 | pending |
| 113-W0-03 | 01 | 0 | CONFLICT-03 | T-113-03 | Default DB service has no host `ports`; opt-in config uses configured host port only | contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | No - W0 | pending |
| 113-W0-04 | 02 | 0 | CONFLICT-04 | T-113-04 | Reset command targets only active project `db_data`, `deps_volume`, and `build_volume` | contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | No - W0 | pending |
| 113-W0-05 | 03 | 0 | TRAEFIK-01 | T-113-05 | Default Compose model has no Traefik dependency or external proxy network | contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | No - W0 | pending |
| 113-W0-06 | 03 | 0 | TRAEFIK-02 | T-113-06 | Optional Traefik mode renders configurable hostname, router, service, network labels, and explicit service port | contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | No - W0 | pending |

## Wave 0 Requirements

- [ ] `test/lockspire/adoption_demo_docker_contract_test.exs` covers CONFLICT-01..04 and TRAEFIK-01..02 by invoking `docker compose config --format json`.
- [ ] Contract tests prove the default Compose path has no DB host port exposure and no Traefik dependency.
- [ ] Contract tests prove opt-in DB host exposure and opt-in Traefik configuration are isolated from default direct Docker mode.
- [ ] Contract tests prove reset behavior uses an active-project volume allowlist.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Optional Traefik browser smoke against a developer-owned external proxy network | TRAEFIK-01, TRAEFIK-02 | Local Traefik DNS/network state is developer-machine-specific and should not be required for CI | Follow the documented optional Traefik path, then run `LOCKSPIRE_DEMO_BASE_URL=http://lockspire-demo.localhost scripts/demo/adoption_smoke.py` or the documented equivalent |

## Validation Sign-Off

- [ ] All tasks have automated verify commands or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency under 90 seconds for quick contract tests
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 exists and passes

**Approval:** pending
