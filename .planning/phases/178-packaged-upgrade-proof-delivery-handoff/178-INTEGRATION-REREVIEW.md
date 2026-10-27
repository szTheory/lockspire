# Phase 178 Integration Re-review

Reviewer: Codex (`gpt-6-luna`, low reasoning), independent integration lane
Reviewed commit: `5adf46c1b6b304fcc99fdb9f0ab25194a62d8c32`
Date: 2026-10-27
Scope: Re-review of prior integration finding and Plan 10 package/source/candidate/handoff wiring. Reviewed `.github/workflows/ci.yml`, `scripts/ci/provision_verifier_candidate.py`, `scripts/ci/run_verifier_upgrade_proof.sh`, `scripts/acceptance/clean_room/verifier_delivery.py`, `scripts/acceptance/clean_room/package_input.py`, `scripts/acceptance/clean_room/verifier_receipts.py`, `scripts/acceptance/clean_room_verifier_upgrade.py`, `scripts/ci/run_owned_source_tests.py`, Plan 10 and its findings ledger, prior source/security/integration reports, and changed call sites. No DB, package producer, freeze, full CI or remote action.

## Findings

### BLOCKER INT-01 — Candidate provisioner is not covered by the frozen source manifest

The original clean-checkout provisioning gap is corrected in workflow structure: the floor and locked jobs provision before invoking the wrapper and pass five explicit pins (runner, candidate source, archive digest, extracted-tree digest, manifest digest). However, the provisioner itself is absent from `verifier_delivery.COVERED_INPUTS` (`verifier_delivery.py:57-178`), while `provision_verifier_candidate.py` uses that exact list to assert runner/package source byte equivalence (`provision_verifier_candidate.py:78-79`). It also exports the candidate archive, creates the frozen manifest, and writes the workflow output pins. Thus its critical selection/provisioning behavior can change without changing the bounded manifest or source/package relation.

Impact: The manifest does not freeze all code controlling the candidate inputs consumed by the package proof. The same-run five pins bind outputs but do not freeze the program that chose and produced them.

Remediation: Include the provisioner and its contract tests in bounded covered inputs and validate their relation to both runner and candidate source. Add an adversarial check proving omission of this evidence-producing script is rejected.

Disposition: OPEN — BLOCKER.

### BLOCKER INT-02 — Hosted package artifact IDs and digests are claims, not authenticated artifact bytes

`_check_candidate` validates seven job records and requires exactly two pair artifact records with positive IDs, names, digest-shaped strings and expected receipt/case counts (`verifier_delivery.py:1037-1085`). It does not retrieve those artifact IDs from the declared workflow run/attempt/job, read the uploaded archive bytes, recompute their hashes, or parse the uploaded raw index. CI uploads validated pair contents (`ci.yml:313-319`, `451-457`), but no candidate-check caller establishes that the supplied `178-CANDIDATE-GATES.json` rows refer to those uploaded bytes.

Impact: A syntactically valid gate record can assert successful raw artifact digests/counts without proof that artifacts exist or contain those bytes. The local candidate validator cannot establish the promised candidate artifact provenance.

Remediation: Have candidate validation consume downloaded artifacts from the authenticated run and attempt, bind each artifact ID to that run/job graph, recompute archive/index digests, parse the raw index, and derive the receipt/case counts from its contents. Reject metadata-only claims.

Disposition: OPEN — BLOCKER.

### BLOCKER INT-03 — Review validation does not require complete scoped file coverage

`validate_reviews` verifies each submitted file row but only requires a nonempty `reviewed_files` list; it does not compare it with the required selected diff/frozen dependency scope, and finding paths need not be members of the reviewed-file set (`verifier_delivery.py:640-711`). A valid report digest therefore authenticates the submitted packet bytes without showing that the lane assessed all required files.

Impact: Review stage can accept a packet that omits changed implementation files or points findings at unreviewed files, weakening the required independent review → freeze gate.

Remediation: Define the per-lane scope from the selected diff plus required bounded dependencies; enforce complete scope or explicit validated exclusions, reject duplicates/out-of-scope entries, and require every finding path to be reviewed.

Disposition: OPEN — BLOCKER.

### WARNING INT-04 — Frozen validation does not fail on missing `git show` blobs

Manifest creation and validation hash `git show` output without checking its return code (`verifier_delivery.py:365-369,411-415`). If the commit lacks a path and its current file is empty, empty stdout can hash equal to the file and be treated as commit-owned. The provisioner checks its own path relation, but the validator remains callable independently and does not implement its stated commit-ownership boundary on this case.

Impact: Frozen source ownership can be falsely established for an empty file when the requested commit blob is absent.

Remediation: Require successful `git show` and exact output before hashing in both manifest creation and validation.

Disposition: OPEN — WARNING.

### WARNING INT-05 — Floor candidate export is ordered after root dependency installation

The floor job sets up the compatibility runtime and runs root `mix deps.get --check-locked` before provisioning the candidate export (`ci.yml:230-260`). The candidate exporter then runs `mix hex.build` from the exported root source with the root `mix.lock`; it does not establish a root lock copied/selected from the floor compatibility fixture. The reviewer report likewise records that floor ordering did not establish the root lock copy. The proof pair itself can still use the correct fixture lock, but candidate source packaging is not explicitly tied to that floor lock context.

Impact: The floor execution's runtime pair is pinned, but the candidate archive build's dependency-lock provenance is ambiguous; do not infer a floor-specific archive build from the job's compatibility runtime alone.

Remediation: Explicitly establish and record which lock governs package construction; if the intended candidate archive is the canonical root source artifact, assert that policy and bind root lock bytes. If floor package construction is intended, select and bind the compatibility lock before export/build.

Disposition: OPEN — WARNING; no source lock copy was observed.

## Rechecked integration paths

| Boundary | Current trace | Status |
|---|---|---|
| Existing seven-job graph → floor/locked proof | Floor and locked jobs each run provisioner before pair wrapper; workflow retains the canonical graph and uploads validated directories on success. | WIRED structurally; hosted execution pending. |
| Clean job checkout → frozen candidate | Provisioner checks expected checkout/source revisions, builds source archive/tree, writes a manifest and emits five explicit pins; wrapper checks those pins and manifest before creating pair receipt directories. | PARTIAL: INT-01 leaves provisioner behavior outside the frozen set. |
| Candidate archive → package proof | `LOCKSPIRE_FROZEN_INPUTS` selects the frozen source; package input validation checks archive digest, extracted tree, owner source revision and source/build relation; wrapper passes runner/candidate pins into raw receipt validation. | WIRED in code; no package proof executed here. |
| Pair roots → exact composed matrix | `verifier_delivery._check_package` composes the locked/floor indexes with frozen candidate owner and expected runner; pair receipt validator enforces typed scope and the pair checks. | WIRED in code; fresh 14/33 + 12/31 wrappers and 26/64 composition remain pending. |
| Guarded source run → source acceptance | `run_owned_source_tests.py --ci` produces the owned manifest; source acceptance checks frozen identity, canonical guarded command/stages, manifest digest/custody, cleanup, and package evidence (`verifier_delivery.py:780-920`). | WIRED in code; no `--ci` run performed. |
| Candidate checkout/run/jobs → candidate identity | Candidate identity compares source acceptance, head/run/checkouts, PR synthetic-parent relation, canonical job names/statuses, and source/package covered-byte relation. | PARTIAL: artifact-byte authenticity remains INT-02. |
| Candidate → handoff/main helper | Handoff requires actual helper receipt bytes and ancestry for accepted main; pending state is separately representable. | WIRED as a validator path; actual run/main/helper facts are future owners. |

## Independent integration lane decision

**Verdict: REJECTED.** INT-01, INT-02 and INT-03 are concrete blockers in frozen input coverage, hosted artifact provenance, and review-scope completeness. INT-04 and INT-05 are warnings requiring resolution or explicit bounded disposition before acceptance. The earlier missing-provisioner step finding is resolved structurally by the new job steps; it is superseded by INT-01, which identifies the new provisioner coverage gap. No actual remote run, main acceptance, package success, or candidate artifact upload is asserted.

Requirements map: VPROOF-02 is PARTIAL (provisioning/proof path exists but frozen authority and fresh runtime proof are incomplete); VDELIV-01 is PARTIAL (review and candidate paths exist but review scope, artifact provenance and final local gates are incomplete); VDELIV-02 remains PENDING (actual helper-backed main acceptance/handoff belongs to a later owner). None is certified WIRED end-to-end at this revision.

## Checks and limitations

- Ran only the offline delivery acceptance suite under the selected runtime environment: 15 tests, 0 failures, 0 errors; process exit 0. Combined output was retained in memory and summarized only as byte count/digest (`114` bytes; SHA-256 `997bad84b9e8d7a6379d930fa7cbb7a8dfbf6030f918769ae09896cd9c93a815`).
- An initial module-style unittest invocation had import errors (3 tests attempted); it is recorded as a failed invocation, not hidden. Its output was retained in memory only (`1,739` bytes; SHA-256 `0b8b9b155b2ee0fcc5c40c4192267ccb93a1b262695d9267f0fc130c807fab0d`).
- No source database, package producer, freeze, canonical full CI, remote workflow, artifact download, merge, or publication was run. Runtime acceptance remains blocked/pending and cannot be inferred from unit tests.
- Historical Plan 08 wrapper exit-1 attempts, prior source DB incidents, source/security review findings, Phase 177 unresolved flags and original prohibition flags remain retained; this report does not waive or restamp them.

### Reviewed implementation blob hashes

These are the exact working-tree bytes reviewed at `5adf46c1b6b304fcc99fdb9f0ab25194a62d8c32`:

| File | SHA-256 |
|---|---|
| `.github/workflows/ci.yml` | `6d43935abee648eb2e9438765aaae02df4e04305ce9b4f069116a6da90bd1ece` |
| `scripts/ci/provision_verifier_candidate.py` | `a3bf5f6eb304fb5863bbee14513a00c1326c2411f074eac7659aae60d2084f1b` |
| `scripts/ci/run_verifier_upgrade_proof.sh` | `c07a28b74d30c7e142a91795fbb8605f316950879acd9eb7bc71be8b7bedcc37` |
| `scripts/acceptance/clean_room/verifier_delivery.py` | `c4267426ac90ccd77ef93aa3797982b0ae16ad222b637e72a7c3fe905a6bf3f9` |
| `scripts/acceptance/clean_room/package_input.py` | `41c2d6e24de57a306d775855f3e51509fb045c08cf4c1bdb5c5260b84ca3987a` |
| `scripts/acceptance/clean_room/verifier_receipts.py` | `bcc60d1eea54f5eb0c6e91144d8f64390c3fbb78e600719d5708d7a7554a3cc5` |
| `scripts/acceptance/clean_room_verifier_upgrade.py` | `a77d8cbabafb04901aaf22f8cc1feb88a84ec1ed88629b0921d45e327d0ea1b0` |
| `scripts/ci/run_owned_source_tests.py` | `4490432083a3254de0e3ececbc09c75a85e01eead11eb236ddb5ebfe4a8acd5b` |
