# Phase 97: Contract + Docs First - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

A single authoritative protected-route doc page exists and is content-hash-pinned across four canonical locations before any runtime change lands in v1.27, so the implementation that ships in Phases 98–102 honors a documented contract instead of having later docs retrofitted to describe an accident.

In scope: `docs/protect-phoenix-api-routes.md` rewrite, `docs/supported-surface.md` non-goals subsection, install-template canonical-block carry, `release_readiness_contract_test` four-file content-hash clause, demo router + smoke script marker-comment alignment, removal of `docs/saas-adoption-recipe.md` plug restatement.

Out of scope (lands in later phases of v1.27): plug narrowing or `iss`/`typ`/`exp` enforcement (Phase 98), `Protocol.AccessTokenSigner` extraction and JWT-default issuance flip (Phase 99), DPoP/mTLS-bound `at+jwt` end-to-end proof (Phase 100), adoption-demo smoke proving `200 with issued token` (Phase 101), install-template uncomment + telemetry + migration guide + doctor task (Phase 102).
</domain>

<decisions>
## Implementation Decisions

### Canonical pipeline-block shape and hashing mechanism

- **D-01:** The canonical pipeline-declaration block is the **full `pipeline :lockspire_protected_api do ... end` Elixir form** — wrapper included — anchored in each of the four files by explicit marker comments `# BEGIN LOCKSPIRE_PROTECTED_PIPELINE` and `# END LOCKSPIRE_PROTECTED_PIPELINE`. Markers are the load-bearing locator; the block content between them is what gets hashed.
- **D-02:** `release_readiness_contract_test` adds one new clause that, for each of the four files, extracts the bytes between `BEGIN` and `END` markers, normalizes (left-strips the per-file uniform indent; strips the leading `# ` from each interior line on the Python file only), then `:crypto.hash(:sha256, normalized)` compares all four hashes — failing loudly with a diff if any pair differs.
- **D-03:** The Python smoke script `scripts/demo/adoption_smoke.py` carries the canonical block as a Python-comment block (every interior `.ex` line prefixed `# `) between the same `BEGIN/END` markers. After the normalization step in D-02, the post-strip byte sequence is identical across `.ex` and `.py` files.
- **D-04:** Reconcile the existing `dpop_replay_store:` drift by adopting the **placeholder name `MyAppWeb.ProtectedApiReplayStore`** in the canonical block. The demo's current `AdoptionDemo.Repo` value will be re-wired in Phase 101 (DEMO-01/02/03 already touch the demo pipeline) to consume this name via a thin adopter-side alias, so the canonical block can land byte-identical in Phase 97 without breaking demo runtime.

### DOCS-01 page restructure depth and forward-reference honesty

- **D-05:** Apply a **section-level rewrite** to `docs/protect-phoenix-api-routes.md`: lead, canonical-plug-order section, and failure table get rewritten; assigns-contract, ownership-boundary, and repo-owned-proof sections stay intact (additive only). This preserves the Phase 92 `assert_protected_routes_guide!` assertions at `test/support/advanced_setup_support_truth.ex:69-80` without parallel test edits.
- **D-06:** The DOCS-01 contract sentence ("Lockspire issues RFC 9068 `at+jwt` access tokens by default. `Lockspire.Plug.VerifyToken` accepts JWT bearer tokens for host Phoenix API routes. Lockspire-owned `/userinfo` and `/introspect` use stored opaque tokens; those are not interchangeable. To opt a client back to opaque, see the admin Client Detail page.") is the page's lead, written in present-tense contract form.
- **D-07:** Append one explicit **forward-reference caveat sentence** immediately after the DOCS-01 contract lead, scoped to the milestone branch only: *"This page describes the contract `Lockspire.Plug.VerifyToken` enforces; the runtime narrowing and the default-issuance flip land in v1.27. Until v1.27 is fully shipped, opaque tokens may still be silently accepted on these routes."* Phase 102 deletes this caveat sentence as part of the issuance-flip-shipped sweep.
- **D-08:** The page continues to defer to `docs/supported-surface.md` as the canonical public support contract (preserve the existing cross-link at `docs/protect-phoenix-api-routes.md:5`). Phase 92's canonical-authority hierarchy stays intact.

### DOCS-02 placement, install-template SCAFFOLD-01 deferral, and adjacent-surface deference

- **D-09:** DOCS-02 lands as a new `## Explicit non-goals for host-API route protection` subsection in `docs/supported-surface.md`, inserted immediately after the existing out-of-scope list (around line 113-138). Each rejected pattern is a one-line bullet with a brief "why rejected" clause sourced from `.planning/REQUIREMENTS.md:103-110`:
  - no introspection-at-the-RS as the host-API seam — recreates gateway/CIAM productization the canon explicitly rejects
  - no auto-detection of token shape — documented ecosystem footgun (Ory oathkeeper #257 class)
  - no dual-verifier dispatcher — hides operator-visible complexity inside the library
  - no RAR enforcement at the RS plug — RAR claims surface via `conn.assigns.access_token` for host-owned enforcement
- **D-10:** The install template `priv/templates/lockspire.install/router.ex` is the fourth content-hashed file from Phase 97 merge day. The canonical pipeline block ships as **commented-out Elixir inside the existing heredoc string** between the `BEGIN/END` markers. Comment-prefixed lines are inert in the generated host router, so the template stays compile-clean on milestone-branch installs. Phase 102 SCAFFOLD-01 removes the leading `#` prefixes (and tightens surrounding prose) — the canonical block's content is unchanged across Phase 97 → 102, so the content hash holds the entire milestone.
- **D-11:** `docs/saas-adoption-recipe.md` (currently restating the three plug names at line 50) gets edited to **replace the plug-name restatement with a cross-link to `docs/protect-phoenix-api-routes.md`**. This closes the silent fifth-surface drift class — only the four RECIPE-01 locations carry the pipeline names.
- **D-12:** No other doc, guide, or template gets a new restatement of the canonical pipeline block in Phase 97. If a future phase wants to reference the pipeline, it cross-links the canonical page, not the plug names. Grep-time guard: a discovered fifth restatement on review is a Phase 97 bug.

### Claude's Discretion

- Exact wording, header hierarchy, and cross-link placement inside the rewritten lead/canonical-plug-order/failure-table sections of `docs/protect-phoenix-api-routes.md`, provided the contract sentence (D-06) and forward-reference caveat (D-07) appear verbatim.
- Exact bullet wording inside the new `## Explicit non-goals for host-API route protection` subsection of `docs/supported-surface.md`, provided the four rejected patterns and their rejection-rationale phrases (D-09) are preserved.
- Exact Elixir formatting of the canonical pipeline block (with-parens vs without-parens, single-line vs multi-line `plug` calls), provided the same form is byte-identical inside the four `BEGIN/END` marker regions after the D-02 normalization step.
- Exact whitespace/comment conventions inside the `release_readiness_contract_test` helper that does the four-file extraction + hash compare, provided the failure message names which file pair drifted.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase boundary

- `.planning/PROJECT.md` — v1.27 milestone goal, Branch A + JWT-default issuance Key Decision, and standing sustainment-default policy
- `.planning/REQUIREMENTS.md` — RECIPE-01, DOCS-01, DOCS-02 (Phase 97 scope); traceability table; explicit Out-of-Scope rationale at lines 103-110 (source for DOCS-02 non-goal wording)
- `.planning/ROADMAP.md` — Phase 97 goal, success criteria, and build-order rationale; subsequent phase dependencies (Phase 98/99/101/102)
- `.planning/STATE.md` — current milestone position, decisions log, and session continuity
- `.planning/METHODOLOGY.md` — assumption-first, least-surprise host seam, one-shot recommendation bundles, high-threshold escalation

### Prior phase truth that constrains Phase 97

- `.planning/phases/92-advanced-setup-support-truth/92-CONTEXT.md` — D-01 (canonical-authority hierarchy: `docs/supported-surface.md` is the single canonical public support contract; adjacent guides defer to it); D-09/D-10/D-11/D-12 (canonical protected-route pipeline, three-plug split, narrow support claim)
- `.planning/research/SUMMARY.md` — v1.27 research synthesis; Branch A rationale; explicit rejection of introspection-at-the-RS, auto-detection, and dual-verifier (source material for DOCS-02 non-goals)

### Adopter-facing docs to be touched in Phase 97

- `docs/protect-phoenix-api-routes.md` — page that becomes the single authoritative protected-route contract (DOCS-01). Existing structure preserved per D-05; lead + canonical-plug-order + failure-table sections rewritten.
- `docs/supported-surface.md` — canonical public support contract; gains new `## Explicit non-goals for host-API route protection` subsection per D-09 (DOCS-02). Phase 92 canonical-authority decision preserved.
- `docs/saas-adoption-recipe.md` — currently restates plug names at line 50; gets cross-link replacement per D-11.

### Files that carry the canonical pipeline block (RECIPE-01 four locations)

- `docs/protect-phoenix-api-routes.md` — canonical block inside `BEGIN/END` markers in the fenced Elixir code block
- `examples/adoption_demo/lib/adoption_demo_web/router.ex` — canonical block inside `BEGIN/END` markers in the live router (lines around 23-27 today)
- `priv/templates/lockspire.install/router.ex` — canonical block inside `BEGIN/END` markers, commented-out, inside the existing heredoc string per D-10
- `scripts/demo/adoption_smoke.py` — canonical block inside `BEGIN/END` markers as a Python-comment block per D-03

### Test infrastructure that the content-hash clause attaches to

- `test/lockspire/release_readiness_contract_test.exs` — host for the new four-file content-hash clause (D-02). Existing regex-extract-then-assert-substring pattern (precedent around lines 131-1031) is extended, not replaced.
- `test/support/advanced_setup_support_truth.ex` — Phase 92 `assert_protected_routes_guide!` (lines 69-80) and supported-surface non-goal assertions (lines 22-28) are preserved; Phase 97 must not invalidate them.

### Runtime surfaces the contract describes (read-only for Phase 97)

- `lib/lockspire/plug/verify_token.ex` — JWT-only plug today (verifies RS256/ES256/PS256); current docstring sets the baseline that DOCS-01 contract describes. Phase 98 hardens this plug; Phase 97 does not touch it.
- `lib/lockspire/protocol/userinfo.ex` — opaque-token lookup path for the Lockspire-owned `/userinfo` resource (DOCS-01 names this as the explicitly non-interchangeable use of opaque tokens)
- `lib/lockspire/protocol/introspection.ex` — `/introspect` opaque-token surface (DOCS-01 names this alongside `/userinfo`)
- `lib/lockspire/protocol/token_formatter.ex` — current 32-byte opaque issuance path; documented in DOCS-01's forward-reference caveat (D-07) as the source of the "until v1.27 is fully shipped" honesty window

### Product and ecosystem guidance

- `prompts/Embedding an OAuth-OIDC server in Phoenix the case for a new Elixir library.md` — narrow embedded-library boundary; "lead with embedded, not headless"; source for DOCS-02 rejection rationale
- `prompts/lockspire-host-app-integration-seam.md` — explicit Lockspire ↔ host ownership boundary referenced in DOCS-01 lead sentence about non-interchangeable token shapes
- `prompts/lockspire-oauth-oidc-implementation-playbook.md` — library shape, install model, and boundary discipline that DOCS-02 non-goals preserve

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `release_readiness_contract_test.exs` already uses a regex-extract-then-assert-substring pattern across docs/template/runtime files; the new four-file SHA-256 content-hash clause extends this pattern rather than introducing a foreign mechanism.
- `test/support/advanced_setup_support_truth.ex` (Phase 92) already encodes "docs are a contract the implementation honors" — Phase 97 inherits that posture and the existing helpers stay valid.
- The install template `priv/templates/lockspire.install/router.ex` is already a `def lockspire_routes do """..."""` heredoc — commented Elixir inside the heredoc is a natural carrier for the canonical block in Phase 97 without changing generated-host behavior.
- Phase 92's canonical-authority hierarchy (one canonical support contract; adjacent guides defer) is the exact pattern Phase 97 extends to the protected-route page; no new doctrine is being introduced.

### Established Patterns

- The repo treats `docs/supported-surface.md` as the single canonical public support contract; adjacent setup guides defer to it. Phase 97 honors this by adding the non-goals subsection inside `supported-surface.md` rather than in `protect-phoenix-api-routes.md`.
- The repo treats `release_readiness_contract_test` as the durable home for "docs/runtime/template stay aligned" assertions — Phase 97's content-hash clause lands there.
- Forward-reference honesty in docs (caveat sentences scoped to milestone branches) has precedent in prior milestones' interim doc states; Phase 102 sweeps the caveat per the same precedent.

### Integration Points

- Phase 98 will narrow `Lockspire.Plug.VerifyToken` to honor the DOCS-01 contract — the doc has to land first so the plug change has a written target.
- Phase 99 will flip default issuance to `:jwt` and extract `Protocol.AccessTokenSigner` — the DOCS-01 contract sentence describes this end-state; the D-07 caveat is the honesty bridge until Phase 99 lands.
- Phase 101 will re-wire `examples/adoption_demo` to consume `MyAppWeb.ProtectedApiReplayStore` (or its demo-side alias) so the canonical-block placeholder name introduced in Phase 97 stops being a placeholder.
- Phase 102 will uncomment the canonical block in `priv/templates/lockspire.install/router.ex` (SCAFFOLD-01) and delete the D-07 forward-reference caveat from `docs/protect-phoenix-api-routes.md` — the content hash holds across both transitions because the canonical bytes are unchanged.

</code_context>

<specifics>
## Specific Ideas

- Preferred Phase 97 product feel: calm, narrow, and contract-shaped.
  - one canonical adopter-facing protected-route page;
  - one canonical pipeline block content-hashed across four locations;
  - one explicit four-bullet non-goals subsection in the canonical support contract;
  - one honest forward-reference caveat sentence scoped to the milestone branch.
- Strong ecosystem lessons preserved from Phase 92:
  - prefer one canonical authority over multiple "almost-canonical" guides;
  - prefer explicit marker-comment anchors over implicit regex pattern matches when the load-bearing assertion is byte-equality;
  - prefer cross-links over restatement to close drift-surface classes.
- BEGIN/END marker convention: use `LOCKSPIRE_PROTECTED_PIPELINE` as the marker token verbatim across all four files (case-sensitive). Future GSD phases that introduce additional content-hashed regions should reuse the marker convention with their own token names.
- Forward-reference caveat (D-07) is single-sentence, single-paragraph, and removed in one Phase 102 commit — not a sprawling "transitional state" section.

</specifics>

<deferred>
## Deferred Ideas

- Optional research tightenings flagged by analyzer but not pursued (both currently Likely confidence, neither blocking):
  - RFC 9068 `at+jwt` adopter-facing glossing convention (footnote vs inline gloss vs cross-link to RFC text)
  - Embedded-Elixir-library precedent for SHA-256 cross-host-syntax content-hashing via marker comments
- Separate-file carrier for the canonical block (e.g., `priv/templates/lockspire.install/protected_pipeline_block.eex.commented`) — rejected on letter-of-RECIPE-01 grounds; defer entirely.
- Broader doc architecture refactor across `docs/install-and-onboard.md`, `docs/mtls-host-guide.md`, etc. — explicitly out of scope; Phase 92's canonical-authority hierarchy stays as-is.
- Telemetry on doc-reading or content-hash drift detection in production — telemetry surfaces land in Phase 102 (TELEMETRY-01) and target runtime verification, not doc-state monitoring.

</deferred>

---

*Phase: 97-contract-docs-first*
*Context gathered: 2026-05-27*
