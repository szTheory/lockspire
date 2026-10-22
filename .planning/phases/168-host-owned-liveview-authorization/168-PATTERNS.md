# Phase 168: Host-Owned LiveView Authorization - Pattern Map

**Mapped:** 2026-10-22  
**Files analyzed:** 4 likely touched files (3 tests, 1 host fixture)  
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/support/lockspire/web/admin_route_host.ex` | test fixture / host authorization adapter | request-response, session | same file's `RequireStaff` and `LiveAuthorization` modules | exact |
| `test/lockspire/web/live/admin/admin_route_integration_test.exs` | integration test | request-response, LiveView lifecycle | same file's canonical host and mount rejoin tests | exact |
| `test/lockspire/web/admin_route_separation_test.exs` | integration test | request-response, LiveView navigation/session | same file's public/consent/admin separation tests | exact |
| `test/lockspire/web/admin_route_inventory_test.exs` | route metadata test | batch / structural assertions | same file's 29-route metadata inventory | exact |

The research describes additions to these fixture/test surfaces; no production change is indicated. Current tracked-file checks (`git ls-files -- <path>`) were non-empty for all four analog paths. The installed `deps/phoenix_live_view/...` source is an implementation reference only; it is dependency material, not a tracked project analog.

## Pattern Assignments

### `test/support/lockspire/web/admin_route_host.ex` (host fixture, request-response/session)

**Analog:** `test/support/lockspire/web/admin_route_host.ex`

**HTTP gate** (lines 125-135):

```elixir
def call(conn, _opts) do
  case get_session(conn, "host_staff_id") do
    identity_id when is_binary(identity_id) and identity_id != "" ->
      Lockspire.Web.AdminRouteHost.record_trace(trace_id(conn), :admin_http_allowed)
      assign(conn, :host_staff_id, identity_id)

    _missing ->
      Lockspire.Web.AdminRouteHost.record_trace(trace_id(conn), :admin_http_denied)
      conn |> send_resp(:forbidden, "Forbidden") |> halt()
  end
end
```

This gate currently accepts any non-empty ID; the research identifies that as a needed fixture improvement. Resolve current fixture identity/policy here as in the LiveView hook, and retain a trace or sentinel showing denial happened before protected rendering/action.

**Current-policy LiveView hook** (lines 163-181):

```elixir
def on_mount(_name, _params, session, socket) do
  case Lockspire.Web.AdminRouteHost.Identity.resolve(Map.get(session, "host_staff_id")) do
    {:ok, staff} ->
      Lockspire.Web.AdminRouteHost.Identity.record_hook(staff.id)
      Lockspire.Web.AdminRouteHost.record_trace(Map.get(session, "trace_id"), :admin_hook)
      {:cont, assign(socket, :host_staff, staff)}

    :error ->
      Lockspire.Web.AdminRouteHost.Identity.record_hook(:denied)
      Lockspire.Web.AdminRouteHost.record_trace(Map.get(session, "trace_id"), :admin_hook_denied)
      {:halt, Phoenix.LiveView.redirect(socket, to: "/host/sign-in")}
  end
end
```

`Identity.resolve/1` is the fixture's current authority seam. It should support an authorized identity, deleted/invalid identity, and authenticated-but-unauthorized identity independently. Keep identity and policy fixture-owned; the library must not infer staff roles.

### `test/lockspire/web/live/admin/admin_route_integration_test.exs` (integration test, request-response/lifecycle)

**Analog:** `test/lockspire/web/live/admin/admin_route_integration_test.exs`

**Connected host-route proof** (lines 139-160):

```elixir
admin =
  build_conn()
  |> Phoenix.ConnTest.init_test_session(%{"host_staff_id" => "staff-1"})
  |> live("/lockspire/admin")

assert {:ok, view, html} = admin
assert view.module == Lockspire.Web.Live.Admin.OverviewLive.Index
assert html =~ "Overview"
assert_receive {:host_live_hook, "staff-1"}
assert_receive {:host_session_callback, "admin-route"}
```

**Denial before view mount** (lines 162-176):

```elixir
denied_http = get(build_conn(), "/lockspire/admin")
assert denied_http.status == 403

result =
  live(
    build_conn() |> Phoenix.ConnTest.init_test_session(%{"host_staff_id" => "deleted-staff"}),
    "/admin-auth-probe"
  )

assert result == {:error, {:redirect, %{to: "/host/sign-in"}}}
assert_receive {:host_live_hook, :denied}
refute_receive :admin_mount_reached
```

Use the HTTP response plus `refute` protected mount/action sentinel as the denial proof. Expand cases to missing, invalid/deleted, authenticated-but-unauthorized, and allowed identity. A direct call of `on_mount/4` with fabricated connected/disconnected `%Socket{}` values (current lines 178-209) checks callback branching only; it does **not** establish connected lifecycle execution.

**Fresh LiveView join with fresh host hook** (lines 350-398):

```elixir
{{:ok, view, html}, initial_conn} = endpoint_live_with_conn(endpoint, route, session)
first_pid = view.pid
monitor = Process.monitor(first_pid)
GenServer.stop(first_pid)
assert_receive {:DOWN, ^monitor, :process, ^first_pid, _reason}

rejoin_conn = initial_conn |> Phoenix.ConnTest.recycle() |> Phoenix.ConnTest.dispatch(endpoint, :get, route)
assert Plug.Conn.get_session(rejoin_conn, "host_staff_id") == "staff-1"
assert {:ok, rejoined, _html} = Phoenix.LiveViewTest.__live__(rejoin_conn, nil, [])
assert rejoined.pid != first_pid
assert_receive {:host_live_hook, "staff-1"}
```

This is the closest in-tree fresh-rejoin pattern. For HAUTH-04 mutate the fixture's current authority between initial join and the fresh request, then assert denied and no mount sentinel; separately retain allowed fresh-rejoin success. This is a LiveViewTest lifecycle rejoin, not transport-level socket reconnect proof.

### `test/lockspire/web/admin_route_separation_test.exs` (integration test, session/navigation)

**Analog:** `test/lockspire/web/admin_route_separation_test.exs`

**Public and consent stay outside staff admin gate** (lines 141-188):

```elixir
discovery = build_conn() |> get("/lockspire/.well-known/openid-configuration")
assert discovery.status == 200

anonymous_admin = build_conn() |> get("/lockspire/admin")
assert anonymous_admin.status == 403

consent = build_conn() |> get("/lockspire/consent/interaction-1")
assert consent.status == 200
assert consent.resp_body =~ "Host consent"
refute_receive {:route_trace, "separation-consent-http", :admin_http_allowed}
```

**Separate connected sessions/hooks** (lines 190-220):

```elixir
assert {:ok, consent_view, consent_html} = live(build_conn(), "/lockspire/consent/interaction-2")
assert consent_view.module == AdminRouteHost.ConsentLive
assert_receive {:route_trace, "connected-consent-1", :consent_hook}

assert {:ok, admin_view, _html} =
         build_conn()
         |> init_test_session(%{"host_staff_id" => "staff-1"})
         |> live("/lockspire/admin")

assert_receive {:route_trace, "connected-admin-1", :admin_hook}
refute_receive {:route_trace, "connected-consent-1", :admin_hook}
```

For cross-session behavior, `live_redirect/2` is not a browser navigation simulator: installed LiveViewTest docs/source state that navigation between different `live_session`s returns an error redirect for attempted `push_navigate`. Test the boundary in two parts: (1) `live_redirect(view, to: admin_path)` should produce the expected cross-session redirect condition if the UI emits a LiveView navigation; (2) model the required full page transition as a **new** `live(conn, admin_path)` request with the same cookie/session and mutated identity, asserting the host HTTP gate and admin hook run again. Do not describe this as browser transport proof.

`render_click/3` sends a `handle_event/3` event to the existing view and returns its rendered result (installed source `deps/phoenix_live_view/lib/phoenix_live_view/test/live_view_test.ex:625-646`). It does not navigate across a `live_session` or force a new HTTP request; use it only to prove a control's event behavior/sentinel, then follow the resulting URL through fresh `live/2` when testing a session boundary.

### `test/lockspire/web/admin_route_inventory_test.exs` (route metadata test, batch assertions)

**Analog:** `test/lockspire/web/admin_route_inventory_test.exs`

**Per-destination protected metadata** (lines 62-90):

```elixir
for {router, mount} <- @mounts, {relative_path, :get, view, action} <- @inventory do
  route = route_info!(router, mount <> concrete_path(relative_path))
  {selected_view, selected_action, _opts, live_session} = route.phoenix_live_view

  assert route.plug == Phoenix.LiveView.Plug
  assert selected_view == view
  assert selected_action == action
  assert route.pipe_through == [:browser, :lockspire_admin_mount]
  assert live_session.name == :lockspire_admin
  assert hook_modules(live_session) == [AdminRouteHost.LiveAuthorization, Lockspire.Web.AdminMount]
end
```

Keep this independent inventory assertion for all 29 concrete routes/actions. It proves compiled route/session/hook metadata, not execution of every destination's authorization branch; pair it with representative connected destination and hook trace/sentinel coverage.

## LiveViewTest Lifecycle API and Limits

Installed `phoenix_live_view` is 1.2.10 in `mix.lock` (the project compatibility floor/research docs may name 1.1.28). The checked-out dependency source has `live/2`, `render_click/3`, and `live_redirect/2`; grep found no public `disconnect/1` or `reconnect/1` functions in `Phoenix.LiveViewTest`. Use these concrete options:

| Proof need | Test mechanism | What it establishes |
|---|---|---|
| Connected mount runs the host hook | `live(conn, path)`; assert connected view plus hook trace and protected mount sentinel | LiveViewTest connected lifecycle callback execution |
| Policy revoked before fresh join/rejoin | Stop old `view.pid`; fresh `GET` via recycled connection; `Phoenix.LiveViewTest.__live__(conn, nil, [])` or new `live(conn, path)` | A new static request and LiveView connection re-resolve host authority. Not transport reconnect behavior. |
| Same-session destination navigation | `live_redirect(view, to: path)`; assert destination hook trace/sentinel | LiveViewTest live navigation and destination mount within session |
| Public/consent to admin boundary | Start at public/consent; capture/reuse session cookie; issue a fresh `live(conn, admin_path)` after host authority mutation | Full HTTP/session entry runs again. `render_click` alone cannot establish this. |
| Denied mount before protected code | Host hook denial trace plus `refute_receive` mount/`handle_params` sentinel; for action controls, refute `handle_event` sentinel | Ordered hook halts before protected callback when exercised through `live/2` |

`render_click` only targets an event in the already-connected view. It cannot cross sessions. `live_redirect` intentionally reports a cross-session `push_navigate` as an error redirect; a browser handles a session-changing navigation as a full page load, which LiveViewTest should model via a separate HTTP `live/2` entry. Fresh rejoin can prove current-policy re-evaluation when the fixture changes its authoritative identity/policy source; it must not be called actual socket disconnect/reconnect or browser transport proof. Phase 170 owns browser/socket transport.

## Shared Patterns

### Current identity/policy

**Source:** `test/support/lockspire/web/admin_route_host.ex:163-181`  
**Apply to:** fixture HTTP gate and LiveView authorization callback. Resolve the session identity against the fixture's mutable current authority store each time; don't trust a copied boolean or only the ID's non-emptiness.

### Denial ordering and observable sentinels

**Source:** `test/lockspire/web/live/admin/admin_route_integration_test.exs:162-209`  
**Apply to:** HTTP, disconnected, connected, destination navigation and fresh-rejoin denial. Assert the expected response/redirect, hook-denial trace, and absence of protected mount/`handle_params`/`handle_event` markers. Direct callback tests are supplemental and never substitute for `live/2` lifecycle coverage.

### Route coverage

**Source:** `test/lockspire/web/admin_route_inventory_test.exs:62-90`  
**Apply to:** all admin route/action declarations. Preserve the exact 29-entry inventory and assert the live session and ordered host + Lockspire hooks on each route.

### Public and consent isolation

**Source:** `test/lockspire/web/admin_route_separation_test.exs:141-220`  
**Apply to:** ensure public protocol and host consent still work without staff authorization while each fresh entry into admin runs staff checks.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| None | — | — | All expected changes map to existing host fixture and authorization/route integration tests. |

## Metadata

**Analog search scope:** `test/support/lockspire/web`, `test/lockspire/web`, and the installed `deps/phoenix_live_view/lib/phoenix_live_view/test` implementation for API availability only.  
**Files scanned:** 4 project analogs plus targeted installed LiveViewTest implementation sections.  
**Pattern extraction date:** 2026-10-22
