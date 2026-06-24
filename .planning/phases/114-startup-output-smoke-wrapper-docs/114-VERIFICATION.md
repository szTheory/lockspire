---
phase: 114-startup-output-smoke-wrapper-docs
verified: 2026-06-24T17:06:26Z
status: passed
score: 10/10 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 114: Startup Output, Smoke Wrapper & Docs Verification Report

**Phase Goal:** Startup Output, Smoke Wrapper & Docs
**Verified:** 2026-06-24T17:06:26Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Successful startup prints all important URLs and the exact smoke command for the active base URL. | VERIFIED | `examples/adoption_demo/bin/docker-start:97-98` calls `./bin/docker-info` after `wait_for_http`; `docker-info:4-38` derives URLs from trimmed `LOCKSPIRE_DEMO_BASE_URL` and prints `LOCKSPIRE_DEMO_BASE_URL=${BASE_URL} scripts/demo/adoption_smoke.sh`. Local sample with `http://127.0.0.1:4101/` printed all expected URLs without `//` drift. |
| 2 | Startup output lists seeded accounts and clearly identifies `ops` as the operator account. | VERIFIED | `docker-info:21-24` prints `alice`, `bob`, and `ops` with emails and labels `ops` as `operator account`; focused ExUnit contract passes. |
| 3 | Startup output lists seeded OAuth clients and demo shapes without exposing sensitive material. | VERIFIED | `docker-info:26-31` prints allowlisted client IDs and safe shape fields only; `test/lockspire/adoption_demo_docker_contract_test.exs` refutes demo secrets, token hashes, private JWK material, auth-code material, refresh/access token material, and cookie material in both source and rendered output. |
| 4 | Maintainers can reprint current demo information without recreating containers. | VERIFIED | `docker-info:36-37` prints `docker compose -f examples/adoption_demo/docker-compose.yml exec web ./bin/docker-info`; docs repeat the same command; tests refute `up`/`run` in the reprint output. |
| 5 | The smoke wrapper runs the existing black-box smoke against the active direct Docker base URL. | VERIFIED | `scripts/demo/adoption_smoke.sh:43-47` normalizes `LOCKSPIRE_DEMO_BASE_URL`, echoes the target, and execs `python3 scripts/demo/adoption_smoke.py`; `.github/workflows/ci.yml` keeps the `Adoption Demo Smoke` job with `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100`; `python3 -m py_compile` and wrapper contracts pass. |
| 6 | The same smoke can run against optional Traefik hostname mode. | VERIFIED | `scripts/demo/adoption_smoke.sh:16-17` documents the hostname command and uses the same env var, with no Traefik-specific branch; docs show `LOCKSPIRE_DEMO_BASE_URL=http://lockspire-demo.localhost scripts/demo/adoption_smoke.sh`; compose contracts verify optional Traefik labels/network wiring. |
| 7 | Docs present Docker as the default maintainer path and host-local Mix/Postgres as fallback. | VERIFIED | `docs/adoption-demo.md` has `## Run it with Docker` before `## Run it host-local`; tests assert this ordering and wording. |
| 8 | Docs cover startup, optional Traefik, smoke, stop, reset, cleanup boundary, environment overrides, and troubleshooting. | VERIFIED | `docs/adoption-demo.md` contains sections for startup output, smoke, stop, reset, cleanup boundary, env overrides, optional Traefik, and troubleshooting for port conflict, readiness failure, Traefik network, and base URL drift; focused docs contracts pass. |
| 9 | `docker-start` readiness uses container-local readiness URL, not the public base URL. | VERIFIED | Review fix verified in code: `docker-start:6-8` defines `READINESS_URL` from `LOCKSPIRE_DEMO_READINESS_URL` defaulting to `http://127.0.0.1:${PORT}`; `docker-start:62-75` curls `${READINESS_URL}/`; tests refute curling `${BASE_URL}/`. |
| 10 | `docker-info` advertises `scripts/demo/adoption_smoke.sh` as the smoke command. | VERIFIED | Review fix verified in `docker-info:33-34`; tests assert wrapper command and refute `python3 scripts/demo/adoption_smoke.py` in the banner. |

**Score:** 10/10 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `examples/adoption_demo/bin/docker-info` | Reusable redacted demo information printer | VERIFIED | Exists, executable, passes `sh -n`, prints URL/account/client/smoke/reprint output from allowlisted shell source. |
| `examples/adoption_demo/bin/docker-start` | Startup integration after readiness | VERIFIED | Exists, executable, passes `sh -n`, waits on `READINESS_URL`, then calls `./bin/docker-info`. |
| `scripts/demo/adoption_smoke.sh` | Thin maintainer smoke wrapper | VERIFIED | Exists, executable, passes `sh -n`, normalizes base URL and execs Python smoke. |
| `docs/adoption-demo.md` | Docker-first maintainer guide | VERIFIED | Substantive guide with Docker-first flow, host fallback, Traefik, smoke, reprint, stop/reset, cleanup boundary, env overrides, and troubleshooting. |
| `test/lockspire/adoption_demo_docker_contract_test.exs` | Contracts for startup info, wrapper, docs, review fixes | VERIFIED | Focused suite passes: 22 tests, 0 failures. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `examples/adoption_demo/bin/docker-start` | `examples/adoption_demo/bin/docker-info` | Startup calls info script only after HTTP readiness | VERIFIED | Manual source check shows `wait_for_http` at line 97 immediately before `./bin/docker-info` at line 98. Generic regex probe missed the multiline shell shape. |
| `examples/adoption_demo/bin/docker-info` | `examples/adoption_demo/config/config.exs` | Same base URL env/default contract | VERIFIED | Both use `LOCKSPIRE_DEMO_BASE_URL` with default `http://127.0.0.1:4100`; rendered sample trims trailing slash. |
| `scripts/demo/adoption_smoke.sh` | `scripts/demo/adoption_smoke.py` | Wrapper delegates to existing Python proof | VERIFIED | `LOCKSPIRE_DEMO_BASE_URL="${BASE_URL}" exec python3 scripts/demo/adoption_smoke.py`. |
| Maintainer shell | `examples/adoption_demo/bin/docker-info` | Reprint command targets running `web` service | VERIFIED | Command appears in `docker-info`, docs, and tests: `docker compose -f examples/adoption_demo/docker-compose.yml exec web ./bin/docker-info`. |
| `docs/adoption-demo.md` | `scripts/demo/adoption_smoke.sh` | Docs use wrapper for direct and Traefik smoke examples | VERIFIED | Direct and hostname wrapper commands are present; raw Python smoke examples are refuted by tests. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `docker-info` | `BASE_URL` | `LOCKSPIRE_DEMO_BASE_URL` with `http://127.0.0.1:4100` default | Yes | FLOWING - local rendered sample with alternate base URL proved all printed URLs and smoke command update. |
| `docker-start` | `READINESS_URL` | `LOCKSPIRE_DEMO_READINESS_URL` with container-local `http://127.0.0.1:${PORT}` default | Yes | FLOWING - readiness curl uses readiness URL while banner/smoke still use public base URL. |
| `adoption_smoke.sh` | `BASE_URL` | `LOCKSPIRE_DEMO_BASE_URL` with direct default and optional hostname example | Yes | FLOWING - wrapper exports normalized value into Python smoke. |
| `docs/adoption-demo.md` | Maintainer commands | Concrete script and compose command strings | Yes | FLOWING - docs contracts assert exact commands and ordering. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Shell scripts parse | `sh -n examples/adoption_demo/bin/docker-info && sh -n examples/adoption_demo/bin/docker-start && sh -n scripts/demo/adoption_smoke.sh` | Exit 0 | PASS |
| Python smoke compiles | `python3 -m py_compile scripts/demo/adoption_smoke.py` | Exit 0 | PASS |
| Startup info renders active base URL | `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4101/ examples/adoption_demo/bin/docker-info` | Printed expected URLs, accounts, clients, wrapper smoke command, and reprint command | PASS |
| Focused Docker contracts | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | 22 tests, 0 failures | PASS |
| Full fast test suite | `mix test.fast` | 1096 tests, 0 failures, 287 excluded | PASS |

### Probe Execution

| Probe | Command | Result | Status |
|---|---|---|---|
| None declared | `find scripts -path '*/tests/probe-*.sh' -type f` | No phase probe scripts declared or discovered | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| INFO-01 | 114-01 | Startup prints active base URL, issuer, discovery, JWKS, admin, device verification, developer apps, callback, protected API, and exact smoke command. | SATISFIED | `docker-info` rendered alternate base URL correctly; focused test asserts every URL and wrapper smoke command. |
| INFO-02 | 114-01 | Startup prints `alice`, `bob`, and `ops` accounts with emails/roles and marks `ops` operator. | SATISFIED | `docker-info` account rows and focused account contract. |
| INFO-03 | 114-01 | Startup prints seeded client IDs/shapes without secrets/tokens/private keys/codes/refresh/cookies. | SATISFIED | Static allowlist in `docker-info`; redaction tests against source and rendered output. |
| INFO-04 | 114-02, 114-03 | Maintainer can reprint current info without recreating containers. | SATISFIED | `docker-info` and docs use Compose `exec web ./bin/docker-info`; tests refute recreation verbs in banner output. |
| SMOKE-01 | 114-02, 114-03 | Existing black-box smoke passes against direct Docker URL using `LOCKSPIRE_DEMO_BASE_URL`. | SATISFIED | Wrapper delegates to existing Python smoke with normalized direct default; CI adoption-demo smoke job remains wired to `http://127.0.0.1:4100`; Python compile and focused contracts pass. |
| SMOKE-02 | 114-02, 114-03 | Optional Traefik mode can run the same smoke against hostname URL. | SATISFIED | Same wrapper is base-URL driven; help/docs show hostname URL; tests verify no separate Traefik branch and optional compose Traefik labels/network. |
| DOCS-01 | 114-03 | Docs present Docker as default path with host-local fallback. | SATISFIED | Docs section order and contract test prove Docker before host-local fallback. |
| DOCS-02 | 114-03 | Docs cover startup, optional Traefik, smoke, stop, reset, cleanup, overrides, and port/readiness troubleshooting. | SATISFIED | Docs contracts assert exact coverage, including `LOCKSPIRE_DEMO_READINESS_URL` troubleshooting and Phase 115 cleanup boundary. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| None | - | Debt/stub scan found no `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, placeholder wording, empty implementation, or console-only implementation in changed files. | - | - |

### Human Verification Required

None.

### Gaps Summary

No blocking gaps found. The phase goal is achieved in the codebase: startup output is self-describing and redacted, can be reprinted from a running container, smoke proof is exposed through the wrapper while preserving the existing Python black-box implementation, docs are Docker-first with fallback/troubleshooting, and the recent readiness/smoke-command review fixes are present and covered by tests.

---

_Verified: 2026-06-24T17:06:26Z_
_Verifier: the agent (gsd-verifier)_
