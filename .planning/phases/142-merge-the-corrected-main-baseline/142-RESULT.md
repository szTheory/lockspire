# Phase 142 Exact-Main Result

**Accepted source SHA:** `6f1a19b39999f96eb24352c75c2a0628375175ae`

**Correction PR:** [#113](https://github.com/szTheory/lockspire/pull/113), squash-merged from reviewed head `084e2849a584c5d287add7693e41af37d7abd5d9`

**Acceptance observation:** 2026-10-07 12:40 UTC
**Public release observation:** 2026-10-07 12:29 UTC
**Status:** Exact-source acceptance passed. T-142-10/CR-01 is closed; Phase 143 publication remains a separate action.

## Accepted source and automated evidence

The post-merge source is the PR #113 squash commit. The clean acceptance clone verified synchronized `HEAD`, local `main`, and refreshed `origin/main` at the full source SHA. PR checks were green before merge; the canonical push CI run and Release no-publish run then passed on the merge SHA.

| Check | Result | Evidence |
| --- | --- | --- |
| Canonical CI | Pass; all seven required jobs succeeded | [Run 37617422181](https://github.com/szTheory/lockspire/actions/runs/37617422181): Adoption Demo Smoke, Complete Coverage Evidence, Dialyzer, Fast Checks, Integration Checks, Minimum Supported Elixir/OTP, Release Hygiene Drift |
| Release push graph | Pass, `no_publish`; package proof, Hex publish, exact-main validation, and public-install jobs skipped | [Run 37617422018](https://github.com/szTheory/lockspire/actions/runs/37617422018) |
| Local `mix ci` | Pass; 102 ExUnit tests | Private exact-source acceptance receipt |
| Repository hygiene | Pass; 24 PASS, 0 WARN, 0 BLOCK; no WARN dispositions required | Private exact-source acceptance receipt |
| Supplemental OIDF/FAPI | Non-certifying supplemental evidence; not a required gate | Receipt classifies it as `supplemental_non_certifying` with `required_gate: false` |

The allowlisted exact-source receipt is retained at `/private/var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/lockspire-phase142-acceptance-6f1a19b39999f96eb24352c75c2a0628375175ae.json` (SHA-256 `9de0275ccdf269b5b66f318a5992228af302cc977dc0cb2d8b733d3261b3ea27`). It contains only bounded gate outcomes and identifiers, not raw logs.

## Public release truth

Read-only queries at 12:29 UTC found Hex `latest_version` and `latest_stable_version` both `1.5.0`; the package release list contained no `1.5.1`, and the exact [Hex 1.5.1 release endpoint](https://hex.pm/api/packages/lockspire/releases/1.5.1) returned HTTP 404. The [GitHub release list](https://api.github.com/repos/szTheory/lockspire/releases?per_page=100) showed `lockspire-v1.5.0`, published 2026-08-28, targeting `5d10ce2219c2e687cf9573c8b280abfb118a47d8`; the [1.5.1 tag-ref query](https://api.github.com/repos/szTheory/lockspire/git/ref/tags/lockspire-v1.5.1) returned HTTP 404. The [Hex package API](https://hex.pm/api/packages/lockspire) and [1.5.0 GitHub release](https://github.com/szTheory/lockspire/releases/tag/lockspire-v1.5.0) support this dated observation.

## Security and Phase 143 boundary

The post-fix code review is clean, and the ASVS level 1 security audit records all 13 planned threats closed. PR #113 resolves CR-01/T-142-10 with an active, main-only no-bypass update ruleset plus repeated exact-SHA checks immediately before the Hex publisher. A failed freeze setup or read-back stops publication; an orphaned ruleset may require administrator cleanup. The repository variables `LOCKSPIRE_RELEASE_AUTOMERGE_ENABLED` and `LOCKSPIRE_PHASE143_AUTHORIZED_SHA` were absent at the 12:40 UTC read-back.

Phase 142 performed no release dispatch, tag creation, environment approval, or package publication. Phase 143 owns publication and must revalidate the current full `main` SHA, matching CI and hygiene evidence, and live publication controls before taking any release action. This record is a documentation commit on the retained Phase 141 branch; its containing commit is named separately in `142-03-SUMMARY.md` and does not inherit the source receipt. The earlier acceptance for `5e18d118091a47966bb29300de1fd453bb0880aa` is historical and superseded by the exact-source evidence above.
