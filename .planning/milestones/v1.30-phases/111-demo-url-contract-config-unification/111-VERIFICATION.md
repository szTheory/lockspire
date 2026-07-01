---
phase: 111-demo-url-contract-config-unification
status: passed
verified_at: 2026-06-04T18:20:45Z
requirements_verified: [URL-01, URL-02, URL-03, URL-04, URL-05]
automated_checks:
  passed: 12
  failed: 0
human_verification: []
gaps: []
---

# Phase 111 Verification

## Verdict

Phase 111 passed verification. The adoption demo now has one canonical browser-visible base URL contract, derives endpoint URL generation and Lockspire issuer from it, consumes it in seed data and developer output, and proves the contract through the existing smoke script.

## Requirement Traceability

| Requirement | Status | Evidence |
|-------------|--------|----------|
| URL-01 | passed | `LOCKSPIRE_DEMO_BASE_URL` is parsed in `examples/adoption_demo/config/config.exs`; seed and controller consumers read `Application.fetch_env!(:adoption_demo, :demo_base_url)`. |
| URL-02 | passed | `AdoptionDemoWeb.Endpoint` `url:` and `config :lockspire, issuer:` derive from the same normalized `demo_base_url`; smoke asserts discovery issuer and endpoints from `BASE_URL`. |
| URL-03 | passed | Local seed redirect, registration, interaction, logout, and printed callback URLs derive from `demo_base_url`; developer output uses the same callback URL. |
| URL-04 | passed | `scripts/demo/adoption_smoke.py` uses only `LOCKSPIRE_DEMO_BASE_URL` as the external URL env and reports labelled expected/actual drift for issuer, endpoints, callback, state, and device verification URI. |
| URL-05 | passed | `LOCKSPIRE_DEMO_BIND_IP` defaults to loopback, allows only `0.0.0.0` as Docker opt-in, and compose sets `LOCKSPIRE_DEMO_BIND_IP=0.0.0.0` without adding Phase 112 topology. |

## Must-Have Checks

- Plan 111-01 truths: passed.
- Plan 111-02 truths: passed.
- No Lockspire protocol module, admin workflow, startup wrapper, Docker topology expansion, optional Traefik control, or docs expansion was added.
- External partner fixtures remain external.

## Automated Evidence

- `mix format --check-formatted examples/adoption_demo/config/config.exs` passed.
- `mix format --check-formatted examples/adoption_demo/priv/repo/seeds.exs examples/adoption_demo/lib/adoption_demo_web/controllers/developer_controller.ex` passed.
- `cd examples/adoption_demo && mix compile --warnings-as-errors` passed.
- `cd examples/adoption_demo && LOCKSPIRE_DEMO_BIND_IP=0.0.0.0 mix compile --warnings-as-errors` passed.
- `cd examples/adoption_demo && docker compose config >/tmp/lockspire-phase111-compose.txt && rg -n "LOCKSPIRE_DEMO_BIND_IP: 0\\.0\\.0\\.0" /tmp/lockspire-phase111-compose.txt` passed.
- `rg -n "LOCKSPIRE_DEMO_BIND_IP=0\\.0\\.0\\.0" examples/adoption_demo/docker-compose.yml` passed.
- `cd examples/adoption_demo && mix ecto.setup` passed.
- `python3 -m py_compile scripts/demo/adoption_smoke.py` passed.
- `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100 python3 scripts/demo/adoption_smoke.py` passed against a local `mix phx.server`.
- `mix test.fast` passed: 1074 tests, 0 failures, 287 excluded.
- Schema drift gate passed: no drift detected.
- Code review gate passed: `111-REVIEW.md` status `clean`.

## Issues And Deviations

- Plan 111-02 auto-fixed a blocking seed setup issue where duplicate logout delivery fixtures violated the current unique index. The fix preserved the proof states by attaching duplicate delivery states to separate logout events.
- The default `LOCKSPIRE_DEMO_BASE_URL` literal remains only where it is the configured default input (`config.exs` and `adoption_smoke.py`). The old split `LOCKSPIRE_DEMO_HOST` and hard-coded issuer literal were removed.

## Human Verification

None required.

## Gaps

None.
