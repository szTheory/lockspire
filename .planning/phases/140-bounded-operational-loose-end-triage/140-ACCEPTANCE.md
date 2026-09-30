# Phase 140 post-summary exact-main acceptance contract

This is a fail-closed verification contract, not an acceptance receipt. CI-06 and CI-07 remain pending until the phase verifier records canonical CI and intentional Release no-publish evidence for the same final synchronized `main` SHA after every Phase 140 plan and SUMMARY write.

## Candidate and current evidence

- Candidate observed at Plan 140-04 entry: `57d33ab35f3b16efe2ed184d81a3e7779fa5821a` on `agent-140-01-rerun`.
- Local and `origin/main` were both `5ad2b2e935556c8f1a91be32605958530b477527` at task entry. These observations are not a refreshed post-summary ref proof.
- The Phase 139 receipt at `.git/lockspire-phase-139-acceptance-v1.json` is entry-only evidence for `c6332d3a8b716b938f93d978243281764e3eac41` (CI run `36476762461`; Release no-publish run `36476762490`). It does not accept the Plan 140-04 candidate or any later SHA.
- Final local `mix ci` was run after the scoped disposition commit `c64a5d38` with the acceptance file present as an uncommitted documentation change and `HEX_HOME=/private/tmp/lockspire-hex-cache`. Its result was **failed**: `1439 tests, 44 failures, 6 skipped (286 excluded)` in 1491.3 seconds. Earlier gates in the alias passed, including compile, cycle check, 13 tests, Credo (570 files, no issues), Sobelow, docs generation, retired-package check, dependency audit (`No vulnerabilities found`), package build, and migrations. The full test output included the stale ReleaseAutomation assertion that Phase 140 remains gated although current PROJECT says execution is underway; both Phase 140 recovery diagnostic mismatches; duplicate `client_id: client_jar` constraint errors in `AuthorizationRequestTest`; and an existing `:invalid_signing_key` token exchange failure. The returned output was truncated at 44,624 tokens, so these are observed representative causes, not a full enumeration of all 44 failures. The run also logged `error: cannot open '.git/FETCH_HEAD': Operation not permitted`; the suite proceeded, but that environment-limited fetch evidence is not treated as a pass. None of these local results satisfy CI-06 or CI-07.
- Keep the historical Lockspire 1.5.0 source, CI, protected Release, tag, checksum, and Hex proof distinct from current acceptance. Supplemental OIDF/FAPI evidence remains redacted and non-certifying.

## Verifier sequence after all Phase 140 writes

1. Re-fetch and record full immutable object IDs for `HEAD`, local `main`, and `origin/main`. Require exact equality at one full SHA after the final plan SUMMARY and lifecycle writes. Require a clean worktree; disclose the four protected execution-entry files and use only the existing hygiene contract's exact registered-overlay treatment. Recheck their entry SHA-256 values before concluding that their bytes are unchanged.
2. If reaching synchronized `main` requires a new push, stop before pushing. Obtain separate authorization naming the concrete candidate SHA, exact diff, observed remote OID, normal non-force update, and recovery route. No earlier SHA approval authorizes that push. Do not mutate protected publication state or release-owned files.
3. Query canonical GitHub `CI` and `Release` run and job records for that exact same final SHA. Required CI is `.github/workflows/ci.yml`; require success for Dialyzer, Release Hygiene Drift, Fast Checks, Minimum Supported Elixir/OTP, Integration Checks, Complete Coverage Evidence, and Adoption Demo Smoke.
4. Require the `.github/workflows/release.yml` push run to prove the intentional no-publish graph at that SHA: `Maintain Release Please PR` succeeds, while `Validate exact main head and CI evidence`, `Prove exact package before publication`, `Publish verified release to Hex`, and `Verify public install truth` are completed and skipped. Do not dispatch the protected publication workflow.
5. Run exact hygiene acceptance for that final SHA, supplying one `--warn-disposition LABEL=DISPOSITION` argument for every WARN label actually observed:

   ```sh
   bash scripts/maintainer/repo_hygiene_check.sh \
     --accept-sha {final-sha} \
     --warn-disposition {observed-label}={specific-disposition} \
     --format json
   ```

   Repeat `--warn-disposition` once per distinct observed WARN. Omit all such arguments only when the observed WARN count is zero. Require zero BLOCK, exactly one bounded disposition per WARN, and the CLI's exact synchronized-main and same-SHA workflow validation to pass.
6. Store the resulting bounded receipt and run/job identities with the phase verification. Mark CI-06/CI-07 complete only if the full exact-SHA join and exact hygiene command pass; otherwise keep both pending and name the exact missing ref, authorization, CI, Release, or WARN/BLOCK condition.

The previous dated receipt may support only its recorded SHA. Supplemental OIDF/FAPI results remain separate and cannot substitute for required CI or Release evidence. No current final-SHA receipt is asserted here.

## Current disposition

**CI-06: pending.** The required final synchronized-main full SHA, canonical CI run/job identities at that SHA, and exact hygiene receipt do not yet exist. The entry receipt is for an older SHA. A new push, if required after final writes, needs separate exact-candidate authorization.

**CI-07: pending.** The successful intentional Release no-publish run and its complete job graph must be queried at the same final synchronized-main SHA. No Release dispatch or publication action is authorized by this contract.
