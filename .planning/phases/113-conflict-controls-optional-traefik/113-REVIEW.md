---
phase: 113-conflict-controls-optional-traefik
reviewed: 2026-06-04T21:27:27Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - examples/adoption_demo/docker-compose.yml
  - examples/adoption_demo/docker-compose.db-host.yml
  - examples/adoption_demo/docker-compose.traefik.yml
  - examples/adoption_demo/bin/docker-reset
  - docs/adoption-demo.md
  - test/lockspire/adoption_demo_docker_contract_test.exs
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 113: Code Review Report

**Reviewed:** 2026-06-04T21:27:27Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Reviewed the adoption demo Docker Compose files, reset helper, docs, and Docker contract test. The main defect is that the opt-in PostgreSQL host override publishes the database on all host interfaces while using the demo's static credentials. The contract test also misses the host-bind invariant, which is why this security regression passes.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Opt-in PostgreSQL exposure binds to all host interfaces

**File:** `examples/adoption_demo/docker-compose.db-host.yml:4`
**Issue:** The DB host override uses `"${LOCKSPIRE_DEMO_DB_HOST_PORT:-5432}:5432"`, which Docker renders without a `host_ip`. That publishes PostgreSQL on all host interfaces. Because the demo database uses the static `lockspire`/`lockspire` credentials from `docker-compose.yml`, anyone who can reach the developer machine's Docker-published port can connect when this override is enabled. This contradicts the docs' "inspect it from host tools" intent, which is local-only, and creates an avoidable credential exposure.
**Fix:**
```yaml
services:
  db:
    ports:
      - "127.0.0.1:${LOCKSPIRE_DEMO_DB_HOST_PORT:-5432}:5432"
```

## Warnings

### WR-01: Docker contract test does not assert host bind address

**File:** `test/lockspire/adoption_demo_docker_contract_test.exs:197`
**Issue:** `assert_port/3` only checks the published and target ports. The rendered Compose output for the DB override therefore passes even when Docker exposes PostgreSQL on every interface. This leaves the local-only exposure contract untested.
**Fix:** Extend the helper or add a separate assertion for DB host exposure that requires the rendered port's host IP to be loopback.
```elixir
defp assert_port(service, published, target, host_ip \\ nil) do
  assert Enum.any?(service["ports"], fn port ->
           port["published"] == published and
             port["target"] == target and
             (is_nil(host_ip) or port["host_ip"] == host_ip)
         end)
end

# In the DB host override test:
assert_port(db, "15432", 5432, "127.0.0.1")
```

---

_Reviewed: 2026-06-04T21:27:27Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
