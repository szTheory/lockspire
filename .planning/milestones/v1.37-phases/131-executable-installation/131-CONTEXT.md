# Phase 131: Executable Installation - Context

**Gathered:** 2026-08-26
**Status:** Ready for planning
**Mode:** Autonomous from approved milestone plan

<domain>
## Phase Boundary

Make the packaged Lockspire install path genuinely executable in a fresh Phoenix/Ecto host: generated routes must mount, host-branded consent must use real interaction state, migrations must enter the host's normal migration path safely, required configuration and verification must agree, and generated examples/tests must compile and pass under the default secure profile. This phase does not build the separate partner journey; Phase 133 consumes this foundation.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Lockspire.Web.ConsentLive` already owns correct interaction loading, account resolution, consent reuse, expiry, and finalization context; extract and reuse this behavior.
- `Lockspire.Web.InteractionController` already owns supported approve/deny completion and redirect semantics.
- Existing install/upgrade generators, manifest verification, package fixtures, and `priv/repo/migrations` provide the implementation and proof surfaces.

### Established Patterns
- Host-owned editable templates define account, login, branding, operator-auth, verification, and authorized-app seams.
- Lockspire-owned routers and protocol services remain behind narrow generated host mounts.
- Generator changes apply to new installs and additive upgrades; existing host-owned files are never silently rewritten.

### Integration Points
- `priv/templates/lockspire.install/router.ex`, generated consent/account/config/test templates, install/upgrade tasks, install manifest verification, generated-host fixtures, onboarding docs, and package contents.
- Phase 132 will consume the corrected resource-server and public-client contracts; Phase 133 will consume the executable packaged install path.

</code_context>

<specifics>
## Specific Ideas

- The acceptance bar is a fresh generated host that runs compile, migrations, `mix lockspire.verify`, and its default tests using documented commands and actual generated modules.
- No test may hide generator defects by rebuilding the expected router, resolver, client, key, or migration wiring by hand.

</specifics>

<deferred>
## Deferred Ideas

- Separate-origin partner application and full HTTP token lifecycle proof belong to Phase 133.
- Public access-token accessors, client-registration coherence, and resource-server docs belong to Phase 132.
- Admin or consent visual redesign and formal conformance certification remain out of scope.

</deferred>
