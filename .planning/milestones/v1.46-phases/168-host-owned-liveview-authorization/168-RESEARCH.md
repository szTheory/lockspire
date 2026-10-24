# Phase 168: Host-Owned LiveView Authorization - Research

**Researched:** 2026-10-22
**Domain:** Phoenix host authorization and LiveView lifecycle
**Confidence:** HIGH for current code and locked dependency behavior; MEDIUM for lifecycle guidance cross-checked against official docs

## User Constraints [VERIFIED: `.planning/REQUIREMENTS.md:12-24`; `.planning/ROADMAP.md:64-78`; `.planning/VERIFICATION-POLICY.md:1-17`]

- Host retains staff identity, authentication, authorization, session validity, login UX, and product policy ownership.
- Deny unauthenticated or unauthorized HTTP requests before protected data or actions; enforce current host policy in disconnected and connected LiveView mounts and on reconnect.
- Keep public OAuth/OIDC and host-owned consent outside staff authorization; all admin paths/actions are inside the protected `:lockspire_admin` LiveView session and run host hooks.
- Preserve current protocol behavior and security defaults. Do not add a staff store, role engine, fine-grained resource ACL, polling, distributed revocation coordinator, visual redesign, or immediate revocation promise for an already-connected socket.
- Keep proof boundaries precise: LiveViewTest lifecycle checks do not establish browser/socket transport proof; packaged adoption and exact supported-floor execution remain Phase 170. Generator and adoption changes remain Phase 169.
- Follow automation-first verification: map criteria to executable evidence, do not invent human checkpoints for missing descriptors, and record a closure rule/evidence for any prohibition. Phase 167 UAT is closed; do not reopen it absent relevant changed evidence.
- No subjective UI signoff is required.

## Project Constraints (from AGENTS.md) [VERIFIED: `AGENTS.md`]

- Keep Lockspire a separate embedded companion library; do not turn it into a required auth service or a Sigra module.
- Preserve clear boundaries among protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces.
- Keep account resolution, claims, login redirects, branding, and product policy in the host app.
- Do not broaden v1 into SAML, LDAP/AD federation, hosted auth, or a full CIAM suite.
- Preserve security defaults: required PKCE S256, exact redirect matching, hashed client secrets, short-lived single-use authorization codes, refresh rotation with family revocation on reuse, no implicit flow, no `alg=none`, and strong redaction.
- No admin UI wording or visual change is in scope; if wording changes later, first consult `PRODUCT.md`, use the vocabulary map, and update the retired-wording table when replacing terms.

## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| HAUTH-01 | The host can enforce its staff-access policy on initial admin HTTP requests; unauthenticated and unauthorized visitors are denied before admin data is rendered or actions run. | Existing host HTTP pipeline seam and test fixture; denial matrix below. [VERIFIED: `.planning/REQUIREMENTS.md:21`] |
| HAUTH-02 | The host can enforce its current staff-access policy before disconnected and connected admin mounts through an explicit LiveView authorization seam; missing required authorization wiring is refused rather than silently permitting access. | Required `pipe_through` and `on_mount` macro options and ordered hook composition; test missing/denied/current identity states. [VERIFIED: `.planning/REQUIREMENTS.md:22`] |
| HAUTH-03 | A visitor cannot bypass host staff checks by navigating from a public or consent LiveView into the admin surface or between admin destinations; every admin destination belongs to the protected admin session and receives its required host hooks. | `:lockspire_admin` session and 29-route/action inventory; assert destination hooks and cross-session reload/recheck. [VERIFIED: `.planning/REQUIREMENTS.md:23`] |
| HAUTH-04 | A reconnect with an invalid session or no-longer-authorized host identity is denied by the host policy, while a currently authorized staff session reconnects successfully. | LiveView mount runs again on socket connection; existing tests exercise synthetic socket states but no actual reconnect lifecycle assertion exists. [VERIFIED: `.planning/REQUIREMENTS.md:24`] |

## Summary

Phase 167 supplies an explicit host boundary: its router macro requires a host HTTP pipeline and host `on_mount` hook(s), places those hooks before Lockspire's mount-alignment guard, and groups all 29 admin routes in `:lockspire_admin`. In the fixture, the HTTP Plug denies when the session identity is absent; the LiveView hook separately resolves current identity and halts invalid identities before the view mount. Production Lockspire intentionally has no staff identity or policy implementation. [VERIFIED: `lib/lockspire/web/admin_routes.ex:69-106` — DATA_M4Q8Z2K1_START `:on_mount`, `host_hooks ++ [{Lockspire.Web.AdminMount, {:mount_path, caller.module}}]`, `:lockspire_admin` DATA_M4Q8Z2K1_END; `test/support/lockspire/web/admin_route_host.ex:125-179` — DATA_J6R1P9W3_START `get_session(conn, "host_staff_id")`, `{:halt, Phoenix.LiveView.redirect(socket, to: "/host/sign-in")}` DATA_J6R1P9W3_END; `.planning/phases/167-host-expanded-admin-routing/167-UAT.md:26`]

The main research finding is that LiveView's native lifecycle supports the required check in `on_mount`: it runs before disconnected and connected mounts, can halt with a redirect, and `live_session` hooks apply to every LiveView route in that session. A socket reconnect calls `mount/3` again, so a host hook can resolve current policy then. Phoenix requires HTTP plug checks as well because the initial page render is a regular HTTP request. Distinct live sessions force a full page reload on navigation, so an attempted jump from public or consent into admin must traverse the admin HTTP/session checks again. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.html#on_mount/1; https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.Router.html#live_session/3; installed source `deps/phoenix_live_view/lib/phoenix_live_view/router.ex:119-200`]

**Primary recommendation:** Add focused host-fixture integration/lifecycle coverage around denied HTTP entry, fail-closed absent wiring, every admin destination's session/hooks, cross-session navigation, and reconnect after identity revocation. Keep resolution/current-authority policy inside the host hook. Treat a connected socket's ongoing events and logout/disconnect behavior as host responsibilities; do not imply a mount check continuously revokes an established connection.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Initial admin HTTP denial | Frontend Server (SSR) | API / Backend — | The host Plug pipeline runs before the LiveView's disconnected render and gates data/actions. |
| Current identity and policy decision | API / Backend | Frontend Server (SSR) | The identity resolver and policy are host-owned; the host's Plug and `on_mount` adapt that policy at their respective boundaries. |
| LiveView mount/reconnect gate | Frontend Server (SSR) | Browser / Client — | Server-side `on_mount` runs before disconnected and connected view mounts. |
| Admin navigation boundary | Frontend Server (SSR) | Browser / Client | Same-session navigation remounts the destination; a different live session forces regular HTTP navigation and a new socket. |
| Public OAuth/OIDC and host consent separation | API / Backend | Frontend Server (SSR) | Existing router/session boundaries keep those routes distinct from staff-only admin authorization. |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---|---:|---|---|
| Phoenix | 1.8.13 locked in this checkout | Host router and Plug pipeline | Current dependency lock and native host-expanded route integration. [VERIFIED: `mix.lock:37` — DATA_B7T3P5L2_START `"phoenix", {:hex, :phoenix, "1.8.13"` DATA_B7T3P5L2_END] |
| Phoenix LiveView | 1.2.10 locked in this checkout | LiveView sessions, mount lifecycle, navigation | Current lock; required lifecycle is provided by `on_mount` and `live_session`. [VERIFIED: `mix.lock:40` — DATA_C4R9W1M6_START `"phoenix_live_view", {:hex, :phoenix_live_view, "1.2.10"` DATA_C4R9W1M6_END] |
| ExUnit + Phoenix.LiveViewTest | Project test stack | HTTP and LiveView lifecycle regression coverage | Existing phase fixtures exercise Plug dispatch and disconnected/connected lifecycle APIs. |

No dependency installation or upgrade is indicated. Exact floor/runtime compatibility belongs to Phase 170. Do not use LiveViewTest results as browser transport evidence.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Host Plug plus host `on_mount` | Lockspire-owned staff authorization | Rejected by approved ownership boundary; the library cannot decide host identity validity or policy. |
| Current identity resolution on each mount | Trust a copied session boolean or `conn.assigns` | Rejected: these do not establish current connected identity/policy. |
| Focused lifecycle and route tests | Browser/socket transport checks in this phase | Browser transport and packaged candidate proof belong to Phase 170. |

## Architecture Patterns

### Recommended Project Structure

No production folder restructuring is needed. Keep Phase 168 changes within the host test fixture and relevant admin route tests; Phase 169 owns templates/docs/generators. Existing boundaries: `lib/lockspire/web/admin_routes.ex`, `lib/lockspire/web/admin_mount.ex`, `test/support/lockspire/web/admin_route_host.ex`, `test/lockspire/web/live/admin/admin_route_integration_test.exs`, and `test/lockspire/web/admin_route_separation_test.exs`.

### Pattern 1: Paired HTTP and LiveView current-policy checks

**What:** The host Plug denies the initial HTTP request; the host `on_mount` resolves the session's host identity against current host authority and halts or continues before the admin LiveView mounts. Do not have the library interpret a role or boolean.

**When to use:** Every host admin route and every disconnected/connected/reconnected LiveView mount.

**Example:**

```elixir
def on_mount(_name, _params, session, socket) do
  case Host.Identity.resolve(Map.get(session, "host_staff_id")) do
    {:ok, staff} -> {:cont, Phoenix.Component.assign(socket, :host_staff, staff)}
    :error -> {:halt, Phoenix.LiveView.redirect(socket, to: "/host/sign-in")}
  end
end
```

Source: existing host-only fixture [VERIFIED: `test/support/lockspire/web/admin_route_host.ex:163-179` — DATA_G2K8V6Q4_START `Identity.resolve(Map.get(session, "host_staff_id"))`, `{:cont, assign(socket, :host_staff, staff)}`, `{:halt, Phoenix.LiveView.redirect(socket, to: "/host/sign-in")}` DATA_G2K8V6Q4_END]. This is an illustrative fixture shape, not a library-owned API.

### Pattern 2: Session-wide ordered hook protection

`lockspire_admin_routes/2` accepts required host `pipe_through` and `on_mount`; it appends Lockspire's path guard after host hooks and places the complete route inventory inside one `:lockspire_admin` live session. Test compiled route metadata for all 29 paths/actions and hook order. [VERIFIED: `lib/lockspire/web/admin_routes.ex:77-103` — DATA_H5P2D9R7_START `host_hooks = normalize_hooks!(Keyword.fetch!(options, :on_mount))`, `host_hooks ++ [{Lockspire.Web.AdminMount, {:mount_path, caller.module}}]`, `:lockspire_admin` DATA_H5P2D9R7_END; `test/lockspire/web/admin_route_inventory_test.exs:72-87` — DATA_W4C8M1J6_START `route.pipe_through == [:browser, :lockspire_admin_mount]`, `live_session.name == :lockspire_admin`, ordered `[AdminRouteHost.LiveAuthorization, Lockspire.Web.AdminMount]` DATA_W4C8M1J6_END]

**Lifecycle behavior:** Official LiveView documentation says `on_mount` runs before both disconnected and connected mounts and may halt; official security guidance calls for checks in both the regular HTTP pipeline and LiveView mount. `live_session` boundaries force full page loads across sessions; within a session, navigation mounts another destination within the existing LiveView connection. A connection drop/recovery calls mount again. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.html#on_mount/1; https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.Router.html#live_session/3; installed source `deps/phoenix_live_view/lib/phoenix_live_view/router.ex:119-200`, `deps/phoenix_live_view/lib/phoenix_live_view/lifecycle.ex:142-178`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Disconnected/connected mount interception | Per-LiveView duplicated mount clauses or custom dispatch | Host `on_mount` hook attached to admin `live_session` | Native lifecycle hook runs before each LiveView mount and provides halt/continue semantics. |
| Admin navigation session boundary | Custom client-side role gate or navigation router | Native `live_session` grouping with host hook | Session boundary plus hook preserves server authorization for each destination. |
| Staff identity, session store, or policy engine | Lockspire-owned account/role model | Host application's existing identity and current-policy resolution | Explicit product ownership and keeps embedded library narrow. |

## Current Code and Gaps

| Existing evidence | What it establishes | Remaining Phase 168 gap |
|---|---|---|
| Admin macro requires both host `pipe_through` and `on_mount`; hook(s) precede alignment guard. [VERIFIED: `lib/lockspire/web/admin_routes.ex:77-103` — `:pipe_through`, `:on_mount`, ordered `host_hooks ++ ...`] | Structural requirement and composition. | Add/retain compile regression that absent or empty required host authorization wiring fails closed; macro presence cannot prove that an arbitrary host hook actually enforces policy. |
| Fixture HTTP Plug returns 403 when the session identity is absent, but accepts any non-empty ID; the LiveView hook separately resolves current identity and denies unknown/deleted IDs. [VERIFIED: `test/support/lockspire/web/admin_route_host.ex:125-135` — DATA_K9V2R6B4_START `identity_id when is_binary(identity_id) and identity_id != ""`, `send_resp(conn, :forbidden, "Forbidden") |> halt()` DATA_K9V2R6B4_END; `:163-179` — DATA_P5W8C2J7_START `Identity.resolve(...)`, `{:halt, ...}` DATA_P5W8C2J7_END] | Example host policy behavior; not adopter policy certification. | Align the fixture's initial HTTP decision with current host identity/policy resolution and assert invalid/unauthorized IDs are denied before protected output or action markers; separately retain LiveView hook tests. |
| Admin route inventory confirms 29 route/action entries each use `:lockspire_admin` and ordered hooks; consent has a distinct `:host_consent` session. [VERIFIED: `test/lockspire/web/admin_route_inventory_test.exs:72-87` — exact values quoted in Pattern 2; `test/lockspire/web/admin_route_separation_test.exs:190-215` — DATA_N6T3Q8M1_START `:host_consent`, `:admin_hook`, `:consent_hook` DATA_N6T3Q8M1_END] | Route protection metadata and separate HTTP/connected sessions. | Exercise public/consent navigation attempts into admin and admin-to-admin destinations with authorization checks visible per destination; route metadata alone does not prove lifecycle execution for all destinations. |
| Lifecycle unit coverage calls the fixture hook against synthetic connected/disconnected sockets and rejects missing/deleted IDs. [VERIFIED: `test/lockspire/web/live/admin/admin_route_integration_test.exs:178-209` — DATA_A3J7P5R9_START `"disconnected"`, `"connected"`, `{:missing, %{}}`, `{:deleted, ...}`, `{:halt, redirected_socket}` DATA_A3J7P5R9_END] | Hook logic handles both socket-state shapes. | No actual LiveViewTest reconnect after authority withdrawal or authorized reconnect path has been found in the targeted tests; add fresh-identity reconnect lifecycle proof. |
| Phase 167 separation test independently demonstrates public and consent HTTP behavior and connected hook provenance. [VERIFIED: `test/lockspire/web/admin_route_separation_test.exs:170-215` — DATA_Z8M2K4V7_START `anonymous_admin`, `consent`, `:admin_http_denied`, `:consent_session`, `:admin_hook` DATA_Z8M2K4V7_END] | No shared admin access callback was observed on public/consent flow. | Extend with attempted cross-session navigation and denial after current policy changes; retain public success without staff auth. |

## Denial Matrix

Use a host-fixture authorization resolver with independent cases for missing identity, deleted/invalid identity, valid authenticated but unauthorized staff, and currently authorized staff. Prove both no sensitive render/action and correct access result.

| Entry path | Missing / invalid identity | Valid but unauthorized | Current staff authority | Evidence type / assertion |
|---|---|---|---|---|
| Initial HTTP request to every representative protected admin route/action | Host Plug denies before view data/action; no mount/action marker | Deny before data/action | HTTP request succeeds and intended route/action renders | `Phoenix.ConnTest` / router integration; response plus no protected marker. Not browser transport proof. |
| Disconnected initial LiveView render | Host `on_mount` halts before LiveView `mount/3` | Halt before mount | Static render may proceed only after policy permits | `Phoenix.LiveViewTest.live/2`, assert redirect/deny and no sentinel. |
| Connected LiveView mount | Host hook halts before view mounts | Halt before mount | Connected view mounts | LiveViewTest lifecycle. |
| Admin-to-admin live navigation to each destination/action class | Destination hook denies; no destination state/data | Deny | Destination mounts and host hook sees current staff identity | LiveViewTest navigation plus independent inventory assertion; all 29 destinations must retain session/hook metadata. |
| Public/consent-to-admin navigation | Full HTTP/session entry rechecks and denies | Deny | Only current staff reaches admin | LiveViewTest cross-session navigation; public and consent route still succeed without staff authorization. |
| Reconnect after identity deletion/session invalidation/policy withdrawal | Host resolves current state and denies | Deny if policy now refuses | Currently authorized staff reconnects | LiveViewTest reconnect/lifecycle assertion; no browser/socket transport claim. Phase 170 owns real client/socket proof. |
| Already connected socket after later permission change | No automatic revocation claim | Host's event policy and logout/disconnect handling apply | Existing connection behavior depends on host lifecycle | Document boundary; do not add polling or claim mount hook rechecks continuously. |

## Common Pitfalls

### Pitfall 1: Treating static HTML success as authorization proof

**What goes wrong:** A protected page may render during the disconnected HTTP request before a connected socket hook can run.
**Why it happens:** LiveView has a regular HTTP initial render and a later connected mount.
**How to avoid:** Deny in both host HTTP Plug and host `on_mount`; assert no protected content/action sentinel for denial. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.Router.html#live_session/3]

### Pitfall 2: Trusting copied session state as current authority

**What goes wrong:** Deleted staff or changed policy remains admitted by a stale authorization flag.
**Why it happens:** Session carries host-supplied data, but current policy belongs to host logic.
**How to avoid:** Resolve the host identity using the host's current authority source on each mount/reconnect; test deletion/withdrawal and currently allowed reconnect separately. [VERIFIED: `.planning/REQUIREMENTS.md` — “conn.assigns or a copied session boolean is not current connected authority”; phase scope exact excerpt recorded in requirement discussion; fixture `test/support/lockspire/web/admin_route_host.ex:163-179`]

### Pitfall 3: Protecting the index but missing task destinations

**What goes wrong:** A detail, edit, rotate, policy, or new action route bypasses the host session/hook.
**Why it happens:** Route inventories can drift or tests can exercise only the overview.
**How to avoid:** Keep the independent 29-route tuple baseline and assert every route's compiled live-session and hook metadata; add destination behavior coverage by action families and navigation boundary. [VERIFIED: `test/lockspire/web/admin_route_inventory_test.exs:1-88` — route count `29`, session `:lockspire_admin`, ordered hooks quoted above]

### Pitfall 4: Confusing session boundary checks with continuous revocation

**What goes wrong:** A team assumes a permission change immediately terminates an already-connected LiveView.
**Why it happens:** `on_mount` authorizes entry/reconnect, not every later event.
**How to avoid:** Host app owns logout/disconnect and event-level policy; no polling or immediate already-connected socket revocation promise. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.Router.html#live_session/3; `.planning/REQUIREMENTS.md` acceptance boundaries]

## Focused Runnable Checks

Use the proven environment prefix supplied by the phase owner:

```bash
ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test \
  test/lockspire/web/admin_routes_compile_test.exs \
  test/lockspire/web/live/admin/admin_route_integration_test.exs \
  test/lockspire/web/admin_route_separation_test.exs \
  test/lockspire/web/admin_route_inventory_test.exs
```

For targeted iteration once focused tests are added, run a single test file with the same prefix. Existing file names are present and cover canonical host connect/denial, session separation and route metadata. [VERIFIED: source paths and lines cited in Current Code and Gaps.] These are runnable commands, not claims that this researcher executed tests. Phase 168 should then run its focused union once; no broad duplicate suite or new CI workflow is justified unless recurring coverage is not already selected.

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit; Phoenix.ConnTest and Phoenix.LiveViewTest |
| Config file | `mix.exs` / existing test setup; no new config indicated |
| Quick run command | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/web/admin_routes_compile_test.exs test/lockspire/web/live/admin/admin_route_integration_test.exs test/lockspire/web/admin_route_separation_test.exs test/lockspire/web/admin_route_inventory_test.exs` |
| Full suite command | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test.fast` (use the repository-supported environment/database setup from project CI) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| HAUTH-01 | Anonymous, invalid, and unauthorized HTTP denied before protected render/action; current staff allowed | Integration | Focused command above | Existing integration fixture; complete matrix gap remains |
| HAUTH-02 | Missing hook/pipeline wiring refused; denied and allowed current-policy hook before disconnected and connected mounts | Compile + lifecycle integration | Focused command above | Existing compile test + synthetic lifecycle test; fail-closed and full behavior assertions need coverage |
| HAUTH-03 | All 29 destinations have protected session/hooks; public/consent cross-navigation cannot skip checks | Route metadata + LiveViewTest navigation | Focused command above | Metadata and isolation files exist; actual cross-session navigation gap remains |
| HAUTH-04 | Invalid/withdrawn authority denied on reconnect; currently allowed authority reconnects | LiveViewTest lifecycle | Focused command above after adding case | No actual reconnect scenario identified in targeted files |

### Sampling Rate

- **Per task:** Run the single touched test file with the environment prefix above.
- **Per phase:** Run the focused union after the complete denial/navigation/reconnect matrix; run repository `mix test.fast` only where the execution plan or required project gate calls for it.
- **Phase gate:** Automated behavior evidence and truthful evidence boundary; browser/socket transport is Phase 170.

### Wave 0 Gaps

- No new framework install or test configuration needed. The existing Phase 167 UAT records that `mix test.fast` selects tests under `test/lockspire`; new tests in these same directories should reuse that selector. Verify the selector during execution; this research does not claim a remote CI run. [VERIFIED: `.planning/phases/167-host-expanded-admin-routing/167-UAT.md` — “`mix test.fast` also selects all six files under `test/lockspire`”]
- Add actual reconnect and cross-session navigation cases; add an observable no-data/no-action assertion for HTTP denial and a current-policy refusal case distinct from an absent identity.
- Ensure tests cover hooks on every compiled admin destination without turning source text checks into the sole authorization proof.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | Yes | Host authenticates and resolves the current staff identity. |
| V3 Session Management | Yes | Host browser/session pipeline; invalidated or missing identity denied at HTTP and mount. |
| V4 Access Control | Yes | Host Plug and current-policy hook; host retains action/event policy. |
| V5 Input Validation | Yes | Treat path and LiveView params as untrusted; authorization must not be inferred from route params. |
| V6 Cryptography | No new phase-specific crypto surface | Preserve host session and existing Lockspire cryptographic behavior; no crypto package/design work here. |

### Known Threat Patterns for Phoenix LiveView

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Initial HTTP render bypasses a connected-only guard | Elevation of privilege / Information disclosure | Host Plug denial plus `on_mount` denial before disconnected and connected mounts. |
| Stale or revoked session identity reaches admin | Elevation of privilege | Resolve current host authority on every mount/reconnect; test invalidation/withdrawal. |
| Admin route outside protected session or missing hook | Elevation of privilege | Independent route inventory assertion for every route/session/hook; navigation regression. |
| Permission withdrawal after an established connection | Elevation of privilege | Host event-level checks and logout/disconnect policy; explicitly no Lockspire continuous-revocation promise. |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Check authorization only in a connected `mount/3` or rely on regular plugs alone | Pair host HTTP pipeline checks with a session-wide LiveView `on_mount` hook | Documented LiveView security model; confirmed in installed LiveView 1.2.10 router/lifecycle source | Covers initial HTTP entry and LiveView connected/disconnected mount boundaries. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.Router.html#live_session/3] |
| Treat a copied session flag as current authorization | Resolve host identity/current policy at each mount | Requirement decision for v1.46 | Supports invalid/withdrawn authority denial while preserving host ownership. |

**Deprecated/outdated:** No package/API deprecation is introduced. A mount-only or HTTP-only guard is incomplete for the approved acceptance scope.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | Tests can deterministically simulate a reconnect after host identity or policy changes using existing LiveViewTest APIs without browser transport. | Validation Architecture | If unsupported, use direct server lifecycle fixture for Phase 168 and leave actual transport proof to Phase 170. |

## Open Questions

1. The exact host API shape for the authorization hook is intentionally unresolved here; it remains a host-owned application contract. Planning should preserve the existing `on_mount` seam unless the denial matrix demonstrates a concrete deficiency.
2. Confirm which existing navigation helper can prove a public/consent-to-admin full reload in the current LiveViewTest version; if LiveViewTest cannot establish the boundary, test the server-side redirect/session behavior and leave transport claim to Phase 170.

## Sources

### Primary (HIGH confidence)

- Installed dependency source `deps/phoenix_live_view/lib/phoenix_live_view/router.ex:119-200`, `:163-172`, `:197-200` — live session behavior, hooks on every view, navigation across session boundary.
- Installed dependency source `deps/phoenix_live_view/lib/phoenix_live_view/lifecycle.ex:142-178` — mounted hook execution and halt/continue processing.
- Project source and tests cited inline throughout, especially `lib/lockspire/web/admin_routes.ex`, `lib/lockspire/web/admin_mount.ex`, host fixture, integration, separation, and inventory tests.
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/VERIFICATION-POLICY.md`, `.planning/STATE.md`.
- `.planning/research/v1.46-host-integration/SUMMARY.md` and Phase 167 research, summary, verification, and UAT artifacts.

### Secondary (MEDIUM confidence)

- [Phoenix LiveView 1.1.28 module documentation](https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.html#on_mount/1) — `on_mount` behavior, disconnected and connected mounts, and reconnect remount.
- [Phoenix LiveView 1.1.28 router documentation](https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.Router.html#live_session/3) — paired Plug and LiveView authorization checks and live-session boundaries.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — current lock entries opened and inspected.
- Architecture: HIGH — current macro, plug, fixture, and tests inspected; lifecycle cross-checked against official docs.
- Pitfalls: HIGH — derive directly from accepted requirements and LiveView's documented lifecycle/security model.

**Research date:** 2026-10-22
**Valid until:** 2026-11-21 for stable architecture; verify locked dependency docs if the Phoenix/LiveView pair changes.
