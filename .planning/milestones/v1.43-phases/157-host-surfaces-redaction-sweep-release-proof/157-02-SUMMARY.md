---
phase: 157-host-surfaces-redaction-sweep-release-proof
plan: 02
subsystem: host-surfaces
tags: [key-encryption, install-generator, adoption-demo, clean-room, kek]
requires:
  - phase: 156
    provides: key-encryption KeySet, reencrypt and doctor tasks
provides:
  - install step 9 printing runtime and dev/test key-encryption blocks
  - extended invalid-key config error naming both generation commands
  - adoption demo booting under :reject with a demo-only KEK in config/runtime.exs
  - public-API signing-key seeds across four display states
  - clean-room provider with per-run random KEK from config/runtime.exs
affects: [157-03 CI real-host checks]
actuals:
  tokens: 14000
  tasks: 3
  commits: 3
plan_head_before: 388f82f6eee20bd48e677a6b6b2f28984aba863b
plan_head_after: d0f42055f9e6617e7c8c237594621e7ce97ca14d
commits: 3
tech-stack:
  added: []
  patterns: ["KEK delivered via config/runtime.exs reading LOCKSPIRE_KEY_ENCRYPTION_KEY, fail closed in prod"]
key-files:
  created: [examples/adoption_demo/config/runtime.exs]
  modified:
    - lib/lockspire/generators/install.ex
    - lib/lockspire/config.ex
    - test/integration/install_generator_test.exs
    - test/lockspire/config_key_encryption_test.exs
    - examples/adoption_demo/priv/repo/seeds.exs
    - examples/adoption_demo/docker-compose.yml
    - docs/oauth-oidc-for-phoenix-adopters.md
    - scripts/acceptance/clean_room/build_provider.py
    - scripts/acceptance/clean_room_saas_journey.py
key-decisions:
  - "Generator prints (never writes) the KEK blocks; dev literal is random per install and marked dev/test only"
  - "Demo and clean-room KEKs live only in config/runtime.exs, never compile-time config.exs"
requirements-completed: [HOST-01, SAFE-01]
coverage:
  - id: D1
    description: "mix lockspire.install prints runtime and dev/test KEK blocks; literal accepted by KeySet; differs per run"
    requirement: HOST-01
    verification:
      - kind: integration
        ref: "test/integration/install_generator_test.exs#key encryption next step"
        status: pass
    human_judgment: false
  - id: D2
    description: "Invalid key error names openssl and Elixir one-liner and warns about phx.gen.secret"
    requirement: HOST-01
    verification:
      - kind: unit
        ref: "test/lockspire/config_key_encryption_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Adoption demo boots under :reject, seeds four sealed ES256 keys via public API; ecto.reset, reencrypt --check, doctor all exit 0 on real Postgres"
    requirement: HOST-01
    verification:
      - kind: other
        ref: "mix ecto.reset; mix lockspire.keys.reencrypt --check; mix lockspire.doctor key_encryption (examples/adoption_demo, MIX_ENV=dev)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Clean-room provider reads per-run KEK from runtime.exs under :reject; bootstrap check updated"
    requirement: HOST-01
    verification:
      - kind: integration
        ref: "test/integration/phase133_provider_install_test.exs"
        status: pass
    human_judgment: false
duration: 35min
completed: 2026-10-16
status: complete
---

# Phase 157 Plan 02: Host KEK Delivery Summary

**Install now prints a fail-closed `config/runtime.exs` KEK block (`LOCKSPIRE_KEY_ENCRYPTION_KEY`, `legacy_plaintext: :reject`) plus a per-install random dev/test literal, and the adoption demo and clean-room provider boot under that shape with only sealed signing keys.**

## Performance

- **Duration:** 35 min
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments
- Install step 9 prints a prod block (raises naming `openssl rand -base64 32` when the variable is missing) and a dev/test block with a fresh random 32-byte base64 literal; nothing is written to host files or the install manifest.
- Invalid-key config error also names `elixir -e 'IO.puts(Base.encode64(:crypto.strong_rand_bytes(32)))'` and warns `mix phx.gen.secret` output is not 32 bytes.
- Demo: new `config/runtime.exs` (id `demo-1`, public demo-only fallback literal, `:reject`); `config.exs` untouched and KEK-free. Seeds replaced the raw RS256 ETF insert and placeholder rows with `Lockspire.Admin.generate_key/publish_key/activate_key/retire_key`, producing four ES256 keys (retired, retiring, active, upcoming) with random kids. Compose documents the env var as demo-only; adopter guide no longer cites the old fixed kid.
- Clean-room: provider `config/config.exs` has no KEK; a written `config/runtime.exs` uses the generator body; the journey sets a random per-run KEK in `main()` and registers it as a secret; `check_bootstrap` asserts the new shape and rejects base64 literals and `:allow`.

## Real demo check (D-29), Postgres reachable at localhost:5432
- `mix run --no-start -e ...` printed current KEK id `demo-1` (runtime.exs loaded)
- `mix compile --warnings-as-errors`: exit 0
- `mix ecto.reset`: exit 0
- `mix lockspire.keys.reencrypt --check`: exit 0 (`total=4 on_current=4 legacy=0 ready=true`)
- `mix lockspire.doctor key_encryption`: exit 0 (`kek=demo-1 rows=4`)
- DB rows: 4 ES256 keys: retired, retiring, active, upcoming.

## conformance_seeds.exs audit
No change needed: line 68 generates an ephemeral OIDF client key, not a stored signing key. `git diff 05e024de` on the file is empty.

## Task Commits
1. Task 1: install blocks and config error - `d6730202` (feat)
2. Task 2: demo runtime config, seeds, compose, docs - `cc0f4129` (feat)
3. Task 3: clean-room provider and journey KEK - `d0f42055` (feat)

## Decisions Made
None beyond plan (D-07..D-10, D-23, D-24, D-29 followed).

## Deviations from Plan

**1. [Rule 3 - Blocking] Provider self-test failed with missing KEK in standalone runs**
- **Found during:** Task 3
- **Issue:** `verify_child` probes with `mix`, which loads the new `config/runtime.exs`; with no `LOCKSPIRE_KEY_ENCRYPTION_KEY` in the environment it raised, failing `--self-test` and `phase133_provider_install_test`.
- **Fix:** `prepare_provider` now does `os.environ.setdefault(...)` with a random key before any child runs (the later `environment.setdefault` reuses it), instead of only setting it after the environment was built.
- **Files modified:** scripts/acceptance/clean_room/build_provider.py
- **Verification:** `--check-bootstrap`, `--self-test` path and phase133 test (3 tests, 0 failures).
- **Committed in:** d0f42055

**Total deviations:** 1 auto-fixed (Rule 3). **Impact:** none on scope.

## Issues Encountered
`mix format` rewrapped `examples/adoption_demo/config/runtime.exs`; accepted formatter output. Docker was not needed; a local Postgres was already accepting connections.

## Known Stubs
None.

## Next Phase Readiness
157-03 can add the CI adoption-demo job (`ecto.setup`, then reencrypt `--check` and doctor) and clean-room reencrypt/doctor child commands. The 157-03 CI job remains the required gate (D-29).

## Self-Check: PASSED
