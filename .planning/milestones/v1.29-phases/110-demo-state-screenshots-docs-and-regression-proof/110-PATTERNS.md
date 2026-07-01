# Phase 110: Demo State, Screenshots, Docs, and Regression Proof - Patterns

## PATTERN MAPPING COMPLETE

Phase 110 should reuse the existing v1.28/v1.29 closeout patterns instead of inventing new proof machinery.

## Source Artifacts To Modify Or Create

| Planned Artifact | Role | Closest Existing Analog | Pattern To Reuse |
|------------------|------|-------------------------|------------------|
| `examples/adoption_demo/priv/repo/seeds.exs` | Repeatable demo state for screenshots and browser click-through | Existing Phase 106 seed expansion | Deterministic artificial clients/accounts/tokens/queues with no production-like secret material |
| `docs/operator-admin.md` | Final journey and host-boundary guide | Existing operator admin guide and Phase 107 docs updates | Concise journey sections subordinate to `docs/supported-surface.md` |
| `.planning/phases/110-demo-state-screenshots-docs-and-regression-proof/110-SCREENSHOTS.md` | Route-complete screenshot matrix | `106-SCREENSHOTS.md` | Markdown coverage matrix with route, viewport, journey, seed state, path, notes |
| `.planning/phases/110-demo-state-screenshots-docs-and-regression-proof/110-BROWSER-EVIDENCE.md` | Click-through and mobile overflow evidence | `106-VALIDATION.md`, `106-VERIFICATION.md` | Explicit route checklist, commands/manual steps, pass/gap notes |
| `test/lockspire/web/live/admin/design_system_contract_test.exs` | Deterministic proof fence | Existing Phase 107/108/109 contract tests | Source and artifact assertions over routes, docs, CSS/components, seed source, and inventories |
| `tmp/admin-ui-polish/` | Screenshot evidence directory | Existing v1.28 screenshot files | Evidence-only PNG files named by route and viewport |

## Existing Code Patterns

### Admin Router As Route Truth

`lib/lockspire/web/admin_router.ex` uses `live/3` declarations under a single scope. Tests already parse this source to derive `/admin...` route paths. Phase 110 should reuse that helper pattern and include the Phase 107 query workflow `/admin/clients/:client_id/edit?workflow=logout-propagation`.

### Screenshot Inventory Pattern

`106-SCREENSHOTS.md` uses a single coverage matrix and keeps screenshot paths under `tmp/admin-ui-polish/`. Phase 110 should expand from important routes to every approved route/workflow and include browser notes. Runtime source must not depend on screenshots.

### Contract Test Pattern

`test/lockspire/web/live/admin/design_system_contract_test.exs` reads source files with `File.read!/1`, derives routes with regex helpers, and asserts exact contract strings. Phase 110 should add deterministic artifact checks in the same module unless a separate test module is clearer.

Recommended checks:

- `110-SCREENSHOTS.md` exists and contains every route from `AdminRouter` plus the logout propagation workflow.
- Each inventory row contains `Desktop`, `Mobile`, `Journey`, `Demo state`, and `Browser note` columns or equivalent required fields.
- Screenshot paths either exist under `tmp/admin-ui-polish/` or begin with `Not captured -`.
- `110-BROWSER-EVIDENCE.md` names overview-start click-through, route groups, 390px mobile no-overflow proof, and redaction/copy-once notes.
- `examples/adoption_demo/priv/repo/seeds.exs` contains state terms or domain values for healthy, warning, incident, disabled, self-registered, retryable, revoked, expired, long-value, and copy-once proof.

### Docs Pattern

`docs/operator-admin.md` should stay concise, operator-facing, and subordinate to `docs/supported-surface.md`. It should not become a protocol matrix, marketing page, or standalone-service description.

### Browser Evidence Pattern

`scripts/demo/adoption_smoke.py` is a browser-like HTTP smoke test for the adoption demo, but it is not a screenshot tool. Phase 110 can either script browser capture if tooling is available or record manual browser evidence. The durable requirement is route-complete evidence with explicit gaps, not a new mandatory dependency.

## Verification Hooks

- `MIX_ENV=test mix compile --warnings-as-errors`
- `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1`
- `mix test test/lockspire/web/live/admin --max-failures 1`
- `mix test`
- `git diff --check`
- Source check: `rg "tmp/admin-ui-polish" lib` returns no matches.

## Constraints For Planner

- Do not add Tailwind, shadcn, Playwright dependency, visual regression stack, or screenshot-only CSS unless the repo already has a low-friction tool and the plan states why it is necessary.
- Do not execute irreversible admin actions during browser proof; record confirmation workflows safely.
- Do not expose real or real-looking secrets in seeds, screenshots, docs, inventories, logs, or summaries.
- Do not change OAuth/OIDC protocol behavior, durable storage semantics, or host-owned operator authentication seams.
