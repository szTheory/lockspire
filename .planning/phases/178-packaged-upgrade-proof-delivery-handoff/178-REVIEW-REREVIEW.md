# Phase 178 Source Review Re-review

Reviewer: gsd-code-reviewer / source lane (gpt-6-luna, high)
Reviewed commit: 5adf46c1b6b304fcc99fdb9f0ab25194a62d8c32
Scope: source and harness changes from 9cc4c203263015effe0894e76550045b19edee8d through 5adf46c1b6b304fcc99fdb9f0ab25194a62d8c32, including corrections aab5c517, 011bd239, and 5adf46c1; relevant shared package-input/process, receipt, wrapper, provisioning, source-guard, CI, and review-validation call chains. Prior source and security reports and the Plan 10 correction ledger were rechecked. Planning reports and generated evidence were not treated as shipped source.
Date: 2026-10-27

## Findings

### BLOCKER SRC-02 — Frozen coverage omits the CI candidate provisioner

**File:** `scripts/acceptance/clean_room/verifier_delivery.py:57-178`

The new `scripts/ci/provision_verifier_candidate.py` is executed in both floor and locked CI jobs to choose the checkout/source pins, export the package, build the archive, create the manifest, and emit the five values later trusted by the proof wrapper. It is absent from `COVERED_INPUTS`; the provisioner itself derives its relation from that list at `provision_verifier_candidate.py:78-79`. Consequently the frozen-input manifest can pass while the most privileged candidate-selection/evidence-producing script changes independently of the frozen source set. The new provisioner tests are also outside that bounded set.

**Fix:** Add the provisioner and its CI contract tests to `COVERED_INPUTS`; require the independent runner/package-source byte relation to bind them, and add a regression that fails when an evidence-producing CI input is omitted.

### BLOCKER SRC-03 — Candidate gate validation accepts unverified artifact claims

**File:** `scripts/acceptance/clean_room/verifier_delivery.py:1037-1085`

`_check_candidate` accepts a locally supplied `178-CANDIDATE-GATES.json` after checking asserted run/job fields, positive artifact IDs, syntactically valid SHA-256 strings, and asserted receipt/case counts. It never downloads or reads the referenced hosted artifacts, verifies the artifact IDs against the selected workflow run/attempt/job, or recomputes `sha256` / `raw_index_sha256` from artifact bytes. Thus a fabricated gate record can claim a successful canonical graph and two valid package artifacts without any corresponding hosted run or uploaded receipt index, and the semantic candidate check still accepts those assertions. The workflow upload step at `.github/workflows/ci.yml:312-319` creates artifacts but no consumer in this check establishes that the submitted rows refer to them.

**Fix:** Make candidate validation consume the exact downloaded artifact bytes from a trusted workflow run and attempt; bind artifact IDs to that run/job graph, hash the archive/index bytes, parse the raw index, and derive receipt/case counts from its contents. Fail closed when only metadata claims are available.

### BLOCKER SRC-04 — Independent review scope is not required to cover the code under review

**File:** `scripts/acceptance/clean_room/verifier_delivery.py:674-688`

`validate_reviews` requires a non-empty `reviewed_files` array and validates the bytes for each listed entry, but does not compare that set with the expected source-review scope (the frozen covered inputs or selected implementation diff). It also does not require each finding's `files` to be included in that array. A lane can therefore claim `accepted` after binding only a convenient subset while omitting an implementation-critical file, and a finding can point to an unreviewed file. The report digest binds the submitted report bytes but does not repair this incomplete-scope contract.

**Fix:** Define the required per-lane scope from the selected source diff plus required frozen dependencies, require exact coverage (or an explicit, validated non-source exclusion rule), reject duplicate/out-of-scope paths, and require every finding path to be within the lane's reviewed file set.

### WARNING SRC-06 — Frozen manifest checks ignore `git show` failures

**File:** `scripts/acceptance/clean_room/verifier_delivery.py:365-369,411-415`

Both manifest creation and validation hash `git show` stdout without checking the subprocess return code. A missing blob produces empty stdout; if the corresponding current file is an empty regular file, its digest matches and the code treats that absent commit blob as committed frozen input. The CI provisioner currently adds an earlier checked relation, which narrows exposure in that path, but the manifest functions themselves do not uphold their advertised commit-ownership check when called independently.

**Fix:** Check `returncode == 0` before hashing stdout in both paths and reject absent/ambiguous blobs explicitly.

## Rechecked Findings

| Prior finding | Re-review disposition | Evidence and limit |
|---|---|---|
| SRC-01 independent caller pins | **Resolved** | Wrapper requires five explicit pins, checks current `HEAD`, and validates the frozen manifest against caller values (`run_verifier_upgrade_proof.sh:68-104`, `verifier_delivery.py:386-428`). The same-job provisioner currently supplies those pins; this does not establish actual uploaded hosted artifact provenance (SRC-03). |
| SRC-02 bounded frozen coverage | **Open** | Exact bounded path list and Phase 175 hashes are checked; new candidate provisioner is omitted, as above. |
| SRC-03 hosted candidate and artifact provenance | **Open** | CI now provisions before both proof jobs and uploads validated receipt files. Candidate gate semantics still accept unverified hosted artifact metadata without consuming artifact bytes, as above. Hosted runtime observations remain pending and are not claimed passed here. |
| SRC-04 independent review packet | **Open** | Lane identity, report digest, revision ancestry, file-byte bindings, verdict, and finding disposition are validated. Required source scope is not complete or exact, as above. |
| SRC-05 guarded source acceptance | **Resolved at code level** | Guard manifests now carry output digests/counts, cleanup witness, target identity and stage results; source acceptance requires these records and package checks. I did not run any source DB test or canonical CI. |
| SEC-178-07 diagnostic containment | **Rechecked; no new source defect found** | Guard and process helpers retain child output in memory and emit fixed failure reasons/digests; targeted guard and process/delivery unit suites passed. |
| SEC-178-08 mutation witness | **Resolved at code level** | Transaction evidence now separately exercises rejection/non-mutation and an actual apply mutation with post-state/audit checks (`verifier_transactions.py`); no DB test was run in this re-review. |

## Verification

- Focused delivery and client-verifier acceptance suite: 117 tests, 0 failures.
- Owned source test guard suite: 15 tests, 0 failures.
- Runtime: Elixir 1.19.5 / OTP 28.5 environment selected; `PYTHONDONTWRITEBYTECODE=1` set for Python.
- No source database, package producer/freeze, full CI, hosted run, or remote mutation was performed. Final runtime acceptance remains pending.

## Independent Source Lane Decision (for combined review record)

This is the lane's structured disposition; it is **rejected** while SRC-02, SRC-03, and SRC-04 remain open. The combined record must compute `report_sha256` from this report after it is committed. File digests below are SHA-256 of the exact blobs at the reviewed revision.

```json
{
  "reviewer_identity": "gsd-code-reviewer/source/gpt-6-luna-high",
  "reviewed_revision": "5adf46c1b6b304fcc99fdb9f0ab25194a62d8c32",
  "reviewed_at": "2026-10-27",
  "verdict": "rejected",
  "report_path": "178-REVIEW-REREVIEW.md",
  "report_sha256": "COMPUTE_AFTER_REPORT_COMMIT",
  "reviewed_files": [
    {"path": ".github/workflows/ci.yml", "sha256": "6d43935abee648eb2e9438765aaae02df4e04305ce9b4f069116a6da90bd1ece"},
    {"path": "scripts/acceptance/clean_room/verifier_delivery.py", "sha256": "c4267426ac90ccd77ef93aa3797982b0ae16ad222b637e72a7c3fe905a6bf3f9"},
    {"path": "scripts/acceptance/clean_room/package_input.py", "sha256": "41c2d6e24de57a306d775855f3e51509fb045c08cf4c1bdb5c5260b84ca3987a"},
    {"path": "scripts/acceptance/clean_room/verifier_receipts.py", "sha256": "bcc60d1eea54f5eb0c6e91144d8f64390c3fbb78e600719d5708d7a7554a3cc5"},
    {"path": "scripts/acceptance/clean_room/verifier_rollout.py", "sha256": "3eaeffb0221db415cc0e64e13a86d01b43f668bcadd1acdeabbd596c65bb71ae"},
    {"path": "scripts/acceptance/clean_room/verifier_transactions.py", "sha256": "3ed0227b4faa11a67f2a909fd4005933ea1316086609aba7870eec351a78a2c1"},
    {"path": "scripts/acceptance/clean_room_verifier_upgrade.py", "sha256": "a77d8cbabafb04901aaf22f8cc1feb88a84ec1ed88629b0921d45e327d0ea1b0"},
    {"path": "scripts/ci/provision_verifier_candidate.py", "sha256": "a3bf5f6eb304fb5863bbee14513a00c1326c2411f074eac7659aae60d2084f1b"},
    {"path": "scripts/ci/run_verifier_upgrade_proof.sh", "sha256": "c07a28b74d30c7e142a91795fbb8605f316950879acd9eb7bc71be8b7bedcc37"},
    {"path": "scripts/ci/run_owned_source_tests.py", "sha256": "4490432083a3254de0e3ececbc09c75a85e01eead11eb236ddb5ebfe4a8acd5b"},
    {"path": "test/acceptance/client_verifier_delivery_test.py", "sha256": "dccdd5da85aba00b3ec9c4969120f3e6ab84888d620c2e3e82c12dec8f120115"},
    {"path": "test/acceptance/client_verifier_ci_test.py", "sha256": "ee07cf6321d4ab6ef36b283fe29209d2a55f110f30e87ebd64e4db28d043b3ce"},
    {"path": "test/acceptance/client_verifier_process_supervision_test.py", "sha256": "b734f442c79d7bf729fc60c4c0a28b6eb07464844ee51a5b3030308d9b4ab06a"}
  ],
  "findings": [
    {"id": "SRC-02", "severity": "critical", "status": "open", "disposition": "fix-before-freeze", "evidence": "The frozen-input set omits the CI candidate provisioner that creates the package and emits caller pins.", "files": ["scripts/acceptance/clean_room/verifier_delivery.py", "scripts/ci/provision_verifier_candidate.py"]},
    {"id": "SRC-03", "severity": "critical", "status": "open", "disposition": "fix-before-freeze", "evidence": "Candidate validation checks asserted artifact metadata but never binds artifact IDs or digests to downloaded hosted artifact bytes.", "files": ["scripts/acceptance/clean_room/verifier_delivery.py", ".github/workflows/ci.yml"]},
    {"id": "SRC-04", "severity": "critical", "status": "open", "disposition": "fix-before-freeze", "evidence": "Review validation accepts any nonempty reviewed file subset and permits findings to reference unreviewed files.", "files": ["scripts/acceptance/clean_room/verifier_delivery.py"]},
    {"id": "SRC-06", "severity": "medium", "status": "open", "disposition": "fix-before-freeze", "evidence": "Frozen manifest code hashes git show stdout without requiring git show success.", "files": ["scripts/acceptance/clean_room/verifier_delivery.py"]}
  ]
}
```

Reviewed file digest set is a focused call-chain scope, not a claim that hosted/runtime acceptance has been observed. The combined record should preserve this rejected verdict until the blockers are corrected and independently re-reviewed.
