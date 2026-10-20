---
phase: 159-key-encryption-key-setup-dx
plan: 01
subsystem: key-encryption
tags: [mix-task, generators, clean-room, kek]
requires: []
provides:
  - "mix lockspire.gen.kek (--id, --raw, --help)"
  - "Lockspire.Generators.KekSnippet (env_var/0, generate_key/0, default_id/0, prod_block/2)"
  - "KeySet.valid_id?/1"
  - "build_provider.py --check-gen-kek"
affects: [lib/lockspire/generators/install.ex]
tech-stack:
  added: []
  patterns: ["single shared snippet builder for installer and task"]
key-files:
  created:
    - lib/lockspire/generators/kek_snippet.ex
    - lib/mix/tasks/lockspire.gen.kek.ex
    - test/mix/tasks/lockspire_gen_kek_test.exs
  modified:
    - lib/lockspire/security/key_encryption/key_set.ex
    - lib/lockspire/generators/install.ex
    - test/integration/install_generator_test.exs
    - scripts/acceptance/clean_room/build_provider.py
    - test/integration/phase133_provider_install_test.exs
key-decisions:
  - "KekSnippet is the only builder of key, default id and prod block; installer and gen.kek both call it"
  - "gen.kek has no task prerequisites so it runs where runtime.exs raises"
requirements-completed: [KEK-03, KEK-06]
status: complete
commits: 3
plan_head_before: 1c623bb28dde0f33f648b80831dc15bbff032230
plan_head_after: 553e4018f2b42e48231e20bce8453c3d75d43df4
actuals:
  tokens: 30000
  tasks: 3
  commits: 3
duration: 12 min
completed: 2026-10-19
---

# Phase 159 Plan 01: gen.kek Summary

`mix lockspire.gen.kek` prints a fresh 32-byte base64 key and the installer's own fail-closed `runtime.exs` block from one shared builder, and is proven to run in a clean-room host whose `runtime.exs` raises without the key.

## Accomplishments

- Tracer: `--raw` prints one 44-character key through `KeySet.valid_id?/1` and `KekSnippet`; verified end to end (tracer verified, expanding).
- Default output prints the value once on its own `LOCKSPIRE_KEY_ENCRYPTION_KEY=` line, the shared prod block, and a dev/test note, with no dev/test block holding the key.
- Installer uses `KekSnippet` and names `mix lockspire.gen.kek`; the install test pins it.
- Clean-room `--check-gen-kek` proves gen.kek exits 0 cold while `mix app.config` fails closed; no key reaches output.

## Task Commits

1. Task 1 (tracer): 95a5d206
2. Task 2: a383b0ec
3. Task 3: 553e4018

## Deviations from Plan

**1. [Rule 3 - Blocking] prepare_provider(install=False) crashed in audit_boundary**
- **Found during:** Task 3
- **Issue:** the overlay-based boundary audit reads overlay files that exist only after the installer runs.
- **Fix:** with `install=False`, only the vendor inventory check runs; no other caller used that path.
- **Files modified:** scripts/acceptance/clean_room/build_provider.py
- **Commit:** 553e4018

Tasks 1 and 2 were committed as two commits; the default output branch was completed during Task 1 because the tests were written together.

**Total deviations:** 1 auto-fixed (Rule 3). **Impact:** none on scope.

## Verification

- gen.kek, install generator, key encryption tests pass; `test/lockspire` and `test/mix` pass (1785 tests, 0 failures).
- `--only gen_kek` clean-room case passes; `--check-bootstrap`, release source contract test and the happy_path journey pass (no client_secret in log).
- SAFE-02 diff (mix.exs, mix.lock, priv, protocol, storage) clean; `mix format --check-formatted` clean.

## Known Stubs

None.

## Self-Check: PASSED
