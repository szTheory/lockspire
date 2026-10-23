# Phase 169: Install and Upgrade Convergence - Pattern Map

**Mapped:** 2026-10-23
**Files analyzed:** 26 explicit or strongly implied source, fixture, test, and documentation targets
**Analogs found:** 23 / 26

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `priv/templates/lockspire.install/router.ex` | template/config | transform | `lib/lockspire/web/admin_routes.ex` | role-match |
| `priv/templates/lockspire.install/operator_authorization.ex` (new host seam; exact path TBD) | middleware/hook | request-response | `test/support/admin_route_host.ex` | partial |
| `lib/lockspire/generators/templates.ex` | service/utility | transform | same | exact |
| `lib/lockspire/generators/install.ex` | service/task | request-response | same | exact |
| `lib/lockspire/install/operation_plan.ex` | service/model | transform | same | exact |
| `lib/lockspire/install/manifest.ex` | model/utility | file-I/O | same | exact |
| `lib/lockspire/install/verify.ex` | service | transform | same | exact |
| `test/integration/install_generator_test.exs` | test | file-I/O | same | exact |
| `test/integration/install_upgrade_test.exs` | test | file-I/O | same | exact |
| `test/lockspire/install/verify_test.exs` | test | transform | same | exact |
| `test/mix/tasks/lockspire_verify_test.exs` | test | request-response | same | exact |
| `test/lockspire/web/admin_routes_compile_test.exs` | test | transform | same | exact |
| `test/lockspire/web/admin_route_inventory_test.exs` | test | transform | same | exact |
| `test/lockspire/web/admin_route_integration_test.exs` (or existing route integration suite) | test | request-response | `test/lockspire/web/live/admin/admin_route_integration_test.exs` | role-match |
| `examples/adoption_demo/lib/adoption_demo_web/router.ex` | route | request-response | `lib/lockspire/web/admin_routes.ex` | role-match |
| `examples/adoption_demo/lib/adoption_demo_web/plugs/require_operator.ex` | middleware | request-response | `test/support/admin_route_host.ex` | role-match |
| `examples/adoption_demo/lib/adoption_demo_web/endpoint.ex` | config | request-response | same | exact |
| `test/support/generated_host_app_web/router/lockspire.ex` | fixture/template | transform | `priv/templates/lockspire.install/router.ex` | exact |
| `test/support/generated_host_app_web/router.ex` | route | request-response | same | exact |
| `test/clean_room/provider_host/lib/clean_room_provider_web/router_patch.exs` | fixture/route | transform | `test/support/generated_host_app_web/router/lockspire.ex` | role-match |
| generated-host fail-closed policy fixture (new) | middleware/hook | request-response | `test/support/admin_route_host.ex` | partial |
| clean-room canonical router overlay (new or modified) | fixture/route | transform | `lib/lockspire/web/admin_routes.ex` | role-match |
| `docs/install-and-onboard.md` | documentation | transform | same | exact |
| `docs/supported-surface.md` | documentation | transform | same | exact |
| `docs/adoption-demo.md` | documentation | transform | same | exact |
| `docs/upgrading/host-admin-integration.md` (new or existing upgrade guide target) | documentation | transform | `docs/upgrading/v1.37.md` | role-match |

The research identifies targets by subsystem and names the core convergence files, but does not enumerate every exact fixture/doc path. The entries marked new/TBD are inferred targets to confirm during planning. Keep generator-owned helper separate from host-owned policy files.

## Pattern Assignments

### Canonical route macro and compiled metadata

**Sources:** `lib/lockspire/web/admin_routes.ex` lines 69-105; `test/lockspire/web/admin_routes_compile_test.exs` lines 11-20, 46-79; `test/lockspire/web/admin_route_inventory_test.exs` lines 51-88.

The macro expands a single library-owned view/action inventory into native Phoenix routes, validates the literal/effective path and required host wiring, appends `Lockspire.Web.AdminMount` after host `on_mount` hooks, and puts the host pipeline before its mount guard. The compiled test supplies `pipe_through: [:host_auth]` and `on_mount: [LiveAuthorization, SecondHook]`, then asserts the route set, ordering, and path behavior. The inventory test proves all 29 route/action pairs and checks `live_session.name == :lockspire_admin` with ordered hooks `[HostHook, Lockspire.Web.AdminMount]`.

```elixir
AdminRoutes.lockspire_admin_routes("/lockspire/admin",
  pipe_through: [:host_auth],
  on_mount: [LiveAuthorization, SecondHook]
)
```

Use this exact macro for the generator helper, demo, and maintained host fixtures. Verification must reason over `Phoenix.Router.routes/1` / `route_info/4` results and route order/selected metadata. A source declaration alone cannot establish which route wins after Phoenix compilation; explicitly test a duplicate or earlier catch-all route that shadows a canonical path. Never report hook modules as proof of their policy semantics.

### Generator template and managed upgrade ownership

**Sources:** `priv/templates/lockspire.install/router.ex` lines 36-70; `lib/lockspire/generators/templates.ex` (small module; inspect full file); `lib/lockspire/generators/install.ex` lines 83-105, 155-174; `lib/lockspire/install/operation_plan.ex` lines 1-8, 95-145, 188-255; `lib/lockspire/install/manifest.ex` lines 1-12, 52-95; `test/integration/install_upgrade_test.exs` lines 1-90.

Templates are rendered to bytes, assembled into an immutable operation plan, and only then applied through the filesystem transaction. On upgrade, manifest `managed_files` entries grant update authority only when current bytes match the recorded checksum. Missing, drifted, malformed, or no-longer-shipped managed entries fail closed. Host-owned seams should remain user-owned outputs so upgrading the helper does not overwrite the host's authorization policy.

```elixir
cond do
  current_checksum != expected_checksum ->
    {:error, drift_error(rendered.relative_path, "checksum drift detected")}

  current_checksum == next_checksum ->
    {:ok, file_operation(rendered, :unchanged, expected_checksum)}

  true ->
    {:ok, file_operation(rendered, :update, expected_checksum)}
end
```

For legacy installs, use the manifest as the authority for which exact historical helper bytes may be replaced. If a released legacy variant is not represented by a trusted managed checksum or recognized manifest state, refuse automatic conversion and provide manual migration instructions. Add a tracked legacy fixture that reflects a real forward-only generated host; do not infer permission to overwrite from filename or template resemblance.

### Fail-closed host authorization seam

**Analog:** `test/support/admin_route_host.ex` and the Phase 168 host authorization tests. These demonstrate host-owned Plug and LiveView hook composition and current identity/policy denial behavior. They are test support, not a production template precedent.

No existing generated stub is a close analog for the requested first-run behavior. Generate a compiling host-owned Plug and `on_mount` hook that denies until the adopter implements current host identity and policy checks. Do not introduce an assumed account schema or allow-all default. The helper passes both the host pipeline and hook to `AdminRoutes`; the Plug protects the initial HTTP request, and the hook covers connected LiveView entry/navigation. Host policy must still protect sensitive events/actions and logout/revocation semantics. Generated policy source is intentionally host-owned and excluded from managed overwrite authority.

### Verifier structure and safe diagnostics

**Sources:** `lib/lockspire/install/verify.ex` lines 1-32, 214-316; `lib/lockspire/install/verify/check.ex`; `test/lockspire/install/verify_test.exs` (read the route fixture/test section in one pass); `test/mix/tasks/lockspire_verify_test.exs`; `test/lockspire/install/verify_test.exs` lines 343-355 for redaction.

The verifier aggregates independent checks into `Check.ok/4` or `Check.error/4`, including a safe detail string and an actionable fix. Replace the current forward-only predicate with compiled native route/session/action/pipeline/hook analysis. Check all expected route/action pairs, exact session identity, host authorization pipeline and hook presence/order, public protocol forward separation, duplicate paths, and the selected route for each representative concrete path so an earlier route cannot shadow the canonical one. Diagnostics should name missing or shadowed structure without dumping session values, secrets, or arbitrary host metadata. State explicitly that structural checks establish declarations only; host-owned request and LiveView denial tests establish policy behavior.

```elixir
Check.error(
  :router,
  "Host router wiring is incomplete",
  Enum.join(errors, "; "),
  "Import the generated Lockspire router helper, configure the host authorization pipeline and LiveView hook, then rerun `mix lockspire.verify`. Structural checks cannot prove host policy; cover it with host request tests."
)
```

### Demo, generated host, and clean-room convergence

**Sources:** `examples/adoption_demo/lib/adoption_demo_web/router.ex` lines 58-64 and 137-138; `test/support/generated_host_app_web/router/lockspire.ex`; `test/support/generated_host_app_web/router.ex`; `test/clean_room/provider_host/lib/clean_room_provider_web/router_patch.exs`; `examples/adoption_demo/lib/adoption_demo_web/endpoint.ex` lines 4-28, 40-43.

Replace copied `live/3` declarations and admin forwarding with exactly one canonical `AdminRoutes` macro invocation in each maintained host. Keep host route pipeline and host `on_mount` policy explicit. Keep the public OAuth/OIDC forward separate and after more specific consent/admin routes. The demo endpoint is the concrete reference for LiveView socket `connect_info` session configuration and static JS delivery; endpoint/browser edits remain host-owned and docs must call them out.

### Documentation and tests

Use `docs/install-and-onboard.md` for ordered fresh-install prerequisites and host-owned endpoint/browser/authorization actions; `docs/supported-surface.md` as the canonical bounded support claim; `docs/adoption-demo.md` for runnable demonstration pointers; and `docs/upgrading/v1.37.md` for release-specific upgrade instruction conventions. Generator and upgrade regressions belong in the existing integration suites, while route metadata and structural verifier cases belong in their current focused suites. Extend existing tests rather than creating prose-only evidence. User-facing operator-page wording is not part of the intended scope; if changed, follow AGENTS.md and PRODUCT.md vocabulary rules.

## Shared Patterns

### Route and hook ownership

**Source:** `lib/lockspire/web/admin_routes.ex` lines 3-7, 69-105. **Apply to:** generated helper, demo, generated fixture, clean-room host, verifier.

Host owns staff identity and policy. The host Plug and host `on_mount` hook both run before Lockspire's mount-path guard; the fixed session is `:lockspire_admin`. Admin routes are native host routes from the single macro inventory. Public protocol routing remains an independent forward.

### Upgrade authority and transactional writes

**Source:** `lib/lockspire/install/operation_plan.ex` lines 1-8, 95-145, 188-255; `lib/lockspire/install/manifest.ex` lines 52-95; `lib/lockspire/install/file_transaction.ex` lines 1-9. **Apply to:** any install/upgrade artifact.

Build and validate the complete plan before writing; use checksum-bound manifest ownership, preserve dry-run byte identity, and commit the manifest last through the transaction. Never overwrite host-owned hook or configuration files by template name alone.

### Verification claim boundary

**Source:** `lib/lockspire/install/verify.ex` lines 214-250 and Phase 169 roadmap criteria. **Apply to:** verify output and docs.

Report structural facts and safe next steps. Do not claim arbitrary host policy is correct merely because a module is listed in compiled route metadata. Require host-owned positive and denial tests for that property.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| generated fail-closed authorization Plug and LiveView hook | middleware/hook | request-response | Existing host-auth examples establish the seam, but no generated first-run stub currently provides deny-until-configured behavior. |
| historical forward-only upgrade fixture | test/fixture | file-I/O | Research calls for a legacy generated fixture; current fixture is canonical/current. Select a released tracked variant and ensure its manifest ownership state is known. |
| expanded route-metadata shadowing verifier case | test | transform | Existing route tests validate native metadata and inventory, but no exact analog proves verifier detection of first-match shadowing. |

## Metadata

**Analog search scope:** `lib/lockspire/{web,install,generators}`, `priv/templates/lockspire.install`, `test/{integration,lockspire/install,lockspire/web,mix/tasks}`, `test/support`, `test/clean_room/provider_host`, `examples/adoption_demo`, `docs`. All named source analogs above were confirmed with `git ls-files`; ignored worktree mirrors were excluded.
**Files scanned:** 23 tracked analogs or direct targets.
**Pattern extraction date:** 2026-10-23
