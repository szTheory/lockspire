---
phase: 99
slug: signer-extraction-jwt-default-issuance
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-28
---

# Phase 99 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (bundled with Elixir 1.18) |
| **Config file** | `test/test_helper.exs`; aliases in `mix.exs` (`test.setup`, `test.fast`) |
| **Quick run command** | `mix test test/lockspire/protocol/<file>_test.exs` |
| **Full suite command** | `mix test.setup && mix test` |
| **Estimated runtime** | ~120 seconds full suite; per-file quick runs < 30s |

---

## Sampling Rate

- **After every task commit:** Run the path-specific quick run (e.g. `mix test test/lockspire/protocol/access_token_signer_test.exs`).
- **After every plan wave:** Run `mix test test/lockspire/protocol/ test/lockspire/admin/ test/lockspire/storage/ecto/ test/lockspire/web/live/admin/clients_live/`.
- **Before `/gsd:verify-work`:** `mix test.setup && mix test` fully green.
- **Max feedback latency:** 30 seconds (per-file quick run).

**Regression sentinels (MUST stay green):** `test/lockspire/protocol/rfc8693_exchange_test.exs:192` (AUD-03 bare-string aud) and all Phase 98 verifier tests (`test/lockspire/plug/verify_token_test.exs` — typ/iss/exp/iat/sub contract).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 99-01-01 | 01 | 1 | FORMAT-01/02 | T-99-03 | Ecto.Enum pairs with :text column; no silent enum mismatch | migration | `mix ecto.migrate` | ✅ | ⬜ pending |
| 99-01-02 | 01 | 1 | FORMAT-01 | T-99-01 | put_access_token_format rejects out-of-set values | unit | `mix test test/lockspire/admin/server_policy_test.exs` | ✅ | ⬜ pending |
| 99-01-03 | 01 | 1 | FORMAT-02 | — | Nullable per-client field threaded both changesets | unit | `mix test test/lockspire/storage/ecto/` | ✅ | ⬜ pending |
| 99-02-01 | 02 | 1 | DISCOVERY-01 | T-99-04 / T-99-05 | Truthful alg list; excludes none/EdDSA | unit | `mix test test/lockspire/protocol/discovery_test.exs` | ✅ | ⬜ pending |
| 99-03-01 | 03 | 2 | SIGNER-01/02 | — | RED: signer contract test exists, fails pre-impl | unit | `mix test test/lockspire/protocol/access_token_signer_test.exs` | ❌ W0 | ⬜ pending |
| 99-03-02 | 03 | 2 | SIGNER-01/02, AUD-02/03 | T-99-06..10 | No alg=none; no key in logs; cnf carried; one sign site | unit | `mix test test/lockspire/protocol/access_token_signer_test.exs` | ❌ W0 | ⬜ pending |
| 99-04-01 | 04 | 3 | SIGNER-01, AUD-01/02 | T-99-12 | Stored hash == hash-of-issued-token | unit | `mix test test/lockspire/protocol/token_exchange_test.exs` | ✅ | ⬜ pending |
| 99-04-02 | 04 | 3 | AUD-01/02 | T-99-11 / T-99-13 | Device/CIBA reject unauthorized resource; aud=[resource] | integration | `mix test test/lockspire/protocol/device_authorization_test.exs test/lockspire/protocol/token_exchange_test.exs` | ✅ | ⬜ pending |
| 99-05-01 | 05 | 3 | SIGNER-01, AUD-01/02 | T-99-14 | Refresh sub non-nil (Phase 98 :missing_sub) | unit | `mix test test/lockspire/protocol/refresh_exchange_test.exs` | ✅ | ⬜ pending |
| 99-05-02 | 05 | 3 | SIGNER-01, AUD-03 | T-99-15..18 | Bare-string aud preserved; no duplicated signing (SC5) | unit | `mix test test/lockspire/protocol/rfc8693_exchange_test.exs` | ✅ | ⬜ pending |
| 99-06-01 | 06 | 2 | FORMAT-02 | T-99-19 / T-99-21 | inherit->nil; no :inherit sentinel; forged value rejected | unit | `mix test test/lockspire/admin/clients_test.exs` | ✅ | ⬜ pending |
| 99-06-02 | 06 | 2 | FORMAT-02 | — | Override select renders; stored value pre-selects | LiveView | `mix test test/lockspire/web/live/admin/clients_live/show_test.exs` | ✅ | ⬜ pending |
| 99-06-03 | 06 | 2 | FORMAT-02 | T-99-20 | Effective display matches signer precedence | LiveView | `mix test test/lockspire/web/live/admin/clients_live/show_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/lockspire/protocol/access_token_signer_test.exs` — NEW (Plan 03 Task 1, RED first); covers SIGNER-01/02, format precedence, aud list-vs-string carve-out, cnf carry-through, missing-key 500.
- [ ] Confirm `test/lockspire/admin/server_policy_test.exs` covers `put_access_token_format/1` (extend in Plan 01 Task 2 — file exists).
- [ ] Device + CIBA `resource=`-scoped fixtures (Plan 04 Task 2 — AUD-01 must exercise these explicitly; Pitfall 2).
- [ ] No framework install needed — ExUnit present; all other sibling test files exist (`token_exchange_test.exs`, `refresh_exchange_test.exs`, `rfc8693_exchange_test.exs`, `discovery_test.exs`, `device_authorization_test.exs`, `clients_test.exs`, `show_test.exs`).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| (none) | — | — | — |

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (access_token_signer_test.exs scaffolded RED in Plan 03 Task 1)
- [x] No watch-mode flags
- [x] Feedback latency < 30s (per-file quick run)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-28
