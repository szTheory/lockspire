---
phase: 111-demo-url-contract-config-unification
plan: 01
subsystem: demo-config
tags: [phoenix, docker, oidc, config]
requires: []
provides:
  - Canonical LOCKSPIRE_DEMO_BASE_URL contract for adoption demo config
  - Lockspire issuer derived from the same base URL as Phoenix endpoint URL generation
  - Explicit LOCKSPIRE_DEMO_BIND_IP listener option with Docker opt-in
affects: [adoption-demo, docker-demo, smoke-proof]
tech-stack:
  added: []
  patterns:
    - Parse browser-visible demo base URL once in config and derive public URL consumers from it.
    - Keep listener bind IP separate from browser-visible origin.
key-files:
  created: []
  modified:
    - examples/adoption_demo/config/config.exs
    - examples/adoption_demo/docker-compose.yml
key-decisions:
  - "LOCKSPIRE_DEMO_BASE_URL is the adoption demo's single browser-visible URL input."
  - "LOCKSPIRE_DEMO_BIND_IP controls only the listener socket and accepts loopback or 0.0.0.0."
patterns-established:
  - "Demo URL contract: normalize LOCKSPIRE_DEMO_BASE_URL before deriving endpoint url and Lockspire issuer."
  - "Demo bind contract: Docker opts into 0.0.0.0 explicitly without changing public URL config."
requirements-completed: [URL-01, URL-02, URL-05]
duration: 24 min
completed: 2026-06-04
---

# Phase 111 Plan 01: Demo URL Contract Config Summary

**Adoption demo config now derives Phoenix URL generation and Lockspire issuer from one normalized base URL, with Docker binding controlled by an explicit listener env.**

## Performance

- **Duration:** 24 min
- **Started:** 2026-06-04T17:49:00Z
- **Completed:** 2026-06-04T18:13:26Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `LOCKSPIRE_DEMO_BASE_URL` parsing and validation in adoption demo config.
- Stored `config :adoption_demo, :demo_base_url` for downstream seed, UI, and smoke consumers.
- Derived `AdoptionDemoWeb.Endpoint` `url:` and `config :lockspire, issuer:` from the same normalized base URL.
- Added `LOCKSPIRE_DEMO_BIND_IP` with safe loopback default and Docker `0.0.0.0` opt-in.

## Task Commits

Each task was committed atomically:

1. **Task 1: Derive endpoint URL and issuer from the normalized demo base URL** - `167a742` (feat)
2. **Task 2: Add explicit bind IP config and Docker opt-in** - `f7adec3` (feat)

## Files Created/Modified

- `examples/adoption_demo/config/config.exs` - Parses and validates the demo base URL, stores it for consumers, derives endpoint URL and issuer, and parses the listener bind IP.
- `examples/adoption_demo/docker-compose.yml` - Sets `LOCKSPIRE_DEMO_BIND_IP=0.0.0.0` for the existing web service.

## Decisions Made

- Kept the base URL helper local to config because Phase 111 does not need a new public helper module.
- Allowed only `127.0.0.1` and `0.0.0.0` for `LOCKSPIRE_DEMO_BIND_IP` so listener behavior stays explicit.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

- `docker compose config` normalizes the list-style env entry to `LOCKSPIRE_DEMO_BIND_IP: 0.0.0.0`; the source file still contains the exact planned `LOCKSPIRE_DEMO_BIND_IP=0.0.0.0` entry.

## Verification

- `mix format --check-formatted examples/adoption_demo/config/config.exs` passed.
- `cd examples/adoption_demo && mix compile --warnings-as-errors` passed.
- `cd examples/adoption_demo && LOCKSPIRE_DEMO_BIND_IP=0.0.0.0 mix compile --warnings-as-errors` passed.
- `cd examples/adoption_demo && docker compose config >/tmp/lockspire-phase111-compose.txt && rg -n "LOCKSPIRE_DEMO_BIND_IP: 0\\.0\\.0\\.0" /tmp/lockspire-phase111-compose.txt` passed.
- `rg -n "LOCKSPIRE_DEMO_BIND_IP=0\\.0\\.0\\.0" examples/adoption_demo/docker-compose.yml` passed.
- `test "$(rg -n "LOCKSPIRE_DEMO_HOST|issuer: \"http://127\\.0\\.0\\.1:4100/lockspire\"" examples/adoption_demo/config/config.exs | wc -l | tr -d ' ')" = "0"` passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 111-02 can consume `Application.fetch_env!(:adoption_demo, :demo_base_url)` in seeds and developer output, and can use the same base URL contract for smoke drift assertions.

---
*Phase: 111-demo-url-contract-config-unification*
*Completed: 2026-06-04*
