# Phase 175: Accepted Baseline & Verifier Compatibility Contract - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-10-25
**Phase:** 175-accepted-baseline-verifier-compatibility-contract
**Mode:** assumptions; user-delegated scoped recommendation synthesis
**Areas analyzed:** accepted baseline, public helpers/identity, configuration/envelope, legacy age, store/transaction authority, rollout/recovery, disclosure, finite acceptance ownership.

## Authorization and Method

The user invoked `$gsd-discuss-phase 175`, then explicitly requested subagent fan-out, reputable primary sources, relevant prompt-corpus guidance, adversarial comparison, coherent recommendations and automatic adoption. This authorized substantive scoped choices without a preference interview; no empty question response or implicit default was used. It did not authorize skipping the GSD phase gates or treating discussion as runtime acceptance.

Configured mode was `assumptions`. Runtime identity was `@opengsd/gsd-core` 1.18.0. Init found Phase 175 with no context, research, plans or verification. No pending todo matched. Existing model-bake/global-default warnings were observed; tool installation and model configuration were not changed.

One typed `gsd-assumptions-analyzer` read the codebase and returned five assumption areas, followed by three independent read-only specialist reviews: crypto/legacy/rotation, storage/API/concurrency/redaction, and adversarial maintainer/contract review. No subagent wrote files or ran acceptance/CI/product tests. Research stopped after the independent reviews converged and further surveys would not alter the acceptance boundaries.

## Assumptions Presented and Adopted

| Assumption | Confidence | Evidence |
|---|---|---|
| Fresh accepted main and retained-delivery reconciliation belong to Phase 175 execution | Confident | ROADMAP, v1.48 BASELINE, exact-main helper, Phase 174 DELIVERY |
| Finite outcome ledger with Phase 175–178 owners is preferable to speculative implementation tasks | Likely | approved roadmap and requirements |
| Canonical client identity must precede sealing; hash-only API must remain usable | Confident on source; recommended compatibility fix | clients.ex, registration.ex, admin/clients.ex |
| Preserve ciphertext-sensitive in-flight authority and fresh-JTI retry | Confident | token_exchange/internal/client_authentication.ex, client_secret_jwt.ex |
| Migration must not promote mismatched hash/verifier pairs | Likely recommendation | independently persisted schema fields, existing JWT verifier reader |
| Explicit reader-first states and writer activation avoid old-code unreadability | High | current legacy-only reader; Rails/MultiFernet rotation precedent |
| Dedicated strict text family and purpose/client AAD fit current string storage | High; exact layout/bounds need qualification | ClientRecord string field, OTP AEAD, signing-envelope contrast |
| Existing age behavior must be qualified through persisted-client callers | Confident | Policy, Plug 2.2.1, independent configured lifetime checks |
| Migrating usable old material can extend age even if lifetime columns stay unchanged | High | Plug authenticated timestamp/default age; no-TTL wrapper counterexample |
| Optional maintenance capability over declared shared PostgreSQL authority fits current adapter support | High; callback names need freezing | ClientLifetime, ClientStore, TransactionStore, existing delegating fixture |
| Current locked row, verifier-only CAS and audit atomicity preserve concurrent authority | High | repository locking/rotation, Ecto/PostgreSQL docs |
| Disclosure proof must cover existing full-row queries and nested Inspect as well as new crypto | Confident | repository Support/client calls, domain/schema/result structs, Ecto SQL source |

## Synthesis and Alternatives

| Decision | Selected recommendation | Alternative and tradeoff |
|---|---|---|
| Baseline | Existing exact-main helper, byte-preserved receipt and separate custody annotations | A second acceptance mechanism duplicates truth and permits weaker joins |
| Runtime keys | Purpose-specific resolved per-node snapshot, explicit modes, restart changes | Hot reload adds stale-context/concurrency guarantees without a demonstrated need |
| Failure boundary | Redacted affected-operation failure; invalid never becomes absent/legacy | Blindly copying raising signing config can cause an unrelated whole-host outage; rejected under SEC-02 |
| Helper compatibility | Independent hash-only generation, identity-required dedicated persistence | Making all zero-argument helpers require IDs silently breaks callers |
| Format | Strict separate ASCII family over OTP AES-GCM, authenticated identity/header | Raw signing binary is unsuitable for existing text storage and purpose separation |
| Legacy conversion | Preserve authenticated original deadline; prove metadata extraction | Rewrap-time timestamp rejuvenates age; opaque wrapping retains endpoint dependency |
| Native age | Recommend configured lifetime; qualify and explicitly disposition before dependent planning | A native one-day timer preserves incidental dependency behavior but changes desired operator semantics; removing it without disposition would be silent policy expansion |
| Adapter scope | Existing built-in/shared-PG delegation, optional explicit maintenance capability | Arbitrary stores or direct-Repo fallback cannot establish selected authority/atomicity |
| Rewrap race | Preserve current fingerprint rejection and require fresh assertion/JTI | Hash-only identity could weaken divergence/stale-credential detection |
| Timestamps | Preserve every client field except ciphertext, including updated_at; audit maintenance | Generic client updates can mutate lifecycle metadata and obscure maintenance |
| Inventory | Bounded stable all-row scan, restart from beginning safely, explicit completeness | UI ordering/offset/candidate-filter scans can skip rows while rewriting |
| Redaction | Sensitive query flags plus schema/struct/output-boundary controls | Logger-only or Inspect-only protection leaves raw telemetry/arbitrary maps exposed |

### Material Issue Retained as an Execution Gate

The 23-hour legacy counterexample is not resolved by leaving credential-expiry columns untouched. High-level Plug decrypt does not return authenticated age metadata. The proposed narrowly pinned reader can use public key generation, message decryption and safe non-executable term decoding, but the serialized payload is a private compatibility shape that must be qualified. This discussion therefore does not claim metadata extraction is already supported or silently approve a lifetime-policy change. Phase 175 must freeze supported historical shapes, migrated deadline preservation and native dedicated age policy; unresolved material outcomes stop Phase 176 planning and require an explicit GSD revision when appropriate.

## Corrections Made

No user preference correction was needed: the user delegated scoped synthesis. Independent review refined the initial recommendations:

- Preserving a partner secret does not promise zero in-flight failures: current authority includes ciphertext and replay recording precedes issuance.
- Hash-only callers are a separate compatibility seam from persisted verifier generation.
- Rewrap must preserve effective legacy age, not merely database lifetime fields.
- Invalid verifier configuration must not be copied into a blanket host boot failure; satisfy the approved unrelated-authentication boundary.
- Maintenance redaction must include existing client SQL/Inspect paths.
- Exact envelope/config limits are proposals until compared with accepted input; arbitrary bounds cannot silently strand valid clients.

## External Research

- [Plug.Crypto 2.2.1 source](https://raw.githubusercontent.com/elixir-plug/plug_crypto/v2.2.1/lib/plug/crypto.ex): default 86400 seconds, authenticated timestamp/age tuple, strict-before expiry, future rejection, infinity bypasses both checks. Historic signed_at permits authentic aged fixtures without production overrides.
- [OTP 27](https://www.erlang.org/docs/27/apps/crypto/crypto.html#crypto_one_time_aead/7) and [OTP 28](https://www.erlang.org/docs/28/apps/crypto/crypto.html#crypto_one_time_aead/7): existing AEAD API suffices; caller must enforce the expected GCM tag length.
- [PostgreSQL 14 isolation](https://www.postgresql.org/docs/14/transaction-iso.html) and [locking](https://www.postgresql.org/docs/14/explicit-locking.html): post-wait current-row behavior at Read Committed; stronger isolation may serialize-fail.
- [Ecto 3.13.5 Repo](https://hexdocs.pm/ecto/3.13.5/Ecto.Repo.html): nested transactions do not create independently durable commits; targeted update semantics require deliberate timestamps.
- [Ecto schema redaction](https://hexdocs.pm/ecto/3.13.5/Ecto.Schema.html#module-redacting-fields), [tagged Ecto SQL source](https://raw.githubusercontent.com/elixir-ecto/ecto_sql/v3.13.5/lib/ecto/adapters/sql.ex), [Inspect](https://hexdocs.pm/elixir/1.18.4/Inspect.html): raw telemetry, schema inspection and arbitrary output are distinct disclosure surfaces.
- [RFC 7523](https://www.rfc-editor.org/rfc/rfc7523.html#section-3) and [OIDC client authentication](https://openid.net/specs/openid-connect-core-1_0.html#ClientAuthentication): custody changes do not justify widening authentication behavior; Lockspire retains its stronger required-JTI/replay contract.
- [MultiFernet rotation](https://cryptography.io/en/latest/fernet/#cryptography.fernet.MultiFernet.rotate): original timestamp preservation is useful precedent, not a dependency proposal.
- [Rails MessageVerifiers](https://api.rubyonrails.org/classes/ActiveSupport/MessageVerifiers.html) and [Django fallback settings](https://docs.djangoproject.com/en/5.2/ref/settings/#secret-key-fallbacks): staged readers/writers and retained readers illustrate safe transition and retirement responsibilities, not Lockspire acceptance evidence.

## Methodology and Prompt Corpus

Applied all five repository lenses: assumptions-first, least-surprise host seam, research-first defaults, high-threshold escalation and coherent recommendation bundles. Considered adopter/API compatibility, security/protocol, storage/concurrency, host operations, disclosure, maintainer/release integrity and documentation truth. The specialists consulted relevant existing milestone research and prompt guidance; prompt recommendations remain subordinate to current supported behavior. UI design is outside this phase; the newer brandbook remains the reference if later copy work becomes necessary.

## Evidence Limits

This discussion performed code/document analysis and primary-source research only. No fresh main acceptance, product/runtime test, caller-age qualification, real PostgreSQL race, package journey, hosted CI or release ran. The phase is ready to plan; VBASE-01/VBASE-02 remain pending. No public package or certification claim follows.
