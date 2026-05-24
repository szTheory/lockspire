# Phase 63: Canonical Install Path & Host Diagnostics - Research

**Researched:** 2026-05-06
**Scope:** Canonical embedded install path, post-install diagnostics, managed-vs-host-owned scaffolding, upgrade contract, and truthful generated-host proof for Lockspire's Phoenix adoption surface.
**Confidence:** HIGH

## Summary

Phase 63 should harden one install story rather than widen Lockspire into multiple host shapes. The repo already has the right building blocks for that approach: `mix lockspire.install` generates a narrow Phoenix-first seam, `Lockspire.Config` and `Lockspire.Oban` already fail fast for required runtime configuration, and `install_generator_test.exs` already proves no-overwrite semantics. The gaps are that generation is not bootstrap-safe, every generated file is treated as equally host-owned forever, there is no post-wiring verification command, and the current generated proof still exercises `Lockspire.Web.Router` directly instead of proving host router wiring.

The strongest plan shape is:

1. Make `mix lockspire.install` bootstrap-safe and explicit about artifact ownership.
2. Add `mix lockspire.verify` as the canonical post-install diagnostics command.
3. Add a manifest-aware `mix lockspire.upgrade` path only for Lockspire-managed scaffolding.
4. Update docs and executable proof so the canonical claim is truthful: one generic path, Sigra as the recommended companion, and host-router wiring proven in-repo.

## Planning-Critical Findings

### 1. The current installer is not bootstrap-safe

- `lib/lockspire/generators/install.ex` currently calls `Lockspire.mount_path()` while building assigns.
- That means install generation depends on runtime config that the generator itself is meant to create.
- Phase 63 should remove that circular dependency by introducing an install-time mount-path input with a safe default such as `"/lockspire"`.

### 2. Current generated stubs can look healthy before the host has done real work

- `priv/templates/lockspire.install/account_resolver.ex` returns `{:ok, %{id: account_reference}}` from `resolve_account/2` and a structurally valid empty-claims shape from `build_claims/2`.
- `resolve_current_account/2` redirects to login, which is safe, but the remaining defaults can still make the scaffold feel more implemented than it really is.
- Security-sensitive host seams should fail intentionally until the host app replaces the placeholders.

### 3. Lockspire already has the right fail-fast runtime posture

- `lib/lockspire/config.ex` raises on missing required config such as `:mount_path`.
- `lib/lockspire/oban.ex` raises clearly when repo or Oban config is missing or invalid.
- Phase 63 should preserve that posture and add a second lane for install-oriented diagnostics rather than moving everything into a single generator-time gate.

### 4. The repo has a strong no-overwrite baseline but no managed-scaffolding concept

- `Lockspire.Generators.Install.ensure_file!/2` currently refuses to overwrite any modified generated file.
- That is correct for host-owned seams, but too blunt for files that are effectively Lockspire-managed scaffolding such as `config/lockspire.exs`, `lib/<web>/router/lockspire.ex`, and the generated smoke test.
- A manifest-aware upgrade path can preserve strict host boundaries while still allowing predictable upgrades for unchanged managed files.

### 5. The current proof overstates router integration truth

- `priv/templates/lockspire.install/fapi_smoke_e2e_test.exs` and `test/integration/phase6_onboarding_e2e_test.exs` call `Lockspire.Web.Router` directly.
- That proves protocol behavior, not host router mounting.
- Phase 63 should move the install proof toward a generated-host router or endpoint path so the repo can truthfully claim that host wiring is part of the proven canonical install flow.

### 6. Sigra positioning is already narrow and should stay that way

- `docs/sigra-companion-host.md` and `.planning/ECOSYSTEM-SIGRA.md` already frame Sigra as a companion path, not a dependency.
- `--sigra-host` should remain comments/guidance only.
- The canonical install story should stay generic to Phoenix hosts.

## Recommended File Targets

### Installer / ownership slice

- `lib/mix/tasks/lockspire.install.ex`
- `lib/lockspire/generators/install.ex`
- `lib/lockspire/generators/templates.ex`
- `priv/templates/lockspire.install/config.exs`
- `priv/templates/lockspire.install/router.ex`
- `priv/templates/lockspire.install/account_resolver.ex`
- `priv/templates/lockspire.install/interaction_handler.ex`
- `priv/templates/lockspire.install/fapi_smoke_e2e_test.exs`
- `test/integration/install_generator_test.exs`

### Verify diagnostics slice

- `lib/mix/tasks/lockspire.verify.ex`
- `lib/lockspire/install/verify.ex`
- `lib/lockspire/install/verify/check.ex` or equivalent focused helper modules
- `test/mix/tasks/lockspire_verify_test.exs`
- `test/lockspire/install/verify_test.exs`

### Upgrade / manifest slice

- `lib/mix/tasks/lockspire.upgrade.ex`
- `lib/lockspire/install/manifest.ex`
- `lib/lockspire/generators/templates.ex`
- `lib/lockspire/generators/install.ex`
- `test/integration/install_generator_test.exs`
- `test/integration/install_upgrade_test.exs`

### Docs / proof slice

- `docs/install-and-onboard.md`
- `docs/sigra-companion-host.md`
- `docs/ecosystem-overview.md`
- `docs/supported-surface.md`
- `priv/templates/lockspire.install/fapi_smoke_e2e_test.exs`
- `test/integration/install_generator_test.exs`
- `test/integration/phase6_onboarding_e2e_test.exs`
- `test/support/generated_host_app_web/router.ex`
- `test/support/generated_host_app_web/endpoint.ex`

## Recommended Ownership Model

### Host-owned by default

- `lib/<scope>/account_resolver.ex`
- `lib/<scope>/interaction_handler.ex`
- generated consent LiveView seam
- generated authorized-apps controller / HTML seam
- generated verification controller / HTML seam

These should remain copy-once, never auto-overwritten, and clearly marked as host-owned.

### Lockspire-managed scaffolding candidates

- `config/lockspire.exs`
- `lib/<web>/router/lockspire.ex`
- generated smoke or onboarding proof test
- generated install manifest metadata

These can be safely upgraded only when the manifest proves they are unchanged or machine-reconcilable.

## Recommended Diagnostics Contract

`mix lockspire.verify` should become the canonical verification step after install and host wiring. The first version should check:

- required `:lockspire` runtime config keys and obvious config consistency
- configured account-resolver / interaction seam modules exist and export expected callbacks
- the compiled host router exposes both the Lockspire mount forward and the host-owned `/verify` routes
- pending Lockspire and Oban migrations relevant to the shipped surface

It should print actionable failures rather than letting the first broken request reveal the problem indirectly.

## Risks To Plan Around

- Do not make `mix lockspire.install` depend on config it creates.
- Do not turn `--sigra-host` into a second topology or compile-time dependency.
- Do not introduce broad merge behavior for host-edited source files.
- Do not claim host-router proof until tests stop calling `Lockspire.Web.Router` directly.
- Do not collapse verify-time diagnostics into boot-time validation; both layers are needed.

## Recommended Plan Order

1. Installer/bootstrap safety and ownership annotations.
2. Verify command and diagnostics checks.
3. Manifest-aware upgrade flow for managed scaffolding.
4. Docs plus generated-host proof updates once the install, verify, and upgrade contracts are settled.

## Validation Architecture

The phase should use a layered validation strategy:

- Plan-level tests for generator output, idempotence, ownership headers, and manifest creation.
- Focused diagnostics tests for `mix lockspire.verify` negative paths and success cases.
- Upgrade tests for unchanged managed scaffolding, dirty managed scaffolding, and host-owned drift refusal.
- Integration proof that exercises the generated host router or endpoint rather than calling `Lockspire.Web.Router` directly.

Phase exit should include:

```bash
mix test test/integration/install_generator_test.exs \
  test/integration/install_upgrade_test.exs \
  test/integration/phase6_onboarding_e2e_test.exs \
  test/lockspire/application_test.exs \
  test/lockspire/config_test.exs \
  test/mix/tasks/lockspire_verify_test.exs \
  test/lockspire/install/verify_test.exs
```
