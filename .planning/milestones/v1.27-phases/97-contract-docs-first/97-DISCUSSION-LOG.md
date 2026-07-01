# Phase 97: Contract + Docs First - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-27
**Phase:** 97-contract-docs-first
**Mode:** assumptions
**Calibration tier:** minimal_decisive (user profile: opinionated)
**Areas analyzed:** Canonical pipeline-block shape & hashing mechanism; DOCS-01 page restructure depth & forward-reference handling; DOCS-02 placement, install-template SCAFFOLD-01 deferral, & adjacent-surface deference

## Assumptions Presented

### Canonical pipeline-block shape and hashing mechanism

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Full `pipeline :lockspire_protected_api do ... end` form is the canonical block, anchored by `# BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE` markers; `release_readiness_contract_test` extracts between markers, normalizes whitespace + leading `# ` on Python file, SHA-256 compares all four | Likely | `examples/adoption_demo/lib/adoption_demo_web/router.ex:23-27` (parens, indent 2), `priv/templates/lockspire.install/router.ex:9-53` (heredoc with EEx), `docs/protect-phoenix-api-routes.md:11-18` (fenced code block, no parens), `scripts/demo/adoption_smoke.py` (no current pipeline comment); literal byte-equal compare impossible. `test/lockspire/release_readiness_contract_test.exs:131-1031` precedent for regex-extract-then-assert pattern. |
| Reconcile `dpop_replay_store:` drift by adopting placeholder name `MyAppWeb.ProtectedApiReplayStore`; Phase 101 re-wires demo via thin alias | Likely | `examples/adoption_demo/lib/adoption_demo_web/router.ex:25` uses `AdoptionDemo.Repo`; `docs/protect-phoenix-api-routes.md:14-15` uses `MyAppWeb.ProtectedApiReplayStore`. Phase 101 DEMO-01/02/03 already touch demo pipeline. |

### DOCS-01 page restructure depth and forward-reference honesty

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Section-level rewrite of lead + canonical-plug-order + failure table in `docs/protect-phoenix-api-routes.md`; assigns-contract, ownership-boundary, repo-owned-proof sections stay intact | Likely | Existing structure at `docs/protect-phoenix-api-routes.md:1-113` is sound. Phase 92 `assert_protected_routes_guide!` at `test/support/advanced_setup_support_truth.ex:69-80` pins current shape; full rewrite invalidates working assertions for no contract-clarity gain. |
| Forward-reference caveat sentence ("This page describes the contract... Until v1.27 is fully shipped, opaque tokens may still be silently accepted on these routes.") lands in Phase 97; Phase 102 deletes it | Likely | Phase 97 ships before Phase 98 (plug narrowing) and Phase 99 (issuance flip) per `.planning/ROADMAP.md:107-117`. Unqualified present-tense DOCS-01 wording on Phase 97 merge day would be a lie about shipped behavior. Per-phase merge to milestone branch is the working assumption. |

### DOCS-02 placement, install-template SCAFFOLD-01 deferral, and adjacent-surface deference

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| DOCS-02 lands as new `## Explicit non-goals for host-API route protection` subsection in `docs/supported-surface.md` after existing out-of-scope list (around lines 113-138); four bullets with "why rejected" sourced from `REQUIREMENTS.md:103-110` | Likely | `docs/supported-surface.md` already has positive-list-then-negative-list structure; `test/support/advanced_setup_support_truth.ex:22-28` reads current negative list (additive). Folding non-goals into prose risks drift from the canonical four. |
| Install template carries canonical block as commented-out Elixir inside existing heredoc on Phase 97 merge day; Phase 102 SCAFFOLD-01 removes `#` prefixes (block content unchanged so hash holds) | Likely | `priv/templates/lockspire.install/router.ex:9-53` is a `def lockspire_routes do """..."""` heredoc; `#`-prefixed lines are inert in generated host. SCAFFOLD-01 in Phase 102 is comment-removal, not content rewrite. |
| `docs/saas-adoption-recipe.md:50` plug-name restatement gets replaced with cross-link to `docs/protect-phoenix-api-routes.md`; no other doc gains a new restatement in Phase 97 | Likely | Current restatement at `docs/saas-adoption-recipe.md:50` is a fifth silent-drift surface outside RECIPE-01's four canonical locations. Cross-link closes the drift class without expanding the four-file content-hash set. |

## Corrections Made

No corrections — all three assumption bundles confirmed by user in a single "Yes, proceed" response.

## External Research

Two `Likely → Confident` tightening opportunities were flagged by the analyzer but explicitly **not pursued** (recorded as deferred in CONTEXT.md):

- RFC 9068 `at+jwt` adopter-facing glossing convention (footnote vs inline gloss vs cross-link to RFC text) — no codebase precedent; ecosystem convention question. Confidence on the underlying decision (the DOCS-01 lead sentence verbatim from REQUIREMENTS.md) is not affected.
- Embedded-Elixir-library precedent for SHA-256 cross-host-syntax content-hashing via marker comments — novel for this codebase (current `release_readiness_contract_test.exs` is regex-extract-then-assert-substring). Confirming ecosystem precedent would tighten the hash-mechanism assumption from Likely to Confident, but the BEGIN/END marker + normalize + SHA-256 design is mechanically sound on first principles and analogous to literate-programming and content-anchor patterns common across language ecosystems.

User selected "Yes, proceed" rather than "Run the optional research first" — recorded for future review if the hash-mechanism turns out to need refinement during planning or execution.

## Methodology Lenses Applied

From `.planning/METHODOLOGY.md`:

- **Assumption-First Recommendation Mode** — applied throughout; codebase read first, single coherent default surfaced per area, no menu of low-signal questions.
- **Research-First Decisive Defaults** — applied; the analyzer read the four target files + Phase 92 prior decisions + REQUIREMENTS Out-of-Scope rationale before forming assumptions.
- **One-Shot Recommendation Bundles** — applied; the three areas were presented as one coherent bundle (canonical block shape, DOCS-01 restructure, DOCS-02 + install template + adjacent-surface deference) rather than as independent decisions.
- **High-Threshold Escalation** — applied; the only user-facing question was the single "do these look right" confirmation gate, not piecemeal arbitration on indentation, marker token spelling, or bullet wording.

## Calibration Notes

User profile: `opinionated` → calibration tier `minimal_decisive` (1–2 alternatives per Likely item, decisive single recommendation). Applied:

- 3 assumption areas total (within the 2–3 area target for `minimal_decisive`).
- One alternative considered and rejected per assumption (e.g., narrower three-`plug`-line block; unqualified-present-tense DOCS-01 wording; separate-file canonical-block carrier).
- No menu of options presented to the user — only the confirmation gate.

---

*Discussion log written: 2026-05-27 — assumptions mode for Phase 97 Contract + Docs First.*
