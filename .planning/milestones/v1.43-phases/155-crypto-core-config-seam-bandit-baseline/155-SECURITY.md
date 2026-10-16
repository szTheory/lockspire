---
phase: "155"
slug: "crypto-core-config-seam-bandit-baseline"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-10-16"
---

# Phase 155 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Host runtime config → Lockspire | Host supplies `:key_encryption` KEKs via runtime config | KEK material (secret) |
| Lockspire → database | Private signing JWKs stored in `private_jwk_encrypted` | Sealed AES-256-GCM envelopes (legacy rows plaintext until Phase 156 re-encrypt) |
| Database → signers | Six consumers decode stored keys to sign/decrypt | Envelope ciphertext → in-memory JWK |
| Operator tooling → stdout | `mix lockspire.verify`, `mix lockspire.doctor key_encryption`, boot logs | KEK ids, mode, reason atoms only |
| Hex → host apps | Bandit/thousand_island/hpax/mint upgrades | Third-party code |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-155-01 | DoS | Bandit HTTP/2 blocked-send | medium | mitigate | `bandit == 1.13.1` pinned in demo + both clean-room hosts; locks verified | closed |
| T-155-02 | Spoofing | Bandit HTTP/1 target vs Host | medium | mitigate | Same pin/locks as T-155-01 | closed |
| T-155-03 | Tampering | mint 1.9.3 advisories | medium | mitigate | mint 1.11.0 in all host + compat locks | closed |
| T-155-04 | Tampering | Lock drift | low | mitigate | Only bandit/thousand_island/hpax/mint moved | closed |
| T-155-05 | Tampering | `open/3` truncated tag | high | mitigate | `parse/1` binds `binary-size(12)` IV, `binary-size(16)` tag; key_encryption_test.exs:64,:113 | closed |
| T-155-06 | Tampering | Ciphertext swapped between rows | high | mitigate | AAD binds label+header+kid; key_encryption_test.exs:53 | closed |
| T-155-07 | Tampering | KEK-id / version downgrade | medium | mitigate | Version 1 only; header in AAD; key_encryption_test.exs:74 | closed |
| T-155-08 | Info Disclosure | IV reuse | high | mitigate | `:crypto.strong_rand_bytes(12)` per seal, no IV param; key_encryption_test.exs:98 | closed |
| T-155-09 | Info Disclosure | KEK in boot error / verify / crash | high | mitigate | Atom-only error tuples; `fail_key_encryption!` interpolates atoms; sentinel tests | closed |
| T-155-10 | Info Disclosure | KEK via inspect | medium | mitigate | `KeySet` Inspect omits keys; key_encryption_test.exs:148 | closed |
| T-155-11 | Tampering | Prefix confusion / legacy fall-through | high | mitigate | Strict `classify/1`; no legacy retry; property tests :131,:137 | closed |
| T-155-12 | DoS | `:crypto` raising on forged sizes | medium | mitigate | Size guards + rescue in `decrypt/5`; key_encryption_test.exs:83 | closed |
| T-155-13 | EoP | KEK at compile time / from endpoint secret | high | mitigate | Runtime `Application.get_env` only; no `secret_key_base`; static guard test | closed |
| T-155-14 | Info Disclosure | Raw KEK resident in app env | low | accept | See accepted risks AR-01 | closed |
| T-155-15 | Tampering | Decode without kid | high | mitigate | Map-form `PrivateJwk.decode/1` only; six consumers pass whole struct | closed |
| T-155-16 | Tampering | Forged envelope with mismatched JSON kid | high | mitigate | Post-decrypt kid check → `:kid_mismatch`; private_jwk_test.exs:28 | closed |
| T-155-17 | Tampering | Legacy fallback on envelope | high | mitigate | `:envelope` branch never reaches `decode_legacy` | closed |
| T-155-18 | Info Disclosure | Decrypted JWK in JWKS/discovery/KeyCache | high | mitigate | Fitness test architecture_fitness_test.exs:45 | closed |
| T-155-19 | Info Disclosure | Signer logging JWK/binary | medium | mitigate | Atom reasons; `decode/1` collapses to `:invalid_signing_key` | closed |
| T-155-20 | DoS | KEK outage raising in signers | medium | mitigate | rescue/catch in `decode_with_reason`; per-consumer unconfigured-KEK tests | closed |
| T-155-21 | Behavior | Protocol response change | medium | mitigate | Per-consumer error-shape tests (JAR `:decryption_failed`, signer server_error) | closed |
| T-155-22 | Info Disclosure | `generate_key` plaintext write | high | mitigate | Refuse when keyset nil; seal before `publish_key`; keys_test.exs:218-248 | closed |
| T-155-23 | Info Disclosure | KEK in verify/doctor output | high | mitigate | Fresh validation; ids/current/mode only; sentinel tests | closed |
| T-155-24 | Info Disclosure | `private_jwk_encrypted` via inspect | medium | mitigate | `@derive {Inspect, except: [:private_jwk_encrypted]}` on both structs | closed |
| T-155-25 | DoS | Clean-room broken by refusal | medium | mitigate | `clean-room-1` KEK in build_provider.py:74 + guard :369 | closed |
| T-155-26 | Repudiation | No audit trail | low | mitigate | Seal before `transact_with_audit`; refusal writes nothing | closed |
| T-155-27 | Tampering | Test KEK literal in build_provider.py | low | accept | See accepted risks AR-02 | closed |
| T-155-28 | Behavior | Demo admin Generate refuses until 157 | low | accept | See accepted risks AR-03 | closed |
| T-155-29 | Tampering | Stale cache in absent-KEK tests | low | mitigate | Only key_encryption_helpers.ex touches `:key_encryption` env | closed |
| T-155-SC (01–05) | Tampering | Package installs | high | mitigate | Only expected host deps moved; Bandit hard-pinned 1.13.1; no new root deps | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01 | T-155-14 | Raw KEK stays in app env after boot (host-owned runtime config). `{:system, "ENV"}` resolution is deferred as KEK-05. | Plan 155-02 threat model (milestone scope) | 2026-10-16 |
| AR-02 | T-155-27 | Clean-room acceptance fixture carries a fixed test-only KEK (`clean-room-1`); never shipped. Phase 157 generator must source the KEK from an env var (REVIEW IN-03). | Plan 155-04 threat model | 2026-10-16 |
| AR-03 | T-155-28 | Adoption demo has no KEK until Phase 157 (D-14); its admin Generate shows the generic failure flash. Time-boxed; no CI path exercises it. | Plan 155-04 threat model / CONTEXT D-14 | 2026-10-16 |

*Accepted risks do not resurface in future audit runs.*

Non-blocking carry-forwards (from 155-REVIEW-DISPOSITION.md): WR-01 `:reject` enforcement → Phase 156 (MIG-03); IN-01 failure-reason telemetry → Phase 156 (OPS-02).

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-16 | 33 | 33 | 0 | gsd-security-auditor (ASVS L1, block_on high) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-16
