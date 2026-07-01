---
phase: 114
slug: startup-output-smoke-wrapper-docs
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-24
---

# Phase 114 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit contract tests, POSIX shell syntax checks, Python stdlib smoke compile/runtime |
| **Config file** | `mix.exs`; `examples/adoption_demo/mix.exs`; `examples/adoption_demo/docker-compose.yml` |
| **Quick run command** | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` |
| **Full suite command** | `mix test.fast` |
| **Estimated runtime** | ~60 seconds for contract tests; Docker smoke is environment-dependent |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0`
- **After every shell script change:** Run `sh -n examples/adoption_demo/bin/docker-start` plus `sh -n` for each new or modified shell wrapper
- **After smoke wrapper changes:** Run `python3 -m py_compile scripts/demo/adoption_smoke.py`
- **After every plan wave:** Run `mix test.fast`
- **Before `/gsd:verify-work`:** Full suite must be green and direct Docker smoke should be exercised when Docker is available
- **Max feedback latency:** 90 seconds for source/contract checks

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 114-01-01 | 01 | 1 | INFO-01 | T-114-01 | URLs derive from `LOCKSPIRE_DEMO_BASE_URL` | source/contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | no, Wave 0 | pending |
| 114-01-02 | 01 | 1 | INFO-02 | T-114-02 | `ops` is clearly marked as the operator account | source/contract | `rg -n "alice@acme.test|bob@globex.test|ops@acme.test|operator account" examples/adoption_demo/bin/docker-info` | no, Wave 0 | pending |
| 114-01-03 | 01 | 1 | INFO-03 | T-114-01 | Secret values, tokens, private keys, auth codes, refresh tokens, and cookies are not printed | source/negative | `test "$(rg -n "demo-backend-secret|demo-rat-secret|token_hash|private_jwk|authorization code|refresh token|access token|cookie" examples/adoption_demo/bin/docker-info | wc -l | tr -d ' ')" = "0"` | no, Wave 0 | pending |
| 114-02-01 | 02 | 2 | INFO-04 | T-114-03 | Reprint path is read-only and does not recreate containers | source/docs/runtime | `rg -n "docker compose.*exec web ./bin/docker-info" docs/adoption-demo.md examples/adoption_demo/bin/*` | no, Wave 0 | pending |
| 114-02-02 | 02 | 2 | SMOKE-01 | T-114-04 | Direct Docker smoke uses the active direct base URL | runtime | `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100 python3 scripts/demo/adoption_smoke.py` | yes | pending |
| 114-02-03 | 02 | 2 | SMOKE-02 | T-114-04 | Traefik smoke uses the active hostname base URL when Traefik is enabled | runtime/manual | `LOCKSPIRE_DEMO_BASE_URL=http://lockspire-demo.localhost python3 scripts/demo/adoption_smoke.py` | yes | pending |
| 114-03-01 | 03 | 3 | DOCS-01 | T-114-05 | Docker remains the default documented path and host-local remains fallback | docs contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | yes | pending |
| 114-03-02 | 03 | 3 | DOCS-02 | T-114-05 | Docs cover startup, Traefik, smoke, stop, reset, cleanup, env overrides, and troubleshooting | docs contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | yes | pending |

---

## Wave 0 Requirements

- [ ] `examples/adoption_demo/bin/docker-info` - redacted reusable info printer for INFO-01, INFO-02, INFO-03, and INFO-04.
- [ ] Thin smoke wrapper, either `scripts/demo/adoption_smoke.sh` or an adoption-demo bin script, that delegates to `scripts/demo/adoption_smoke.py`.
- [ ] `test/lockspire/adoption_demo_docker_contract_test.exs` - source/docs contracts for banner strings, redaction, smoke wrapper, reprint command, and docs coverage.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Direct Docker startup banner and smoke | SMOKE-01 | Requires local Docker daemon and available port 4100 | Start the default demo stack, confirm the banner prints the exact smoke command, then run that command. |
| Optional Traefik hostname smoke | SMOKE-02 | Requires local Traefik network/hostname setup | Start with `docker-compose.traefik.yml`, confirm banner uses `http://lockspire-demo.localhost`, then run the printed smoke command. |

---

## Validation Sign-Off

- [x] All planned behaviors have source/contract checks or explicit runtime/manual checks
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing source contracts
- [x] No watch-mode flags
- [x] Feedback latency < 90 seconds for non-Docker gates
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
