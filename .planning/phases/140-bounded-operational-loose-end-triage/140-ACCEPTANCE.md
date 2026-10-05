# Phase 140 post-summary exact-main acceptance contract

This is a fail-closed verification contract, not an acceptance receipt. CI-06 and CI-07 remain pending until the phase verifier records canonical CI and intentional Release no-publish evidence for the same final synchronized `main` SHA after every Phase 140 plan and SUMMARY write.

## Candidate and current evidence

- Candidate observed at Plan 140-04 entry: `57d33ab35f3b16efe2ed184d81a3e7779fa5821a` on `agent-140-01-rerun`.
- Local and `origin/main` were both `5ad2b2e935556c8f1a91be32605958530b477527` at task entry. These observations are not a refreshed post-summary ref proof.
- The Phase 139 receipt at `.git/lockspire-phase-139-acceptance-v1.json` is entry-only evidence for `c6332d3a8b716b938f93d978243281764e3eac41` (CI run `36476762461`; Release no-publish run `36476762490`). It does not accept the Plan 140-04 candidate or any later SHA.
- The failed Plan 140-04 local `mix ci` result (`1439 tests, 44 failures, 6 skipped`) is retained as historical evidence in `140-04-SUMMARY.md`; its recovery, signing-key, fixture, formatter, and full-suite findings were repaired and reconciled in Plans 140-06 through 140-12. It is not the current local result.
- Earlier preparatory local `mix ci` receipt: Plan 140-13 source candidate `0227dea2fd7cc8646d098505c3eb6637afb70d87`; command `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 ERL_FLAGS='+S 1:1' HEX_HOME=/private/tmp/lockspire-hex-cache mix ci`; result **1,441 tests, 0 failures, 6 skipped (286 excluded), then 102 integration tests, 0 failures (33 excluded)**. Log: `/private/tmp/lockspire-140-13-ci.oVxPXP` (mode `0600`). It remains historical source evidence; later Plan 140-15 exact-SHA receipts are recorded below.
- Keep the historical Lockspire 1.5.0 source, CI, protected Release, tag, checksum, and Hex proof distinct from current acceptance. Supplemental OIDF/FAPI evidence remains redacted and non-certifying.

## Post-GSD verifier sequence for Plan 140-18

Run this sequence only after the standard GSD executor commits 140-18-SUMMARY.md and all lifecycle records. Re-read 140-VERIFICATION.md and REQUIREMENTS.md; CI-06 and CI-07 must still be pending and verification must still report gaps_found at 30/32. The verifier's adversarial CLI contract is part of mix test.fast and runs in the required Minimum Supported Elixir/OTP CI job. This automated proof replaces the one-off reviewer signature and manual verifier UAT; do not add either back unless new evidence shows a property the tests and CI cannot establish.

1. Capture a fresh full-SHA candidate packet: HEAD, local main, freshly fetched origin/main, server-advertised origin/main, clean porcelain, exact binary diff (git diff --binary origin/main...HEAD), and SHA-256 values for the four protected files below. If local-main movement or a push is required, stop for separate authorization naming that exact SHA, remote OID, diff, normal non-force update and recovery route. This approval is only for the external ref action; it is not a verification or UAT request. Earlier approval never transfers. Preserve unrelated dirty or untracked paths.

2. After any separately authorized synchronization, run the existing exact hygiene command once for that full SHA with the pinned Plan 140-15 environment. It runs complete local mix ci and emits the private receipt JSON. Capture it under the owner-only mode-0700 directory, use umask 077 and noclobber, and supply one bounded disposition for each observed WARN:

    set -euo pipefail
    umask 077
    set -o noclobber
    install -d -m 700 /private/tmp/lockspire-140-plan
    LOCKSPIRE_140_RECEIPT="/private/tmp/lockspire-140-plan/140-18-final-acceptance.$LOCKSPIRE_140_FULL_SHA.json"
    ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 \
      ERL_FLAGS='+S 1:1' HEX_HOME=/private/tmp/lockspire-hex-cache \
      bash scripts/maintainer/repo_hygiene_check.sh \
        --accept-sha "$LOCKSPIRE_140_FULL_SHA" \
        --warn-disposition {observed-label}={specific-disposition} \
        --format json > "$LOCKSPIRE_140_RECEIPT"
    chmod 600 "$LOCKSPIRE_140_RECEIPT"
    export LOCKSPIRE_140_RECEIPT

Set LOCKSPIRE_140_FULL_SHA to the authorized full candidate before this block. Repeat --warn-disposition once for each distinct WARN; omit it when there are none. Require local CI to pass, zero hygiene BLOCK and one bounded disposition per WARN. On failure, keep the output as a private diagnostic and do not use it as a passing receipt.

3. Wait for the canonical .github/workflows/ci.yml push run and .github/workflows/release.yml push run to complete on that same full SHA. CI must pass Dialyzer, Release Hygiene Drift, Fast Checks, Minimum Supported Elixir/OTP, Integration Checks, Complete Coverage Evidence and Adoption Demo Smoke. Release must pass Maintain Release Please PR; all four protected publication jobs must be completed and skipped. The required Minimum Supported Elixir/OTP job runs mix test.fast, including the closure CLI contract test. Do not dispatch protected publication work.

4. Run the verifier with the same candidate, committed records, receipt and a new private result path:

    python3 scripts/maintainer/verify_phase140_read_only_closure.py \
      --sha {full-sha} \
      --record-head {same-full-sha} \
      --receipt "$LOCKSPIRE_140_RECEIPT" \
      --output /private/tmp/lockspire-140-plan/140-18-read-only-closure.{full-sha}.json

It checks that the committed executable, adversarial CLI contract and CI test wiring are present at the candidate, re-queries canonical workflow evidence, then confirms the worktree, HEAD, local main, fetched and advertised remote main, protected hashes and no-publish graph. If any check fails, keep CI-06 and CI-07 pending, retain the diagnostic, and restart from a new candidate after a tracked repair. An existing output is never overwritten. The private result is terminal evidence; a later tracked edit creates a new candidate and requires the sequence again. Do not write a tracked completion claim after success.

The previous dated receipt supports only its recorded SHA. Supplemental OIDF/FAPI results remain separate and cannot substitute for required CI or Release evidence. No current final-SHA receipt is asserted here.

## Current protected-file baseline (reconciled 2026-10-05)

The Phase 140 entry hashes remain historical. The current verifier pins the exact later committed versions of the two files refreshed by completed Phase 139/138 work; it still rejects any subsequent change. This preserves the reviewed content instead of restoring older snapshots.

| File | Current SHA-256 | Recorded source |
|---|---|---|
| `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` | `e28f727046273109629dceaf5b99ab9af6927a7d2084ff960b6fa337983f289d` | Phase 139 refresh commit `171d46351f804951e8a13c82173113662bb14c1c` |
| `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-UAT.md` | `adebfc5edc5d5671b4776b6c6495643a43123768907635c8905bd7045abd517b` | Preserved entry version |
| `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION.md` | `b2c4ada9a7c34fe266dfa527a7c43c00be9afb8d7ce70ff0f8f0a7232d1bf904` | Phase 138 verification refresh commit `17a908a794449885c39e5a059f370a5823eeefd3` |
| `docs/lockspire-milestone-roadmap-ratchet-prompt.txt` | `8cba24252908e0de1a9c64198b0644579970c5c9c1bfa0ab26d733d720ca3b05` | Preserved entry version |

The CLI contract fixture now starts from these committed versions and includes an adversarial case that changes a protected file and expects rejection. Earlier receipts and summaries retain their original entry hashes as evidence for their own dates and candidates.

## Current disposition

**CI-06: predecessor passed; terminal candidate pending.** Candidate `4ce0ab3dfd9acbf587bb5aea6d8ba679c951fb3d` passed its full exact-SHA join, recorded below. The completion-record update creates a new candidate; refresh T1 and obtain separate exact-candidate authorization before its normal non-force push, then require a new terminal receipt.

**CI-07: predecessor passed; terminal candidate pending.** Release run `37056328607` passed the no-publish graph on candidate `4ce0ab3dfd9acbf587bb5aea6d8ba679c951fb3d`. The completion-record candidate still requires its own same-SHA Release graph and exact-hygiene receipt. No Release dispatch or publication action is authorized by this contract.

## Post-merge local verification update (2026-10-01)

The latest complete local `mix ci` preparatory evidence is the Plan 140-13 source candidate `0227dea2fd7cc8646d098505c3eb6637afb70d87`, with 1,441 tests, 0 failures, 6 skipped (286 excluded), then 102 integration tests, 0 failures (33 excluded). The full private log is `/private/tmp/lockspire-140-13-ci.oVxPXP`. This supersedes the earlier `93e85d11…` candidate as the latest local-code receipt; it does not replace or invalidate the older run's historical evidence.

After merge, the primary checkout remained at `8061247594fb563d79e3b7d62f1d21b6789ede9f` across the clean post-merge local gates. `post-merge-gate-result.json` records identical before/after HEAD, build exit 0, and full repository-hygiene test exit 0. The hygiene log reports **60 tests, 0 failures** at seed `924694` (`/private/tmp/lockspire-140-plan/post-merge-hygiene-seed-924694.log`). This is local contract proof, not a final exact-main acceptance receipt.

Review warning `WR-01` remains cause-unknown and is **deferred with a recurrence trigger**, not fixed. The earlier standalone run recorded one Phase 139 sealed Release Please relation rejection (`relation_chain|phase-139-sealed-candidate|refresh_required`). The clean post-merge full hygiene replay passed; record only that the failure did not reproduce. Reopen and diagnose with stage-specific evidence if the exact selector/relation rejection recurs.

CI-06 and CI-07 remain pending independently of WR-01 until final post-summary exact-main local/remote equality, required canonical CI jobs, successful Release no-publish job graph, and exact hygiene acceptance are all proven on one immutable full SHA. The archived predecessor receipt digest is `cfab9f9ea553a9cce0ee7db54aa128acbf66710d4faf7d17a37780fbaf881f4d`; the current pending recovery-v2 receipt digest is `59df9121aa8680f29c856a78f51608b34e8d84d4497ad63e4b092a019728093c`. Neither certifies CI-06/07. No final acceptance SHA is asserted in this contract.

## Entry-point recovery versus completed-phase acceptance (2026-10-01)

Plan 140-14's tagged fixture exercises the real Phase 139 acceptance finalizer against a complete accepted historical chain and the exact seven-commit Phase 140 planning prefix. Its valid recovery-v2 receipt reaches the exact no-publish barrier; tampered archived lineage fails at the archived-receipt digest check before that barrier. Both fixture paths preserve refs, worktree state, receipt/archive bytes and publication state. This closes the prior resolver-only behavioral gap at the supported planning-entry stage.

The accepted Phase 139 receipt remains historical entry evidence for `c6332d3a8b716b938f93d978243281764e3eac41` only. The current completed Phase 140 execution history is outside `validate_phase_140_recovery_chain`'s seven-commit planning classifier. The recorded live probe at `5259a6545c04277ee44038779b23b139b6b1fcb2` therefore remains a failure before the no-publish barrier (`relation_boundary|phase-139-sealed-candidate|refresh_required`); the first out-of-classifier execution commit is `d9ed1899bed11f80891475fd11bce07da6ac4892`. Do not expand the classifier to bless execution commits or GSD merges, and do not describe the successful receipt CAS or fixture test as a passing live `plan:pre` gate.

The final-acceptance sequence is the post-GSD procedure above. After this plan's SUMMARY and all lifecycle/verifier writes, refresh full `HEAD`, local `main`, fetched `origin/main`, advertised `origin/main`, worktree state, exact binary diff and all four protected-file hashes. If local-main movement or a push is required, present that refreshed exact candidate SHA, remote OID, diff, protected hashes, worktree state, normal non-force update and recovery route for authorization. The earlier local-main SHA `8fadb0984de9252475e8390bf4338c4df055f934` does not authorize movement of a later candidate. After exact-action authorization and synchronization, require current-SHA local `mix ci`, canonical required CI jobs, the successful Release no-publish job graph and `repo_hygiene_check.sh --accept-sha {final-sha} --format json` with one specific `--warn-disposition LABEL=DISPOSITION` for each observed WARN and zero BLOCK. The required CI test suite proves the verifier contract; no manual verifier signoff is required. CI-06/CI-07 remain pending until the read-only verifier records all required same-SHA evidence. Preserve WR-01 as deferred unless its exact selector/relation rejection recurs.

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

## Full local gate after timeout adjustments (2026-10-02)

Pinned `mix ci` passed on candidate `0027dcfed0b2c7d761ce73cccbc366c54332538a`: **1,441 unit tests, 0 failures, 6 skipped (286 excluded)**, followed by **102 integration tests, 0 failures (33 excluded)**. The unit group took 2,031.6 seconds and integration took 66.6 seconds. Mode-0600 log: `/private/tmp/lockspire-140-plan/phase140-15-full-ci.0027dcfed0b2c7d761ce73cccbc366c54332538a.log`. The audit step printed a `.git/FETCH_HEAD` permission error and then reported no vulnerabilities; the overall command exited successfully.

Candidate `0027dcfe` is local-only and its evidence does not satisfy exact-SHA acceptance. The tracked update to record this result creates a new candidate; rerun full local `mix ci` on that resulting SHA before any sync or ref-action checkpoint. No canonical CI, Release, or terminal hygiene receipt exists for `0027dcfe`. CI-06/CI-07 remain pending, and the Phase 139 live finalizer was not rerun.

## Plan 140-15 first post-write receipt A (2026-10-02)

Candidate `4ce0ab3dfd9acbf587bb5aea6d8ba679c951fb3d` passed exact acceptance after its separately approved normal non-force push. `HEAD`, local `main`, fetched `origin/main`, and advertised `origin/main` matched; the worktree was clean and the remote diff was empty. The pinned local gate passed with 102 executed ExUnit tests. Exact hygiene reported 24 PASS, 0 WARN, 0 BLOCK; Docker was reachable and no matching containers, volumes, or generated artifacts existed.

- CI push run [37056328643](https://github.com/szTheory/lockspire/actions/runs/37056328643) passed all seven required jobs.
- Release push run [37056328607](https://github.com/szTheory/lockspire/actions/runs/37056328607) passed; Maintain Release Please PR succeeded and all four protected publication jobs were skipped.
- Protected-file hashes remained the preserved values: ledger `b200d2491cffd55c5334e03a25f3410945a6df77e43c57172972e61f8c93c10f`; `138-UAT.md` `adebfc5edc5d5671b4776b6c6495643a43123768907635c8905bd7045abd517b`; `138-VERIFICATION.md` `a38ba1062de64e990bd05381cacd1a044abefad1e5d1a6320b72413a7a55cc10`; roadmap ratchet prompt `8cba24252908e0de1a9c64198b0644579970c5c9c1bfa0ab26d733d720ca3b05`.
- Private mode-0600 exact receipt: `/private/tmp/lockspire-140-plan/140-15-final-acceptance.4ce0ab3dfd9acbf587bb5aea6d8ba679c951fb3d.json`, SHA-256 `6dc2c03865ec66cd745edc84b23169807ff3e714f5b47e30ac5fd559ff17e8db`.

Receipt A supports these dated completion marks only for its recorded SHA. The tracked completion-record update creates a new candidate, so CI-06 and CI-07 remain pending for that terminal candidate until its own exact receipt passes. If the terminal check fails, restore both requirement marks to pending. No protected Release publication was dispatched, and the live Phase 139 finalizer was not rerun.

## Plan 140-16 T1 record seal (2026-10-03)

Receipt A remains historical evidence for `4ce0ab3dfd9acbf587bb5aea6d8ba679c951fb3d`; CI-06 and CI-07 remain pending until a private terminal receipt matches the last tracked candidate and proves the complete exact-SHA join. The T1 packet is captured only after the summary, this conditional contract, verification status, and requirement marks are committed. Any required local-main update or push is gated by T2's candidate-specific `blocking-human` checkpoint. Preserve the failed `5259a6545c04277ee44038779b23b139b6b1fcb2` observation and the skipped Phase 139 `plan:pre` hook as recorded; no finalizer rerun or reclassification is authorized.

## Plan 140-18 first post-GSD gate attempt (2026-10-05)

The approved candidate `4717e1d6d8626bc2e7e3957824216bfd5c64e677` was fast-forwarded to local and remote `main`. The fresh fetch and advertised remote matched that SHA, and the worktree was clean before acceptance. The exact hygiene command exited 1 because its required local `mix ci` stopped at `mix format --check-formatted`: `test/support/lockspire/release_proof/package_assertions.ex` needed one blank line before the `parent =` assignment. No ExUnit tests ran in this attempt. The private mode-0600 command output is `/private/tmp/lockspire-140-plan/140-18-local-mix-ci-debug.4717e1d6d8626bc2e7e3957824216bfd5c64e677.log`; the exact hygiene report is retained separately as `/private/tmp/lockspire-140-plan/140-18-final-acceptance.failure.4717e1d6d8626bc2e7e3957824216bfd5c64e677.log`, not as a receipt.

The focused closure contract on the correction passed (**3 tests, 0 failures**), and `mix format --check-formatted` plus `git diff --check` pass. For the old SHA, Release run [37332396094](https://github.com/szTheory/lockspire/actions/runs/37332396094) succeeded with `Maintain Release Please PR` successful and all four publication jobs skipped. CI run [37332396119](https://github.com/szTheory/lockspire/actions/runs/37332396119) had Fast Checks fail on the formatter issue while Minimum Supported Elixir/OTP was still in progress; it does not establish CI-06.

The formatting correction and this record create a new candidate; the full local gate, exact hygiene receipt, canonical CI and Release no-publish evidence must all be collected again for that candidate after any required ref update is separately approved. The earlier SHA has no terminal receipt. CI-06 and CI-07 remain pending.

## Plan 140-18 second post-GSD gate attempt (2026-10-05)

The approved candidate `113257bae65c6f862c1a443b7a34a2157cdc7e68` was synchronized to local and remote `main`. Its exact hygiene command exited 1 because `mix ci` stopped during Credo after the 13 repository contract tests passed. Credo found two refactoring warnings in the newly added `fake_gh_script/0`: `Enum.map/2 |> Enum.join/2` can use `Enum.map_join/3`. The private mode-0600 `mix ci` log is `/private/tmp/lockspire-140-plan/140-18-local-mix-ci-debug.113257bae65c6f862c1a443b7a34a2157cdc7e68.log`; the hygiene report is retained at `/private/tmp/lockspire-140-plan/140-18-final-acceptance.failure.113257bae65c6f862c1a443b7a34a2157cdc7e68.log`, not as a receipt.

At the recorded check, CI run [37333984551](https://github.com/szTheory/lockspire/actions/runs/37333984551) had Fast Checks fail while Integration Checks and Minimum Supported Elixir/OTP were still running. Release run [37333984673](https://github.com/szTheory/lockspire/actions/runs/37333984673) was still running `Maintain Release Please PR`; all four publication jobs were skipped. This candidate has no terminal local receipt, and these workflow observations do not transfer to a later SHA. CI-06 and CI-07 remain pending.

The two flagged expressions have been changed to `Enum.map_join/3` locally. Run the focused closure test and formatting check, then prepare a new exact candidate. Any required update of local or remote `main` needs authorization for that candidate's SHA; rerun the full local gate, exact hygiene, required CI and Release no-publish checks for that same SHA.

## Plan 140-18 third post-GSD gate attempt (2026-10-05)

The approved candidate `b7717ea78bc12252a241634c241b33b730654085` passed `mix qa` and the focused closure test before its push. CI then failed on six test assertions: Fast Checks reported 1,446 tests / 6 failures; Minimum Supported Elixir/OTP reported 1,732 tests / 6 failures. Both identified stale Phase 139/140 status expectations, three phase-label false positives in the new closure fixture, and two fixture cases that tried to create `/private/tmp/lockspire-140-plan`, which is unavailable on the GitHub runner. Fast Checks also showed the exact file and assertion locations in its log. CI run [37341255501](https://github.com/szTheory/lockspire/actions/runs/37341255501) failed; Dialyzer, Release Hygiene Drift, Integration Checks and Adoption Demo Smoke passed, with Complete Coverage Evidence skipped. Release run [37341255616](https://github.com/szTheory/lockspire/actions/runs/37341255616) passed its maintenance job and skipped all four publication jobs.

The exact-SHA local hygiene command had started its full suite when CI reported the failures. It was interrupted to avoid spending more time on a candidate already proven to fail; it produced no terminal receipt. The empty private interruption record is `/private/tmp/lockspire-140-plan/140-18-final-acceptance.interrupted.b7717ea78bc12252a241634c241b33b730654085.log`; the mode-0600 partial local output is `/private/tmp/lockspire-140-plan/140-18-mix-ci-live.b7717ea78bc12252a241634c241b33b730654085.log`.

Corrections are prepared locally: fixture files now use a per-fixture private directory under `System.tmp_dir!()`; the verifier accepts a configurable private directory while retaining mode-0700 directory and mode-0600 receipt/result checks; the proof baseline identifies the closure contract as fixture data; and the two planning tests no longer require obsolete Phase 139/140 lifecycle prose. The verifier also rejects a symlink or publicly accessible private directory.

The updated `mix qa` passed. The focused closure, release automation, Phase 139 planning, proof baseline and repository hygiene selectors passed: **9 tests, 0 failures (65 excluded)**. Python byte-compilation and `git diff --check` passed. CI-06 and CI-07 remain pending; this is not the full local gate or a terminal receipt. Run the full acceptance sequence only after the correction commit has its own candidate SHA and any needed main-ref action has fresh authorization.
