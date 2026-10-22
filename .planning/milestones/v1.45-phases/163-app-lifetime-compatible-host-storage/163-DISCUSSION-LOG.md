# Phase 163: App Lifetime & Compatible Host Storage - Discussion Log

> **Audit trail only.** Do not use as input to planning, research or execution agents. Selected decisions are in 163-CONTEXT.md.

**Date:** 2026-10-20
**Mode:** assumptions; user-authorized research and automatic recommendation adoption
**Areas:** consumer eligibility, token truth, concurrency/clocks, storage authority, custom adapters, host upgrade, deterministic proof.

## Authority and prior decisions

The user explicitly requested subagents, breadth/depth through relevant roles, adversarial analysis, reputable primary sources, one coherent recommendation set and "auto follow those". This supplied authority to resolve the technical assumptions and capture decisions without an invented separate confirmation response. Phase 162's verified normative contract was carried forward rather than reopened. Project methodology also favors research-first decisive defaults. No product boundary or lifetime semantic changed.

## Delegated analysis

Three typed gsd-assumptions-analyzer agents used configured adaptive routing (gpt-6.1-sol, xhigh), read-only and with disjoint ownership. All reached terminal results before external research. A fourth primary-source researcher verified the remaining pinned Ecto/PostgreSQL details.

| Area | Selected recommendation | Confidence | Evidence |
|---|---|---|---|
| Consumers | Shared eligibility plus endpoint errors and final guards; no global storage filtering | Confident after synthesis | ClientAuth, AuthorizationFlow, CIBA worker, Phase 162 contract |
| Token consistency | One effective persisted expiry drives JWT and response | Confident | TokenIssuer, AccessTokenSigner, RefreshExchange, RFC8693 |
| Ordering | Current state/credential identity, stable client locks, fresh time after final blocking lock | Confident | GrantPersistence, TokenStore, PG14 lock/clock docs |
| Adapter support | Adapter-owned declaration and explicit shared transaction authority | Likely, selected | ClientStore, Dependencies, LegacyOptions, architecture tests |
| Legacy state | Explicit v0 only; missing is invalid; new constructors v1 | Confident after synthesis | Domain.Client, ClientRecord, normative contract |
| Migration | New prefix-aware expansion; unchanged shipped bytes; exclusive-lock caveat | Confident | Migration inventory/helper, PG14 ALTER TABLE |
| Upgrade proof | Real database and pinned old/candidate process proof plus conformance | Likely, selected | InstallUpgrade tests, clean-room package_root seam |
| Race proof | Independent sessions, identified PID/blocker and injected clock | Confident after research | Existing barriers, Ecto sandbox, pg_blocking_pids |

## Adversarial findings incorporated

- ClientAuth omits universal active checks; public, resumed and push paths bypass secret-only gates.
- CIBA push calls stable issuance directly, without ClientAuth; host approval also uses ambient wall time.
- RFC8693 validates token rows without current source-app checks and loses durable actor identity into claims.
- UserInfo's hardcoded Ecto client lookup conflicts with injectable storage.
- Refresh signs and timestamps before locks; checking only the first client lock misses a later grant lock spanning expiry.
- Current locked client replacement can still restore stale whole-row fields.
- JARM redirect construction occurs inside transaction closures and may fetch remote JWKS.
- Callback presence/permissive capabilities do not establish shared rollback or durable field preservation.
- Shared SQL sandbox tasks do not prove independent transactions; a global blocked-query count does not prove the intended race.
- File-copy upgrade tests alone do not establish old-binary database compatibility.

## Tradeoffs resolved

Use narrow shared eligibility rather than duplicated rules or hidden filtering. Use explicit adapter-owned support rather than request assertions or a general discovery framework. Require supported shared transaction ownership rather than inventing a distributed coordinator. Keep current API clock conventions with explicit adaptation rather than global state or broad public churn. Preserve existing response modes while moving delivery outside locks. Keep one outer rollback boundary rather than relying on misleading nested return values. Accept brief documented cutover rather than adding a mixed-version bridge.

## External research

- Actual pins: Ecto 3.13.6, Ecto SQL 3.13.5, Postgrex 0.22.4. Repo.transaction callback error tuples can commit unless explicitly rolled back; Repo.transact commits ok tuples/rolls back error tuples. Nested rollback aborts outer authority. Source: https://raw.githubusercontent.com/elixir-ecto/ecto/v3.13.6/lib/ecto/repo.ex
- READ COMMITTED locking selects wait and inspect updated rows, but related rows need their own ordered locks. Sources: https://www.postgresql.org/docs/14/transaction-iso.html and https://www.postgresql.org/docs/14/explicit-locking.html#LOCKING-ROWS
- now/CURRENT_TIMESTAMP are transaction-start; statement_timestamp is statement-start. Explicitly sample injected time after all waits. Source: https://www.postgresql.org/docs/14/functions-datetime.html#FUNCTIONS-DATETIME-CURRENT
- Nullable additions/constant defaults avoid rewrite but still require ACCESS EXCLUSIVE; no production duration inferred. Source: https://www.postgresql.org/docs/14/sql-altertable.html
- Independent sessions and expected pg_blocking_pids relationships establish lock waits; shared sandbox ownership does not. Sources: https://www.postgresql.org/docs/14/functions-info.html#FUNCTIONS-INFO-SESSION-TABLE and https://raw.githubusercontent.com/elixir-ecto/ecto_sql/v3.13.5/lib/ecto/adapters/sql/sandbox.ex

## Corrections and auto-resolution

No separate user corrections occurred. Likely architecture choices were selected under the user's automatic-adoption instruction. Primary sources corrected the assumed Ecto package pin and strengthened transaction/locking cautions. No unresolved product choice remains for planning. The matched umbrella todo remains pending for Phase 166. No runtime behavior is claimed by this discussion.
