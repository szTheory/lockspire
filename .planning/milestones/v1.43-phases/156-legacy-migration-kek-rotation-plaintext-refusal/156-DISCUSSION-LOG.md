# Phase 156: Legacy Migration, KEK Rotation & Plaintext Refusal - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md; this log preserves the analysis.

**Date:** 2026-10-16
**Phase:** 156-legacy-migration-kek-rotation-plaintext-refusal
**Mode:** assumptions, with a user-requested research fan-out (4 parallel agents: codebase analyzer, Postgres/Ecto concurrency, operator CLI/DX, refusal/telemetry/audit)
**Areas analyzed:** Re-encryption engine, Storage seam, Public API and CLI, Readiness gate (check/doctor/verify), Plaintext refusal, Telemetry and audit, Tests

## Assumptions Presented

### Re-encryption engine
| Assumption | Confidence | Evidence |
|---|---|---|
| Per-row transaction: FOR UPDATE → classify after lock → seal → round-trip → CAS → audit | Likely → resolved | `signing_key_store.ex:134-202` (activate locks two rows out of id order), `:190-195` locked_key |
| Classify in Elixir, not SQL WHERE (EvalPlanQual) | Confident | PostgreSQL transaction-iso docs |
| Legacy JWK `kid` must match row before sealing; re-serialize ETF to JSON | Likely | `private_jwk.ex:45` vs `:52-57` (no legacy kid check) |
| Engine bypasses `:reject` via internal legacy-tolerant entry | Likely | recovery from restored backups / premature reject |

### Storage seam
| Assumption | Confidence | Evidence |
|---|---|---|
| New KeyStore callback, Ecto impl in SigningKeyStore, one-line Repository delegate | Confident | `key_store.ex:10-25`, `repository.ex:482-532`, `architecture_fitness_test.exs:84-91` |

### Public API, CLI, readiness gate
| Assumption | Confidence | Evidence |
|---|---|---|
| Task uses app.config + ensure_all_started(:ecto_sql) + with_repo (ecto.migrate pattern) | Likely | `verify.ex:370`, `lockspire.test.setup.ex:37`, ecto_sql `ecto.migrate` source |
| Per-row failures inside `{:ok, report}`; Mix.raise exit 1 on failure | Confident | existing tasks; Mix docs |
| encryption_status opens every envelope (deep), shared by --check/doctor/verify | Unclear → resolved deep | C4 same-id/wrong-material |
| Verify errors only on broken-now; legacy under :allow stays ok | Unclear → resolved | KEK-02 non-breaking; 155 D-08 |
| No Lockspire.Release module | Likely | host owns `MyApp.Release` (phx.gen.release) |

### Refusal, telemetry, audit
| Assumption | Confidence | Evidence |
|---|---|---|
| Refuse before parsers in `decode_with_reason` legacy branch | Confident | `private_jwk.ex:26-64` |
| Hot path: direct `:telemetry.execute`, no audit mirror, no durable audit | Likely → user-confirmed | `verify_token.ex:478-496`, `token_issuer.ex:21-24` |
| Operator path via `Observability.emit(:key, …)` + durable `key_encrypted`/`key_rewrapped` | Confident | `admin/keys.ex:86-314` |
| Once-per-node Logger dedupe via persistent_term | Likely | no-key-material flag |

## Conflicts Resolved During Synthesis

- **Batch lock vs per-row lock.** The concurrency researcher proposed `ORDER BY id FOR UPDATE` batches with a deadlock retry. The codebase analyzer proposed per-row transactions. Resolved: per-row. A transaction holding one lock cannot deadlock with `activate`, there is no retry code to write, and the cost at tens of rows is negligible. Both reports agreed this is safe.
- **Shallow vs deep `--check`.** The CLI researcher proposed header-only. Resolved: deep (open and discard), so `ready?` and verify's broken-now check catch a KEK id carrying the wrong material.
- **CLI row identifier.** The CLI researcher proposed the admin handle `kid_<hash>`. Resolved: raw `kid`, which is public in JWKS and identical to audit/telemetry, so operators can grep across them.
- **Telemetry path.** The codebase analyzer proposed `Observability.emit` for hot-path events. Resolved: direct `:telemetry.execute`, following the documented `verify_token.ex` precedent that avoids flooding the audit mirror.
- **Redaction drop-list pull-forward.** The telemetry researcher proposed adding drop keys now. Resolved: deferred to the 157 RED-01 sweep (a generic `keys` drop key risks collateral damage); 156 relies on allowlisted builders plus leak tests.

## Corrections Made

No corrections. The user confirmed all recommendations, including the D-23 wording correction to ROADMAP criterion 5 and OPS-02 (hot-path events are telemetry-only).

## External Research

- PostgreSQL READ COMMITTED re-check / EvalPlanQual: https://www.postgresql.org/docs/current/transaction-iso.html
- Row locks, plain SELECT not blocked, deadlock ordering: https://www.postgresql.org/docs/current/explicit-locking.html
- SKIP LOCKED "inconsistent view… not suitable for general purpose work": https://www.postgresql.org/docs/current/sql-select.html
- Ecto SQL Sandbox `unboxed_run`: https://ecto-sql.hexdocs.pm/Ecto.Adapters.SQL.Sandbox.html
- `Ecto.Repo.transact/2`, `transaction/2` deprecation in 3.14: https://ecto.hexdocs.pm/Ecto.Repo.html
- `Ecto.Migrator.with_repo/3`: https://ecto-sql.hexdocs.pm/Ecto.Migrator.html; `ecto.migrate` source: https://github.com/elixir-ecto/ecto_sql/blob/master/lib/mix/tasks/ecto.migrate.ex
- Mix.Task requirements, `Mix.raise`: https://mix.hexdocs.pm/Mix.Task.html, https://mix.hexdocs.pm/Mix.html
- Releases / eval does not start apps: https://mix.hexdocs.pm/Mix.Tasks.Release.html; phx.gen.release: https://hexdocs.pm/phoenix/releases.html
- `ash.codegen --check` exit semantics: https://ash.hexdocs.pm/Mix.Tasks.Ash.Codegen.html
- Cloak migrator (brute-force rewrite, no dry-run, app.start): https://github.com/danielberkompas/cloak_ecto/blob/master/lib/cloak_ecto/migrator.ex
- Rails Active Record Encryption (`support_unencrypted_data` migration-only): https://guides.rubyonrails.org/active_record_encryption.html
- Vault Transit rewrap / `min_decryption_version`: https://developer.hashicorp.com/vault/api-docs/secret/transit
- AWS KMS ReEncrypt (SourceKeyId, DryRun): https://docs.aws.amazon.com/kms/latest/APIReference/API_ReEncrypt.html
- Ory Hydra secret rotation (no re-encrypt): https://www.ory.com/docs/hydra/self-hosted/secrets-key-rotation
- Kubernetes encrypt-data rotation steps: https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/
- MultiFernet.rotate: https://cryptography.io/en/latest/fernet/#cryptography.fernet.MultiFernet.rotate

## Target CLI Output Shapes (from CLI research)

```
$ mix lockspire.keys.reencrypt
current_kek=2026-10 legacy_plaintext=allow
scanned=7 encrypted=4 rewrapped=2 already_current=1 failed=0
Next: run `mix lockspire.keys.reencrypt --check`, then set legacy_plaintext: :reject.

$ mix lockspire.keys.reencrypt --dry-run
Dry run: no rows will be changed.
would encrypt  key=<kid> from=legacy   to=2026-10
would re-wrap  key=<kid> from=2026-01  to=2026-10
scanned=7 would_encrypt=2 would_rewrap=1 already_current=4 failed=0
Dry run complete. Run without --dry-run to apply.

$ mix lockspire.keys.reencrypt --check            # pass
current_kek=2026-10 total=7 on_current=7 legacy=0 other_kek=0 unknown_kek=0
Ready: every signing key is sealed with key-encryption key 2026-10.
Next: set legacy_plaintext: :reject. Key-encryption keys other than 2026-10 now protect 0 rows and can be removed.

$ mix lockspire.keys.reencrypt --check            # fail, exit 1
current_kek=2026-10 total=7 on_current=4 legacy=2 other_kek=1 (2026-01=1) unknown_kek=0
Not ready: 3 signing keys still need re-encryption.
Run `mix lockspire.keys.reencrypt`, then check again.
** (Mix) lockspire.keys.reencrypt --check failed: 3 signing keys not on current key-encryption key

$ mix lockspire.keys.reencrypt                    # failure, exit 1
current_kek=2026-10 legacy_plaintext=allow
failed  key=<kid> reason=unknown_kek kek=2025-04
  fix: add key-encryption key 2025-04 back to :keys (not as current), deploy, and rerun.
scanned=7 encrypted=3 rewrapped=2 already_current=1 failed=1
** (Mix) 1 signing key could not be re-encrypted. The other rows were saved; rerun is safe.
```

Fix lines per reason: `decryption_failed` → "key material for id X does not match the key that sealed this row; check :keys"; unreadable legacy → "this stored key cannot be read; retire it and generate a replacement"; `kid_mismatch` (legacy) → "the stored key's kid does not match its row; retire it and generate a replacement"; `conflict` → "rerun".
