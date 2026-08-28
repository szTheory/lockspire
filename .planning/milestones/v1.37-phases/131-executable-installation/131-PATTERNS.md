# Phase 131: Executable Installation - Pattern Map

**Mapped:** 2026-08-26  
**Files analyzed:** 19 change surfaces  
**Analogs found:** 19 / 19

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/web/consent_context.ex` (new) | public service | request-response / transform | `lib/lockspire/web/live/consent_live.ex` | exact behavior extraction |
| `lib/lockspire/web/live/consent_live.ex` | LiveView component | request-response | its existing loaders | exact |
| generated `consent_live.ex` | generated host LiveView | request-response | `ConsentLive` and host templates | role-match |
| generated `router.ex` | router macro | request-response | `lib/lockspire/web/router.ex` | exact DSL role |
| generated-host router modules | compiled fixture | request-response | generated router template | exact consumer |
| `lib/lockspire/install/migrations.ex` (new) | installer service | file-I/O / batch | `Install.ensure_file!/2`, `Manifest` | role-match |
| install/upgrade/manifest modules | installer orchestration | file-I/O / batch | current render/manifest/drift flow | exact |
| install task, template registry, config, resolver | config/template registry | transform | strict options and inventory maps | exact |
| default/FAPI smoke templates | generated integration tests | HTTP request-response | Phase 6 E2E test | role-match |
| `install/verify.ex` and tests | diagnostic service | request-response / aggregate | current checks | exact |
| generator/upgrade integration tests | integration test | file-I/O / compile | current generated fixture flow | exact, to refine |
| `docs/install-and-onboard.md` | onboarding docs | sequential workflow | numbered install flow | exact |

## Pattern Assignments

### Consent context and reference LiveView

**Files:** new `lib/lockspire/web/consent_context.ex`, `lib/lockspire/web/live/consent_live.ex`  
**Analog:** [ConsentLive](/Users/jon/projects/lockspire/lib/lockspire/web/live/consent_live.ex:11)

```elixir
case load_consent_context(socket, interaction_id) do
  {:ok, assigns} -> {:ok, assign(socket, assigns)}
  {:redirect, redirect_uri} -> {:ok, redirect(socket, external: redirect_uri)}
  {:error, %Error{} = error} -> {:ok, assign(socket, page_title: ..., error: error)}
end
```

Extract ConsentLive lines 83-260 into a documented additive `load/2` service: interaction/client
lookup, host account/claims resolution, pending-login resumption, remembered-consent redirect,
subject/expiry checks, authorization-detail types, and completion path. Return only render-ready
facts plus a stable safe error map. Keep ConsentLive as a consumer so behavior stays characterized.
Generated code must not alias `Repository`, `AuthorizationFlow`, or protocol error structs.

**Completion boundary:** [InteractionController](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/interaction_controller.ex:39)

```elixir
def complete(conn, %{"interaction_id" => interaction_id, "decision" => decision} = params) do
  with {:ok, interaction} <- fetch_interaction(interaction_id),
       {:ok, subject_context} <- resolve_subject_context(conn, interaction),
       outcome <- finalize_interaction(interaction_id, decision, subject_context, params) do
    ...
  end
end
```

The generated LiveView only posts to `finalize_path`; it cannot duplicate decision, remembered-
consent, subject binding, or redirect behavior. Characterize populated, pending-login, expired,
and mismatch outcomes from [consent_live_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/live/consent_live_test.exs:70) before extraction.

### Generated host consent template

**File:** `priv/templates/lockspire.install/consent_live.ex`  
**Analog:** public context consumer above and generated host controller/template seams.

`mount/3` calls the supported context with the route interaction ID, then assigns returned data,
redirects, or presents safe local error copy. HEEx remains host-owned and semantic: scope/detail-
type lists, loading status, alert region, and distinct approve/deny POST forms. Follow the UI
contract by omitting raw interaction IDs, subject IDs, redirect URIs, tokens, and raw authorization-
detail JSON. This deliberately refines the reference LiveView diagnostic display, not protocol
behavior.

### Router macro and generated-host route fixture

**Files:** generated `router.ex`, `test/support/generated_host_app_web/router.ex`, and rendered
fixture `test/support/generated_host_app_web/router/lockspire.ex`  
**Analog:** [Lockspire.Web.Router](/Users/jon/projects/lockspire/lib/lockspire/web/router.ex:6)

```elixir
use Phoenix.Router
import Phoenix.LiveView.Router

scope "/" do
  post("/interactions/:interaction_id/complete", Lockspire.Web.InteractionController, :complete)
  live("/consent/:interaction_id", Lockspire.Web.ConsentLive, :show)
end
```

Replace the template's string-returning function with `defmacro lockspire_routes` returning quoted
router DSL with concrete generated module names. Emit in strict order: browser host verification/
authorized-app routes; browser generated consent `live`; browser + host-defined
`:require_operator` admin forward; public forward last. The fixture imports the rendered module,
defines fixture-only `:require_operator`, invokes `lockspire_routes()`, and asserts plugs/order via
`Phoenix.Router.routes/1`. Remove the independently hand-written route set because it masks
template defects.

### Migration copier, installer, upgrade, and manifest

**Files:** new `lib/lockspire/install/migrations.ex`, generator installer, upgrade task, manifest  
**Installer analog:** [Install.run/1](/Users/jon/projects/lockspire/lib/lockspire/generators/install.ex:10)

```elixir
assigns = build_assigns(opts)
rendered_templates = rendered_templates(assigns)
Enum.each(rendered_templates, fn rendered -> ensure_file!(rendered.destination, rendered.rendered) end)
write_manifest!(assigns, rendered_templates)
```

**Integrity analog:** [Manifest](/Users/jon/projects/lockspire/lib/lockspire/install/manifest.ex:49)

```elixir
%{"path" => rendered.relative_path, "checksum" => checksum(rendered.rendered)}
def checksum(contents), do: :crypto.hash(:sha256, contents) |> Base.encode16(case: :lower)
```

Implement the copier as plan/preflight/apply: deterministically inventory packaged and host
`version_name.exs` files, validate every version/name/content collision before any copy, then copy
only missing files byte-for-byte. Reuse `Manifest.checksum/1`; add an optional `"migrations"`
inventory to the old-compatible manifest. The manifest audits installation; it never authorizes
overwriting a host file.

**Upgrade error style:** [lockspire.upgrade](/Users/jon/projects/lockspire/lib/mix/tasks/lockspire.upgrade.ex:91)

```elixir
Mix.shell().info("REFUSE #{path} (#{reason})")
Mix.raise("Lockspire upgrade refused because managed scaffolding drifted.")
```

Run migration preflight before managed writes and manifest refresh in both install and upgrade.
Keep actionable refusal output and dry-run semantics. Use temporary-directory source/destination
fixtures for fresh, repeat, additive upgrade, byte-identical existing, every collision, and late-
collision atomicity; never alter repository migrations in tests.

### Template registry, options, config, and claims

**Registry analog:** [Templates.all/0](/Users/jon/projects/lockspire/lib/lockspire/generators/templates.ex:6)
uses template/output/ownership maps. Add or rename default-smoke and opt-in FAPI entries there,
then synchronize inventory and manifest tests.

**Option analog:** [install task](/Users/jon/projects/lockspire/lib/mix/tasks/lockspire.install.ex:13)

```elixir
{opts, _argv, invalid} = OptionParser.parse(args, strict: [web: :string, ..., sigra_host: :boolean])
if invalid != [], do: Mix.raise("Unknown options: ...")
```

Use the same strict, documented switch pattern for explicit `--with-fapi-smoke`; ordinary generated
tests stay default-secure and profile-neutral.

**Config analog:** [config template](/Users/jon/projects/lockspire/priv/templates/lockspire.install/config.exs:7)
is a compact explicit `config :lockspire` contract. Add `logout_path` with host-editable guidance;
the logout route/session remains host-owned.

**Claims analog:** [ConsentLive test resolver](/Users/jon/projects/lockspire/test/lockspire/web/live/consent_live_test.exs:14)

```elixir
%Claims{subject: to_string(account.id), id_token: %{}, userinfo: %{}}
```

Replace the resolver template's nonexistent `claims:` field with `subject`, `id_token`, and
`userinfo`, then compile the rendered resolver fixture. Do not disturb host-owned claims policy.

### Verification service

**Files:** `lib/lockspire/install/verify.ex`, Mix-task/service tests  
**Analog:** [Verify.run/1](/Users/jon/projects/lockspire/lib/lockspire/install/verify.ex:17)

```elixir
checks = [config_check(), seam_modules_check(...), router_check(router, mount_path), migrations_check(repo)]
%{ok?: Enum.all?(checks, &(&1.status == :ok)), checks: checks}
```

Preserve the aggregate result pattern, but split or aggregate config diagnostics so repo, resolver,
issuer, mount path, logout path, and Oban errors all have exact `config/lockspire.exs` remediation.
Retain `Phoenix.Router.routes/1` route validation and extend it to consent route/order, not
generated-source parsing.

### Generated proof and onboarding docs

**Files:** smoke/FAPI templates, generated fixture modules, generator/upgrade tests, docs  
**Analog:** [Phase 6 onboarding E2E](/Users/jon/projects/lockspire/test/integration/phase6_onboarding_e2e_test.exs:61)

Reuse its endpoint, real client registration (`allowed_scopes: ["email", "profile"]`), PKCE,
session, discovery/JWKS, and interaction sequence. Change its consent leg to visit and submit the
actual generated host consent route rather than directly post completion. Default generated smoke
must compile and execute rendered modules under `:none`; move FAPI PAR assertions to an explicit
opt-in test and avoid `allowed_scopes: ["openid"]`.

Update [install-and-onboard.md](/Users/jon/projects/lockspire/docs/install-and-onboard.md:18) only
after host-path migrations make `mix ecto.migrate` true, verify reports all seams, and the FAPI
command is explicitly separate.

## Shared Patterns

### Ownership boundary

Host templates own accounts, login/logout, layout/copy, operator authorization, and product policy.
Library code owns protocol state, completion, storage, and managed scaffolding. New public APIs
expose safe facts rather than repositories or host-policy decisions.

### Safe writes and diagnostics

[Install](/Users/jon/projects/lockspire/lib/lockspire/generators/install.ex:88) and
[upgrade](/Users/jon/projects/lockspire/lib/mix/tasks/lockspire.upgrade.ex:91) compare before
writing, accept unchanged content, and fail with exact remediation. Extend this style to a whole-
inventory migration preflight for atomic behavior.

### Proof consumes generated output

[install_generator_test.exs](/Users/jon/projects/lockspire/test/integration/install_generator_test.exs:174)
already compiles rendered smoke and compares select fixture files. Strengthen it until router,
consent, config, resolver, and smoke runtime modules are actual rendered output—not substitutes or
string-only assertions.

## No Analog Found

| File/Area | Role | Data Flow | Planner Guidance |
|---|---|---|---|
| `Lockspire.Install.Migrations` | installer service | file-I/O/batch | Compose existing installer refusal semantics, manifest checksums, and upgrade preflight; test temporary directories before task wiring. |
| public `ConsentContext` | public service | request-response | Extract current private ConsentLive behavior behind stable render-context data and preserve characterization tests. |

## Metadata

**Analog search scope:** `lib/lockspire`, `lib/mix/tasks`, `priv/templates`, `test/integration`,
`test/lockspire`, `test/support`, `docs`  
**Files scanned:** 22  
**Pattern extraction date:** 2026-08-26
