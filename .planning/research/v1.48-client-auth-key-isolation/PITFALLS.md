# SEC-01 failure modes and qualification

2026-10-25. Source plus one isolated synthetic dependency probe; no product/database/browser suite or fresh main acceptance executed.

## Fresh dependency observation: legacy ciphertext has an age

The locked Plug.Crypto 2.2.1 higher-level API defaults to one day. A probe with random process-local key material and a non-secret synthetic payload returned:

```text
plug_crypto: "2.2.1"
fresh_default_read: true
aged_default_result: {:error, :expired}
aged_explicit_unbounded_read: true
```

The aged input was minted with `signed_at` two days in the past. This proves dependency behavior only, not an actual adopter incident or a full Lockspire route counterexample. [Tagged implementation](https://raw.githubusercontent.com/elixir-plug/plug_crypto/v2.2.1/lib/plug/crypto.ex) and [reproducer](legacy_lifetime_probe.exs).

`Policy` supplies no override today. Therefore “all old rows survive migration” is not an honest unqualified promise. Phase 175 must compare this timer with declared client/secret lifetime and decide how usable, aged-but-authentic, malformed and truly expired credentials are classified. Do not silently choose `max_age: :infinity`, resurrect an expired credential, or reinterpret storage age as a new application lifetime. Any intended behavior correction needs a route/lifecycle reproducer, explicit policy disposition, documentation and negative tests; escalate a security-policy widening through GSD before implementing it. Rotation/reprovision remains the honest recovery option where compatibility does not permit a read.

## Threat and acceptance ledger

| Failure / threat | Prevention and required evidence | Owning outcome |
|---|---|---|
| Endpoint or signing-key reuse | Independent config/material; reject configured key-set overlap and prove rotation of one purpose does not alter another. Unknown external key reuse cannot be certified away. | Custody |
| Client/purpose substitution, truncated tag, forged version/key ID | Authenticated identity/purpose/header, strict bounded parser, fixed tag length; mutation and cross-client/cross-purpose rejection tests. Never retry failed new-format input as legacy. | Custody |
| Temporary client identity | Final client ID exists before sealing; direct, DCR and rotation writer tests inspect persisted identity-bound round trips. | Custody |
| Old reader encounters new writer | Reader-first rollout and explicit write activation; two-version host proof and honest rollback boundary. | Compatibility |
| Early key removal | Complete all-row inventory/check, explicit failures and old-key usage; missing key tests and key-loss runbook. | Maintenance |
| Secret rotation races with rewrap | Lock/reload under shared transaction authority, verifier-only writes and expected-generation checks; real PostgreSQL races prove new secret/hash/expiry win. | Maintenance |
| Concurrent rewrap or mid-run failure | Per-row atomic transactions, idempotent retry, honest partial/conflict counts and audit rollback. No whole-table lock or false all-success summary. | Maintenance |
| Custom-store capability missing | Declare narrow supported capability, fail before mutation with typed unsupported result, prove configured shared-authority adapter; no repository fallback. | Maintenance/proof |
| Status overclaims readiness | Separate inventory counts, successful decryptability and local runtime config; unavailable/incomplete check fails and node parity stays operator-owned. | Maintenance |
| Sensitive error/report data | Allowlisted IDs/counts/reasons only; inspect errors, SQL params, logs, telemetry, audit, task output and protocol bodies with secret/ciphertext sentinels. | All |
| Key loss | Fail affected JWT auth closed; preserve unrelated methods/host UX, restore a real key or authorize existing secret rotation. Do not claim impossible decryption or delete rows. | Recovery |
| Rewrap extends credential lifetime | Preserve hash, secret/client expiry and rotation timestamps byte-for-byte; lifecycle and expired-client negative proof after rewrap. | All |
| Success inferred from docs/unit test | Real persistence, bare-Mix repo startup, packaged lifecycle and required candidate/main gates. Local proof never becomes hosted/production proof. | Proof/delivery |

## Review and stop rule

These recommendations were adversarially checked inline against alternatives in ARCHITECTURE.md. No independent review is claimed. Stop broad research here: remaining unknowns are finite release/storage/rollout qualification cases, not a reason for an ecosystem survey. Do not create a KMS service, redefine supported JWT algorithms, move host account policy or start the UI candidate.
