---
phase: 159-key-encryption-key-setup-dx
plan: 03
subsystem: key-encryption
tags: [guidance, docs, contract-test, kek]
requires: ["159-01", "159-02"]
provides:
  - "Every key-generation guidance message and doc names mix lockspire.gen.kek"
  - "Lockspire.KekGuidanceContractTest (no OpenSSL recipe, elixir -e only in the upgrade guide after gen.kek)"
affects: [lib/lockspire/config.ex, docs/upgrading/signing-key-encryption.md, docs/install-and-onboard.md]
tech-stack:
  added: []
  patterns: ["contract test scanning lib, docs and harness for forbidden recipes"]
key-files:
  created:
    - test/lockspire/kek_guidance_contract_test.exs
  modified:
    - lib/lockspire/config.ex
    - lib/lockspire/application.ex
    - lib/lockspire/install/verify.ex
    - lib/mix/tasks/lockspire.keys.reencrypt.ex
    - lib/mix/tasks/lockspire.doctor.key_encryption.ex
    - docs/upgrading/signing-key-encryption.md
    - docs/install-and-onboard.md
    - test/lockspire/config_key_encryption_test.exs
    - test/lockspire/install/verify_test.exs
    - test/lockspire/upgrade_guide_contract_test.exs
key-decisions:
  - "The elixir -e fallback survives only in the upgrade guide, after gen.kek; config.ex names only gen.kek"
requirements-completed: [KEK-06, KEK-05, KEK-03]
status: complete
commits: 3
plan_head_before: 22fc5ac0b7a432e25f8e57d0189d3cede87ffebb
plan_head_after: 6bd33e91a102def7fce82ce5d4bea69eae9bcafc
actuals:
  tokens: 9000
  tasks: 3
  commits: 3
duration: 10 min
completed: 2026-10-19
---

# Phase 159 Plan 03: gen.kek guidance sweep Summary

Config errors, the boot warning, verify, reencrypt, doctor and both docs now send adopters to `mix lockspire.gen.kek`, and a contract test fails if the OpenSSL recipe returns or the elixir -e fallback leaves the upgrade guide.

## Accomplishments

- Config generic key error, boot warning, verify fix text, reencrypt and doctor not-set errors name gen.kek; the phx.gen.secret warning is kept.
- Upgrade guide: gen.kek first, elixir -e as the no-Mix fallback, installer-form Step 1, `{:system, var}` sentence, store-exactly-as-printed and restart notes, rotation uses `--id 2026-07`.
- install-and-onboard carries the same gen.kek wording, snippet raise text, `{:system, var}`, trailing-newline and restart lines.
- `kek_guidance_contract_test.exs` proven to fail (1 failure) when the OpenSSL recipe is appended to a doc, then reverted.

## Task Commits

1. Task 1: 11de2736
2. Task 2: d1137c25
3. Task 3: 6bd33e91

## Deviations from Plan

None - plan executed exactly as written.

## Verification

- `mix ci` exit 0; `MIX_ENV=test mix test --only integration` 105 tests, 0 failures; `mix docs.verify` clean; vocabulary contract test passes.
- SAFE-02 diff (mix.exs, mix.lock, priv, protocol, storage, key_set_inspect.ex) vs 0ba2b724 is empty.
- No 44-char base64 values in either doc; no `openssl` in lib, docs or README.

## Known Stubs

None.

## Self-Check: PASSED
