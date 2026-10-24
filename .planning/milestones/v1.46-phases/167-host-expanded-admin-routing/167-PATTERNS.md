# Phase 167: Host-Expanded Admin Routing - Pattern Map

**Mapped:** 2026-10-22  
**Files analyzed:** 5 likely source/test files  
**Analogs found:** 5 / 5

This map uses only git-tracked source paths. The Phase 167 target paths below are inferred from `167-RESEARCH.md`; the new route macro and test names are proposals, not existing files. Phase 169 owns generator/demo convergence. Phase 168 owns the complete authorization denial matrix. Phase 170 owns browser/package/exact-floor CI proof.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/web/admin_routes.ex` (new; shared inventory and host expansion) | route / utility | request-response | `lib/lockspire/web/admin_router.ex` | role-match |
| `lib/lockspire/web/admin_router.ex` (modified to consume shared inventory) | route | request-response | itself | exact |
| `test/lockspire/web/live/admin/admin_route_integration_test.exs` (new synthetic host) | test | request-response | `test/lockspire/web/live/admin/admin_liveview_runtime_contract_test.exs` | role-match |
| `test/support/endpoint.ex` (test host fixture, if adapted) | config / route | request-response | itself | exact |
| `test/lockspire/web/live/admin/admin_liveview_runtime_contract_test.exs` (extend route metadata checks) | test | request-response | itself | exact |

No generator or adoption-demo target is assigned to this phase. If implementation chooses a different focused test filename, retain the same fixture and assertion patterns below.

## Pattern Assignments

### `lib/lockspire/web/admin_routes.ex` (route / utility, request-response)

**Analog:** `lib/lockspire/web/admin_router.ex`

The current router is the canonical route/action inventory. Preserve each `live/3` declaration exactly, including both overview paths and task actions. The excerpt shows its import/scope convention and representative task routes:

```elixir
import Phoenix.LiveView.Router

scope "/" do
  live("/", Lockspire.Web.Live.Admin.OverviewLive.Index, :index)
  live("/overview", Lockspire.Web.Live.Admin.OverviewLive.Index, :index)
  live("/clients", Lockspire.Web.Live.Admin.ClientsLive.Index, :index)
  live("/clients/new", Lockspire.Web.Live.Admin.ClientsLive.Index, :new)
  live("/clients/:client_id", Lockspire.Web.Live.Admin.ClientsLive.Show, :show)
  # Preserve named task actions such as :par_policy, :rotate_secret, and :show.
end
```

Source: `lib/lockspire/web/admin_router.ex:11-20,36-85`. The shared expansion should keep the Phoenix `live` calls in the host router's compile context and wrap them in host HTTP pipelines plus a named `live_session`; the legacy `AdminRouter` should remain available and consume the same inventory. Do not infer identity or supply a permissive hook.

**Research example caveat for planner:** `167-RESEARCH.md` recommends a required literal admin path and illustrates `lockspire_admin_routes "/lockspire/admin"` in one example, then illustrates the macro called with `"/admin"` inside `scope "/lockspire"` in another. Those paths compose differently. Requirements govern: settle the API and effective path through compiled route metadata, and avoid double-prefixing an enclosing scope. Do not copy either example as a settled contract.

### `lib/lockspire/web/admin_router.ex` (route, request-response)

**Analog:** `lib/lockspire/web/admin_router.ex`

Its route declarations are the exact baseline; the first declarations above and final policies at lines 74-85 show the syntax and action mapping. Keep public protocol routes out of this admin inventory, as verified by the existing focused tests.

### `test/lockspire/web/live/admin/admin_route_integration_test.exs` (test, request-response)

**Analog:** `test/lockspire/web/live/admin/admin_liveview_runtime_contract_test.exs`

The runtime contract test compiles a synthetic host router, filters compiled `Phoenix.Router.routes/1` by `Phoenix.LiveView.Plug`, normalizes the host prefix, and checks pipelines with `route_info/4`:

```elixir
mounted_admin_routes =
  AdoptionDemoWeb.Router
  |> Phoenix.Router.routes()
  |> Enum.filter(
    &(&1.plug == Phoenix.LiveView.Plug and String.starts_with?(&1.path, "/lockspire/admin"))
  )

assert mounted_paths == expected_paths

pipeline =
  router
  |> Phoenix.Router.route_info(String.upcase(to_string(route.verb)), route.path, "localhost")
  |> Map.fetch!(:pipe_through)
```

Source: `test/lockspire/web/live/admin/admin_liveview_runtime_contract_test.exs:25-62`. Strengthen this from path-set equality to `(relative path, verb, LiveView module, action)` equality and test representative `route_info/4` matches. Put admin declarations before the public forward; assert public/consent routes still resolve independently. Keep this narrowly focused: the complete allow/deny proof belongs to Phase 168.

For a focused connected navigation assertion, use the repository's existing LiveViewTest conventions: `live(conn_for_admin(), path)` and `assert_patch(view, expected_path)` appear at `test/lockspire/web/live/admin/clients_live_test.exs:190-203`. These existing tests target the current test host, so add a synthetic host endpoint/router setup for the new host-expanded path rather than treating those old paths as proof of the new integration. Reconnect-specific authorization semantics belong to Phase 168.

### `test/support/endpoint.ex` (test config / route, request-response)

**Analog:** `test/support/endpoint.ex`

This tracked fixture shows how the test host owns the endpoint session and delegates routing:

```elixir
defmodule Lockspire.Web.Endpoint do
  use Phoenix.Endpoint, otp_app: :lockspire

  plug(Plug.Session,
    store: :cookie,
    key: "_lockspire_key",
    signing_salt: "lockspire_salt"
  )

  plug(Lockspire.Web.TestHostRouter)
end
```

Source: `test/support/endpoint.ex:92-102`. Host cookie settings remain endpoint-owned. If a fixture is needed for more than one mount, use separately compiled endpoint/router fixtures or isolate their configuration; do not confuse LiveView's `live_session` `session:` option with Plug cookie configuration.

The corresponding tracked router fixture currently duplicates every admin route in `test/support/endpoint.ex:12-85`, then forwards the public router at lines 87-89. That duplication is evidence of the drift the shared inventory should remove; do not perpetuate it in a new fixture.

### `test/lockspire/web/live/admin/admin_liveview_runtime_contract_test.exs` (test, request-response)

**Analog:** itself; supporting route assertions in `test/lockspire/web/admin_router_test.exs`

`admin_router_test.exs:4-56` uses `Phoenix.Router.route_info/4` pattern matches to assert exact LiveView module/action metadata for list, new, and policy routes, and lines 59-67 keep OAuth routes out of the admin surface. Follow that style for route/action introspection; add dynamic host-prefix cases for root, default and nested paths, rather than checking only path existence. The mount-prefix link convention is currently explicit in `lib/lockspire/web/live/admin/overview_live/index.ex:233` and `clients_live/index.ex:430-445`:

```elixir
defp admin_path(path), do: Lockspire.mount_path() <> "/admin" <> path

defp clients_index_path(nil), do: Lockspire.mount_path() <> "/admin/clients"
defp clients_index_path(filters),
  do: Lockspire.mount_path() <> "/admin/clients?" <> URI.encode_query(filters)
```

Source: `lib/lockspire/web/live/admin/overview_live/index.ex:233`; `lib/lockspire/web/live/admin/clients_live/index.ex:430-445`. Preserve prefix, query, task path and redirect behavior or centralize it consistently. `Lockspire.Config.mount_path/0` accepts any binary, including `""` (`lib/lockspire/config.ex:86-104`); normalization precedent is `lib/lockspire/install/verify.ex:305-307`, where both `""` and `"/"` produce `/admin`.

## Shared Patterns

### Host routing and session ownership

**Sources:** `test/support/endpoint.ex:92-102`; `test/support/generated_host_app_web/router.ex:8-40`; `test/support/generated_host_app_web/router/lockspire.ex:63-75`.

Host pipelines and endpoint sessions belong to the host. Keep admin routes before the broad `forward`, and consent routes in their own host scope. The generated-host fixture demonstrates `pipe_through` composition and consent-before-public-forward ordering, but its route macro/generator use is Phase 169 territory.

### Route inventory and metadata

**Sources:** `lib/lockspire/web/admin_router.ex:13-85`; `test/lockspire/web/admin_router_test.exs:4-67`; `test/lockspire/web/live/admin/admin_liveview_runtime_contract_test.exs:25-67`.

Use compiled Phoenix route metadata as the source of proof. Compare route paths, verbs, LiveView modules, actions, and pipeline/session metadata. A `200` static render or route path set alone does not prove connected host routing.

### Prefix normalization and links

**Sources:** `lib/lockspire/config.ex:86-104`; `lib/lockspire/install/verify.ex:305-307`; `lib/lockspire/web/live/admin/clients_live/index.ex:430-445`.

The configured mount can be empty for root. Ensure route composition and generated links both produce `/admin` at root, retain nested mount prefixes, and preserve query/task URLs. Since route macros compile while `mount_path/0` reads application config, tests should make the compiled path and runtime link prefix agree for each fixture.

## No Analog Found

No missing-role analogs. Existing tests cover connected pages at the test host's current route table, but there is no close test proving a route macro expanded into a separately configured synthetic host and then connected navigation works there. Build that focused Phase 167 regression using existing `Phoenix.LiveViewTest` idioms.

## Metadata

**Analog search scope:** `lib/lockspire/web`, `lib/lockspire/config.ex`, `lib/lockspire/install`, `test/lockspire/web`, `test/support`, `examples/adoption_demo/lib/adoption_demo_web`.  
**Tracked-source check:** All named analogs were confirmed with `git ls-files -- <path>`; no ignored runtime mirrors are referenced.  
**Pattern extraction date:** 2026-10-22
