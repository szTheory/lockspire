---
phase: 178-packaged-upgrade-proof-delivery-handoff
plan: "09"
subsystem: docs
tags: [client-secret-jwt, verifier-keys, phoenix, postgres, release]
requires:
  - phase: 178-08
    provides: Pinned retained package receipt matrix and validator
provides:
  - Host-owned fresh-install and verifier-key guidance matching generated host output
  - Reader-first activation, maintenance, recovery, and support-boundary instructions
  - Current candidate, accepted-main, and protected-release guidance
affects: [178-10, verifier-delivery, maintainer-handoff]
actuals:
  tokens: 4576
  tasks: 2
  commits: 2
tech-stack:
  added: []
  patterns: [host-owned-verifier-configuration, fresh-custody-check-before-retirement, exact-main-release-authority]
key-files:
  created: []
  modified:
    - docs/client-secret-verifier-configuration.md
    - docs/client-secret-jwt-host-guide.md
    - docs/install-and-onboard.md
    - docs/getting-started.md
    - docs/supported-surface.md
    - docs/maintainer-release.md
    - test/lockspire/security/client_secret_verifier_maintenance_guidance_test.exs
key-decisions:
  - "The install generator owns Phoenix integration scaffolding; verifier keys and their configuration remain host-owned."
  - "A mode-less maintenance task applies; preview, apply, and a separate fresh beginning-to-end check remain distinct."
  - "A local custody check does not authorize fleet retirement, and restored keys remain distinct from authorized partner-secret replacement."
  - "Retained package validation corroborates existing receipts only; fresh fixed-wrapper runs and frozen inputs remain Plan 10 work."
requirements-completed: []
duration: 15min
completed: 2026-10-27
status: complete
plan_head_before: 0a091295fc4a643f294b659f3f232ab68ed5c8d8
plan_head_after: 3a7b1286e43f3df41020f8c80ec4e00c0e72603c
---

# Phase 178 Plan 09: Observed Adopter and Release Guidance Summary

**Installed-outcome guidance now records host-owned verifier setup, fresh custody-check limits, and current main/release boundaries.**

## Performance

- **Duration:** approximately 15 minutes.
- **Started:** approximately 2026-10-27T03:31:35Z, following the recorded Plan 08 session boundary.
- **Completed:** 2026-10-27T03:46:42Z.
- **Tasks:** 2.
- **Files modified:** 7.
- **Task commits:** 2, measured from `plan_head_before` through `plan_head_after`.
- **Actual diff size:** 18,304 patch characters / 4 = 4,576 tokens; no dependency, runtime, schema, protocol, or UI changes.

## Accomplishments

- Confirmed from the installer and generated config template that `mix lockspire.install` creates the host integration file `config/lockspire.exs` but does not provision verifier key material or settings. The onboarding guides now keep this configuration with the host and point to the canonical verifier guide.
- Reconciled verifier configuration and recovery guidance with the installed outcomes: compatible readers and legacy writers first, explicit dedicated-writer activation after the old writer drains, no format conversion on rollback, native configured lifetime versus migrated original deadline, and restoration of the original key versus authorized secret replacement and its one-time handoff.
- Documented five supported direct JWT endpoints, `/par` and FAPI exclusions, and the continued Basic/post credential paths. Updated the one public supported-surface contract and maintainer guidance for preview/apply/fresh-check semantics, local versus fleet authority, and conditional exact-main acceptance after normal reviewed integration.
- Extended the existing semantic guidance contract for the actual task flags, host ownership, endpoint/support boundaries, recovery consequences, and release authority.

## Task Commits

1. **178-09-01: Reconcile fresh install, generated host and JWT upgrade instructions** — `05a0a2ed` (`docs(178-09): reconcile client auth install and upgrade guidance`).
2. **178-09-02: Document operational decisions and current release/main boundaries** — `3a7b1286` (`docs(178-09): clarify verifier support and release boundaries`).

## Verification and Evidence

The Plan 09 retained-receipt command ran exactly with explicit runner and candidate-source pins:

```sh
python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair all --store all --group all --validate-receipts .artifacts/phase178/complete-2da528fb --expected-runner-revision 2da528fba3ca894cda4e5776b47eb6ccaf12f93c --expected-candidate-source-revision 2da528fba3ca894cda4e5776b47eb6ccaf12f93c --aggregate-output .artifacts/phase178/aggregate-plan09/aggregate.json
```

It exited **0**. The fresh aggregate records runner and candidate source `2da528fba3ca894cda4e5776b47eb6ccaf12f93c`, aggregate validator revision `0a091295fc4a643f294b659f3f232ab68ed5c8d8`, 26/26 required receipts, 64/64 cases, and 0 failed cases. It read retained receipts only; no package producer or installed case was rerun and raw receipt bytes were not refreshed. The retained package identity is archive digest `8be113c5d8cd630ee9fefba3494aac2c236350589a5cd9e7c98600a11a8d1e91` and extracted-tree digest `2af2082226f0be0e47b1f761cb4e98dd526effc0f93800fbacacce1f3a46b243`. The locked host pair is Phoenix 1.8.13 / LiveView 1.2.10; the floor pair is Phoenix 1.8.5 / LiveView 1.1.28.

The required source command was run only through `scripts/ci/run_owned_source_tests.py` with `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4'`:

```sh
python3 scripts/ci/run_owned_source_tests.py test/lockspire/security/client_secret_verifier_maintenance_guidance_test.exs test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs
```

- Initial Task 1 attempt: exit **1**, 20 tests / 1 failure / 0 properties. The failure was a guidance-contract assertion expecting one host-ownership phrase where the onboarding guide used two explicit responsibility statements. No product behavior failed. Manifest source/base SHA was `0a091295fc4a643f294b659f3f232ab68ed5c8d8`; `checkout_clean_before=false`, status digest `837ccf6d8a58741d69c7e948431044b0790cdb3dee415d6eb59b14e2b9fe8dd7`; the witnessed database `lockspire_owned_0218dbcd9dce4782b70c4834a8fc7e96` (OID `39148675`) was independently absent after cleanup.
- Corrected Task 1 attempt: exit **0**, 20 tests / 0 failures / 0 properties at the same base SHA and dirty-checkout digest. The owned database `lockspire_owned_d3939a13d9d44310b673448f18b7e819` (OID `39149006`) was witnessed and independently absent after cleanup.
- Task 2 attempt: exit **0**, 20 tests / 0 failures / 0 properties at source/base SHA `05a0a2ed15d9c7c7a4af8508f6c043f8236673c7`; `checkout_clean_before=false`, status digest `5051c2ff233e0b66b0e90003d7a8599de0e3c64f15f3e076df49f4ff109ef21d`; the witnessed database `lockspire_owned_2342fa05c7a54a8cb5c8f11153ef3c83` (OID `39149338`) was independently absent after cleanup.

For all three runs, `source_sha` is the base commit identity, not a claim that the edited working-tree inputs were clean or committed. The guard manifests separately record checkout cleanliness and status digest. Allowlisted manifest projections, original paths, and original manifest digests are preserved in the mode-0700 directory `.artifacts/phase178/owned-source-guard/plan09/`; its JSON files are mode 0600 and contain counts, resource identity, cleanup state, and output digests only. No raw child output or credentials were copied. Projection index SHA-256: `7fa0c5ccb8f5dd33fc45d4864477c00480927b0d3d28df80b952132468f78b0d`.

`mix format test/lockspire/security/client_secret_verifier_maintenance_guidance_test.exs` and `git diff --check 0a091295..HEAD` passed. The final test bytes are the same bytes committed by Task 2. No source test was run outside the guard.

## Inherited Proof and Review Limits

- Phase 08's retained full matrix is valid under explicit runner/candidate pins. Its historical locked 14/33 and floor 12/31 wrapper attempts on runner `90858f9fa1fecb3b5a6daa7ecc5946370e60303f` each exited 1 at the pre-fix validator import. No fixed-wrapper success is claimed; Plan 10 owns fresh fixed-wrapper runs and strict 14 + 12 composition.
- The original Plan 08 RED JSON gap and newly labeled historical-source reproductions remain distinct. The actual validator/import failures remain preserved. Earlier Plan 03 raw synthetic JWT/code/PKCE material was scrubbed after exposure; Plan 04 and Plan 06 each retain a separate failed-tool synthetic-secret exposure.
- Plan 07 retains two source-database wrong-target incidents (an unboxed shared fixture change and development-database migrations), with no repair or cleanup claimed. The first guard OID-string refusal and root-authorized exact owned-database cleanup/cast correction remain recorded. The unexplained post-capture failure remains without a causal fix.
- These histories remain in planning/evidence records and are not moved into adopter flows. Plan 09 adds no new package execution claim, source-database repair, or incident classification.

## Decisions Made

- The installer generates the Phoenix integration boundary, while the host owns verifier secrets and the `Lockspire.Security.ClientSecretVerifier` configuration.
- A resumed cursor is traversal progress only; local custody readiness requires a separate complete scan from the beginning. A local result does not establish fleet retirement permission.
- Restoring the original verifier key preserves the partner credential; authorized rotation or re-provisioning replaces it and returns the replacement through the existing one-time secret handoff.
- The supported-surface page remains the single public support authority. Main acceptance remains pending until its exact synchronized-main conditions are met after normal reviewed integration; publication remains in Release Please and the protected exact-ref workflow.
- VPROOF-02, VDELIV-01, and VDELIV-02 remain pending at this point. `requirements-completed` is intentionally empty.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Guidance contract correction] Corrected the host-ownership assertion after the first source run**
- **Found during:** Task 1.
- **Issue:** A new semantic assertion expected the install guide's host responsibility boundary as one phrase; the existing guide expresses it across the introductory paragraph and a separate responsibility statement.
- **Fix:** Asserted both actual host-owned statements without removing the account, login, consent, branding, or policy boundary.
- **Files modified:** `test/lockspire/security/client_secret_verifier_maintenance_guidance_test.exs`.
- **Verification:** Guarded rerun passed 20 tests / 0 failures; exact command and manifest identities are recorded above.
- **Committed in:** `3a7b1286`.

**Total deviations:** 1 auto-fixed test-contract issue (Rule 1).
**Impact on plan:** No behavior, support scope, or verification claim was broadened. All plan tasks completed.

## Issues Encountered

The initial Task 1 source run exposed the guidance assertion mismatch described above. The source guard completed its exact owned database cleanup and the corrected guarded run passed. Git metadata writes were initially denied by the workspace sandbox; the authorized narrow local Git escalation succeeded for the exact task files and commits. No remote action was attempted.

## User Setup Required

None.

## Next Phase Readiness

Plan 09 guidance and semantic contracts are ready for Plan 10's frozen-source reconciliation, required canonical guarded `--ci`, and fresh fixed-wrapper locked/floor package runs. Do not treat the retained receipt validation or the guarded documentation tests as the final package/candidate gate. Phase requirements remain pending; the package wrapper histories, inherited review flags, and unavailable/future owner actions remain open for their assigned plans.

## Self-Check: PASSED

- Both task commits exist on the requested milestone branch.
- All seven modified files exist; Plan 09 receipt validation and guarded source checks have the recorded exits/counts.
- The summary records `plan_head_before` `0a091295fc4a643f294b659f3f232ab68ed5c8d8`, `plan_head_after` `3a7b1286e43f3df41020f8c80ec4e00c0e72603c`, and the measured two task commits.
- No placeholder or stub pattern was introduced in the changed files.

---
*Phase: 178-packaged-upgrade-proof-delivery-handoff*
*Completed: 2026-10-27*
