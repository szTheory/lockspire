---
phase: "159"
slug: "key-encryption-key-setup-dx"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-10-19"
---

# Phase 159 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| `mix lockspire.gen.kek` → terminal / shell history / CI log | Developer runs the task and copies the value into a secret manager | Freshly generated key-encryption key (once) |
| Host environment → `Lockspire.Config` | `{id, {:system, "VAR"}}` entries are read from the OS environment at runtime | Key-encryption key bytes (base64) |
| Config errors / verify / doctor / reencrypt → terminal, logs, admin relay | Error messages explain how to fix missing or invalid keys | Variable names and commands only (never values) |
| Clean-room harness → CI evidence | Harness runs gen.kek in a child host and captures output | Generated key in child stdout |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-159-01 | Tampering | `--id` interpolation into printed snippet | medium | mitigate | `KeySet.valid_id?/1` (key_set.ex:30) checked in `lockspire.gen.kek.ex:70` before printing; invalid-id tests in `lockspire_gen_kek_test.exs` | closed |
| T-159-02 | Information disclosure | gen.kek output | high | mitigate | No Logger/telemetry/File/Repo in task or `KekSnippet` (grep: 0 hits); dev/test note never embeds the key (`lockspire.gen.kek.ex:96-97`); capture_log + empty tmp cwd test | closed |
| T-159-03 | Information disclosure | clean-room `--check-gen-kek` | high | mitigate | `build_provider.py` `_scrub` (l.435) on stderr tails, value never echoed; ExUnit `:gen_kek` case refutes 44-char base64 in output (`phase133_provider_install_test.exs:47`) | closed |
| T-159-04 | Spoofing | weak key generation | medium | mitigate | `KekSnippet.generate_key/0` uses `:crypto.strong_rand_bytes(32)` (kek_snippet.ex:15); output round-trips `KeySet.new/1` in tests | closed |
| T-159-05 | Denial of service | gen.kek on a host whose runtime config raises | low | mitigate | No `@requirements`/app.config/app.start in the task; clean-room cold proof (`--check-gen-kek`) green | closed |
| T-159-06 | Tampering | silent unencrypted fallback on missing variable | high | mitigate | `resolve_env_entries` halts with `{:keys, :missing_env, var}` (config.ex:281-283) → `fail_key_encryption!/3` raises; test asserts cache never becomes `:unconfigured` (config_key_encryption_test.exs:272) | closed |
| T-159-07 | Information disclosure | missing_env and config error messages | high | mitigate | Message interpolates only the variable name (config.ex:315-317); tests refute sentinel values, trailing-newline and short values | closed |
| T-159-08 | Information disclosure | key baked into beam files or app env | medium | mitigate | Runtime `System.fetch_env/1` only; no `compile_env`/`Application.put_env`/`String.trim` in config.ex (grep: 0); test asserts app env still holds the tuple | closed |
| T-159-09 | Information disclosure | inspect/Logger of resolved KeySet | medium | mitigate | `key_set_inspect.ex` unchanged vs 0ba2b724; inspect/log tests for base64/raw/url-safe/hex forms (`structs: false` not claimed) | closed |
| T-159-10 | Tampering | guidance drift to a weaker or wrong recipe | medium | mitigate | `test/lockspire/kek_guidance_contract_test.exs`; `openssl rand` in lib/docs: 0; `elixir -e` only in `docs/upgrading/signing-key-encryption.md`; phx.gen.secret warning pinned | closed |
| T-159-11 | Information disclosure | docs/messages carrying an example key | medium | mitigate | No 44-char base64 values in either guide (grep: 0); messages name only commands and the variable | closed |
| T-159-12 | Tampering | unintended protocol/default/dependency change | high | mitigate | SAFE-02: `git diff --quiet 0ba2b724 -- mix.exs mix.lock priv lib/lockspire/protocol lib/lockspire/storage` clean | closed |
| T-159-SC | Tampering | package installs (npm/pip/cargo/hex) | high | accept | Phase installs no packages; see AR-159-01 | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-159-01 | T-159-SC | No dependencies added or changed (mix.exs/mix.lock unchanged vs phase base); no supply-chain surface introduced | plan-time threat model (159-01/02/03) | 2026-10-19 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-19 | 13 | 13 | 0 | secure-phase orchestrator (L1 grep-depth, plan-time register) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-19
