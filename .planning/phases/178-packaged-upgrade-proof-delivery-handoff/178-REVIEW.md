# Phase 178 Source Review

Reviewer: Codex (`gpt-6-luna`, high reasoning), source/code reviewer, agent `/root/phase178_execution_workflow/review178_source`
Reviewed commit: `9cc4c203263015effe0894e76550045b19edee8d`
Scope: `4bd35961944d3f70be0db2aadff9664b165264bb..9cc4c203263015effe0894e76550045b19edee8d`; changed source, harness, tests, fixtures, docs, workflow, and `mix.exs`/`mix.lock` paths under `lib/`, `scripts/`, `test/`, `docs/`, `.github/`, and `config/`. The review included the frozen-input/package provenance chain, verifier group dispatch and receipts, CI wrapper/workflow, owned source-test guard, host fixtures, and consumer guidance.
Date: 2026-10-27

Reviewed paths: `.github/workflows/ci.yml`; `docs/client-secret-jwt-host-guide.md`, `docs/client-secret-verifier-configuration.md`, `docs/getting-started.md`, `docs/install-and-onboard.md`, `docs/maintainer-release.md`, `docs/supported-surface.md`; `lib/lockspire/oban.ex`; `scripts/acceptance/clean_room/{build_provider.py,package_input.py,verifier_core.py,verifier_delivery.py,verifier_disclosure.py,verifier_endpoints.py,verifier_receipts.py,verifier_recovery.py,verifier_rollout.py,verifier_transactions.py}`; `scripts/acceptance/clean_room_verifier_upgrade.py`; `scripts/ci/{run_owned_source_tests.py,run_verifier_upgrade_proof.sh}`; `test/acceptance/{client_lifetime_boundary_test.py,client_verifier_ci_test.py,client_verifier_core_test.py,client_verifier_delivery_test.py,client_verifier_disclosure_test.py,client_verifier_endpoints_test.py,client_verifier_receipts_test.py,client_verifier_recovery_test.py,client_verifier_rollout_test.py,client_verifier_tracer_test.py,client_verifier_transactions_test.py,owned_source_tests_test.py}`; `test/clean_room/provider_host/lib/clean_room_provider/{lifetime_client_store.ex,verifier_disclosure.ex,verifier_recovery.ex,verifier_transactions.ex}`; `test/clean_room/provider_host/{mix.exs,verifier_endpoints.exs,verifier_rollout.exs}`; all 26 receipt fixtures under `test/fixtures/verifier-matrix-26/`; `test/lockspire/security/client_secret_verifier_maintenance_guidance_test.exs`.

## Findings

### BLOCKER SRC-01: The wrapper derives the candidate pin from the manifest it is meant to authenticate

**Evidence:** [`run_verifier_upgrade_proof.sh:63`](/Users/jon/projects/lockspire/scripts/ci/run_verifier_upgrade_proof.sh:63) reads `runner_revision` and `candidate_owner.source_revision` from the selected frozen manifest, then lines 81–82 only compare the manifest runner with the current checkout. The candidate revision read from that same manifest is passed back as `--expected-candidate-source-revision` at line 274. [`verifier_delivery.py:272`](/Users/jon/projects/lockspire/scripts/acceptance/clean_room/verifier_delivery.py:272) verifies only the candidate-owner digest recomputed from fields in that same manifest.

**Issue/impact:** These are self-consistency checks, not an independent frozen-owner pin. A changed manifest can select another valid in-repository source revision and its matching archive/tree, recalculate `owner_sha256`, and have both the wrapper and later composition accept that candidate as expected. This defeats the required separation between runner and independently selected candidate identity, and can attribute package proof to the wrong candidate while all internal hashes agree.

**Fix:** Require separately supplied expected runner revision, candidate source revision, archive SHA-256, tree SHA-256, and frozen-manifest digest from the caller/evidence owner. Verify those values before starting children and carry the same independent pins into composition. Do not derive an expected value from the object being checked.

**Disposition:** Open; blocks frozen-input and package acceptance.

### BLOCKER SRC-02: The frozen input allowlist omits code and fixtures that determine the installed proof outcomes

**Evidence:** [`verifier_delivery.py:35`](/Users/jon/projects/lockspire/scripts/acceptance/clean_room/verifier_delivery.py:35) bounds `COVERED_INPUTS` to 25 paths. It includes only delivery/receipt/package-input logic and two acceptance tests, but omits the changed group producers `verifier_core.py`, `verifier_rollout.py`, `verifier_endpoints.py`, `verifier_transactions.py`, `verifier_recovery.py`, `verifier_disclosure.py`, as well as `build_provider.py`, `redaction.py`, `clean_room_saas_journey.py`, the main runner's related test modules, and the newly added host fixture files.

**Issue/impact:** `validate_frozen_manifest` compares only this allowlist against current bytes and the selected runner commit ([`verifier_delivery.py:256`](/Users/jon/projects/lockspire/scripts/acceptance/clean_room/verifier_delivery.py:256)). The fixed wrapper does not verify a clean checkout. An omitted producer or host fixture can therefore change after freeze and execute from the working tree while receipts still claim the frozen runner revision. This makes the freeze incomplete and permits stale or mutated test logic to produce evidence under an unchanged source identity.

**Fix:** Freeze every selected producer, imported helper, host fixture/template, lock, workflow, receipt contract, and test input that can affect outcomes. Validate all of them against the frozen commit before execution, or require and verify a clean checkout whose full tree equals the frozen runner tree.

**Disposition:** Open; blocks proof freshness and source attribution.

### BLOCKER SRC-03: Hosted verifier jobs cannot obtain the frozen inputs required by the wrapper

**Evidence:** The production wrapper refuses to start without `.planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-FROZEN-INPUTS.json` and validates the archive and extracted tree referenced by it ([`run_verifier_upgrade_proof.sh:27`](/Users/jon/projects/lockspire/scripts/ci/run_verifier_upgrade_proof.sh:27), [`run_verifier_upgrade_proof.sh:58`](/Users/jon/projects/lockspire/scripts/ci/run_verifier_upgrade_proof.sh:58)). The new floor and locked CI steps invoke this wrapper at [`ci.yml:284`](/Users/jon/projects/lockspire/.github/workflows/ci.yml:284) and [`ci.yml:398`](/Users/jon/projects/lockspire/.github/workflows/ci.yml:398), with no preceding step that downloads or creates the frozen manifest, archive, or extracted tree. The candidate archive is required under `.artifacts/phase178`, which is a run-local artifact path.

**Issue/impact:** A clean GitHub Actions checkout has no mechanism in this workflow to materialize the required frozen package artifacts, so both newly required CI proof steps exit in preflight before executing cases. The wrapper also requires its locally frozen runner revision to equal the workflow checkout `HEAD`, which needs an explicit design for the GitHub PR synthetic-merge checkout identity rather than a local-only frozen pin.

**Fix:** Add an explicit, verified CI input handoff/build step that provides the frozen owner and archive/tree to each job, and define independent pins for the actual workflow checkout (including synthetic merge identity) while preserving candidate source identity separately. Add a fail-closed workflow contract test for the exact hosted setup.

**Disposition:** Open; the configured CI proof gates are not runnable as written.

### BLOCKER SRC-04: Review validation can accept a report without validating its review content or scope

**Evidence:** [`verifier_delivery.py:439`](/Users/jon/projects/lockspire/scripts/acceptance/clean_room/verifier_delivery.py:439) accepts a review file by substring checks for headings, the expected lane word, and a date. It does not parse or compare the reviewed commit, require source-file scope, validate classified findings/dispositions, or bind evidence to the candidate under review.

**Issue/impact:** Arbitrary report text can satisfy the `reviews` gate without a review of the frozen candidate or an explicit disposition of its findings. This turns the independent-review requirement into a document-presence/keyword check and can create a false green for VDELIV-01.

**Fix:** Validate a structured review record with exact reviewed commit and file scope, reviewer/lane identity, date, line-level evidence, severity for every finding, and explicit disposition for each blocker/warning. The gate must reject missing or mismatched findings instead of accepting generic strings.

**Disposition:** Open; blocks review acceptance.

### BLOCKER SRC-05: Source acceptance accepts unbound, self-reported stage counts

**Evidence:** [`verifier_delivery.py:509`](/Users/jon/projects/lockspire/scripts/acceptance/clean_room/verifier_delivery.py:509) checks a JSON record's tested revision and covered-input list, then accepts any nonempty `canonical_ci.stages` list whose entries report exit 0, a positive test count, zero failures, and a syntactically valid stdout digest ([lines 521–530](/Users/jon/projects/lockspire/scripts/acceptance/clean_room/verifier_delivery.py:521)). It does not require the three canonical `mix ci` stages, identify the owned-runner manifest, or verify raw command-capture bytes against the supplied hashes.

**Issue/impact:** A fabricated record with one arbitrary positive stage and a made-up SHA-256 can pass the source gate without proving that the guarded `mix ci` ran or that its required architecture/fast/integration stages executed. The record is self-reported and does not link to the owned runner's private manifest or retained raw observations, contrary to the requirement for actual command outcomes.

**Fix:** Require the exact expected stage set and counts, bind the record to the guarded source-run manifest and its tested checkout/command, and verify hashes of retained raw capture artifacts. Preserve only safe summaries in output, but make the evidence bytes available to the validator.

**Disposition:** Open; blocks source-gate acceptance.

## Verification Evidence

- `python3 -m unittest discover -s test/acceptance -p 'client_verifier_*_test.py'` — environment-default run executed 101 tests and had one OTP runtime-probe failure (exit 126); no source database or package producer was started.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' python3 -m unittest discover -s test/acceptance -p 'client_verifier_*_test.py'` — passed, 101 tests, 0 failures.
- `python3 -m unittest test.acceptance.client_verifier_delivery_test test.acceptance.client_verifier_receipts_test test.acceptance.client_verifier_ci_test` — invocation failed before test discovery because this repository's `test/` directory is not importable as `test.acceptance`; the corrected discovery command above passed.
- No source database tests, installed package producers, canonical source gate, hosted CI jobs, or final pair wrappers were launched. Those remain pending acceptance work, not review evidence.

## Disposition

**BLOCKED:** Five implementation blockers remain in frozen-input authenticity/completeness, hosted CI input setup, independent review validation, and source-gate evidence binding. Runtime acceptance is still pending; no missing runtime execution is being counted as a source defect.
