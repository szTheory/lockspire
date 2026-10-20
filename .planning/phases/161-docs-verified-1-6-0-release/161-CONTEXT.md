# Phase 161: Docs & Verified 1.6.0 Release - Context

**Gathered:** 2026-10-19 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Adopters can read accurate guides for the new setup path and install a publicly verified Lockspire 1.6.0 that carries v1.43 and v1.44. Covers DOC-02, REL-01, REL-02, SAFE-02. Release runs last: all v1.44 work on `main` with CI green. No protocol behavior, security default, schema or dependency change.
</domain>

<decisions>
## Implementation Decisions

### Docs (DOC-02)
- **D-01:** `docs/install-and-onboard.md` and `docs/upgrading/signing-key-encryption.md` already describe `mix lockspire.gen.kek`, `--raw` and `{:system, "VAR"}`. Re-read them against shipped code (`lib/mix/tasks/lockspire.gen.kek.ex`, config KEK handling) and fix drift only; no rewrite.
- **D-02:** Add a short "Key protection" subsection to `docs/operator-admin.md`. Use the PRODUCT.md "UI says" state labels exactly as shipped in `lib/lockspire/web/live/admin/keys_live/protection.ex` (Encrypted / Encrypted, some with an older key-encryption key / Some keys are stored unencrypted / Some keys cannot be read / Not set up / Setup needs attention / Unknown). It must say that the line is read-only, that Unknown is not a healthy result, and that the missing-KEK generate error points to `mix lockspire.gen.kek` and the upgrade guide. Write for the least technical operator persona (AGENTS.md admin-copy rules).
- **D-03:** Lock the new operator-guide content with a contract test alongside `test/lockspire/documentation_contract_test.exs` / `kek_guidance_contract_test.exs`. `vocabulary_contract_test.exs` must stay green.
- **D-04:** Do not change `docs/supported-surface.md`. Adding `gen.kek` there would widen the supported-surface claim.
- **D-05:** Run `mix docs.verify` (ExDoc `--warnings-as-errors`) on Elixir 1.19.5 / OTP 28, matching CI. Local 1.20.4 type warnings are not a docs failure signal.

### Landing v1.44 and Release Please PR #121 (REL-01)
- **D-06:** Local `main` holds v1.44 unpushed (about 100 commits ahead of `origin/main` at `038df080`). Follow the v1.43 precedent (PR #131): put the work on a `milestone/v1.44-<slug>` branch, open one PR, get CI green, and squash-merge it with one conventional title (e.g. `feat(keys): ... (v1.44)`). Then reset local `main` to `origin/main`. Never push the phase commits straight to main, because each one would become a changelog entry.
- **D-07:** The v1.44 PR title and body must not claim that "every DB-touching task" starts the repo, because `mix lockspire.keys.reencrypt` still uses raw `Ecto.Migrator.with_repo`.
- **D-08:** Fix the missing v1.40/v1.41 changelog coverage with a `BEGIN_COMMIT_OVERRIDE ... END_COMMIT_OVERRIDE` block in the body of the merged PR #122. Use conventional lines for the v1.40 admin operator UI refinement and the v1.41 language/docs work, then let Release Please regenerate #121. Do not hand-edit #121, because regeneration overwrites it. Before acting, check the vendored release-please (`.github/actions/release-please/runtime/node_modules/release-please/build/src/commit.js` ~line 376) to confirm that an override on an already-merged PR's body is picked up and how multiple lines render.
- **D-09:** Re-read the regenerated #121. Confirm that it proposes 1.6.0 and that the changelog covers v1.40–v1.44, then squash-merge it manually. Keep the `Release Please Auto Merge` workflow disabled until 1.6.0 is verified. Leave the Dependabot Actions PRs #125–#127 unmerged until after publish.

### Publish & Independent Verification (REL-02)
- **D-10:** Reuse the Phase 143 procedure exactly, with no workflow changes. Start from the #121 squash SHA, which must equal `origin/main` and have its own successful CI push run:
  1. Set `LOCKSPIRE_PHASE143_AUTHORIZED_SHA`.
  2. Dispatch `release.yml` with `recovery_ref`, `source_ci_run_id` and `recovery_reason`.
  3. The maintainer approves the `hex-publish` environment.
  4. Clear the variable afterwards.
- **D-11:** Verify independently from public sources:
  - The Hex API checksum matches both the manifest and the SHA-256 of the downloaded outer tarball.
  - HexDocs serve `/lockspire/1.6.0`.
  - The `lockspire-v1.6.0` tag (peeled) and the GitHub release target equal the source SHA.
  - An explicit tarball listing shows `lib/mix/tasks/lockspire.gen.kek.ex` and the other new Mix tasks. This step is new because no existing script lists tarball contents.
  - A clean-room host installs `{:lockspire, "== 1.6.0"}` in a fresh `HEX_HOME`.
- **D-12:** Record the result in `.planning/RELEASE-TRAIN.md` using the existing Current Baseline / Current Main Readiness format, and refresh the 1.5.1-era lines.

### Safety Sweep (SAFE-02)
- **D-13:** "Milestone diff" means the v1.44 diff (`038df080..<v1.44 squash commit>`), not the full 1.5.1→1.6.0 range. v1.43's intentional Bandit/`mix.lock` change is outside the check.
- **D-14:** The proof has two parts:
  1. Diff checks that `mix.exs`, `mix.lock`, `priv/repo/migrations`, `lib/lockspire/protocol` and security-default config keys are unchanged.
  2. Re-run and cite the existing redaction/no-leak tests, plus a grep of the v1.44 `lib/` diff for `Logger`, `:telemetry`, `IO.puts`, `Mix.shell` and raise sites near key or KEK values.

  The only allowed key output is `gen.kek` stdout.

### Maintainer-Only Actions
- **D-15:** These are the user's to approve or perform, and plans must checkpoint before each one:
  - Pushing the v1.44 branch and squash-merging its PR.
  - Editing the body of #122.
  - Squash-merging #121.
  - Setting and clearing the authorized-SHA variable.
  - Dispatching `release.yml`.
  - Approving `hex-publish`.
  - Deciding when to re-enable auto-merge.

### Release Gate Repair (decided after research, 2026-10-20)
- **D-16:** Merging #121 as-is would fail the required `Release Hygiene Drift` check: `scripts/maintainer/repo_hygiene_check.sh` (~676-694) requires the RELEASE-TRAIN "Latest public package" version to equal the Release Please metadata version. The test helpers `test/support/lockspire/release_proof/workflow_assertions.ex` and `package_assertions.ex` hardcode the 1.5.1 values. The user chose to repair this inside the v1.44 PR:
  - The hygiene check accepts metadata version >= public version, as long as the public version, artifact, tag and source SHA lines stay consistent with each other.
  - The test helpers derive their version and SHA values from the file instead of hardcoding them.

  The #121 squash SHA must then pass CI on its own, so D-10 holds unchanged. The fallback (publish a later fix-PR SHA, as with 1.5.1) is rejected.
- **D-17:** Correction to D-11: `lockspire.test.setup` is excluded from the package. The 1.6.0 tarball must gain exactly three tasks over 1.5.1: `lockspire.doctor.key_encryption`, `lockspire.gen.kek` and `lockspire.keys.reencrypt`. The in-app missing-KEK error names only `mix lockspire.gen.kek`. The operator guide links the upgrade guide itself and must not claim that the error does (refines D-02).
- **D-18:** Trigger the #121 regeneration by editing #122's body *before* squash-merging the v1.44 PR, so the push to main regenerates #121 once. Do not re-run the workflow, because its retry step would dispatch the disabled auto-merge workflow. Override entries are separated by blank lines and use `feat(admin): ... (#122)` for v1.40 and v1.41.
- **D-19:** Before resetting local `main`, stash the uncommitted `.planning/state.json` edit and create a backup branch. Commit all Phase 161 repo work (docs, contract test, gate repair, evidence) to local main *before* the push, so it ships in the v1.44 PR.

- **D-20:** Plan-check found that DOC-02 says all three guides describe the Key protection line. To meet it, `docs/install-and-onboard.md` and `docs/upgrading/signing-key-encryption.md` each get one short sentence pointing to the operator guide's "Key protection" subsection, and a contract assertion locks both. This is consistent with D-01's minimal-edit scope, so no rewrite.

- **D-21:** PR #121 is pushed with the default GitHub Actions token, so it never gets PR-level CI checks (`gh pr checks 121` reports none, as PR #93 did). The #121 merge is gated on three things instead:
  1. The plan-02 simulation of the post-#121 tree passes hygiene and the release contract tests.
  2. A re-read of the regenerated title and body (1.6.0, v1.40–v1.44) and its file list.
  3. After the merge, per D-10: the squash SHA S has its own successful CI push run before publish. If that run is red, nothing is published and a fix PR follows.

### Claude's Discretion
- Exact wording of the operator-guide subsection and the override lines, within the vocabulary map and conventional-commit format.
- Exact `milestone/v1.44-<slug>` branch name and the v1.44 squash title.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` (Phase 161)
- `.planning/REQUIREMENTS.md` (DOC-02, REL-01, REL-02, SAFE-02)
- `.planning/STATE.md` (v1.44 direction)
- `.planning/RELEASE-TRAIN.md`
- `.planning/MILESTONES.md`
- `.planning/phases/143-publish-and-verify-lockspire-1-5-1/143-CONTEXT.md`
- `.planning/milestones/v1.39-phases/143-publish-and-verify-lockspire-1-5-1/143-RESULT.md`
- `.planning/phases/159-key-encryption-key-setup-dx/159-CONTEXT.md`
- `.planning/phases/160-admin-key-protection-missing-kek-copy/160-CONTEXT.md`, `160-VERIFICATION.md`
- `docs/maintainer-release.md`
- `docs/install-and-onboard.md`
- `docs/upgrading/signing-key-encryption.md`
- `docs/operator-admin.md`
- `docs/supported-surface.md`
- `PRODUCT.md` (personas; vocabulary map rows ~140-142)
- `lib/lockspire/web/live/admin/keys_live/protection.ex`, `keys_live/index.ex`
- `lib/mix/tasks/lockspire.gen.kek.ex`
- `mix.exs` (version, `docs.verify` alias ~line 141, extras/groups ~200-246, `package_files` ~521-533)
- `release-please-config.json`, `.release-please-manifest.json`
- `.github/workflows/release.yml`, `release-please-automerge.yml`, `ci.yml`
- `scripts/publish/verify_install_truth.sh`, `release_artifact.py`, `release_main_freeze.sh`, `publish_hex_idempotently.sh`, `upload_hex_artifact.exs`
- `scripts/acceptance/run_clean_room_saas_journey.sh`, `scripts/acceptance/clean_room/build_provider.py`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Doc contract tests: `test/lockspire/documentation_contract_test.exs`, `upgrade_guide_contract_test.exs`, `kek_guidance_contract_test.exs`, `test/lockspire/web/live/admin/vocabulary_contract_test.exs`.
- SAFE-02 proofs: `test/lockspire/redaction/redaction_test.exs`, `test/mix/tasks/lockspire_gen_kek_test.exs`, `test/lockspire/web/live/admin/keys_live/protection_test.exs`, `test/lockspire/config_key_encryption_test.exs`, and the 158–160 `*-SECURITY.md` / `*-VERIFICATION.md` files.
- Clean-room journey already exercises `gen.kek` (`build_provider.py:447`).
- `verify_install_truth.sh` encodes the checksum, HexDocs and clean-room install checks.

### Established Patterns
- Push events only maintain the Release Please PR. Publishing goes only through the exact-ref `workflow_dispatch` in `release.yml`, gated by the authorized-SHA variable, the `hex-publish` environment and the main-freeze ruleset. The publisher's Hex version is pinned from the manifest.
- Release Please `elixir` type bumps `mix.exs` and CHANGELOG.md. Extra-files markers bump `.planning/RELEASE-TRAIN.md`. Squash titles become changelog entries.
- Always squash-merge.

### Integration Points
- New guide content must stay in the `mix.exs` docs extras/groups for `docs.verify`.
- `package_files` includes `lib/**/*.ex`, so the new Mix tasks ship in the tarball by construction. The explicit listing is still required as evidence.
</code_context>

<specifics>
## Specific Ideas

- v1.43 precedent: PR #131 `milestone/v1.43-signing-key-encryption`, squash-merged as `feat(keys): encrypt private signing keys at rest (v1.43) (#131)`.
- #121 currently lists #123, #129, #131, #124, #128, #120. v1.40/v1.41 came in through #122 (non-conventional title, merged 2026-10-11).
- Check at execution time that the Hex API `/api/packages/lockspire/releases/1.6.0` checksum field and the HexDocs exact-version URL behave as they did for 1.5.1.
</specifics>

<deferred>
## Deferred Ideas

### Reviewed Todos (not folded)
- `2026-10-13-audit-dcr-default-lifetime-semantics.md`: protocol work, owned by a later DCR lifetime milestone (DCR-01).
- `2026-10-19-keys-reencrypt-via-repo-runner.md`: Mix task behavior change. Deferred to a post-1.6.0 quick task so the release diff stays quiet (see D-07).
</deferred>


## Execution correction to D-21 (2026-10-20)

Live GitHub behavior disproved the premise that bot-token PRs cannot have PR-level workflows. Current GitHub creates approval-required pull_request CI and Dependency Review runs (action_required). The initial empty rollup did not waive protected-main checks. A manually dispatched head CI passed but did not clear the PR gate. Approving the existing PR runs through the normal workflow approval API produced the required checks, and the normal exact-head squash then succeeded with protections intact. See RELEASE-EVIDENCE.md for run IDs, primary documentation and read-backs.

For future release PRs, inspect approval-required PR runs first, approve reviewed-source CI/dependency runs as part of the authorized merge work, and require their actual success. Preserve the exact-head simulation and the mandatory post-squash main push CI before publish. The older instruction not to inspect or wait for PR checks is superseded by this observed correction. Never bypass protections or use --admin.
