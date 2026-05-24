---
phase: 56
slug: rar-domain-validation-storage
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-06
---

# Phase 56 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: 56-RESEARCH.md §"Validation Architecture" (line 947).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18 / OTP 27) |
| **Config file** | `test/test_helper.exs` (already exists) |
| **Quick run command** | `mix test --include focus --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~30 seconds full suite, <5 seconds per focused module |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/<changed_module>_test.exs --warnings-as-errors`
- **After every plan wave:** Run `mix test --warnings-as-errors`
- **Before `/gsd-verify-work`:** Full suite + `mix dialyzer` + `mix credo --strict` must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

> Filled by planner. Plans MUST attach a row per task referencing the test file
> and command. The 21-row test map in `56-RESEARCH.md` §"Validation Architecture"
> is the source-of-truth template.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| {filled by planner} | | | | | | | | | |

---

## Wave 0 Requirements

Wave 0 installs new test scaffolding ahead of the implementation waves. Concrete files:

- [ ] `test/lockspire/rar/fingerprint_test.exs` — property tests for `Lockspire.RAR.Fingerprint.compute/1` (RFC 8785 determinism, key reordering, list reordering rejected, OTP-version stability — anchors mitigation for HIGH-risk assumptions A1/A2 in RESEARCH §"Assumptions Log")
- [ ] `test/lockspire/rar/dispatcher_test.exs` — unit tests for type lookup, telemetry span emission, unknown-type strict reject
- [ ] `test/lockspire/host/rar_type_validator_test.exs` — behaviour contract test (callback signature, default-impl deny path)
- [ ] `test/support/test_rar_validators.ex` — fake validator modules for ExUnit (mirror `test/support/test_token_exchange_validators.ex` pattern; Application.put_env/on_exit registration)
- [ ] `test/lockspire/rar_test.exs` — `error_description/1` formatting tests (changeset → RFC 9396 string, plain string passthrough)
- [ ] No new framework install — ExUnit + StreamData (already in mix.lock for property tests) cover everything.

*StreamData verification before Wave 0: `mix deps | grep stream_data` — if missing, Wave 0's first task adds it.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Migration applied successfully on dev DB | RAR-03 | Migration is environmental — `mix ecto.migrate` runs in CI but the schema column shape must be eyeballed once | `mix ecto.migrate && psql lockspire_dev -c '\d consent_grants' \| grep authorization_details` then `\d tokens \| grep consent_grant_id` |
| Fingerprint determinism across BEAM versions | RAR-03 / D-17 | Property test covers within-version determinism; cross-version requires running the suite on Elixir 1.18 + 1.19 | Run `mix test test/lockspire/rar/fingerprint_test.exs` on both versions, compare hash output for fixture inputs |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (5 new test files + test_support module)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter (toggled by planner once per-task map populated)

**Approval:** pending
