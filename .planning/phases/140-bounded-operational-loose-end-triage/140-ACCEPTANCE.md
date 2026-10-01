# Phase 140 post-summary exact-main acceptance contract

This is a fail-closed verification contract, not an acceptance receipt. CI-06 and CI-07 remain pending until the phase verifier records canonical CI and intentional Release no-publish evidence for the same final synchronized `main` SHA after every Phase 140 plan and SUMMARY write.

## Candidate and current evidence

- Candidate observed at Plan 140-04 entry: `57d33ab35f3b16efe2ed184d81a3e7779fa5821a` on `agent-140-01-rerun`.
- Local and `origin/main` were both `5ad2b2e935556c8f1a91be32605958530b477527` at task entry. These observations are not a refreshed post-summary ref proof.
- The Phase 139 receipt at `.git/lockspire-phase-139-acceptance-v1.json` is entry-only evidence for `c6332d3a8b716b938f93d978243281764e3eac41` (CI run `36476762461`; Release no-publish run `36476762490`). It does not accept the Plan 140-04 candidate or any later SHA.
- The failed Plan 140-04 local `mix ci` result (`1439 tests, 44 failures, 6 skipped`) is retained as historical evidence in `140-04-SUMMARY.md`; its recovery, signing-key, fixture, formatter, and full-suite findings were repaired and reconciled in Plans 140-06 through 140-12. It is not the current local result.
- Latest complete local `mix ci` preparatory receipt: Plan 140-13 source candidate `0227dea2fd7cc8646d098505c3eb6637afb70d87`; command `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 ERL_FLAGS='+S 1:1' HEX_HOME=/private/tmp/lockspire-hex-cache mix ci`; result **1,441 tests, 0 failures, 6 skipped (286 excluded), then 102 integration tests, 0 failures (33 excluded)**. Log: `/private/tmp/lockspire-140-13-ci.oVxPXP` (mode `0600`). This is the latest local source proof; it supersedes the earlier successful `93e85d11…` run for recency but preserves that run as historical evidence. The full-SHA candidate is not the final exact-main acceptance SHA and cannot satisfy CI-06/CI-07.
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
