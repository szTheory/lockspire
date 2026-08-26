# Phase 131: Executable Installation - Research

**Researched:** 2026-08-26  
**Domain:** Phoenix embedded-library installation, router macros, host seams, and Ecto migration delivery  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Router and Route Ownership
- Replace the generated normal function that returns route source text with an imported Phoenix router macro that emits real route AST when called from the host router.
- Preserve host route ownership and ordering: host browser/device/authorized-app routes and host consent first, host-authenticated admin forwarding before the general Lockspire public forward.
- Keep operator authentication host-owned and fail clearly when the generated example's required host pipeline is absent; do not move admin auth into Lockspire.
- Assert generated route truth through `Phoenix.Router.routes/1`, not source-string inspection or a hand-written replacement router.

### Host-Branded Consent
- Keep consent layout, copy, and branding in generated host code while Lockspire remains authoritative for interaction lookup, subject binding, expiry, remembered consent, and final redirects.
- Extract a supported additive consent-context interface from the existing reference LiveView instead of asking generated host code to call internal Repository or protocol modules.
- Mount the generated host consent LiveView ahead of the public router forward and keep decision completion on the existing supported interaction endpoint.
- Preserve the existing minimal generated visual treatment; this phase is wiring and truth, not an admin or consent redesign.

### Migration Installation and Upgrade
- Copy versioned Lockspire migrations into the host's normal `priv/repo/migrations` path so ordinary `mix ecto.migrate` and releases use the documented host workflow.
- Install and upgrade copy only missing migrations, treat byte-identical existing files as already installed, never overwrite host-owned files, and fail with actionable output on version/name/content collisions.
- Existing applied migrations and existing host files remain untouched; upgrade adds only newly shipped Lockspire migrations.
- Generated-host and package tests must cover fresh install, repeat install, upgrade, and collision failure without relying on the adoption demo's dependency-path workaround.

### Configuration, Claims, and Generated Tests
- Generate an explicit host logout path alongside repo, resolver, issuer, mount path, and storage prefixes; verification must report every missing required seam with the exact remediation command or file.
- Correct `%Lockspire.Host.Claims{}` examples to use `subject`, `id_token`, and `userinfo`, and compile the rendered template in the generated-host fixture.
- The ordinary generated test suite must pass under Lockspire's default secure configuration; FAPI-specific assertions belong in an explicit opt-in profile/test path.
- Generated proof must execute behavior, not merely assert rendered strings or compile a hand-written substitute host.

### the agent's Discretion
- Exact additive module/function names for the consent-context interface and migration-copy helpers, provided they follow existing Lockspire naming and public-support conventions.
- Internal organization of generator rendering and verification checks.

### Deferred Ideas (OUT OF SCOPE)
- Separate-origin partner application and full HTTP token lifecycle proof belong to Phase 133.
- Public access-token accessors, client-registration coherence, and resource-server docs belong to Phase 132.
- Admin or consent visual redesign and formal conformance certification remain out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| INST-01 | Generated helper yields real ordered host, guarded-admin, consent, and public routes. | Replace the string-returning helper with a quoted router macro and assert its compiled route table. |
| INST-02 | Host-branded consent uses real interaction state and supported completion. | Extract `Lockspire.Web.ConsentContext` from the reference LiveView and mount the generated LiveView before the public forward. |
| INST-03 | Migrations install/upgrade safely and idempotently. | Add a preflighted package-to-host migration copier plus migration manifest entries and focused filesystem tests. |
| INST-04 | Config includes logout and verify gives executable remediation. | Add `logout_path` to generated config and enumerate config/seam/router/migration checks independently. |
| INST-05 | Default generated test works; FAPI proof is opt-in. | Replace the always-generated FAPI assertion with a default-profile behavioral smoke and an opt-in FAPI template/profile. |
| INST-06 | Claims example is truthful and compiles. | Render and compile the resolver template with `subject`, `id_token`, and `userinfo`. |
</phase_requirements>

## Summary

The install pipeline is structurally close but not executable as generated. `priv/templates/lockspire.install/router.ex` defines `lockspire_routes/0` as an ordinary function returning a heredoc, so importing and calling it inside a Phoenix router cannot register routes. The generated consent module only echoes query parameters, while `Lockspire.Web.ConsentLive` contains the real interaction, subject, expiry, remembered-consent, and redirect work. The installer also never copies the packaged migration files, despite docs directing a host to run plain `mix ecto.migrate`. [VERIFIED: codebase `priv/templates/lockspire.install/router.ex`, `priv/templates/lockspire.install/consent_live.ex`, `lib/lockspire/web/live/consent_live.ex`, `lib/lockspire/generators/install.ex`, `docs/install-and-onboard.md`]

The smallest coherent implementation keeps all host seams host-owned while moving only reusable protocol-backed preparation into explicit additive Lockspire APIs. It should add one router macro template, one supported consent-context service, one migration-copy service used by both install and upgrade, corrected generated config/tests, and a generated-host fixture that imports the actual output rather than re-creating routes manually. No new dependency is needed. [VERIFIED: codebase `AGENTS.md`, `lib/lockspire/generators/templates.ex`, `test/support/generated_host_app_web/router.ex`, `mix.exs`]

**Primary recommendation:** Implement Phase 131 in dependency order: extract consent context and migration installer first; make generated templates consume them; then make the generated-host fixture compile and execute the actual generated router/config/seams and prove the complete install contract.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Router registration/order | Host Phoenix router | Lockspire generator | The host owns pipelines and placement; the generated macro emits only the documented integration AST. |
| Operator authorization | Host Phoenix router | — | The host owns identity, MFA, role, tenant, and network policy before forwarding to Lockspire admin. |
| Consent presentation | Host LiveView | Lockspire consent-context API | The host owns copy/layout; Lockspire computes authoritative interaction facts and completion target. |
| Consent completion | Lockspire HTTP interaction controller | Host browser form | `Lockspire.Web.InteractionController` owns protocol transition and redirect semantics. |
| Migration application | Host Ecto repo/release | Lockspire installer | The package supplies source migrations; the host’s normal `priv/repo/migrations` and `mix ecto.migrate` own application. |
| Install diagnostics | Lockspire Mix task | Host config/router/repo | Lockspire can inspect declared seams and route table, but it must not infer or implement host policy. |

## Project Constraints (from AGENTS.md)

- Keep Lockspire a separate embedded companion library, never a required standalone auth service. [VERIFIED: codebase `AGENTS.md`]
- Preserve boundaries among protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces. [VERIFIED: codebase `AGENTS.md`]
- Keep account resolution, login redirects, branding, claims, and product policy at a narrow explicit host seam. [VERIFIED: codebase `AGENTS.md`]
- Do not expand into SAML, LDAP/AD federation, hosted auth, or CIAM. [VERIFIED: codebase `AGENTS.md`]
- Retain PKCE S256 by default, exact redirect matching, hashed secrets, one-use short authorization codes, refresh-family revocation on reuse, no implicit flow, no `alg=none`, and redaction. [VERIFIED: codebase `AGENTS.md`]

## Standard Stack

### Core

| Library | Resolved Version | Purpose | Why Standard |
|---|---:|---|---|
| Phoenix | 1.8.13 | Router DSL and compiled route table | Existing project dependency; `Phoenix.Router.routes/1` is the authoritative runtime route introspection surface used by verification. |
| Phoenix LiveView | 1.2.10 (supports declared 1.1.28+) | Host consent LiveView | Existing project dependency and generated UI boundary. |
| Ecto SQL | 3.13.5 | Host migration discovery/application | Existing migration runner and the normal Phoenix/Ecto host path. |

No package installation is part of this phase. [VERIFIED: codebase `mix.exs`, `mix.lock`]

### Compatibility constraints

- A host router needs Phoenix route macros at compile time; a normal function returning source text cannot add routes after `use Phoenix.Router` compiles. The generated helper must therefore be a `defmacro` returning quoted route DSL. [VERIFIED: codebase `priv/templates/lockspire.install/router.ex`, `lib/lockspire/web/router.ex`]
- `live/3` is supplied by `Phoenix.LiveView.Router`; `Lockspire.Web.Router` imports it explicitly. The generated macro should either emit a remote macro call or document/import `Phoenix.LiveView.Router` in the host router fixture so Phoenix 1.8/LiveView 1.1 hosts compile consistently. [VERIFIED: codebase `lib/lockspire/web/router.ex`, `mix.exs`]
- The macro must reference generated controller/LiveView modules through the template’s concrete module assigns, and must retain the host’s `:browser` and `:require_operator` pipeline names. An undefined `:require_operator` must fail at router compilation with host-facing guidance; Lockspire must not define or bypass the pipeline. [VERIFIED: codebase `priv/templates/lockspire.install/router.ex`, `AGENTS.md`]

## Implementation-Ready Architecture Patterns

### 1. Imported router macro emits only integration AST

Replace the generated `def lockspire_routes` function with `defmacro lockspire_routes`. Its quoted body should produce this order in the caller router:

```text
host router
  ├─ browser scope: /verify + /authorized-apps       (host controllers)
  ├─ browser scope: <mount_path>/consent/:id         (host LiveView)
  ├─ browser + require_operator: <mount_path>/admin  (Lockspire admin forward)
  └─ general scope: <mount_path>                     (Lockspire public forward)
```

Use concrete generated modules (`<Web>.LockspireVerificationController`, `<Web>.AuthorizedAppsController`, `<Web>.LockspireConsentLive`) inside the quote. Keep the public `forward` last so it cannot swallow the protected admin or host consent path. The fixture router must `import GeneratedHostAppWeb.Router.Lockspire`, define `:require_operator`, call `lockspire_routes()`, and then be inspected with `Phoenix.Router.routes(GeneratedHostAppWeb.Router)`. [VERIFIED: codebase `priv/templates/lockspire.install/router.ex`, `lib/lockspire/install/verify.ex`, `test/support/generated_host_app_web/router.ex`]

Do not preserve the commented protected-resource pipeline in this macro. It is unrelated to install truth and Phase 132 owns its public resource-server contract. Keep protected API fixture routes separately. [VERIFIED: codebase `131-CONTEXT.md`, `test/support/generated_host_app_web/router.ex`]

### 2. Extract an additive consent-context API, not repository access

Factor the private work in `Lockspire.Web.ConsentLive` into a documented additive module, preferably `Lockspire.Web.ConsentContext`:

```elixir
@spec load(Phoenix.LiveView.Socket.t(), String.t()) ::
        {:ok, map()} | {:redirect, String.t()} | {:error, map()}
```

`load/2` should retain the current sequence exactly: fetch interaction, resolve host account and `%Lockspire.Host.Claims{}`, resume `:pending_login` interaction / reuse remembered consent, reject subject mismatch or expiry, fetch client, and return only render-ready data (`interaction_id`, `client_name`, requested scopes, authorization details/type list, `subject_id`, `finalize_path`). Return a stable public error map rather than asking the host template to pattern-match `Lockspire.Protocol.AuthorizationRequest.Error`. The existing `Lockspire.Web.ConsentLive` becomes a consumer of the same API, so behavior stays characterized. [VERIFIED: codebase `lib/lockspire/web/live/consent_live.ex`, `lib/lockspire/web/controllers/interaction_controller.ex`]

The generated host LiveView should call this API in `mount/3`, render the same minimal host-owned markup from returned assigns, redirect on `{:redirect, uri}`, and render a local neutral error state on `{:error, context}`. Forms must post to returned `finalize_path`, which remains `<mount_path>/interactions/:id/complete`; do not add a generated decision endpoint or call repository/protocol code from host code. [VERIFIED: codebase `priv/templates/lockspire.install/consent_live.ex`, `lib/lockspire/web/router.ex`, `lib/lockspire/web/controllers/interaction_controller.ex`]

### 3. Migration copier has a preflight, copy, and record transaction-like boundary

Add a focused install helper (for example `Lockspire.Install.Migrations`) with a source root of `Application.app_dir(:lockspire, "priv/repo/migrations")` and destination `<host_root>/priv/repo/migrations`. It should enumerate source migrations deterministically, parse Ecto filenames as `version_name.exs`, build checksums, inspect every destination conflict before copying any file, then copy only approved missing files. [VERIFIED: codebase `lib/mix/tasks/lockspire.test.setup.ex`, `mix.exs`, `priv/repo/migrations`]

The preflight must classify every source migration as:

| Destination state | Required result |
|---|---|
| Exact destination absent; no same version/name in host directory | Copy byte-for-byte. |
| Exact destination present with equal bytes | Report unchanged/already installed; do not touch timestamp/content. |
| Exact destination present with unequal bytes | Fail `content collision`, naming both paths and saying Lockspire will not overwrite host files. |
| Different host file with same migration version | Fail `version collision` before any copy. |
| Different host file with same Lockspire migration name/suffix | Fail `name collision` before any copy. |
| Unparseable packaged migration filename | Fail internal/package integrity check before copy. |

Record the complete shipped migration inventory in the existing install manifest as an additive `"migrations"` array of `{version, name, path, checksum}`. Old manifests without that key remain upgrade-compatible: derive current state from disk, copy only current missing source files, then write the new inventory. The manifest is auditability, not authority to overwrite. A repeat install and upgrade must remain byte-identical when no package migration is new. [VERIFIED: codebase `lib/lockspire/install/manifest.ex`, `lib/lockspire/generators/install.ex`, `lib/mix/tasks/lockspire.upgrade.ex`]

Invoke the helper from both `Install.run/1` and `Upgrade.do_run/1` after all collision preflight succeeds, before final manifest write. Update onboarding to remove the adoption-demo-only `--migrations-path ../../priv/repo/migrations` workaround and make plain `mix ecto.migrate` true for a generated host. [VERIFIED: codebase `examples/adoption_demo/mix.exs`, `docs/install-and-onboard.md`, `lib/mix/tasks/lockspire.upgrade.ex`]

### 4. Treat generated configuration as an exhaustive contract

`Lockspire.Config.logout_path/0` raises when omitted, while the install template currently omits it. Add `logout_path: "/logout"` (or an equally explicit host-editable default) to `config/lockspire.exs`, and instruct the host to point it at its own logout route. [VERIFIED: codebase `lib/lockspire/config.ex`, `priv/templates/lockspire.install/config.exs`, `config/test.exs`]

Split `Verify.config_check/0` into explicit independent checks or aggregate all missing keys before returning. At minimum check `repo`, `account_resolver`, `issuer`, `mount_path`, `logout_path`, and valid Lockspire Oban runtime config; use a remediation that names `config/lockspire.exs` and the exact config key. Preserve router/migration checks so a missing config key does not prevent reporting independently detectable host defects. [VERIFIED: codebase `lib/lockspire/install/verify.ex`, `lib/mix/tasks/lockspire.verify.ex`]

### 5. Generated proof must reflect the active security profile

The generated `fapi_smoke_e2e_test.exs` currently runs as an ordinary test yet asserts FAPI PAR rejection, even though the documented default security profile is `:none`. It also registers `allowed_scopes: ["openid"]`, but `Lockspire.Clients.validate_allowed_scopes/1` rejects `openid` because it is protocol-reserved. [VERIFIED: codebase `priv/templates/lockspire.install/fapi_smoke_e2e_test.exs`, `lib/lockspire/config.ex`, `lib/lockspire/clients.ex`]

Replace it with a managed default-profile smoke test that runs against the real generated endpoint/router and proves a default-safe behavior such as discovery/JWKS availability, exact redirect rejection, and authorization-code + S256 request routing. Register only application scopes in `allowed_scopes` (for example `["profile"]`) while requesting `openid profile`, because `openid` is accepted by authorization request validation separately. Generate FAPI assertions only through an explicit `--with-fapi-smoke` install option (or an explicit opt-in template/profile); that test must set a FAPI server/client profile and be excluded from ordinary `mix test` until invoked by its documented command. [VERIFIED: codebase `lib/lockspire/protocol/authorization_request.ex`, `lib/lockspire/protocol/fapi20_enforcer_plug.ex`, `mix.exs`]

### 6. Keep `%Claims{}` examples true to its public struct

The generated resolver’s illustrative `%Claims{claims: ...}` field does not exist. Change it to:

```elixir
%Claims{
  subject: "user:" <> to_string(account.id),
  id_token: %{"email" => account.email, "name" => account.name},
  userinfo: %{"email" => account.email, "name" => account.name}
}
```

This aligns with the struct and with how ID-token and userinfo values are deliberately built. The generated fixture must compile this rendered resolver rather than only searching its text. [VERIFIED: codebase `lib/lockspire/host/claims.ex`, `priv/templates/lockspire.install/account_resolver.ex`, `test/lockspire/host/claims_test.exs`]

## Exact Change Surface

| File / area | Change |
|---|---|
| `lib/lockspire/generators/install.ex` | Invoke migration copier, include install results in onboarding output, and write additive migration inventory. |
| `lib/mix/tasks/lockspire.install.ex` | Add an explicit FAPI-proof option only if keeping a generated FAPI file; update help. |
| `lib/mix/tasks/lockspire.upgrade.ex` | Reuse copier after preflight and before manifest refresh; do not alter host-owned seams. |
| `lib/lockspire/install/manifest.ex` | Add backward-compatible migration inventory serialization/checksum support. |
| new `lib/lockspire/install/migrations.ex` | Deterministic source discovery, collision preflight, idempotent copy and result reporting. |
| `priv/templates/lockspire.install/router.ex` | Convert to `defmacro`; emit browser host routes, generated consent route, guarded admin forward, public forward in order. |
| `priv/templates/lockspire.install/consent_live.ex` | Consume supported consent context rather than query params. |
| `lib/lockspire/web/live/consent_live.ex` + new public context module | Extract existing preparation behavior without altering completion semantics. |
| `priv/templates/lockspire.install/config.exs` | Include `logout_path`. |
| `lib/lockspire/install/verify.ex` and task tests | Make every required config/seam failure visible with exact remediation. |
| `priv/templates/lockspire.install/account_resolver.ex` | Correct claims example fields. |
| generated smoke/FAPI templates and `Lockspire.Generators.Templates` | Default behavioral smoke; explicit FAPI profile/test only. |
| `test/support/generated_host_app_web/**` | Compile and use actual rendered outputs, including macro import, operator pipeline, generated consent module/config/resolver. |
| `test/integration/install_generator_test.exs`, `test/integration/install_upgrade_test.exs` | Replace source-string-only assertions with compilation and behavior/collision proof. |
| `docs/install-and-onboard.md`, related install references | Tell adopters only the now-executable commands and FAPI opt-in path. |

## Don't Hand-Roll

| Problem | Do not build | Use instead | Why |
|---|---|---|---|
| Route registry | A string parser or duplicate route list | Phoenix router macro + `Phoenix.Router.routes/1` | Only Phoenix compilation proves a host router actually contains the routes. |
| Consent transition | New generated approve/deny protocol logic | Existing interaction completion endpoint | It already owns interaction state, redirects, and protocol safety. |
| Host account resolution | Library-side sessions/users | Existing `Lockspire.Host.AccountResolver` seam | Host accounts and login policy remain intentionally external. |
| Migration runner | A custom schema/migration executor | Host `mix ecto.migrate` | Releases and host deployment already use Ecto’s migration lifecycle. |
| Hash comparison | Ad hoc strings | Existing `Manifest.checksum/1` SHA-256 helper | One existing checksum convention makes manifest/collision output consistent. |

## Common Pitfalls

### Macro executes in the caller, not the generator module

**What goes wrong:** Quoted route code resolves aliases or pipelines relative to the generated helper instead of the host router, or the host lacks `Phoenix.LiveView.Router` import.  
**Avoid:** Emit fully qualified generated modules, use the caller’s Phoenix router DSL, compile the generated router fixture, and call `Phoenix.Router.routes/1`. [VERIFIED: codebase `lib/lockspire/web/router.ex`, `test/support/generated_host_app_web/router.ex`]

### A public forward shadows a more-specific host path

**What goes wrong:** `<mount_path>` public forwarding is registered before consent/admin and captures those requests.  
**Avoid:** Keep host `/verify`, `/authorized-apps`, and generated consent first; admin second; public forward last. Test the index order as well as route plugs. [VERIFIED: codebase `lib/lockspire/install/verify.ex`, `131-CONTEXT.md`]

### Partial migration copies leave a confusing host state

**What goes wrong:** A collision in a later file happens after earlier files were copied.  
**Avoid:** Build and validate the entire plan before any `File.cp`; only then create/copy missing destinations and write the manifest. [VERIFIED: codebase `131-CONTEXT.md`, `lib/lockspire/generators/install.ex`]

### A host file has the expected contents but a conflicting migration identity

**What goes wrong:** Checking only destination filename misses a host migration with the same version under a different filename.  
**Avoid:** Scan all destination migration filenames by version and suffix/name before copy; report the exact offending host and package files. [VERIFIED: codebase `priv/repo/migrations`, `lib/mix/tasks/lockspire.test.setup.ex`]

### Default test quietly asserts an opt-in FAPI behavior

**What goes wrong:** `mix test` fails for a new host or teaches that the default profile is FAPI.  
**Avoid:** Keep baseline proof profile-neutral/default-secure and make FAPI test generation/execution explicit. [VERIFIED: codebase `priv/templates/lockspire.install/fapi_smoke_e2e_test.exs`, `lib/lockspire/config.ex`]

### Host consent reaches private Lockspire modules

**What goes wrong:** Generated code imports `Repository` or `AuthorizationFlow`, locking adopters to internals.  
**Avoid:** Expose one stable render-context API; retain internal stores/flow behind it. [VERIFIED: codebase `lib/lockspire/web/live/consent_live.ex`, `AGENTS.md`]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit / Mix 1.19.5; Phoenix 1.8.13; LiveView 1.2.10 resolved (declared host support starts at LiveView 1.1.28). |
| Fixture root | `test/support/fixtures/generated_host_app` plus runtime host modules under `test/support/generated_host_app_web`. |
| Quick targeted runs | `mix test test/integration/install_generator_test.exs test/integration/install_upgrade_test.exs test/lockspire/install/verify_test.exs test/mix/tasks/lockspire_verify_test.exs` |
| Router/consent integration run | `mix test --include integration test/integration/phase6_onboarding_e2e_test.exs` plus a new generated-host consent route test. |
| Full phase-compatible suites | `mix test.fast` and `mix test.integration` after `mix test.setup`. |

### Phase Requirements → Test Map

| Req ID | Behavior | Test type | Automated command | File status |
|---|---|---|---|---|
| INST-01 | Actual generated macro compiles in a host router; route table contains host routes, consent LiveView, guarded admin forward, public forward in order. | compile + integration | targeted generator test | Gap: replace string checks/substitute router. |
| INST-02 | Generated host consent route loads stored interaction, host subject and client/scopes; completion POST remains existing interaction endpoint. | HTTP/LiveView integration | `mix test --include integration test/integration/phase6_onboarding_e2e_test.exs` plus new generated-consent case | Gap: Phase 6 currently posts completion without visiting generated consent UI. |
| INST-03 | Fresh copy, repeat install, upgrade-only new source migration, byte-identical existing migration, version/name/content collision; no partial changes. | filesystem unit/integration | targeted upgrade/generator tests | Gap: no migration-copy tests exist. |
| INST-04 | Generated config includes logout; verify reports each missing key/module/route/migration and command/file remediation. | unit + Mix task | targeted verify tests | Partial: current verification stops config checks at first failure and omits logout. |
| INST-05 | Rendered default smoke compiles and executes against real generated host under default profile; FAPI proof only runs on opt-in. | generated-host integration | targeted generated smoke and opt-in FAPI command | Gap: existing template is default-run FAPI smoke. |
| INST-06 | Rendered resolver claims example compiles and uses only real struct fields. | template compile | targeted generator test | Gap: only FAPI template is compiled; resolver is string-inspected. |

### Sampling Rate

- **Per task commit:** targeted commands for changed installer/verification/LiveView files. [VERIFIED: codebase `mix.exs`]
- **Per wave merge:** `mix test.fast` and the generated-host integration tests. [VERIFIED: codebase `mix.exs`]
- **Phase gate:** `mix test.fast && mix test.integration`, `mix qa`, and `mix docs.verify`; use the pre-existing database setup aliases. [VERIFIED: codebase `mix.exs`]

### Wave 0 Gaps

- [ ] A real compiled generated-host router fixture that imports the rendered macro rather than independently spelling routes.
- [ ] A generated-host consent route test that exercises returned context and the supported completion URL.
- [ ] A temporary/package migration fixture utility that can copy a controlled source inventory, simulate upgrade, and assert collision atomicity without mutating repository migrations.
- [ ] Template compilation coverage for the generated resolver, consent LiveView, router macro, config, and default smoke.
- [ ] Default-profile generated smoke and an independently selected FAPI profile/test path.

## Security Domain

| ASVS Category | Applies | Standard control |
|---|---|---|
| V2 Authentication | Yes | Host owns sessions/login; generated operator pipeline must be present and is never supplied by Lockspire. |
| V3 Session Management | Yes | Generated logout path routes back to host session clearing; Lockspire end-session completion stays protocol-owned. |
| V4 Access Control | Yes | Admin forward sits behind host `:require_operator`; generated consent binds interaction to resolved subject. |
| V5 Input Validation | Yes | Router parameters are processed by existing interaction/consent behavior; migration filenames are parsed and conflict-checked before filesystem writes. |
| V6 Cryptography | Yes | Reuse SHA-256 manifest checksums and existing PKCE/JWT behavior; do not introduce crypto. |

| Threat pattern | STRIDE | Mitigation |
|---|---|---|
| Public forward bypasses admin guard | Elevation of privilege | Compile-time macro route order plus `Phoenix.Router.routes/1` assertions. |
| Consent decides for wrong or expired interaction | Tampering / elevation | Shared context retains existing subject-match, expiry, and `AuthorizationFlow.resume_interaction` checks. |
| Installer overwrites or masks migration | Tampering | Preflight all identity/content collisions, copy only missing byte-for-byte files, never overwrite. |
| Misconfigured logout causes protocol redirect failure | Availability / integrity | Generated explicit config and independent verify error with remediation. |
| FAPI controls silently treated as baseline | Security configuration | Default and opt-in test profiles are distinct. |

## Sequencing and Dependencies

1. Add consent-context API with characterization tests around every current `ConsentLive` outcome before changing templates.
2. Add migration-copy inventory/preflight and its isolated filesystem tests; invoke it from install/upgrade and extend manifest backward-compatibly.
3. Convert router template to macro and update the runtime fixture to import its actual generated output; add a real operator pipeline solely in the fixture.
4. Update generated consent/config/claims/smoke templates and template registry/manifest expectations together.
5. Upgrade `lockspire.verify` to report the newly explicit contract and replace source-string assertions with compiled/HTTP proof.
6. Update onboarding documentation only after commands and generated outputs are executable.

The consent API must precede the generated LiveView, and the router macro must precede the host fixture because all route assertions need compiled AST. Migration copying is independent of consent work and can be its own plan/wave. [VERIFIED: codebase `lib/lockspire/web/live/consent_live.ex`, `lib/lockspire/generators/install.ex`, `test/support/generated_host_app_web/router.ex`]

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|---|---|---|
| A1 | `Lockspire.Web.ConsentContext` is the preferred exact public module name. | Architecture Patterns | Low: name is discretionary; semantics and boundary are locked. |
| A2 | `--with-fapi-smoke` is the preferred exact opt-in switch. | Generated proof | Low: switch/template path is discretionary; opt-in separation is locked. |

## Open Questions

1. **What exact default behavioral smoke should a generated host own?**
   - What we know: it must compile and execute the actual generated endpoint/router under `:none`; it must not require FAPI PAR rejection. [VERIFIED: codebase `131-CONTEXT.md`, `priv/templates/lockspire.install/fapi_smoke_e2e_test.exs`]
   - Recommendation: use discovery/JWKS plus default authorization-code + S256 routing and exact redirect rejection, borrowing the real host setup pattern from Phase 6 without attempting Phase 133’s separate-origin journey.
2. **Should migration inventory be a section of the existing manifest or a small separate file?**
   - What we know: the existing manifest is already install-owned and versioned, but tracks only managed scaffolding. [VERIFIED: codebase `lib/lockspire/install/manifest.ex`]
   - Recommendation: add an optional `migrations` array to that manifest to keep one audit file and preserve old-manifest compatibility.

## Environment Availability

| Dependency | Required by | Available | Version / state | Fallback |
|---|---|---|---|---|
| Elixir/Mix | compile and ExUnit proof | Yes | Mix 1.19.5 / OTP 28 | — |
| PostgreSQL | generated-host Ecto integration | Yes | `pg_isready` accepts localhost:5432 | Existing `mix test.setup` runner |
| Phoenix/Ecto dependencies | router/migration proof | Yes | resolved in `mix.lock` | — |

## Sources

### Primary (HIGH confidence)

- `AGENTS.md` — embedded boundary and non-negotiable security defaults.
- `131-CONTEXT.md` — locked Phase 131 decisions.
- `lib/lockspire/generators/install.ex`, `lib/mix/tasks/lockspire.install.ex`, `lib/mix/tasks/lockspire.upgrade.ex`, `lib/lockspire/install/manifest.ex` — current generator lifecycle.
- `priv/templates/lockspire.install/{router.ex,consent_live.ex,config.exs,account_resolver.ex,fapi_smoke_e2e_test.exs}` — generated defects and exact template surface.
- `lib/lockspire/web/live/consent_live.ex`, `lib/lockspire/web/router.ex`, `lib/lockspire/web/controllers/interaction_controller.ex` — authoritative consent/route behavior.
- `lib/lockspire/install/verify.ex`, `lib/lockspire/config.ex`, `lib/lockspire/host/claims.ex`, `lib/lockspire/clients.ex` — verification/config/claims/profile facts.
- `test/integration/install_generator_test.exs`, `test/integration/install_upgrade_test.exs`, `test/integration/phase6_onboarding_e2e_test.exs`, `test/support/generated_host_app_web/router.ex` — present proof limitations and reusable fixture path.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all versions and behavior read from the lockfile and repository.
- Architecture: HIGH — concrete code seams and user decisions directly identify the required direction.
- Pitfalls: HIGH — each is present in a template, test fixture, or current verification behavior.

**Research date:** 2026-08-26  
**Valid until:** 2026-09-25 (repository-local implementation findings)
