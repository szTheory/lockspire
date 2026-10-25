# SEC-01 integration and recommended sequence

Researched 2026-10-25 by the current agent, inline. Source evidence identifies integration work; it does not establish runtime acceptance. Exact public option/callback/task names remain Phase 175 design output, not invented supported APIs.

## Current paths

| Boundary | Current owner and observation | Required change / preserved responsibility |
|---|---|---|
| Encrypt/decrypt | `Security.Policy` seals/verifies with Plug.Crypto, a fixed salt and explicit or inferred endpoint `secret_key_base`. `ClientAuth.ClientSecretJwt` calls that reader. | One explicit verifier-custody boundary; keep environment resolution in outer configuration/adaptation. Typed failures must reach existing invalid-client handling without raw exception values. |
| Configuration | `Config` and `Application` validate/cache signing KEKs; `KeySet` is pure and has redacted Inspect. | Independent verifier config and resolved set; separate compatibility policy from signing `legacy_plaintext`. Validate configured cross-purpose key reuse and specify missing-config behavior without breaking unrelated host auth at boot. |
| Direct registration | `Clients.normalize_client_attrs/1` generates material before `normalize/1` chooses client ID. | Establish canonical identity before client-bound sealing or finalize encryption at a documented persistence boundary. Preserve documented helper behavior; no hidden unbound fallback for persisted new envelopes. |
| DCR | `Registration.generate_credentials/2` generates material before its client ID. Basic/post/JWT methods all receive verifiers. | Cover every actual shared-secret writer; preserve DCR policy, one-time handoff and secret hashing. |
| Operator rotation | `Admin.Clients` generates material; `ClientLifecycle` delegates rotation and audit through configured transaction/client stores. | Seal for the existing client ID; keep secret issuance as an explicit operator action. Maintenance rewrap is a different operation. |
| Persistence | Client `:text`/`:string` field, repository client store, configured `ClientStore` and shared transaction authority. Row locking already exists for rotation/lifetime. | Text-safe envelope and narrow atomic maintenance capability; all writes use the selected store or fail explicitly. No silent direct-Ecto fallback for an unsupported configured adapter. |
| Maintenance | Signing-key re-encryption demonstrates per-row transactions, round-trip validation, bounded apply pages, redacted errors and audit/telemetry. | Reuse patterns, not signing-specific row logic. A verifier-only update preserves other client fields and atomically records its truthful audit outcome. |
| Operator DX | Existing RepoRunner/TaskError, install/upgrade/verify and diagnostics. | Extend narrow maintainer/host operations, use existing repo startup and redacted task errors; no new broad admin page. Read PRODUCT.md before any actual UI copy change. |

## Recommended contract

1. Host-controlled dedicated verifier key set with explicit active write selection and legacy compatibility/write stage. Keys are independent of endpoint `secret_key_base` and signing KEKs. Fresh installs receive dedicated-mode guidance; existing unconfigured hosts retain a declared compatibility path rather than a surprise global boot failure.
2. Versioned text-safe authenticated envelope; bind the purpose and stable client ID, authenticate the selected key ID/header, use fresh 96-bit IVs and fixed 128-bit tags. Unknown new-format versions/tampering never retry as legacy. Exact parsing limits and formats freeze with adversarial fixtures before implementation.
3. Reader-first rollout: new release reads permitted legacy and dedicated formats while still writing the old compatible format; deploy read keys everywhere; explicitly enable dedicated writes; rewrap/check; only then reject legacy or retire old keys. Do not dual-write plaintext or duplicate durable verifiers. New-format writes bound how far code rollback is safe.
4. No request-time automatic migration. Rewrap runs through a scoped operator operation, locks/reloads current state, checks expected verifier/secret generation, opens/seals/round-trips, changes only ciphertext and commits audit atomically. Conflict/failure preserves the current row and is reported; concurrent maintenance runs converge. A single transaction authority covers configured stores.
5. Inventory all stored verifier rows, including disabled/expired apps and basic/post clients that retain verifier material. Missing optional verifier fields are classified, not fabricated. Database-unavailable or partial inventory cannot attest readiness. A local check is not proof every node has keys or the same write mode.

## Adversarial alternatives

| Alternative | Why not recommended |
|---|---|
| Reuse signing KEK and existing `LSK` bytes unchanged | Couples custody again; signing AAD and binary storage are wrong for this client field. |
| New general cipher framework | Expands public abstraction and review surface for one purpose. A small private primitive extraction is enough if it reduces duplication and preserves signing bytes. |
| Enable new writes whenever keys first appear | During rolling deployment, old readers can encounter unsupported ciphertext. Explicit writer activation is necessary. |
| Rewrap with `rotate_client_secret` | Would alter hash/expiry/rotation semantics and invalidate partner credentials. Add a verifier-only atomic operation. |
| Read all rows from Ecto regardless of configured adapter | Gives status for one store and mutation for another; contradicts selected host storage ownership. |
| Rewrap only active JWT clients | Misses stored material and can strand disabled or subsequently reconfigured clients after key retirement. |

## Dependency order for roadmap

Qualify fresh accepted-main entry and finite compatibility/storage/age contract → implement custody plus production readers/writers → implement safe maintenance/status/recovery → prove packaged fresh/upgrade/mixed-key journeys and deliver through normal verification/CI/main acceptance. Four coherent outcomes are sufficient; exact phase approval follows requirements. Do not schedule UI, KMS or scale work within these outcomes.

## Evidence and limits

Primary source [PostgreSQL 14 locking](https://www.postgresql.org/docs/14/explicit-locking.html) supports the reload-under-lock recommendation; it does not prove Lockspire's race handling. Integration must use real concurrent connections and forced rollback. Local files: `clients.ex`, `protocol/registration.ex`, `admin/clients.ex`, `client_lifecycle.ex`, `storage/client_store.ex`, `storage/ecto/repository/client_store.ex`, `storage/ecto/client_record.ex`, `admin/keys/reencrypt.ex`, `config.ex`, `application.ex`. Relative source names are under `lib/lockspire/`.
