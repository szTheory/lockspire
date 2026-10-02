# Phase 140 post-summary exact-main acceptance contract

This is a fail-closed verification contract, not an acceptance receipt. CI-06 and CI-07 remain pending until the phase verifier records canonical CI and intentional Release no-publish evidence for the same final synchronized `main` SHA after every Phase 140 plan and SUMMARY write.

## Candidate and current evidence

- Candidate observed at Plan 140-04 entry: `57d33ab35f3b16efe2ed184d81a3e7779fa5821a` on `agent-140-01-rerun`.
- Local and `origin/main` were both `5ad2b2e935556c8f1a91be32605958530b477527` at task entry. These observations are not a refreshed post-summary ref proof.
- The Phase 139 receipt at `.git/lockspire-phase-139-acceptance-v1.json` is entry-only evidence for `c6332d3a8b716b938f93d978243281764e3eac41` (CI run `36476762461`; Release no-publish run `36476762490`). It does not accept the Plan 140-04 candidate or any later SHA.
- The failed Plan 140-04 local `mix ci` result (`1439 tests, 44 failures, 6 skipped`) is retained as historical evidence in `140-04-SUMMARY.md`; its recovery, signing-key, fixture, formatter, and full-suite findings were repaired and reconciled in Plans 140-06 through 140-12. It is not the current local result.
- Earlier preparatory local `mix ci` receipt: Plan 140-13 source candidate `0227dea2fd7cc8646d098505c3eb6637afb70d87`; command `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 ERL_FLAGS='+S 1:1' HEX_HOME=/private/tmp/lockspire-hex-cache mix ci`; result **1,441 tests, 0 failures, 6 skipped (286 excluded), then 102 integration tests, 0 failures (33 excluded)**. Log: `/private/tmp/lockspire-140-13-ci.oVxPXP` (mode `0600`). It remains historical source evidence; later Plan 140-15 exact-SHA receipts are recorded below.
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

## Post-merge local verification update (2026-10-01)

The latest complete local `mix ci` preparatory evidence is the Plan 140-13 source candidate `0227dea2fd7cc8646d098505c3eb6637afb70d87`, with 1,441 tests, 0 failures, 6 skipped (286 excluded), then 102 integration tests, 0 failures (33 excluded). The full private log is `/private/tmp/lockspire-140-13-ci.oVxPXP`. This supersedes the earlier `93e85d11…` candidate as the latest local-code receipt; it does not replace or invalidate the older run's historical evidence.

After merge, the primary checkout remained at `8061247594fb563d79e3b7d62f1d21b6789ede9f` across the clean post-merge local gates. `post-merge-gate-result.json` records identical before/after HEAD, build exit 0, and full repository-hygiene test exit 0. The hygiene log reports **60 tests, 0 failures** at seed `924694` (`/private/tmp/lockspire-140-plan/post-merge-hygiene-seed-924694.log`). This is local contract proof, not a final exact-main acceptance receipt.

Review warning `WR-01` remains cause-unknown and is **deferred with a recurrence trigger**, not fixed. The earlier standalone run recorded one Phase 139 sealed Release Please relation rejection (`relation_chain|phase-139-sealed-candidate|refresh_required`). The clean post-merge full hygiene replay passed; record only that the failure did not reproduce. Reopen and diagnose with stage-specific evidence if the exact selector/relation rejection recurs.

CI-06 and CI-07 remain pending independently of WR-01 until final post-summary exact-main local/remote equality, required canonical CI jobs, successful Release no-publish job graph, and exact hygiene acceptance are all proven on one immutable full SHA. The archived predecessor receipt digest is `cfab9f9ea553a9cce0ee7db54aa128acbf66710d4faf7d17a37780fbaf881f4d`; the current pending recovery-v2 receipt digest is `59df9121aa8680f29c856a78f51608b34e8d84d4497ad63e4b092a019728093c`. Neither certifies CI-06/07. No final acceptance SHA is asserted in this contract.

## Entry-point recovery versus completed-phase acceptance (2026-10-01)

Plan 140-14's tagged fixture exercises the real Phase 139 acceptance finalizer against a complete accepted historical chain and the exact seven-commit Phase 140 planning prefix. Its valid recovery-v2 receipt reaches the exact no-publish barrier; tampered archived lineage fails at the archived-receipt digest check before that barrier. Both fixture paths preserve refs, worktree state, receipt/archive bytes and publication state. This closes the prior resolver-only behavioral gap at the supported planning-entry stage.

The accepted Phase 139 receipt remains historical entry evidence for `c6332d3a8b716b938f93d978243281764e3eac41` only. The current completed Phase 140 execution history is outside `validate_phase_140_recovery_chain`'s seven-commit planning classifier. The recorded live probe at `5259a6545c04277ee44038779b23b139b6b1fcb2` therefore remains a failure before the no-publish barrier (`relation_boundary|phase-139-sealed-candidate|refresh_required`); the first out-of-classifier execution commit is `d9ed1899bed11f80891475fd11bce07da6ac4892`. Do not expand the classifier to bless execution commits or GSD merges, and do not describe the successful receipt CAS or fixture test as a passing live `plan:pre` gate.

The final-acceptance sequence remains steps 1–6 above. After this plan's SUMMARY and all lifecycle/verifier writes, refresh full `HEAD`, local `main`, fetched `origin/main`, advertised `origin/main`, worktree state, exact binary diff and all four protected-file hashes. If local-main movement or a push is required, stop at a separate `gate=blocking-human` checkpoint and present that refreshed exact candidate SHA, remote OID, diff, protected hashes, worktree state, normal non-force update and recovery route. The earlier local-main SHA `8fadb0984de9252475e8390bf4338c4df055f934` does not authorize movement of a later candidate. After exact-candidate authorization and synchronization, require current-SHA local `mix ci`, the canonical required CI jobs, the successful Release no-publish job graph, and `repo_hygiene_check.sh --accept-sha {final-sha} --format json` with one specific `--warn-disposition LABEL=DISPOSITION` for each observed WARN and zero BLOCK. CI-06/CI-07 remain pending until the unfiltered verifier records all required same-SHA evidence. Preserve WR-01 as deferred unless its exact selector/relation rejection recurs.

## Plan 140-15 implementation update (2026-10-02)

The exact-SHA identity helper now runs git fetch --no-tags "$REMOTE" "refs/heads/main:refs/remotes/$REMOTE/main", limiting refresh to the selected remote's main tracking ref. Its existing tagged contract fixture records and accepts that exact argv only; pruning, tag fetches, and other refspecs fail closed, and the explicit remote-refresh failure case remains covered. The local local_checks() fetch path is unchanged. Shell syntax and the focused phase139_exact_sha_hygiene contract passed (2 tests, 0 failures; 58 excluded), and both edited Elixir files pass mix format --check-formatted.

At the implementation-update boundary, CI-06/CI-07 still lacked same-SHA acceptance. The first exact-SHA receipt below later passed for candidate `47fbdf68a33c0542afa479c43aa95da2174b2bd6`; tracked completion-record writes now create another candidate, so the terminal receipt must join that resulting SHA. The failed live Phase 139 finalizer observation remains historical and is not rerun.

## Plan 140-15 first exact-SHA receipt (2026-10-02)

The first T3 evidence run (A) passed for full candidate `47fbdf68a33c0542afa479c43aa95da2174b2bd6` after the separate T2 authorization and normal non-force push. At capture, `HEAD`, local `main`, freshly fetched `origin/main`, and advertised `origin/main` were byte-equal at that SHA, the worktree was clean, and the binary diff from `origin/main` was empty.

- Post-sync local `mix ci`: **1,441 tests, 0 failures, 6 skipped (286 excluded), then 102 integration tests, 0 failures (33 excluded)**. Mode-0600 log: `/private/tmp/lockspire-140-plan/phase140-15-post-sync-mix-ci.47fbdf68a33c0542afa479c43aa95da2174b2bd6.log`.
- Exact hygiene receipt: **24 PASS, 0 WARN, 0 BLOCK**; its pinned local gate passed with 102 executed ExUnit tests. The mode-0600 WARN disposition file is empty because Docker 29.5.2 was reachable and no active/stopped adoption-demo containers or matching volumes existed.
- CI push run [37010692578](https://github.com/szTheory/lockspire/actions/runs/37010692578): success for Dialyzer, Release Hygiene Drift, Fast Checks, Minimum Supported Elixir/OTP, Integration Checks, Complete Coverage Evidence, and Adoption Demo Smoke.
- Release push run [37010692603](https://github.com/szTheory/lockspire/actions/runs/37010692603): success; Maintain Release Please PR succeeded and the four protected publication jobs were skipped. No protected publication was dispatched.
- Protected hashes matched the preserved entry values: ledger `b200d2491cffd55c5334e03a25f3410945a6df77e43c57172972e61f8c93c10f`; `138-UAT.md` `adebfc5edc5d5671b4776b6c6495643a43123768907635c8905bd7045abd517b`; `138-VERIFICATION.md` `a38ba1062de64e990bd05381cacd1a044abefad1e5d1a6320b72413a7a55cc10`; roadmap ratchet prompt `8cba24252908e0de1a9c64198b0644579970c5c9c1bfa0ab26d733d720ca3b05`.
- Private mode-0600 receipt: `/private/tmp/lockspire-140-plan/140-15-final-acceptance.47fbdf68a33c0542afa479c43aa95da2174b2bd6.json`; SHA-256 `76b42dc2154c728b6fa096532bcfd49b068276ef203e67964a23e0b28449af5c`.

The first exact-hygiene invocation omitted the pinned ASDF variables and returned a local-gate BLOCK before tests ran. The corrected invocation used `ASDF_ELIXIR_VERSION=1.19.5-otp-28`, `ASDF_ERLANG_VERSION=28.1`, `ERL_FLAGS='+S 1:1'`, and the private Hex cache; it completed successfully. This was an invocation correction, not a source or test failure.

This receipt is dated predecessor evidence. The completion-record commit that follows changes the candidate SHA, so CI-06/CI-07 are not terminal until the resulting candidate has its own current receipt after fresh T2 review and synchronization. Run the final automated evidence join once and make no tracked write after it. If it fails, restore the CI-06/CI-07 marks to pending. The live Phase 139 finalizer was not rerun.

## Plan 140-15 post-write candidate failure (2026-10-02)

The separately authorized post-write candidate was `f9a0c50a7ef117aa8023fae823d14c12e95f46c2`. At post-push verification, `HEAD`, local `main`, freshly fetched `origin/main`, and advertised `origin/main` matched; the worktree was clean and all four protected execution-entry hashes matched their preserved values.

- Pinned local `mix ci` failed: **1,441 tests, 8 failures, 6 skipped (286 excluded)** after 1,612.8 seconds. Seven failures were Phase 139/140 lifecycle relation fixtures; the baseline-snapshot relation fixture timed out after 180 seconds. The run stopped before integration tests. Mode-0600 log: `/private/tmp/lockspire-140-plan/phase140-15-post-sync-mix-ci.f9a0c50a7ef117aa8023fae823d14c12e95f46c2.log`.
- Canonical CI run [37024977354](https://github.com/szTheory/lockspire/actions/runs/37024977354) failed: Fast Checks reported 1,441 tests / 7 failures and Minimum Supported Elixir/OTP reported 1,727 tests / 7 failures. Integration Checks, Dialyzer, Release Hygiene Drift, and Adoption Demo Smoke succeeded; Complete Coverage Evidence was skipped.
- Release run [37024977672](https://github.com/szTheory/lockspire/actions/runs/37024977672) succeeded with `Maintain Release Please PR` successful and all four protected publication jobs skipped. Release Please Auto Merge run 37026427771 was skipped; `main` remained at the candidate.
- Docker 29.5.2 was reachable, and the exact project-label queries found no running or stopped adoption-demo containers and no project volumes. The mode-0600 WARN disposition file is empty.

The terminal `repo_hygiene_check.sh --accept-sha` command was not run because its required local gate and canonical CI were already failing for this SHA. No terminal receipt exists. CI-06 and CI-07 remain pending; the first passing receipt for `47fbdf68a33c0542afa479c43aa95da2174b2bd6` does not transfer. The tracked requirement marks have been restored to pending. Preserve the Phase 139 classifier and historical failed live observation; the live Phase 139 finalizer was not rerun.

## Plan 140-15 follow-up candidate failure (2026-10-02)

The separately authorized candidate `1ca94e8ca31d46ea3550f596208e96ce2cb8d607` was pushed with a normal non-force update. At post-push verification, `HEAD`, local `main`, freshly fetched `origin/main`, and advertised `origin/main` matched, and the worktree was clean.

- Pinned local `mix ci` failed after 1,150.5 seconds: **1,441 tests, 7 failures, 6 skipped (286 excluded)**. All seven were Phase 139/140 repository-hygiene contract fixtures whose synthetic Phase 139 completion relation returned `refresh_required`. Mode-0600 log: `/private/tmp/lockspire-140-plan/phase140-15-post-sync-mix-ci.1ca94e8ca31d46ea3550f596208e96ce2cb8d607.log`.
- Canonical CI run [37030798398](https://github.com/szTheory/lockspire/actions/runs/37030798398) failed in Fast Checks (1,441 tests / 7 failures) and Minimum Supported Elixir/OTP (1,727 tests / 7 failures). Integration Checks, Dialyzer, Release Hygiene Drift, and Adoption Demo Smoke succeeded; Complete Coverage Evidence was skipped.
- Release run [37030798360](https://github.com/szTheory/lockspire/actions/runs/37030798360) succeeded with `Maintain Release Please PR` successful and all four protected publication jobs skipped. Release Please Auto Merge run 37032202307 was skipped; `main` remained at the candidate.

Diagnosis: the Phase 139 fixture copied the current root `.planning/REQUIREMENTS.md`, then replaced it with a pinned historical completion snapshot. The candidate had four extra requirement-description and traceability lines, exceeding the strict validator's expected 14-line completion diff. The local test-support repair seeds that file from the historical verification parent instead. It does not change the Phase 139 classifier. Focused affected selectors passed on rerun; the full local gate and a new pushed candidate are still required.

The terminal `repo_hygiene_check.sh --accept-sha` join was not run because local `mix ci` and required canonical CI failed. No terminal receipt exists for `1ca94e8`. CI-06 and CI-07 remain pending, and the first receipt for `47fbdf68a33c0542afa479c43aa95da2174b2bd6` does not transfer. The live Phase 139 finalizer was not rerun.

## Fixture-repair candidate local gate (2026-10-02)

Candidate `259933e76d14ea303a134d41dda9833442682e79` passed pinned fast ExUnit (**1,441 tests, 0 failures, 6 skipped (286 excluded)**), then its integration suite had **1 failure among 102 tests (33 excluded)**. The Phase 133 package-provenance self-test exceeded its 60-second limit during the full run. The mode-0600 log is `/private/tmp/lockspire-140-plan/phase140-15-post-fix-mix-ci.259933e76d14ea303a134d41dda9833442682e79.log`.

The same integration test passed alone in 24.8 seconds (1 test, 0 failures) with `--only dependency_lock`; mode-0600 log: `/private/tmp/lockspire-140-plan/phase140-15-phase133-package-self-test.259933e76d14ea303a134d41dda9833442682e79.log`. A test-specific 180-second timeout is now set for the load-sensitive self-test. This adjusted candidate still needs a complete local `mix ci`, fresh synchronization and exact-candidate authorization, canonical CI and Release evidence, and the exact hygiene join. CI-06/CI-07 remain pending; no terminal receipt exists, and the live Phase 139 finalizer was not rerun.

## Follow-up local gate attempt (2026-10-02)

The next candidate, `0375505c61057386b125e8cc2415509cc4d87496`, retained the complete unit test pass as an open question: its full run reached the baseline snapshot topology/bookkeeping fixture, which exceeded its existing 180-second timeout. That fixture checks many isolated Git histories and relation failures. The saved mode-0600 log is `/private/tmp/lockspire-140-plan/phase140-15-post-timeout-mix-ci.0375505c61057386b125e8cc2415509cc4d87496.log`. The run was stopped after the failure and before the unit or integration groups completed; it is not a full-gate result.

The topology/bookkeeping fixture now has a 600-second test-specific timeout. On candidate `19092e8016821d6dcad775a2d0e8c3db462f9533`, it passed alone: **1 test, 0 failures**, in 107.7 seconds. Mode-0600 log: `/private/tmp/lockspire-140-plan/phase140-15-snapshot-fixture.19092e8016821d6dcad775a2d0e8c3db462f9533.log`. The complete gate on the timeout adjustment is still required. CI-06/CI-07 remain pending, with no terminal hygiene receipt and no rerun of the Phase 139 live finalizer.
