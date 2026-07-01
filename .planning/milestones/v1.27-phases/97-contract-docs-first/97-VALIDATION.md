---
phase: 97
slug: contract-docs-first
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 97 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Seeded from 97-RESEARCH.md `## Validation Architecture` section.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18 stdlib) |
| **Config file** | `test/test_helper.exs`, `mix.exs` aliases (`test.fast`, `test.integration`) |
| **Quick run command** | `mix test test/lockspire/release_readiness_contract_test.exs` |
| **Full suite command** | `mix ci` |
| **Estimated runtime** | ~5 seconds (single file, async) for quick; ~2 minutes for `mix ci` |

---

## Sampling Rate

- **After every task commit:** `mix test test/lockspire/release_readiness_contract_test.exs` (< 5s)
- **After every plan wave:** `mix test.fast` (full unit suite)
- **Before `/gsd:verify-work`:** `mix ci` green (includes integration, qa, docs.verify, deps.audit)
- **Max feedback latency:** ~5 seconds per task commit

---

## Per-Task Verification Map

> Pre-plan scaffold. Task IDs are filled in by the planner; this row table is a coverage skeleton tied to phase requirements and the validation seed in 97-RESEARCH.md.

| Req ID | Behavior | Threat Ref | Test Type | Automated Command | File Exists | Status |
|--------|----------|-----------|-----------|-------------------|-------------|--------|
| RECIPE-01 | Four files carry BEGIN/END markers around byte-identical (post-normalization) canonical pipeline blocks; pairwise hash compare fails on any drift | — | unit | `mix test test/lockspire/release_readiness_contract_test.exs` | ❌ NEW clause | ⬜ pending |
| RECIPE-01 (negative) | Markers renamed or extraction empty raises with named diff and sanity guard | — | unit | Same file, sanity-guard assertion | ❌ Same NEW clause | ⬜ pending |
| RECIPE-01 (no-fifth-restatement guard) | `git grep` for any new restatement of the three plug names outside the four canonical sites finds zero hits | — | manual + doc-state lint | Wave 1 verification step | ⚠️ Manual grep | ⬜ pending |
| DOCS-01 | `docs/protect-phoenix-api-routes.md` contains the D-06 contract sentence verbatim | — | unit | `assert_protected_routes_guide!/1` extended | ⚠️ Helper extension | ⬜ pending |
| DOCS-01 (caveat) | Page contains the D-07 forward-reference caveat sentence verbatim during the v1.27 milestone branch | — | unit | Same helper, new substring assertion | ⚠️ Helper extension | ⬜ pending |
| DOCS-01 (Phase 92 preservation) | Existing 8 substrings asserted by `assert_protected_routes_guide!/1` remain | — | unit | `mix test test/lockspire/release_readiness_contract_test.exs:642` | ✅ Existing | ⬜ pending |
| DOCS-02 | `docs/supported-surface.md` contains the four non-goal bullets with rejection rationales sourced from `.planning/REQUIREMENTS.md:103-110` | — | unit | `assert_advanced_setup_support_contract!/1` extended | ⚠️ Helper extension | ⬜ pending |
| DOCS-02 (Phase 92 preservation) | Existing 5 out-of-scope substrings remain | — | unit | `mix test test/lockspire/release_readiness_contract_test.exs:642` | ✅ Existing | ⬜ pending |
| D-11 saas-recipe restatement removal | Line 50 plug-name restatement gone; cross-link to `docs/protect-phoenix-api-routes.md` present | — | unit | New `assert` + `refute` in `release_readiness_contract_test.exs` | ❌ NEW clause | ⬜ pending |
| D-15 within-file restatement | Two secondary fenced blocks in `docs/protect-phoenix-api-routes.md` rewritten to reference the canonical block, not restate plug names | — | unit | `refute` in `release_readiness_contract_test.exs` | ❌ NEW clause | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/support/advanced_setup_support_truth.ex` — extend `assert_protected_routes_guide!/1` to require the D-06 contract sentence and D-07 caveat sentence verbatim. Phase 97 legitimately edits this helper because Phase 97 IS the phase that defines the new contract sentences; extension is not invalidation of Phase 92 assertions.
- [ ] `test/support/advanced_setup_support_truth.ex` — extend `assert_advanced_setup_support_contract!/1` to require the four DOCS-02 bullets.
- [ ] New test clause in `test/lockspire/release_readiness_contract_test.exs`: four-file content-hash comparison with pairwise diffing. Helper functions: `extract_canonical_pipeline!/2`, `normalize/2`, `canonical_hash!/2`. Three new module attributes: `@adoption_demo_router_path`, `@install_template_router_path`, `@adoption_smoke_script_path`.
- [ ] New test clause: `docs/saas-adoption-recipe.md` line-50 restatement removed (assert cross-link present; refute the three plug names appear in restated form).

No framework install needed. No new fixtures needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Fifth-restatement guard outside the four canonical sites | RECIPE-01 | A `git grep` for the three plug names across the repo is faster and clearer as a one-shot review step than a permanent test that has to keep an allow-list of legitimate occurrences (e.g., the three plug files themselves, the canonical sites). Phase 97 verifies once at merge; Phase 102 may convert this to a test if drift recurs. | `git grep -nE 'Lockspire\.Plug\.(VerifyToken\|RequireScopes\|RequireAudience\|ReplayGuard)' -- docs/ priv/templates/` and inspect that only the four canonical sites carry the names in restated form. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter (planner sets this when all rows have automated commands)

**Approval:** pending
