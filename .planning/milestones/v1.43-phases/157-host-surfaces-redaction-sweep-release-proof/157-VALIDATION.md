---
phase: "157"
slug: "host-surfaces-redaction-sweep-release-proof"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-16"
---

# Phase 157 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source: 157-RESEARCH.md § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5 / OTP 28.4.1); Python 3 scripts for the clean-room host |
| **Config file** | `test/test_helper.exs` (integration tag excluded by default), `config/test.exs` (fixed test KEKs `test-1`, `test-2`) |
| **Quick run command** | `cd /Users/jon/projects/lockspire && HEX_HOME=/private/tmp/lockspire-hex ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 MIX_ENV=test mix test <touched files>` |
| **Full suite command** | same prefix with `mix test --include integration`, then `mix qa` and Dialyzer (CI Elixir 1.19.5-otp-28) |
| **Estimated runtime** | quick: ~1–10 s per file; full: several minutes |

---

## Sampling Rate

- **After every task commit:** run the quick command on the touched test files. For Python changes, also run `python3 scripts/acceptance/clean_room/build_provider.py --check-bootstrap`.
- **After every plan wave:** `mix test test/lockspire test/mix --include integration`, `mix format --check-formatted`, `mix compile --warnings-as-errors`.
- **Before `/gsd-verify-work`:** the full suite plus `mix qa`, Dialyzer and the clean-room journey must be green on CI Elixir.
- **Max feedback latency:** 60 seconds for task-level checks.

---

## Per-Task Verification Map

| Req | Behavior | Test Type | Automated Command (append to prefix) | File Exists | Status |
|-----|----------|-----------|---------------------------------------|-------------|--------|
| RED-01 | No key bytes in repo log or telemetry for any of the 9 key-reading paths. The sweep covers logs, telemetry, audit, inspect, changesets, the KeysLive and OverviewLive pages, and exceptions. | unit (DB sandbox) | `mix test test/lockspire/security/key_material_leak_test.exs` | ✅ extend | ✅ green |
| RED-01 | The changeset masks `changes`, and inspect of the record is masked. | unit | `mix test test/lockspire/storage/ecto/signing_key_record_test.exs` | ✅ (created) | ✅ green |
| RED-01 | Redaction drops the key names (atom and string) and `LSK\x01` values, and keeps the `kid` and `kek_id` fields. | unit | `mix test test/lockspire/redaction/redaction_test.exs` | ✅ extend | ✅ green |
| RED-01 | `PrivateJwk.to_jwk/1` never raises or echoes key bytes, and all six consumers keep their error contract. | unit | `mix test test/lockspire/protocol/private_jwk_test.exs test/lockspire/protocol/envelope_signing_consumers_test.exs` | ✅ extend | ✅ green |
| RED-01 | The Oban logout worker never persists key bytes in `errors`. | unit | `mix test test/lockspire/workers/backchannel_logout_delivery_worker_test.exs` | ✅ extend | ✅ green |
| HOST-01 | Install prints the runtime KEK block with `:reject` and the `LOCKSPIRE_KEY_ENCRYPTION_KEY` env var, plus a per-install dev literal. | integration | `mix test test/integration/install_generator_test.exs` | ✅ extend | ✅ green |
| HOST-01 | The config error names the key-generation commands and keeps the `openssl rand -base64 32` substring. | unit | `mix test test/lockspire/config_key_encryption_test.exs test/lockspire/install/verify_test.exs` | ✅ extend | ✅ green |
| HOST-01 | Demo seeds produce only envelopes, and `--check` and doctor pass. | CI job | adoption-demo CI step: `mix lockspire.keys.reencrypt --check && mix lockspire.doctor key_encryption` | ✅ (created) | ✅ green |
| HOST-01 | The clean-room host has no literal KEK, runs under `:reject`, and its evidence scan catches the KEK. | integration + Python | `python3 scripts/acceptance/clean_room/build_provider.py --check-bootstrap` | ✅ extend | ✅ green |
| PROOF-01 | Upgrade journey: legacy rows → sign under `:allow` → reencrypt → `--check` → byte assertions → `:reject` → rotate → remove the old KEK, with all six consumers checked at each stage. | integration | `mix test test/integration/signing_key_upgrade_journey_test.exs` | ✅ (created) | ✅ green |
| DOC-01 | Doc contracts (extras, groups, diagrams, walkthrough blocks) and the upgrade-guide phrases. | unit | `mix test test/lockspire/documentation_contract_test.exs test/lockspire/upgrade_guide_contract_test.exs` | ✅ / ✅ (created) | ✅ green |
| DOC-01 | No `BREAKING` text and no `!:` commit subject anywhere in the release. | shell | `git log origin/main..HEAD --format=%B \| grep -nE "BREAKING\|^[a-z]+(\(.*\))?!:"` (expect empty) | n/a | ✅ green |
| SAFE-01 | No dependency, migration or column change, and the fitness guards hold. | shell + unit | `git diff --exit-code v1.42 -- mix.lock priv/repo/migrations`; `mix test test/lockspire/architecture_fitness_test.exs test/lockspire/config_key_encryption_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/support/` sentinel matcher module (D-05/D-20: raw, base64, base64url, inspect byte-list, structural binary walk)
- [x] Shared six-consumer driver helper (D-11)
- [x] `test/integration/signing_key_upgrade_journey_test.exs` (PROOF-01)
- [x] `test/lockspire/storage/ecto/signing_key_record_test.exs` (RED-01 changeset/inspect)
- [x] `test/lockspire/upgrade_guide_contract_test.exs` (DOC-01 phrases)
- [x] CI steps: adoption-demo `--check` and doctor; clean-room `--check` and doctor

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Release version (1.6.0 vs 1.7.0), depending on how release PR #121 is sequenced | DOC-01 | Decided at ship time (D-21) | Before the squash-merge, replace `{VERSION}` in the release-note file |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-10-16 — 173 requirement-mapped tests green on 1.19.5-otp-28; clean-room `--check-bootstrap` exit 0. The adoption-demo CI job's new `--check`/doctor steps run only on GitHub Actions (verified locally against Postgres in 157-02).

## Validation Audit 2026-10-16

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
