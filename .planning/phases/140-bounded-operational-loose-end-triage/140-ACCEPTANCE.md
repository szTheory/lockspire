# Phase 140 post-summary exact-main acceptance contract

This is a fail-closed verification contract, not an acceptance receipt. CI-06 and CI-07 remain pending until the phase verifier records canonical CI and intentional Release no-publish evidence for the same final synchronized `main` SHA after every Phase 140 plan and SUMMARY write.

## Candidate and current evidence

- Candidate observed at Plan 140-04 entry: `57d33ab35f3b16efe2ed184d81a3e7779fa5821a` on `agent-140-01-rerun`.
- Local and `origin/main` were both `5ad2b2e935556c8f1a91be32605958530b477527` at task entry. These observations are not a refreshed post-summary ref proof.
- The Phase 139 receipt at `.git/lockspire-phase-139-acceptance-v1.json` is entry-only evidence for `c6332d3a8b716b938f93d978243281764e3eac41` (CI run `36476762461`; Release no-publish run `36476762490`). It does not accept the Plan 140-04 candidate or any later SHA.
- The failed Plan 140-04 local `mix ci` result (`1439 tests, 44 failures, 6 skipped`) is retained as historical evidence in `140-04-SUMMARY.md`; its recovery, signing-key, fixture, formatter, and full-suite findings were repaired and reconciled in Plans 140-06 through 140-12. It is not the current local result.
- Latest complete local `mix ci` preparatory receipt: candidate `93e85d11cbb491d619e391acabec2641b14ae015`; command `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 ERL_FLAGS='+S 1:1' HEX_HOME=/private/tmp/lockspire-hex-cache mix ci`; result **1,440 tests, 0 failures, 6 skipped (286 excluded), then 102 integration tests, 0 failures (33 excluded)**. Log: `/private/tmp/lockspire-140-08-ci-final.RVOcF5` (mode `0600`). The current Plan 140-09 executor started at `27b05579df8ec894b8efba39feeeac8172fc3270`, a descendant of the tested candidate; `git diff 93e85d11cbb491d619e391acabec2641b14ae015 27b05579df8ec894b8efba39feeeac8172fc3270 -- lib test scripts .github mix.exs mix.lock` is empty. This proves the local code candidate only; later SUMMARY/lifecycle writes still change the exact full SHA, so the receipt is preparatory and cannot satisfy CI-06/CI-07.
- Keep the historical Lockspire 1.5.0 source, CI, protected Release, tag, checksum, and Hex proof distinct from current acceptance. Supplemental OIDF/FAPI evidence remains redacted and non-certifying.

## Verifier sequence after all Phase 140 writes

1. After this plan's SUMMARY and every lifecycle write, fetch `origin` and record full immutable object IDs for `HEAD`, local `main`, and freshly fetched `origin/main`; record the porcelain worktree state and the exact diff from remote (`git diff --binary origin/main...HEAD`, including an explicit empty result when there is no diff). Require all three OIDs to be equal at one full SHA for final acceptance. Disclose the four protected execution-entry files: the Phase 138 ledger, `138-UAT.md`, `138-VERIFICATION.md`, and `docs/lockspire-milestone-roadmap-ratchet-prompt.txt`. Use only the existing hygiene contract's exact registered-overlay treatment and recheck each recorded entry SHA-256 before concluding the bytes are unchanged. Preserve and report every unrelated dirty or untracked path; do not clean it.
2. If reaching synchronized `main` requires a new push or local ref movement, stop at a separate `gate=blocking-human` authorization checkpoint before either action. Present the final full candidate SHA, exact diff, freshly observed remote OID, normal non-force ref update, and recovery route; wait for explicit authorization for that exact candidate and action. No earlier SHA approval transfers. Do not mutate protected publication state or release-owned files.
3. Query canonical GitHub `CI` and `Release` run and job records for that exact same final SHA. Required CI is `.github/workflows/ci.yml`; require success for Dialyzer, Release Hygiene Drift, Fast Checks, Minimum Supported Elixir/OTP, Integration Checks, Complete Coverage Evidence, and Adoption Demo Smoke.
4. Require the `.github/workflows/release.yml` push run to prove the intentional no-publish graph at that SHA: `Maintain Release Please PR` succeeds, while `Validate exact main head and CI evidence`, `Prove exact package before publication`, `Publish verified release to Hex`, and `Verify public install truth` are completed and skipped. Do not dispatch the protected publication workflow.
5. Run a clean local `mix ci` on that final SHA with the supported Elixir/OTP environment, then run exact hygiene acceptance for the same SHA, supplying one `--warn-disposition LABEL=DISPOSITION` argument for every WARN label actually observed:

   ```sh
   bash scripts/maintainer/repo_hygiene_check.sh \
     --accept-sha {final-sha} \
     --warn-disposition {observed-label}={specific-disposition} \
     --format json
   ```

   Repeat `--warn-disposition` once per distinct observed WARN. Omit all such arguments only when the observed WARN count is zero. Require local `mix ci` to pass, zero hygiene BLOCK, exactly one bounded disposition per WARN, and the CLI's exact synchronized-main and same-SHA workflow validation to pass.
6. Store the final SHA, exact diff and worktree-state receipt, protected-overlay hashes, local `mix ci` result, bounded hygiene receipt, and canonical CI/Release run and job identities with the phase verification. Mark CI-06/CI-07 complete only if the full exact-SHA join and exact hygiene command pass; otherwise keep both pending and name the exact missing ref, authorization, CI, Release, or WARN/BLOCK condition.

The previous dated receipt may support only its recorded SHA. Supplemental OIDF/FAPI results remain separate and cannot substitute for required CI or Release evidence. No current final-SHA receipt is asserted here.

## Current disposition

**CI-06: pending.** The required final synchronized-main full SHA, canonical CI run/job identities at that SHA, and exact hygiene receipt do not yet exist. The entry receipt is for an older SHA. A new push, if required after final writes, needs separate exact-candidate authorization.

**CI-07: pending.** The successful intentional Release no-publish run and its complete job graph must be queried at the same final synchronized-main SHA. No Release dispatch or publication action is authorized by this contract.
