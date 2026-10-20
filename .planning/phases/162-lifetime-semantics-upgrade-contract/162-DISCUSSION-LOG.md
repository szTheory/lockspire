# Phase 162: Lifetime Semantics & Upgrade Contract - Discussion Log

> Audit trail only. Do not use as downstream planning/research/execution input. Selected decisions are in 162-CONTEXT.md.

**Date:** 2026-10-20
**Mode:** assumptions; user-directed research fanout and automatic adoption
**Areas:** protocol/security, legacy storage/deployment/concurrency, adopter/operator DX, standards verification

## User direction and decision authority

The user explicitly requested subagents, primary-source research where useful, breadth/depth through relevant stakeholder roles, an adversarial pass, coherent one-shot recommendations, and to “auto follow those.” They prefer small/flat dependency trees. This instruction supplied selection authority for the researched bundle; no separate yes/proceed response is fabricated. The workflow's usual per-assumption interview was replaced by that explicit direction. Prior milestone scope approval alone was not treated as semantics approval.

## Research execution

Three typed gsd-assumptions-analyzer agents ran independent read-only code analysis with the configured adaptive model/effort. Their role prohibits external research; they flagged RFC/database gaps instead. All three reached terminal results before a separate general agent verified primary online sources. The parent synthesized after all terminal results, without duplicate parallel investigation. No child edited files or ran runtime tests.

| Lane | Findings | Confidence |
|---|---|---|
| protocol_semantics | Full consumer inventory, independent credentials, missing enabled gate, offline signer/response/persistence disagreement, lost injected clock | High on source facts; recommendations selected in context |
| upgrade_storage | Ambiguous legacy dates, stale full-row replacements despite locks, minimal v0/v1 canonicalization, adapter contract, maintenance cutover and rollback | High on source facts; v1 shape is selected design |
| adversarial_dx | Intake-disabled management lockout, no implicit app revival, policy validation bypass, deadline discovery, false PUT secret-rotation docs, vacuous telemetry proof and actor attribution | High on source facts; product choices selected in context |
| primary_source_verification | RFC response/replacement/error rules, management availability guidance, offline limits, PostgreSQL time/lock semantics, scoped token capping, Keycloak comparison | High on verified source constraints |

## Assumptions synthesized and alternatives rejected

| Decision area | Selected recommendation | Alternative / tradeoff |
|---|---|---|
| Defaults | Nil/zero unlimited; positive issuance snapshot | Finite defaults improve retirement but silently change deployed acceptance; zero-immediate makes issuance unusable |
| Policy timing | Prospective issuance/rotation | Retroactive edits surprise integrations and cannot revoke offline signed JWTs |
| App lifetime | Request-time eligibility; no implicit renewal | Pruner-only lags; renewing on ordinary PUT defeats finite policy; permanent disable conflates administrative action and expiry |
| Token effects | Cap new access/refresh at app deadline; recheck online artifacts | Cap every artifact adds unrelated ID-token/flow churn; no caps leaves avoidable offline access tail for new tokens |
| Management | Default unlimited; optional finite with host recovery; expired GET/DELETE only | All-block strands diagnosis/cleanup; allowing expired PUT risks revival; dual-token overlap adds state |
| API discovery | Two server-owned namespaced expiry fields | Docs-only finite RAT timing is undiscoverable; headers less durable; standard fields cannot be repurposed |
| Legacy | Grandfather effective unlimited; whole-row canonicalization on credential replacement | Enforce/reconstruct old dates causes breakage; per-credential provenance adds combinations without a proven history-display need |
| Storage | Explicit one-version conformance at adapter boundary | Silent fallback/field dropping is a security bypass; generic capability framework is unnecessary |
| Concurrency | Current locked state/hash and fresh decision clock; intended patch only | Row lock plus stale replacement resurrects secrets/active state; transaction-start time permits post-expiry writes |
| Deploy | Additive schema + drain/cutover; fix forward after v1 | Mixed-version service routes around enforcement; bridge release possible but additional scope |
| DX | Existing operator recovery, truthful copy/events, no deps | New recovery authority broadens attack surface; UI internals and new abstractions burden adopters |

## Corrections during synthesis

- Protocol lane initially considered denying all management after app expiry; reconciled to valid-token read/delete only, preserving deliberate disablement denial.
- Protocol lane proposed capping codes/PAR/device/CIBA/ID tokens too. Primary-source/adversarial review showed online rechecks suffice for intermediate artifacts and ID-token expiry does not govern RP sessions. Selected access/refresh cap only.
- Chose one v0/v1 marker with mandatory whole-row canonicalization over per-credential markers. Explicitly prohibit marker-only promotion.
- Selected maintenance cutover rather than inventing persistent activation coordination. Downgrade after v1 writes is explicitly unsupported for old binaries.
- Selected read-only extension echo handling, preserved standard PUT prohibited fields, and documented a local `registration_expired` code for authenticated forbidden PUT. It is not an RFC-defined error.
- Preserve existing 401 client-auth behavior where standards permit; do not expand scope into global error-code normalization.
- Chose no new legacy-adoption command or app renewal surface. Legacy credential replacement establishes finite policy; finite app lifetime requires a new registration.

## Methodology and stakeholder lenses applied

Applied all five .planning/METHODOLOGY.md lenses: assumption-first, least-surprise host seam, research-first defaults, high-threshold escalation and coherent recommendation bundles. Security examined method/endpoint bypass, replay, stale authority, lockout and redaction. Architecture/Elixir reviewed pure helpers, explicit dependency boundaries and existing transactions. Distributed-systems/SRE reviewed authoritative state, locks, clock freshness, deployment and downgrade. Product/partner DX reviewed defaults, discoverability, independent lifecycle meanings and lost-response recovery. Support/operator language reviewed actual outcomes against PRODUCT.md. No visual redesign was proposed; unrelated rendering/graphics roles were intentionally excluded.

## External research

- RFC7591 §3.2.1: Unix-secret timestamps/zero and additional fields; policy duration zero is not specified. https://www.rfc-editor.org/rfc/rfc7591.html#section-3.2.1
- RFC7592 §§2,5 (Experimental): management tokens SHOULD NOT expire while active; rotation and full-replacement/error rules; 403 for forbidden valid-token operation. https://www.rfc-editor.org/rfc/rfc7592.html
- RFC6749 §§4.1.2.1,5.2 and RFC6750 §3: redirect safety, `invalid_client`, Basic challenge, missing vs invalid bearer. https://www.rfc-editor.org/rfc/rfc6749.html https://www.rfc-editor.org/rfc/rfc6750.html#section-3
- RFC7662 §§2,4: invalid caller vs inactive target and cache staleness. https://www.rfc-editor.org/rfc/rfc7662.html
- RFC7009 §3 and OIDC Core §2: offline revocation and ID-token/session limits. https://www.rfc-editor.org/rfc/rfc7009.html#section-3 https://openid.net/specs/openid-connect-core-1_0.html#IDToken
- PostgreSQL14: row locks/current rows, transaction/statement clocks vs fresh time, additive columns still need locks. https://www.postgresql.org/docs/14/explicit-locking.html#LOCKING-ROWS https://www.postgresql.org/docs/14/functions-datetime.html#FUNCTIONS-DATETIME-CURRENT https://www.postgresql.org/docs/14/ddl-alter.html#DDL-ALTER-ADDING-A-COLUMN
- Ecto3.13.5: existing query locks and atomic transactions suffice. https://ecto.hexdocs.pm/3.13.5/Ecto.Query.html#lock/3 https://ecto.hexdocs.pm/3.13.5/Ecto.Repo.html#transact/2
- Keycloak official rotation guidance separates replacement policy and old-secret overlap. Borrow explicit timing/activation; do not import its dual-secret overlap feature. https://www.keycloak.org/docs/latest/server_admin/index.html#_client_secret_rotation

## Remaining boundaries

No unresolved product choice blocks Phase 162 planning. Exact internal signatures/column helper names/test layout remain engineering discretion. The Phase162 contract must still be produced and verified before any Phase163–166 implementation plan. Runtime behavior, automated test results, CI, package publication and todo closure are not claimed by this discussion.
