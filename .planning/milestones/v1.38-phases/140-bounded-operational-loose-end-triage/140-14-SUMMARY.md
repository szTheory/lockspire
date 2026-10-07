---
phase: 140-bounded-operational-loose-end-triage
plan: "14"
subsystem: testing
tags: [phase-finalizer, recovery-v2, exunit, no-publish, exact-sha]
requires:
  - phase: 140-bounded-operational-loose-end-triage
    provides: accepted Phase 139 entry fixture, recovery-v2 receipt helpers, final acceptance contract
provides:
  - Real-finalizer positive and hostile recovery-v2 entry-point regression
  - Bounded live identity and protected-overlay packet with explicit stage mismatch
  - Post-summary exact-candidate approval and CI/Release handoff
affects: [phase-140-verification, phase-140-acceptance, CI-06, CI-07]
actuals:
  tokens: 2843 # measured summary characters / 4
  tasks: 3
  commits: 3
tech-stack:
  added: []
  patterns: [fixture-local lifecycle finalization, exact-ref acceptance handoff]
key-files:
  created:
    - .planning/phases/140-bounded-operational-loose-end-triage/140-14-SUMMARY.md
  modified:
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
    - .planning/phases/140-bounded-operational-loose-end-triage/140-ACCEPTANCE.md
key-decisions:
  - "Keep the production planning-prefix classifier unchanged; distinguish its historical entry boundary from final exact-main acceptance."
  - "Keep CI-06 and CI-07 pending until final synchronized-main local, hygiene, CI, and Release evidence joins on one SHA."
requirements-completed: [BASE-03, LOOSE-03]
requirements-pending: [CI-06, CI-07]
coverage:
  - id: D1
    description: "A valid recovery-v2 receipt reaches the real finalizer's exact no-publish barrier, while tampered archived lineage fails earlier with fixture state unchanged."
    requirement: LOOSE-03
    verification:
      - kind: unit
        ref: "test/lockspire/release/repository_hygiene_contract_test.exs#phase140_entrypoint_recovery; full mix ci at a68ab1bb"
        status: pass
    human_judgment: false
  - id: D2
    description: "The post-summary candidate and canonical same-SHA acceptance route are explicit, while live ref movement remains a separate authorization gate."
    requirement: CI-06
    verification:
      - kind: other
        ref: "140-ACCEPTANCE.md steps 1–6 and 140-14-SUMMARY.md read-only candidate packet"
        status: pass
    human_judgment: true
    rationale: "Any required local-main update or push needs explicit authorization for the refreshed exact candidate, and final CI/Release evidence does not yet exist."
duration: 55min
completed: 2026-10-01
status: complete
plan_head_before: 9397619458903b28ce292dfca314dd41262c60da
---

# Phase 140 Plan 14: Recovery Entry-Point Proof Summary

**The real Phase 139 finalizer now proves valid and hostile recovery-v2 behavior at the accepted planning-prefix entry boundary, with completed-phase acceptance kept separate.**

## Performance

- **Duration:** approximately 55 minutes, including the fresh full CI run
- **Started:** 2026-10-01T20:28:00Z (approximate, based on private plan-prompt creation)
- **Completed:** 2026-10-01T21:21:52Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Extended the existing tagged planning-prefix fixture to create a complete accepted Phase 139 receipt through its real driver, retain the seven recognized Phase 140 planning commits, create recovery-v2 through the supported supersede operation, and invoke the copied production finalizer without a publish argument.
- Verified that the valid fixture reaches the exact no-publish barrier and the hostile archived predecessor fails at the specific archived digest check first. Both paths preserve fixture HEAD, all fixture and temporary-origin refs, worktree state, pending receipt and archive bytes, and publication-call state.
- Recorded a bounded read-only identity packet and clarified that the accepted Phase 139 receipt supports only its historical SHA; the live completed-phase post-transition probe remains a failure before the barrier, and final CI-06/CI-07 acceptance remains a separate exact-SHA gate.
- Ran one fresh full `mix ci` at candidate HEAD `a68ab1bb74aa0b8dbed30f46fd632d42731a54c5`: 1,441 tests, 0 failures, 6 skipped (286 excluded), then 102 integration tests, 0 failures (33 excluded). The full log is `/private/tmp/lockspire-140-plan/phase140-14-mix-ci.g5QHGn` (mode `0600`).

## Task Commits

1. **T1: Prove valid and hostile recovery-v2 through the real no-publish entry point** — `438c7c1f` (`test(140-14): prove phase 139 recovery entrypoint`)
2. **T3: Bind the stage distinction to the post-summary exact-SHA handoff** — `a68ab1bb` (`docs(140-14): clarify recovery acceptance handoff`)
3. **T2/T3: Record the live stage mismatch, candidate packet, and completed verification** — this summary's atomic commit

**Plan metadata:** recorded by the parent orchestrator; this executor does not own STATE.md or ROADMAP.md.

## Focused fixture result

The focused selector passed with seed `355859`: **1 test, 0 failures**. Its private mode-0600 log is `/private/tmp/lockspire-140-plan/phase140-entrypoint-recovery.bSVnM5`. The output records:

- `phase140-entrypoint-positive=candidate preparation is blocked until its exact SHA is explicitly published`
- `phase140-entrypoint-planning-consistency=1.19.5-otp-28|28.1|test|test test/lockspire/quality/phase_139_planning_consistency_test.exs`
- `phase140-entrypoint-hostile=superseded receipt archive digest`

The test-only fake Mix leaf satisfies the fixture planning-consistency command and records that it ran; it does not change production behavior or invent additional receipt topology. The accepted fixture chain and exact seven-commit planning prefix stay intact. The live repository, production finalizer, classifier, receipt/archive, refs and protected overlays were not modified by the test.

## Read-only live packet

Captured at `2026-10-01T21:19:27Z`, before this summary was written:

| Observation | Value |
| --- | --- |
| Candidate HEAD | `a68ab1bb74aa0b8dbed30f46fd632d42731a54c5` |
| Local `main` | `8fadb0984de9252475e8390bf4338c4df055f934` |
| Tracking `origin/main` | `218b50502e33f046ab24a61c807a4271b9a1436e` |
| Advertised `origin/main` (`git ls-remote`) | `218b50502e33f046ab24a61c807a4271b9a1436e` |
| Candidate-to-tracking-origin binary diff | 17 files; 1,235 insertions; 313 deletions; 195,428 bytes |
| Saved binary diff SHA-256 | `4b2e340392bba4eab99c3c802fcefc8e7706dcb9eecd618e3da119da2b49c0ae` |
| Porcelain worktree paths | 0 (clean) |
| Accepted Phase 139 baseline ancestry | `c6332d3a8b716b938f93d978243281764e3eac41` is an ancestor of candidate HEAD |

The accepted Phase 139 receipt is mode `0600`, SHA-256 `63963961a5e3698a739aca7c416cd45cc9b4a804af50304c7bb2d6d696346786`, and supports its recorded historical baseline only. Its required CI run is `36476762461`; its Release no-publish run is `36476762490`. These dated identities do not certify Phase 140 acceptance.

The current pending recovery-v2 lifecycle receipt is `.git/gsd-lifecycle/post-completion-finalizer.json`, mode `0600`, SHA-256 `59df9121aa8680f29c856a78f51608b34e8d84d4497ad63e4b092a019728093c`. Its archived predecessor is `.git/gsd-lifecycle/receipt-archive/cfab9f9ea553a9cce0ee7db54aa128acbf66710d4faf7d17a37780fbaf881f4d.json`, mode `0600`, SHA-256 `cfab9f9ea553a9cce0ee7db54aa128acbf66710d4faf7d17a37780fbaf881f4d`. The archive bytes match the recorded predecessor digest; neither receipt is final CI-06/CI-07 evidence.

All four protected execution-entry files still match their recorded hashes:

- `baseline-inventory-2026-08-28.md`: `b200d2491cffd55c5334e03a25f3410945a6df77e43c57172972e61f8c93c10f`
- `138-UAT.md`: `adebfc5edc5d5671b4776b6c6495643a43123768907635c8905bd7045abd517b`
- `138-VERIFICATION.md`: `a38ba1062de64e990bd05381cacd1a044abefad1e5d1a6320b72413a7a55cc10`
- `docs/lockspire-milestone-roadmap-ratchet-prompt.txt`: `8cba24252908e0de1a9c64198b0644579970c5c9c1bfa0ab26d733d720ca3b05`

The prior live probe at `5259a6545c04277ee44038779b23b139b6b1fcb2` exited 1 before the no-publish barrier with `relation_boundary|phase-139-sealed-candidate|refresh_required`. The first completed-phase execution commit outside the accepted seven-commit planning classifier is `d9ed1899bed11f80891475fd11bce07da6ac4892`. The fixture proof does not relabel this live failure or broaden the production classifier.

## Acceptance disposition

- **CI-06: pending.** The candidate is not synchronized across HEAD, local `main`, and freshly fetched `origin/main`, and there is no final-SHA exact hygiene receipt. `repo_hygiene_check.sh --accept-sha` remains the owner of that independent join.
- **CI-07: pending.** No canonical CI/Release query for the final synchronized candidate exists. The historical run IDs above are entry-only evidence.
- The required fresh local `mix ci` passed at candidate HEAD `a68ab1bb…`. During its `mix_audit` step, the sandbox denied access to `.git/FETCH_HEAD`; the command continued and reported no vulnerabilities. After CI, the supported advisory-only `HEX_API_KEY= mix deps.audit` was rerun with the prescribed Elixir/OTP environment and escalation; it refreshed the advisory cache and exited 0 with “No vulnerabilities found.” `mix.lock` and source status remained unchanged. This later audit does not rewrite the original CI log's freshness limitation.
- No local-main movement, fetch into the project's refs, push, publish command, live finalizer rerun or receipt mutation was performed.
- Before any local-main update or push, refresh all candidate/ref/worktree/protected-file evidence after this SUMMARY and all lifecycle/verifier writes, then present the full exact candidate SHA, remote OID, diff, hashes, worktree state, normal non-force update and recovery route at a separate `gate=blocking-human` checkpoint. The earlier `8fadb098…` local-main observation is not authorization for a later candidate.
- After exact-candidate authorization and synchronization, require current-SHA local `mix ci`, canonical required CI jobs, successful Release no-publish graph, and exact hygiene with one disposition for each observed WARN and zero BLOCK. Keep CI-06/CI-07 pending until the unfiltered verifier joins all evidence on that same SHA. Preserve WR-01 as deferred unless its exact selector/relation rejection recurs.

## Deviations from Plan

None. The advisory cache refresh was an isolated follow-up to the access denial observed during the required `mix ci`; it changed no project source, dependency lock, Git ref or receipt.

## Issues Encountered

- The first escalated advisory command did not start Mix because asdf had no version selected in that environment. Retrying the same supported `mix deps.audit` command with the repository's required Elixir `1.19.5-otp-28` and Erlang `28.1` succeeded.
- The full CI audit step could not read `.git/FETCH_HEAD` in the sandbox. Its later supported advisory refresh passed, but the freshness caveat is retained for the original run.

## Next Phase Readiness

The behavioral entry-point gap is closed at the recognized historical planning stage. Final Phase 140 acceptance still requires the separate post-summary exact-candidate authorization path and same-SHA hygiene, CI and Release evidence. The parent orchestrator owns lifecycle state, the unfiltered verifier and refreshed final checkpoint packet.

---
*Phase: 140-bounded-operational-loose-end-triage*
*Completed: 2026-10-01*
