---
phase: 115
slug: repo-hygiene-gate-scoped-cleanup
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-24
---

# Phase 115 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit contract tests, POSIX/Bash shell syntax checks, Python stdlib compile check |
| **Config file** | `mix.exs`; `.github/workflows/ci.yml`; `examples/adoption_demo/docker-compose.yml` |
| **Quick run command** | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` |
| **Full suite command** | `mix test.fast` |
| **Estimated runtime** | ~60 seconds for focused contracts; full suite depends on local environment |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0`
- **After every hygiene script change:** Run `bash -n scripts/maintainer/repo_hygiene_check.sh`
- **After every adoption-demo shell helper change:** Run `sh -n examples/adoption_demo/bin/docker-reset` plus `sh -n` for each new or modified helper.
- **After every smoke wrapper touch:** Run `python3 -m py_compile scripts/demo/adoption_smoke.py`
- **After every plan wave:** Run focused contract tests plus `bash ./scripts/maintainer/repo_hygiene_check.sh --ci`
- **Before `/gsd:verify-work`:** Full suite must be green, and local start -> smoke -> stop -> cleanup -> hygiene proof should run when Docker is available.
- **Max feedback latency:** 90 seconds for non-Docker gates.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 115-01-01 | 01 | 1 | CLEAN-01 | T-115-01 | Stop preserves active-project volumes and avoids `--volumes` / `-v` deletion | source/contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | yes | pending |
| 115-01-02 | 01 | 1 | CLEAN-02 | T-115-01 | Reset remains scoped to `db_data`, `deps_volume`, and `build_volume` for the active project | source/contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | yes | pending |
| 115-01-03 | 01 | 1 | CLEAN-03, HYGIENE-03 | T-115-02 | Cleanup is dry-run by default, requires explicit execution, and preserves `tmp/admin-ui-polish/` | source/contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | no, Wave 0 | pending |
| 115-02-01 | 02 | 1 | HYGIENE-01 | T-115-03 | Local hygiene reports demo Docker leftovers and generated artifacts with PASS/WARN/BLOCK and exact remediation | source/contract | `mix test test/lockspire/release_readiness_contract_test.exs --seed 0` | yes | pending |
| 115-02-02 | 02 | 1 | HYGIENE-02, SMOKE-03 | T-115-04 | `--ci` hygiene remains Docker-daemon-free and only validates deterministic repo contracts | source/contract | `bash ./scripts/maintainer/repo_hygiene_check.sh --ci` | yes | pending |
| 115-02-03 | 02 | 1 | HYGIENE-04 | T-115-05 | Start -> smoke -> stop -> cleanup -> hygiene can leave no demo-owned BLOCK findings | local/runtime | `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100 scripts/demo/adoption_smoke.sh` plus hygiene command | yes | pending |
| 115-03-01 | 03 | 2 | BOUNDARY-01, BOUNDARY-02 | T-115-06 | Docs and contracts keep cleanup repo-local and do not add protocol/admin UI/production Docker support claims | docs/contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs test/lockspire/release_readiness_contract_test.exs --seed 0` | yes | pending |

---

## Wave 0 Requirements

- [ ] `test/lockspire/adoption_demo_docker_contract_test.exs` — add RED contracts for stop/cleanup command shape, dry-run default, explicit execute, allowlists, forbidden Docker prune/down-volume commands, and admin evidence preservation.
- [ ] `test/lockspire/release_readiness_contract_test.exs` — add RED contracts for local-vs-CI hygiene behavior, Docker-free `--ci`, PASS/WARN/BLOCK wording, and boundary claims.
- [ ] Shell syntax gates for any new adoption-demo helpers and the updated hygiene script.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Direct Docker lifecycle proof | HYGIENE-04 | Requires Docker daemon, free port, and local machine state | Start the default demo, run `scripts/demo/adoption_smoke.sh`, stop it, run cleanup with explicit execution, then run hygiene and confirm no demo-owned `BLOCK` findings. |
| Optional Traefik cleanup posture | CLEAN-03 | Requires optional local Traefik network/proxy setup | Start with the Traefik override if available, run cleanup for the active project, and confirm only demo-owned project resources are reported/removed. |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing source contracts.
- [x] No watch-mode flags.
- [x] Feedback latency < 90s for non-Docker gates.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
