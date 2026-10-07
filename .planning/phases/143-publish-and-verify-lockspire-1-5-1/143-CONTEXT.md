# Phase 143: Publish and Verify Lockspire 1.5.1 - Context

**Gathered:** 2026-10-07 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Publish the prepared Lockspire 1.5.1 release from one explicitly authorized, exact current `main` commit through the existing protected workflow. Prove that the manifest-bound artifact tested before publication is the artifact available from Hex, that the matching `lockspire-v1.5.1` GitHub tag/release resolves to the same source commit, and that the public Hex package and clean-room install journey work. Update `.planning/RELEASE-TRAIN.md` with the factual result, or preserve a blocker and leave the milestone open if any gate fails. This phase does not change OAuth/OIDC behavior, public APIs, the host seam, operator UI, release ownership, or the publishing platform.

</domain>

<decisions>
## Implementation Decisions

### Candidate and publication authorization
- **D-01:** Treat Phase 142's accepted SHA `6f1a19b39999f96eb24352c75c2a0628375175ae` as a dated readiness observation, not standing publication authorization. Immediately before dispatch, refresh remote `main` and re-establish the full current SHA, its matching successful canonical CI run, repository-hygiene result, public package/tag state, and the live protected controls.
- **D-02:** First establish whether the already-prepared 1.5.1 release metadata on current `main` is publishable without another Release Please merge. If a release PR must merge, use the reviewed path, then repeat exact-SHA CI, hygiene, and authorization checks against the new merge SHA. Never silently substitute a newer or older commit during the dispatch.
- **D-03:** Keep Release Please auto-merge closed during this exceptional release. Authorize only one lowercase 40-character current-main SHA, dispatch the protected workflow with its matching CI run ID and a concise reason, and retain the existing `hex-publish` environment approval as the final human gate before Hex credentials are available. Clear the one-SHA authorization after the attempt. If `main` changes or the run becomes stale, stop and reauthorize with fresh evidence.
- **D-04:** Do not use a tag-triggered or unattended publish as the release authority. A tag can identify an old/non-current commit, and an automatic Release Please merge would change the candidate and its required evidence. Keep the ordinary sustaining auto-merge lane closed until the 1.5.1 result and repository controls are reconciled.

### Artifact identity and public proof
- **D-05:** Build one package tar from the detached, verified SHA. Bind source SHA, version, filename, byte length, and SHA-256 in the manifest; run prepublish proof against those tar bytes; transfer the tar and manifest as one immutable run artifact; and have the protected publisher re-verify and publish those same bytes. Do not rebuild in the credentialed job. Use the SHA-256 of the whole outer Hex tarball when comparing the registry checksum.
- **D-06:** A complete release requires all of these to agree: the manifest and source SHA, the public Hex release checksum and exact-version docs, the `lockspire-v1.5.1` GitHub release and actual tag target, and the clean-room journey installed from the public Hex package. For an existing GitHub tag, verify the remote tag ref and peel annotated tags to the commit; `targetCommitish` alone does not prove the target when a tag already exists. Stop on a mismatch; never retarget an existing tag to make the evidence appear to match.
- **D-07:** Keep the publisher compatible with the exact-tar model. The current workflow installs the latest Hex client in the publish job and calls `Hex.API.Release.publish/5`, while the manifest records the builder's Hex version. Planning should establish and record a compatible publisher-client version or supported direct-tar upload surface without changing the package tar bytes. A publisher/API compatibility failure blocks the release; it does not justify rebuilding under the old proof.

### Failure truth and recovery
- **D-08:** Preserve a bounded, redacted terminal receipt for every outcome, including failures after Hex accepts the package but before GitHub release creation or public install verification. The receipt should identify the source SHA, CI run, package version and manifest digest, and each stage as passed, failed, not run, or unknown; include observed Hex checksum/public presence, GitHub release and dereferenced tag state, install-proof state, and the blocker/next safe action. The current postpublish job runs only after the publish job succeeds, so a plan must cover partial-publication paths as well as the all-success path.
- **D-09:** Separate public presence from verified completion. If Hex has accepted 1.5.1 but a later gate fails, record that Hex now exposes 1.5.1 while stating that release proof is incomplete; do not say the verified release shipped, close the milestone, or leave 1.5.0 recorded as the latest public package when that is no longer true.
- **D-10:** Recovery may resume only with the same authorized source SHA and the same manifest-verified tar. Re-query Hex and accept an existing 1.5.1 only when its whole-tar checksum matches; otherwise stop. Do not automatically revert, overwrite, or rebuild a package under previous evidence. Keep the exact package artifact available through the practical recovery window; current tar retention is 30 days while final evidence is 90 days, so make the expiry boundary explicit and never claim same-artifact recovery after its bytes are unavailable.
- **D-11:** Keep the final maintainer-facing result consumer- and decision-focused: current public version, whether release proof is complete, source SHA, matching CI run, package checksum, GitHub release/tag target, install result, blockers, and next safe action. Link bounded receipts rather than copying raw logs; redact credentials and copy-once values.

### the agent's Discretion
- Reuse the existing exact-ref workflow, artifact manifest, idempotent Hex publisher, main-freeze helper, clean-room journey, and release contract tests. Keep new checks narrow to the Phase 143 success criteria.
- Use the existing environment-scoped Hex credential for this cut. Hex Trusted Publishers/OIDC and signed build attestations are possible later hardening, but are not prerequisites for this release and should not delay or widen it.
- No UI, API, or visual-design decision applies. The brand book is not a release-workflow reference.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope, requirements, and prior authorization
- `AGENTS.md` — Product boundaries and security defaults.
- `.planning/PROJECT.md` — v1.39 release goal and executable-verification default.
- `.planning/REQUIREMENTS.md` — REL-01, REL-02, and REL-03 acceptance criteria.
- `.planning/ROADMAP.md` — Phase 143 goal and success criteria.
- `.planning/STATE.md` — Current phase state and prior release decisions.
- `.planning/METHODOLOGY.md` — Research-first, recommendation-led defaults.
- `.planning/RELEASE-TRAIN.md` — Release ownership and current public truth.
- `.planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md` — Phase boundary, exact-SHA controls, and publication authorization handoff.
- `.planning/phases/142-merge-the-corrected-main-baseline/142-RESULT.md` — Accepted Phase 142 SHA and dated public-release observation.

### Existing release lane and proof contracts
- `docs/maintainer-release.md` — Maintained release runbook.
- `.github/workflows/ci.yml` — Canonical CI run whose evidence is bound to the candidate SHA.
- `.github/workflows/release.yml` — Exact-ref validation, artifact transfer, protected publish, and public install proof.
- `.github/workflows/release-please-automerge.yml` — Guarded Release Please merge lane that stays closed for this cut.
- `scripts/publish/release_artifact.py` — Manifest creation, digest verification, and bounded stage receipts.
- `scripts/publish/release_main_freeze.sh` — Main freeze and immediate prepublish SHA/authorization recheck.
- `scripts/publish/publish_hex_idempotently.sh` — Same-version checksum and retry behavior.
- `scripts/publish/upload_hex_artifact.exs` — Protected exact-tar upload path.
- `scripts/publish/verify_install_truth.sh` — Public checksum, documentation, and package-install verification.
- `scripts/acceptance/run_clean_room_saas_journey.sh` — Clean-room package journey entry point.
- `test/lockspire/release_artifact_chain_contract_test.exs` — Artifact chain contract.
- `test/lockspire/release_workflow_artifact_contract_test.exs` — Workflow artifact contracts.
- `test/lockspire/publish_verification_test.exs` — Publish and public-truth verification behavior.
- `test/lockspire/release_ci_evidence_contract_test.exs` — Exact-source CI evidence contract.
- `test/lockspire/release_main_freeze_test.exs` — Main-freeze behavior.

### Applicable prompt guidance
- `prompts/README.md` — How to select relevant project prompt guidance.
- `prompts/lockspire-release-engineering-and-ci.md` — Release automation, CI, credential, and maintainer ergonomics.
- `prompts/lockspire-release-readiness-and-conformance.md` — Lockspire release gates and non-certifying conformance boundary.
- `prompts/lockspire-elixir-oss-library-practices.md` — Use only its Hex packaging, docs, and release guidance; its API/UI sections are out of scope.

### External research references
- GitHub protected environments: `https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments`
- GitHub manual dispatch: `https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow`
- GitHub workflow artifacts and concurrency: `https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts` and `https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency`
- GitHub release target behavior: `https://docs.github.com/en/rest/releases/releases`
- Hex package publishing and tarball checksum: `https://hex.pm/docs/publish` and `https://hex-core.hexdocs.pm/hex_tarball.html`
- Release Please ownership boundary: `https://github.com/googleapis/release-please/blob/main/docs/design.md`
- Ecosystem examples: Phoenix CI `https://github.com/phoenixframework/phoenix/blob/main/.github/workflows/ci.yml`; Plug CI `https://github.com/elixir-plug/plug/blob/main/.github/workflows/ci.yml`; Ecto SQL CI `https://github.com/elixir-ecto/ecto_sql/blob/master/.github/workflows/ci.yml`; Oban's simple Hex release alias `https://github.com/oban-bg/oban/blob/main/mix.exs`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.github/workflows/release.yml` already validates the exact current-main SHA and matching canonical CI, builds one tar, creates a manifest, tests the tar, transfers it to the protected publisher, freezes main, verifies the public checksum/docs, and runs the public clean-room journey.
- `release_artifact.py`, `publish_hex_idempotently.sh`, `upload_hex_artifact.exs`, `release_main_freeze.sh`, and `verify_install_truth.sh` provide the current artifact and publication path.
- Release artifact, workflow, CI-evidence, main-freeze, and publish-verification contract tests already live under `test/lockspire/`.

### Established Patterns
- Lockspire separates Release Please bookkeeping from protected Hex publication. A tag, merged PR, green CI, or no-publish run is not itself public-package proof.
- Phase 142 bound readiness to a full source SHA and its own CI/hygiene evidence. Its accepted SHA and public-state observation are dated, so Phase 143 must refresh mutable facts.
- Phoenix, Plug, and Ecto workflows illustrate ordinary required Elixir CI and compatibility coverage; they do not establish exact-byte publish guarantees. Oban illustrates the simpler common `mix hex.publish --yes` release alias, which trades away Lockspire's same-tested-tar evidence.
- GitHub artifacts are the run-to-run handoff; avoid rebuilding a second package after prepublish proof. The current release workflow concurrency group allows no concurrent publish, but a new pending run can replace the previous pending one, so dispatch once and inspect the queued/current runs.

### Integration Points
- The exact-ref dispatch consumes the current `main` SHA, matching canonical CI and hygiene proof, one-SHA authorization, and `hex-publish` approval.
- Successful or failed publication must project into `.planning/RELEASE-TRAIN.md` and the Phase 143 result/verification records without conflating Hex public presence with full release proof.
- The current GitHub-release path validates an existing release through `targetCommitish`; the plan should add actual tag-ref resolution. The current postpublish evidence job is gated on publish-job success; the plan should preserve a terminal receipt for partial-publication failures too.

</code_context>

<specifics>
## Specific Ideas

- On the 2026-10-07 read-only observation, Hex still listed 1.5.0 as latest and returned no 1.5.1 release; GitHub had no `lockspire-v1.5.1` release or tag ref. These are dated facts, not execution-time authorization.
- Hex's checksum comparison must use the SHA-256 of the complete outer package tar. For an existing GitHub release, validate the actual tag ref and dereferenced commit, not only `targetCommitish`.
- The final receipt should distinguish `public on Hex` from `release verified`, and preserve per-stage outcomes plus a safe recovery action. No screenshots, raw credentials, token-like values, or copy-once secrets belong in evidence.
- No dedicated fan-out prompt file was found in `prompts/`; the user's supplied fan-out guidance was applied with the relevant release, readiness, and Elixir OSS prompt documents. UI/brandbook direction is not applicable to this phase.
</specifics>

<deferred>
## Deferred Ideas

- Hex Trusted Publishers/OIDC and signed build attestations may be evaluated as separate supply-chain hardening after the 1.5.1 cut; they are not necessary to satisfy the already-defined exact-SHA and manifest/checksum contract.
- Broad release-system redesign, new runtime/public API or OAuth/OIDC behavior, admin UI, visual design, and supplemental conformance gates are outside Phase 143.
</deferred>

---

*Phase: 143-publish-and-verify-lockspire-1-5-1*
*Context gathered: 2026-10-07*
