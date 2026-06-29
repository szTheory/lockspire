# Phase 123 Operate Proof Matrix

Maintainer-only evidence for Phase 123: Operate Queue Flow Polish. This artifact records how `/admin/interactions`, `/admin/device_authorizations`, and `/admin/logouts` satisfy OPERATE-01, OPERATE-02, and OPERATE-03 without widening Lockspire's public support surface, runtime routes, package contents, schema, or command capabilities.

Browser, axe, screenshot, component-lab, and manual evidence remains supplemental and maintainer-only. It is not a public support surface, not a supported admin route, not a Hex/runtime package input, and not a substitute for the ExUnit, LiveView, LazyHTML, and source-contract proof recorded here.

## Route Coverage

| Route | Plan | Source file | Focused test | Evidence |
|------|------|-------------|--------------|----------|
| `/admin/interactions` | 123-01 | `lib/lockspire/web/live/admin/interactions_live/index.ex` | `test/lockspire/web/live/admin/interactions_live_test.exs` | Renders `Authorization interaction queue`, `Review interactions`, status buckets for pending login, pending consent, completed, denied, expired, pressure subtitles, safe durable interaction IDs, redacted client/subject handles, prompt, created/activity/expiry timestamps, empty state, no table, and no command controls. |
| `/admin/device_authorizations` | 123-02 | `lib/lockspire/web/live/admin/device_authorizations_live/index.ex` | `test/lockspire/web/live/admin/device_authorizations_live_test.exs` | Renders `Device authorization queue`, `Review device authorizations`, status buckets for pending, approved, denied, expired, completed, pressure subtitles, redacted client/subject/authorization handles, expiry, poll interval, next poll, lifecycle activity, empty state, no raw device/user code material, no table, and no command controls. |
| `/admin/logouts` | 123-03 | `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex` | `test/lockspire/web/live/admin/logout_deliveries_live_test.exs` | Renders `Logout propagation queue`, `Review logout deliveries`, waiting/retrying/failed/discarded/completed buckets, channel, endpoint, attempts, last activity, support note, long endpoint proof, HTTP status plus allowlisted failure class for retryable incidents, empty state, no worker/internal leakage, no table, and no command controls. |

## Requirement Coverage

| Requirement | Proof files | Coverage |
|-------------|-------------|----------|
| OPERATE-01 | Three Operate LiveViews and three focused LiveView tests | Interactions, device authorizations, and logout deliveries expose status pressure, prompt/channel, client, subject/account or endpoint, age/created/activity, expiry or last activity, attempts/support note where applicable, and durable non-secret identifiers through dense rows and `long_value` without table overload. |
| OPERATE-02 | `test/lockspire/web/live/admin/design_system_contract_test.exs`, three focused LiveView tests | Source/API contracts prove only existing Operate routes are present, `Lockspire.Admin` exposes no Operate queue mutation delegates, queue LiveViews have no `handle_event`, `phx-click`, `phx-submit`, table surface, retry/discard/approve/deny/logout-now/requeue/worker-control labels, or unsupported command UI. |
| OPERATE-03 | Three focused LiveView tests, design-system contract test, component stress test | Rendered/source proof covers empty, dense, incident, expired, retryable, discarded, skipped, rendered, completed, long-value, mobile wrapping, light/dark/system theme aliases, reduced motion, visible focus, ARIA target integrity, and maintainer-only lab boundary. |

## State Coverage

| State | Primary proof | Evidence detail |
|-------|---------------|-----------------|
| empty | All three route tests | Route-specific empty states say there is no interaction, device authorization, or logout delivery work waiting for operator review, with no `phx-click` or `phx-submit`. |
| dense | All three route tests and component stress test | Metrics render before dense rows; dense rows use `lockspire-admin-dense-resource-row`, `resource_list`, visible status badges, and wrapped metadata rather than tables. |
| incident | Logout route test and design-system contracts | Retryable logout rows show warning pressure, support note, HTTP status, and sanitized failure class while denying raw response, cookie, endpoint secret, SQL, Oban, and worker internals. |
| expired | Interaction and device authorization route tests | Expired interaction and device authorization rows render closed-state pressure copy and no action controls. |
| retryable | Logout route test | Retryable logout row shows endpoint, attempts, last activity, support note, HTTP 503, and allowlisted failure class without a retry button. |
| discarded | Logout route test | Discarded logout row is terminal/historical support truth, not an active discard control. |
| skipped | Logout route test | Skipped logout row is completed/terminal support truth when no endpoint work was required. |
| rendered | Logout route test | Rendered front-channel logout row keeps endpoint and timestamp context as completed support truth. |
| completed | All three route tests | Completed interaction, consumed device authorization, and succeeded/rendered logout delivery states remain visible with durable context. |
| long-value | All three route tests and design-system contracts | Long interaction IDs, device handles, redacted pivots, and logout endpoint URLs render through `AdminComponents.long_value` and CSS source proof for `overflow-wrap: anywhere`. |

## Read-Only Boundary

| Boundary | Proof | Result |
|----------|-------|--------|
| Route containment | `design_system_contract_test.exs` checks `Lockspire.Web.AdminRouter` routes | Only `/interactions`, `/device_authorizations`, and `/logouts` are accepted for this Operate slice; no `/operate`, detail route, lab route, browser-proof route, Storybook route, or theming route is introduced. |
| Admin API | `design_system_contract_test.exs` checks `lib/lockspire/admin.ex` | No retry, discard, approve, deny, logout-now, requeue, pause/resume, or worker-control delegates are added for interactions, device authorizations, logout deliveries, or logout queues. |
| LiveView source | `design_system_contract_test.exs` and focused route tests | The three queue LiveViews remain read-only, non-table source surfaces using `page_hero`, `pane`, `metric_grid`, `resource_list`, `dense_resource_row`, `status_badge`, `long_value`, and `empty_state`. |
| Rendered HTML | Focused route tests with `HtmlAssertions.assert_no_interactive_controls/2` | Rendered queues omit `phx-click`, `phx-submit`, unsupported command labels, and generic command copy. |

## Redaction And Secret Denial

| Decision | Surface | Proof |
|----------|---------|-------|
| D-09 logout allowed/forbidden data | `/admin/logouts` | Delivery id, redacted client handle, channel, endpoint URL, attempts, status pressure, sanitized HTTP/failure class, last activity, and support note may render. Logout token JTI, Oban job IDs, raw responses, cookies, endpoint secrets, SQL rows, and worker internals are denied by tests/source contracts. |
| D-10 interaction allowed/forbidden data | `/admin/interactions` | Interaction id, redacted client/account handles, prompt, status pressure, created/activity, and expiry may render. Authorization codes, request object internals, cookies, session tokens, nonce/state values, PKCE material, raw params, and raw sensitive return values are denied. |
| D-11 device authorization allowed/forbidden data | `/admin/device_authorizations` | Redacted client/account handles, redacted durable authorization handle, status, expiry, poll interval, next-poll, and lifecycle activity may render. Raw device/user codes, hashes, raw verification handle, authorization codes, token material, PKCE material, state, nonce, raw params, backend storage details, and `auth.updated_at` rendering are denied. |
| D-12 redaction pattern | All three routes | Rows use `Lockspire.Redaction.handle/2` through page-local helpers and `AdminComponents.long_value`; rendered tests seed sensitive fixture values and assert raw values do not appear. |

## Layout, Theme, Motion, And Focus

| Area | Proof | Result |
|------|-------|--------|
| Mobile and wrapping | `design_system_contract_test.exs` reads `lib/lockspire/web/admin_css.ex` | `long_value` wraps with `overflow-wrap: anywhere`, dense row metadata flex-wraps, support notes can span full width, and rows stack below 720px. |
| Light/dark/system theme | `design_system_contract_test.exs` reads `admin_css.ex` | Light, dark, and system theme selectors and semantic status aliases are present; status meaning remains visible through text labels. |
| Reduced motion | `design_system_contract_test.exs` reads `admin_css.ex` | `prefers-reduced-motion: reduce` neutralizes transition duration and transforms. |
| Keyboard focus | `design_system_contract_test.exs` reads `admin_css.ex` and `admin_components.ex` | Existing `:focus-visible` rules and `--ls-focus-ring-*` tokens remain in source. |
| Shared CSS/layout changes | Phase 123 summaries and git history | No Phase 123 committed change modified `lib/lockspire/web/admin_css.ex` or `lib/lockspire/web/components/admin_components.ex`; layout/theme/focus proof is source-contract evidence over existing primitives. |

## Command Outcomes

Task 123-05-02 will fill this table with exact command strings, dates, pass/fail status, and scoped caveats.

| Command | Date | Result | Notes |
|---------|------|--------|-------|
| `MIX_ENV=test mix test test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs --max-failures 1` | pending | pending | Focused Operate route proof. |
| `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` | pending | pending | Design-system/source/stress proof. |
| `mix format --check-formatted lib/lockspire/web/live/admin/interactions_live/index.ex lib/lockspire/web/live/admin/device_authorizations_live/index.ex lib/lockspire/web/live/admin/logout_deliveries_live/index.ex test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs` | pending | pending | Phase 123 modified source/test formatting proof. |
| `MIX_ENV=test mix test.fast --max-failures 5` | pending | pending | Full-suite status or scoped caveat. |

## No Schema Push Required

No schema push required because Phase 123 changed only LiveViews, tests, and planning proof files in its plan-owned commits. No Ecto schema, migration, storage record, repository schema file, runtime dependency, package file, or database migration is part of this phase.

## Public Support Boundary

This proof is under `.planning` and is maintainer-only. It does not update `docs/supported-surface.md`, does not claim browser/axe certification, does not add screenshot evidence as primary proof, does not create a lab/browser route, does not make AdminLab public, and does not add package or runtime support surface.

## Residual Caveats

- The repository had unrelated dirty work before Plan 123-05 started. This proof records Phase 123 plan-owned evidence and does not stage or commit unrelated source/test/docs changes.
- Focused commands in prior Phase 120-123 summaries consistently reported a non-fatal KeyCache startup log before `Lockspire.TestRepo` started; passing command outcomes should be read with that known benign log caveat when it appears.
- Plan 122-03 previously recorded `MIX_ENV=test mix test.fast --max-failures 5` failures in `Lockspire.ReleaseReadinessContractTest` tied to pre-existing Phase 115 adoption-demo documentation/lifecycle dirty work. If the same failure class appears again, it is scoped outside Phase 123 unless the failing module or assertion names Phase 123 files.
