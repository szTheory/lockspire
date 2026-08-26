---
phase: 131-executable-installation
reviewed: 2026-08-26T22:09:52Z
depth: standard
files_reviewed: 29
files_reviewed_list:
  - lib/lockspire/generators/install.ex
  - lib/lockspire/generators/templates.ex
  - lib/lockspire/install/manifest.ex
  - lib/lockspire/install/migrations.ex
  - lib/lockspire/install/operation_plan.ex
  - lib/lockspire/install/verify.ex
  - lib/lockspire/web/consent_context.ex
  - lib/lockspire/web/live/consent_live.ex
  - lib/mix/tasks/lockspire.install.ex
  - lib/mix/tasks/lockspire.upgrade.ex
  - priv/templates/lockspire.install/account_resolver.ex
  - priv/templates/lockspire.install/config.exs
  - priv/templates/lockspire.install/consent_live.ex
  - priv/templates/lockspire.install/default_smoke_e2e_test.exs
  - priv/templates/lockspire.install/fapi_smoke_e2e_test.exs
  - priv/templates/lockspire.install/router.ex
  - test/integration/install_generator_test.exs
  - test/integration/install_upgrade_test.exs
  - test/integration/phase57_rar_introspection_verification_e2e_test.exs
  - test/integration/phase6_onboarding_e2e_test.exs
  - test/lockspire/install/migrations_test.exs
  - test/lockspire/install/verify_test.exs
  - test/lockspire/web/consent_context_test.exs
  - test/mix/tasks/lockspire_verify_test.exs
  - test/support/generated_host_app_web/live/lockspire_consent_live.ex
  - test/support/generated_host_app_web/plugs/require_operator.ex
  - test/support/generated_host_app_web/router.ex
  - test/support/generated_host_app_web/router/lockspire.ex
  - docs/install-and-onboard.md
findings:
  critical: 3
  warning: 3
  info: 0
  total: 6
status: issues_found
---

# Phase 131: Code Review Report

**Reviewed:** 2026-08-26T22:09:52Z  
**Depth:** standard  
**Files Reviewed:** 29  
**Status:** issues_found

## Summary

The generated route macro and migration preflight are meaningful improvements, and the focused suite passes (47 tests). However, the advertised install verifier can approve an entirely unguarded admin mount, an opted-in FAPI installation cannot subsequently be upgraded, and the generated logout seam ignores the explicit configuration it asks hosts to maintain. The filesystem apply path also lacks the promised all-artifact atomicity and symlink/race defenses.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: `mix lockspire.verify` false-passes an unguarded operator UI

**File:** `lib/lockspire/install/verify.ex:272-275`  
**Issue:** `admin_mount_route?/2` establishes only that `Lockspire.Web.AdminRouter` is forwarded at the expected path. It does not inspect the route's pipeline metadata or otherwise establish that the host's `:require_operator` guard ran. The passing test router itself has no operator pipeline or `pipe_through` at all (`test/lockspire/install/verify_test.exs:45-47`), proving that the verifier reports a safe admin mount for a publicly reachable one. This defeats the phase's fail-closed operator-boundary promise.

**Fix:** Make the generated macro tag the admin route with a verifiable private/metadata marker after the host guard, or inspect Phoenix route metadata/pipeline information that reliably records the required guard. Require that proof in `admin_mount_route?/2`; add a negative test with an admin forward that has only `:browser` and assert `mix lockspire.verify` fails.

### CR-02: `--with-fapi-smoke` installs cannot run `mix lockspire.upgrade`

**File:** `lib/mix/tasks/lockspire.upgrade.ex:16-25, 53-71`  
**Issue:** The install task records the optional FAPI smoke as a managed file, but upgrade does not accept or preserve `:with_fapi_smoke`. It always builds assigns with `false`, so `Templates.all/1` excludes that artifact. `OperationPlan.manifest_entries/2` then rejects the manifest's FAPI entry as “managed file is no longer shipped” (`lib/lockspire/install/operation_plan.ex:115-145`). An adopter who explicitly requested the documented FAPI proof is therefore permanently blocked from every later managed upgrade. No upgrade test covers an opted-in manifest.

**Fix:** Add a strict `--with-fapi-smoke` upgrade option (and document it), or persist the optional-template selection in the manifest inputs and derive it during upgrade. Add fresh-install-with-FAPI → dry-run → upgrade coverage and ensure the optional file is retained/updated without making it default-generated.

### CR-03: Generated logout configuration is ignored by the generated resolver

**File:** `priv/templates/lockspire.install/account_resolver.ex:86-95`  
**Issue:** The generated config explicitly introduces `logout_path` as a host-owned seam, but `redirect_for_logout/2` hard-codes `"/logout"`. Changing `config/lockspire.exs` as the guide directs (`docs/install-and-onboard.md:97-100`) has no effect on the redirect returned by the generated resolver. Hosts with a non-default logout route will redirect to the wrong endpoint during logout handling.

**Fix:** Return `login_path: Lockspire.logout_path()` (or pass an explicit, validated host logout path through the supported seam) and add a rendered-template behavior test with a non-`/logout` configured path.

## Warnings

### WR-01: Apply can leave an install or upgrade partially mutated after a write failure

**File:** `lib/lockspire/install/operation_plan.ex:73-80, 279-306`; `lib/lockspire/install/migrations.ex:350-372`  
**Issue:** Even though planning is exhaustive, `OperationPlan.apply/1` copies migrations first and then writes generated files one at a time; `Migrations.apply/1` itself also copies one at a time. A permission failure, disk failure, or post-preflight race leaves earlier migrations/files in the host tree while the manifest is absent or stale. This contradicts the claimed all-artifact preflight/apply boundary and makes recovery state ambiguous.

**Fix:** Stage every changed artifact under a private temporary directory and atomically rename into place only after all writes succeed, with explicit rollback/cleanup for any already-renamed paths. At minimum, return a recovery report that lists all completed writes and test an injected failure after the first migration/file to prove deterministic recovery.

### WR-02: Managed-file and migration writes follow symlinks and have a TOCTOU window

**File:** `lib/lockspire/install/migrations.ex:131-142, 315-372`; `lib/lockspire/install/operation_plan.ex:234-306`; `lib/lockspire/install/manifest.ex:24-45`  
**Issue:** `File.stat/1`, `File.read/1`, and ordinary `File.write/2` follow symlinks. In particular, an upgrade validates the checksum of a managed destination and later writes it with `File.write/2`; replacing that path with a symlink between those operations redirects the write outside the host project. Packaged migration sources likewise accept symlinked regular-file targets. There is no realpath/containment check or no-follow primitive at this filesystem trust boundary.

**Fix:** Reject any symlink in the source, project-root ancestry, destination ancestry, or artifact path using `File.lstat/1`; canonicalize and verify every resolved path remains under its approved root before and immediately before writes. Use create-only/no-follow atomic writes (and rename from a verified temp file) for managed artifacts and the manifest. Add adversarial symlink and swap-race tests.

### WR-03: Generated FAPI requests teach fixed state, nonce, and PKCE verifier values

**File:** `priv/templates/lockspire.install/fapi_smoke_e2e_test.exs:120-131`  
**Issue:** The FAPI smoke hard-codes `state`, `nonce`, and the PKCE verifier. Although this is test code, it is generated into adopters' projects as a reference implementation and contradicts the plan's requirement for random authorization-request values. Copying it into a real client removes CSRF/session binding and makes nonce/PKCE material predictable.

**Fix:** Generate fresh cryptographically random values per request (for example `:crypto.strong_rand_bytes/1 |> Base.url_encode64(padding: false)`) and derive the challenge from that verifier. Assert values are present/accepted without coupling tests to fixed literals.

---

_Reviewed: 2026-08-26T22:09:52Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
