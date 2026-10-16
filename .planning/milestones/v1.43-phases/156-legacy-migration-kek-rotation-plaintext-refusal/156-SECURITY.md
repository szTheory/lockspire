---
phase: "156"
slug: "legacy-migration-kek-rotation-plaintext-refusal"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-10-16"
---

# Phase 156 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| operator -> `Admin.Keys.reencrypt/1` | operator-only entry (release rpc, Mix task); no HTTP route or admin UI | re-encrypt / dry-run / check commands |
| engine -> Postgres | engine rewrites `private_jwk_encrypted`; CAS parameters include legacy plaintext | private signing key material (critical) |
| engine -> telemetry/audit sinks | host-attached handlers and the durable audit table receive engine events | kid, KEK id, reason atoms only |
| concurrent writers -> signing-key rows | engine runs, `activate/retire/publish_key` and other nodes share rows | row state |
| operator shell -> Mix task argv | untrusted typing; a typo must never trigger a write | CLI flags |
| task / doctor / Verify -> terminal, CI logs | output copied into tickets and logs | kid, KEK id, counts |
| stored row -> `PrivateJwk` decoder | stored bytes may be legacy plaintext, tampered or foreign | private signing key material (critical) |
| config change -> running nodes | `legacy_plaintext` mode and KEK list reach nodes at different times | config |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-156-01 | Information disclosure | `SigningKeyStore.reencrypt_signing_key/4` CAS and locked read | high | mitigate | `sensitive_locked_key/2` and `replace_material/5` pass `sensitive: true` (`signing_key_store.ex`); `Support.maybe_disable_sensitive_logging/2` sets `log: false` and `telemetry_event: nil` (`support.ex:40-45`); leak test `test/lockspire/security/key_material_leak_test.exs` | closed |
| T-156-02 | Tampering | `Reencrypt.decide/3` double-wrap | high | mitigate | `Reencrypt.assess/2` and `decide/3` classify under `FOR UPDATE`; current-KEK envelopes return `{:keep, _}`; round-trip mismatch -> `:roundtrip_failed` (`admin/keys/reencrypt.ex:94-202`); `keys_reencrypt_test.exs`, `reencrypt_concurrency_test.exs` | closed |
| T-156-03 | Tampering | lost update vs concurrent runs, `activate`, `publish_key` | high | mitigate | `lock("FOR UPDATE")` plus CAS on old `private_jwk_encrypted`; only that column and `updated_at` set; `{0, _}` -> `:conflict` (`signing_key_store.ex`); `reencrypt_concurrency_test.exs` | closed |
| T-156-04 | Denial of service | lock ordering with `activate_signing_key` | medium | mitigate | one row lock per transaction in `reencrypt_signing_key/4`; coexistence test in `reencrypt_concurrency_test.exs` | closed |
| T-156-05 | Information disclosure | engine telemetry, audit metadata, report | high | mitigate | allowlisted event builders; exceptions mapped to `:storage_error` (`admin/keys/reencrypt.ex`, Mix task); leak test asserts exact key sets | closed |
| T-156-06 | Tampering | dry-run path | medium | mitigate | `dry_run/2` (`admin/keys/reencrypt.ex:206`) never calls the store write callback; before/after row and audit comparison in `keys_reencrypt_test.exs` | closed |
| T-156-07 | Denial of service | writing an undecryptable envelope (stranded key) | high | mitigate | seal and verify with one freshly resolved key set; mismatch -> `:roundtrip_failed`, nothing written | closed |
| T-156-08 | Tampering | `lockspire.keys.reencrypt` argument parsing | medium | mitigate | `OptionParser.parse(args, strict: @switches)` with positional/invalid/conflict rejection before app start (`lib/mix/tasks/lockspire.keys.reencrypt.ex:30`); `lockspire_keys_reencrypt_test.exs` | closed |
| T-156-09 | Denial of service | removing an old KEK id while rows depend on it | high | mitigate | `Admin.Keys.encryption_status/0` opens every envelope with the fresh key set; `--check` exits 1 on unsealed or undecryptable live rows; rotation order in help text | closed |
| T-156-10 | Denial of service | setting `:reject` too early | high | mitigate | Verify errors on `:reject` with legacy rows (`install/verify.ex:451`); `--check` gate in help/Next lines (`verify.ex:480`) | closed |
| T-156-11 | Denial of service | Verify or doctor restarting a running repo pool | medium | mitigate | `RepoRunner.run/2` calls directly when `Process.whereis(repo)` is a pid (`install/repo_runner.ex:14`) | closed |
| T-156-12 | Information disclosure | task, doctor and Verify output | high | mitigate | kid/KEK id only; fixed sentences (`fix_text/2` in the Mix task); output tests assert no sentinel `d`, KEK base64 or "LSK" | closed |
| T-156-13 | Denial of service | `Install.Verify` crashing on DB errors | low | mitigate | `safely/1` rescues `MatchError`, `DBConnection.ConnectionError`, `Postgrex.Error`; `safe_message(%MatchError{})` avoids inspecting terms (`install/verify.ex:491-500`) | closed |
| T-156-14 | Elevation of privilege | `PrivateJwk.decode_stored/2` refusal bypass | high | mitigate | `refuse_plaintext?/2` returns `:plaintext_key_refused` before `read_stored/2` reaches Jason or the term parser (`protocol/private_jwk.ex:103-113`); `private_jwk_test.exs` | closed |
| T-156-15 | Information disclosure | hot-path telemetry and Logger | high | mitigate | `Redaction.for_telemetry/1` on fixed maps (`private_jwk.ex:122,145`); logs interpolate kid and reason only; sentinel leak test | closed |
| T-156-16 | Denial of service | alarm flood during a key outage | medium | mitigate | telemetry only; write-once `:persistent_term` flag per kid+reason (`private_jwk.ex:154-160`) | closed |
| T-156-17 | Information disclosure | repo query log / telemetry of the CAS parameter | high | mitigate | same as T-156-01: `sensitive: true` -> `log: false` + `telemetry_event: nil`; leak test attaches to the repo query event and asserts absence in `params` / `cast_params` | closed |
| T-156-18 | Denial of service | mixed `:allow`/`:reject` nodes during a rolling restart | low | accept | see Accepted Risks Log AR-156-01 | closed |
| T-156-SC | Tampering | npm/pip/cargo/hex installs | high | mitigate | no dependency changes: `mix.lock` unchanged since `32355619`; the only `mix.exs` change is a docs extra from phase 157 (`db28270a`) | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-156-01 | T-156-18 | `legacy_plaintext` mode follows each node's boot-cached key set by design; during a rolling restart some nodes may still allow legacy reads. The flip to `:reject` is gated on `mix lockspire.keys.reencrypt --check` and documented in the task help and the signing-key-encryption upgrade guide. | plan 156-03 threat model | 2026-10-16 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-16 | 19 | 19 | 0 | gsd-secure-phase (L1 grep verification, auditor short-circuit) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-16
