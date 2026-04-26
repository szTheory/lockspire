# Phase 25: DCR Storage Skeleton, Domain Types, and Policy Resolver - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in `25-CONTEXT.md` — this log preserves the analysis.

**Date:** 2026-04-26
**Phase:** 25-dcr-storage-skeleton-domain-types-and-policy-resolver
**Mode:** assumptions
**Calibration:** standard
**Areas analyzed:** Migration Shape & Ordering, ServerPolicy Field Shape and Admin Surface, Client Provenance Fields and Backfill, InitialAccessToken Schema, DcrPolicy Resolver Shape and Discovery Binding

## Assumptions Presented

### Migration Shape & Ordering

| Assumption | Confidence | Evidence |
|---|---|---|
| Three additive migrations (server_policies extension → clients extension with in-place backfill → new IAT table) | Confident | `priv/repo/migrations/20260424180000_add_lockspire_server_policy_and_client_par_policy.exs`; ARCHITECTURE.md §"Build Order Level 1" |
| In-place backfill of `provenance = 'operator'` via `null: false, default: 'operator'` at `ADD COLUMN` time | Confident | Postgres atomic `ADD COLUMN ... NOT NULL DEFAULT`; small `lockspire_clients` table |
| `unique_index(:lockspire_initial_access_tokens, [:token_hash])` shipped in Phase 25 | Confident | Required by Phase 26 atomic redemption (DCR-11) |

### ServerPolicy Field Shape and Admin Surface

| Assumption | Confidence | Evidence |
|---|---|---|
| DCR fields as top-level columns on `lockspire_server_policies` | Confident | `lib/lockspire/storage/ecto/server_policy_record.ex:14`; `lib/lockspire/domain/server_policy.ex:15-18`; ARCHITECTURE.md §State Management |
| `registration_policy` as `Ecto.Enum` text column, default `:disabled` | Confident | Mirrors PAR text-as-enum pattern; success criterion 2 names tri-state literally |
| Allowlists as `{:array, :text}`; lifetimes as `:integer` seconds | Confident | `priv/repo/migrations/20260422000100_create_lockspire_core_tables.exs:11-13` array idiom |
| `Admin.ServerPolicy` extended in place with `get_dcr_policy/0` / `put_dcr_policy/1` | Confident | `lib/lockspire/admin/server_policy.ex:11-22` precedent |

### Client Provenance Fields and Backfill

| Assumption | Confidence | Evidence |
|---|---|---|
| Seven new columns on `lockspire_clients` (provenance, RAT hash, registration_client_uri, IAT FK, two timestamps) | Likely | `lib/lockspire/domain/client.ex:38-46` timestamp idiom; ROADMAP success criterion 1 |
| Two-value provenance enum `:operator | :self_registered` | Likely | Phase 28 success criterion 3 (`.planning/ROADMAP.md:72`); IAT-vs-open recoverable via `initial_access_token_id IS NOT NULL` |
| IAT FK uses `on_delete: :restrict` | Likely | Preserves audit trail; soft-delete via `revoked_at` is the supported retirement path |
| `client_id_issued_at` is a stored column, not derived from `inserted_at` | Likely | RFC 7591 §3.2.1 wants stable on-row field; ORM `inserted_at` semantics may diverge |

### InitialAccessToken Schema

| Assumption | Confidence | Evidence |
|---|---|---|
| Column set: id, token_hash (unique), expires_at, single_use bool, used_at, revoked_at, policy_overrides jsonb, created_by, timestamps | Likely | ARCHITECTURE.md §State Management |
| Schema-only in Phase 25; redemption in Phase 26 | Confident | DCR-11 explicitly assigned to Phase 26 |
| `single_use boolean` (default true), not `uses_remaining int` | Likely | Milestone says single-use default; v1.5 admin mints single-use only |
| Hash-at-rest reuses `Lockspire.Security.Policy.hash_token/1` | Confident | `lib/lockspire/security/policy.ex:84-89` is the established sink |

### DcrPolicy Resolver Shape and Discovery Binding

| Assumption | Confidence | Evidence |
|---|---|---|
| `Lockspire.Protocol.DcrPolicy.resolve/3` with `(server_policy, iat_overrides_or_nil, inbound_metadata)` signature | Likely | DCR-08 names `resolve/3` literally |
| Returns `{:ok, %Resolved{}} | {:error, :invalid_client_metadata, %{field, reason, allowed}}` | Likely | DCR-07 requires named-field rejection; `Admin.ServerPolicy` error-shape idiom at `lib/lockspire/admin/server_policy.ex:9` |
| Mirrors `lib/lockspire/protocol/par_policy.ex:1-52` shape | Confident | Only existing resolver precedent in repo |
| IAT overrides assumed already-narrowed at mint time, not re-validated for widening at resolve time | Likely | Mint-time validation is a Phase 28 concern; intersection naturally drops out-of-allowlist values |
| Invariant test at `test/lockspire/protocol/dcr_policy_invariant_test.exs` asserting `MapSet.equal?(intersection(server, discovery), accepted_dcr)` | Confident | DCR-09 verbatim |
| Add public `Lockspire.Protocol.Discovery.token_endpoint_auth_methods_supported/0` (does not exist today) | Confident | `discovery.ex:21,82` — only private `/1` plus module attribute exist |

## Repository-Truth Gaps Surfaced

These are codebase-vs-research discrepancies the analyzer caught that the planner needs to know about:

1. **JAR resolver module / migration cited by research does not exist in repo.** The `.planning/research/` corpus repeatedly cites `lib/lockspire/protocol/jar_policy.ex` and a v1.4 JAR-policy migration as precedents. Neither exists — only `par_policy.ex` and the v1.3 PAR migration are real. The actual v1.4 JAR slice did not ship a separate policy-resolver module.
   - **Impact on Phase 25:** PAR is the **only** structural precedent. Plan and research agents must cite `par_policy.ex`.

2. **`Lockspire.Protocol.Discovery.token_endpoint_auth_methods_supported/0` does not exist as a public function.** Only a private `/1`-arity helper plus a module attribute (`discovery.ex:21,82`) exist today.
   - **Impact on Phase 25:** Add a public `/0` accessor in this phase. Treat as a small in-phase task, not an external blocker.

## Corrections Made

No corrections — the user reviewed all five areas and selected "Yes, proceed". All assumptions promoted to locked decisions in `25-CONTEXT.md`.

## External Research

No external research performed — `.planning/research/` corpus (DCR-specific, 5 documents committed 2026-04-26) plus the codebase scout were sufficient.
