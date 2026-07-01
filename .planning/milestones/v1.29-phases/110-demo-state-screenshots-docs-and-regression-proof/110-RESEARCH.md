# Phase 110 Research: Demo State, Screenshots, Docs, and Regression Proof

## RESEARCH COMPLETE

Phase 110 is a proof and closeout phase. The implementation should not redesign admin routes or add protocol behavior. It should make final v1.29 proof durable by aligning demo state, operator docs, screenshot/browser evidence, and deterministic tests around the route surface already defined by Phase 107 and polished by Phases 108 and 109.

## Phase Scope

The roadmap success criteria require:

- Demo seeds exercise healthy, warning, incident, disabled, self-registered, retryable, revoked, expired, long-value, and copy-once states.
- Desktop and mobile screenshots cover every admin route in the route surface.
- `docs/operator-admin.md` describes the final journey model and host-owned boundary.
- Compile, diff-check, admin LiveView tests, design-system contract tests, screenshot inventory, and browser evidence pass.

`110-UI-SPEC.md` tightens this to route-complete proof, including detail routes and the query-driven logout propagation workflow from the Phase 107 route contract.

## Existing Assets

### Demo Seeds

`examples/adoption_demo/priv/repo/seeds.exs` already seeds a broad matrix:

- Clients: public, confidential, self-registered DCR, disabled, long-name/URI cases.
- Keys: active, upcoming, retiring, retired.
- Consents: remembered and revoked.
- Tokens: active access, active refresh, reuse-detected refresh family, revoked access, expired access.
- Interactions: pending login, pending consent, denied.
- Device authorizations: pending, approved, expired.
- IATs: active, revoked, used.
- Logout deliveries: succeeded, retryable, front-channel rendered.

Likely gaps for Phase 110 are explicit waiting/failed/discarded/completed states where domain support exists, expired IAT or expired interaction coverage, long-value expansion for every proof route, and copy-once proof for IAT minting, client secret rotation, and RAT rotation. Planning should verify before adding; do not duplicate seed state just to satisfy labels.

### Docs

`docs/operator-admin.md` already contains:

- Subordination to `docs/supported-surface.md`.
- Orient / Configure / Support / Operate journey model.
- DCR onboarding versus DCR policy split.
- Post-logout redirect URIs versus logout propagation URIs split.
- Host-owned operator-auth, session, MFA, role, tenant-policy, layout, branding, and product-authorization boundary.

Phase 110 should tighten final route proof references and ensure docs stay aligned with the route inventory without becoming a second support matrix.

### Screenshot Evidence

`tmp/admin-ui-polish/` contains broad v1.28 desktop/mobile screenshots, and `.planning/phases/106-demo-seeds-docs-screenshots-and-contract-verification/106-SCREENSHOTS.md` records the prior matrix. That matrix covers top-level routes and a canonical client workspace, but Phase 110 needs route-complete proof against `107-ROUTE-JOURNEY-CONTRACT.md`, including detail and workflow routes.

Screenshot files remain evidence only. Runtime code under `lib/` must not reference `tmp/admin-ui-polish/`.

### Contract Tests

`test/lockspire/web/live/admin/design_system_contract_test.exs` already fences:

- Admin route/docs journey alignment.
- Phase 107 route contract coverage.
- Design tokens and reduced-motion behavior.
- Shared admin primitives and no inline styles.
- Phase 109 route labels, primitive usage, generic CTA avoidance, redaction, risky action copy, and deliberate exclusion of Phase 110 screenshot/demo proof from Phase 109.

Phase 110 should extend this file or a nearby deterministic test module to check the Phase 110 proof artifacts:

- Seed source contains the required state labels or domain states.
- Screenshot inventory covers all Phase 107 routes/workflows and both desktop/mobile viewports.
- Every inventory row has route, journey, demo state, screenshot path, and browser note.
- Screenshot paths exist or explicitly record a route-specific `Not captured - ...` reason.
- Browser evidence starts from overview and reaches every route group.
- Docs preserve journey vocabulary and host-owned boundary.

## Recommended Plan Shape

Use four dependent plans:

1. **Demo State Matrix:** inventory and fill seed gaps in `examples/adoption_demo/priv/repo/seeds.exs`.
2. **Docs And Evidence Inventory:** update `docs/operator-admin.md` and create Phase 110 screenshot/browser evidence artifacts.
3. **Deterministic Regression Contracts:** extend source tests for seeds, docs, screenshot inventory, route surface, redaction, and mobile proof metadata.
4. **Browser/Screenshot Closeout:** capture or refresh desktop/mobile screenshots, record click-through/mobile no-overflow evidence, and run final verification commands.

This keeps runtime/demo data changes separate from proof artifacts, and it lets contract tests validate the evidence artifacts before final browser capture.

## Validation Architecture

Phase 110 validation is a mixed deterministic and browser-evidence contract:

- **ExUnit deterministic proof:** `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1`
- **Focused admin LiveView proof:** `mix test test/lockspire/web/live/admin --max-failures 1`
- **Compile proof:** `MIX_ENV=test mix compile --warnings-as-errors`
- **Full suite:** `mix test`
- **Diff/check proof:** `git diff --check`
- **Evidence proof:** deterministic inventory tests plus browser screenshots/click-through recorded in Phase 110 artifacts.

Browser proof may be manual or scripted depending on the local adoption demo environment, but missing evidence must be explicit and route-specific. Do not silently pass a route without desktop, mobile, journey, demo state, and browser note.

## Security Considerations

Phase 110 handles screenshot and demo data, so information disclosure is the main risk:

- Do not render real-looking secrets or recoverable plaintext in docs/inventory.
- Copy-once screenshot proof may show immediate artificial demo plaintext only where the UI intentionally shows it once, and later inventory/docs must not persist that value.
- Do not expose client secrets, access/refresh token plaintext, token hashes, IAT/RAT plaintext after creation/rotation, user codes, verifier material, or raw credentials.
- Host-owned staff authentication and authorization boundaries must remain explicit.

## Needs External Research

None. Repo-local planning artifacts, Phoenix/LiveView tests, and existing evidence patterns are sufficient for this closeout phase.
