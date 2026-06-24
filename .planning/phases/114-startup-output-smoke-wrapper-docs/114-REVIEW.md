---
phase: 114-startup-output-smoke-wrapper-docs
reviewed: 2026-06-24T17:00:04Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - docs/adoption-demo.md
  - examples/adoption_demo/bin/docker-info
  - examples/adoption_demo/bin/docker-start
  - scripts/demo/adoption_smoke.sh
  - test/lockspire/adoption_demo_docker_contract_test.exs
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 114: Code Review Report

**Reviewed:** 2026-06-24T17:00:04Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Reviewed the Phase 114 adoption demo docs, Docker startup/banner helpers, smoke wrapper, and Docker contract tests. The direct Docker path is covered by string and compose-config checks, but the promoted Traefik startup path can deadlock on container-internal readiness, and the new wrapper is not the command advertised by the startup banner.

## Critical Issues

### CR-01: Traefik startup can fail before readiness because the entrypoint curls the public hostname from inside the web container

**Classification:** BLOCKER
**File:** `examples/adoption_demo/bin/docker-start:63`, `docs/adoption-demo.md:154`
**Issue:** The docs instruct maintainers to start Traefik mode with `LOCKSPIRE_DEMO_BASE_URL=http://lockspire-demo.localhost`, and `docker-start` uses that same value for its readiness probe: `curl -fsS "${BASE_URL}/"`. That probe runs inside the `web` container. For the documented Traefik URL there is no explicit port, so the container curls `lockspire-demo.localhost:80`; the Phoenix/Bandit server is listening in the same container on `PORT`/4100, while Traefik is outside this container. The entrypoint can therefore time out and exit before printing `docker-info`, even though the service would be reachable through Traefik from the host. The current tests only assert compose labels and source ordering, so they do not catch this runtime split between public issuer URL and container-local readiness URL.
**Fix:**
```sh
PORT="${PORT:-4100}"
READINESS_URL="${LOCKSPIRE_DEMO_READINESS_URL:-http://127.0.0.1:${PORT}}"
READINESS_URL="${READINESS_URL%/}"

wait_for_http() {
  attempt=1

  while [ "$attempt" -le 60 ]; do
    if curl -fsS "${READINESS_URL}/" >/dev/null 2>&1; then
      return 0
    fi

    attempt=$((attempt + 1))
    sleep 1
  done

  echo "Adoption demo did not become ready at ${READINESS_URL}" >&2
  return 1
}
```
Keep `LOCKSPIRE_DEMO_BASE_URL` as the public issuer/browser URL, add or document the internal readiness URL separately, and add a contract test that Traefik mode does not use the public hostname for the in-container readiness probe.

## Warnings

### WR-01: Startup banner bypasses the newly documented smoke wrapper

**Classification:** WARNING
**File:** `examples/adoption_demo/bin/docker-info:33`, `test/lockspire/adoption_demo_docker_contract_test.exs:27`
**Issue:** Phase 114 adds `scripts/demo/adoption_smoke.sh` and the docs tell maintainers to use it, but `docker-info` still prints `LOCKSPIRE_DEMO_BASE_URL=... python3 scripts/demo/adoption_smoke.py`. That leaves the startup output and docs with two different maintainer contracts, bypasses the wrapper's repo-root normalization and target echo, and the contract test now locks in the raw Python command instead of the wrapper path.
**Fix:** Change the banner and test expectation to the wrapper:
```sh
Smoke command
  LOCKSPIRE_DEMO_BASE_URL=${BASE_URL} scripts/demo/adoption_smoke.sh
```
Then update the contract assertion to expect `scripts/demo/adoption_smoke.sh` and refute raw `python3 scripts/demo/adoption_smoke.py` in the banner.

---

_Reviewed: 2026-06-24T17:00:04Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
