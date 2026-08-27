---
phase: 137-ci-conformance-and-release-proof
verified: 2026-08-27T23:25:44Z
status: human_needed
score: 10/12 must-haves verified
behavior_unverified: 2
overrides_applied: 0
behavior_unverified_items:
  - truth: "The scheduled OIDC/FAPI workflow executes the pinned external profiles and retains only their redacted receipts."
    test: "Dispatch `Supplemental OIDF Conformance` on the default branch with the repo-native secrets provisioned, then inspect the resulting artifacts."
    expected: "Both profiles invoke their pinned plan runners, succeed or fail with a classified redacted receipt, and upload only `receipt.json`; no raw configuration, logs, OAuth material, or hosted URL is retained."
    why_human: "The repository tests exercise the runner and workflow topology with doubles, but this verifier cannot invoke GitHub-hosted jobs, protected secrets, Docker images, and the external OIDF suite."
  - truth: "The protected release workflow publishes the clean-room-proven tar and repeats the journey against that exact public version."
    test: "Use a disposable release candidate through the protected `hex-publish` environment (or an approved staging-equivalent) and follow prepublish, publish, and post-publish jobs."
    expected: "The prepublish tar checksum is the manifest checksum, the uploader sends those exact bytes, Hex reports the same checksum, versioned HexDocs is available, and the exact-version clean-room HTTP journey passes; retained evidence contains only the manifest and bounded receipts."
    why_human: "The exact-byte upload path and workflow wiring have focused automated evidence, but publication, GitHub environment protection, registry propagation, and public install cannot be safely exercised from this checkout."
human_verification:
  - test: "Run the default-branch supplemental OIDC/FAPI workflow and inspect its artifacts."
    expected: "Only validated `receipt.json` artifacts are retained, with correct success/infrastructure/suite-failure classification."
    why_human: "Requires GitHub secrets, Docker, and the pinned external suite."
  - test: "Execute a protected release or approved staging rehearsal."
    expected: "The artifact/manifest/Hex checksum/public clean-room chain remains one identity end to end."
    why_human: "Requires protected publication credentials and external Hex/HexDocs state."
---

# Phase 137: CI, Conformance, and Release Proof Verification Report

**Phase Goal:** A release carries reproducible security, coverage, conformance, and package-install evidence from immutable inputs.
**Verified:** 2026-08-27T23:25:44Z
**Status:** human_needed
**Re-verification:** Yes — refreshed after merging current `origin/main` (Lockspire 1.4.0)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Both shipped routers are low-severity, fail-closed Sobelow targets. | ✓ VERIFIED | `scripts/ci/check_sobelow_routers.sh` has two explicit `--router`, `--private`, `--threshold low`, `--exit` calls; `mix qa` invokes it; the script and its negative contracts passed. |
| 2 | CI rejects unused locked dependencies and compile-connected cycles. | ✓ VERIFIED | `check_dependency_truth.sh` runs `mix deps.unlock --check-unused` then the `xref --format cycles --label compile-connected` gate; live execution passed and CI calls it. |
| 3 | Fast and integration partitions run once, with a truthful complete-suite >=84% native aggregate. | ✓ VERIFIED | Fresh merged-tree run: fast `1362/0` (6 skipped), integration `284/0`, clean-room `0` failures; each emitted one same-identity export and `aggregate_coverage.sh` reported **84.78%** for merge-candidate tree `cc447d051380ed947e29a0b83bd9aaa76c1680ff`, whose source and test contents were recorded in merge commit `654238d6`. |
| 4 | OIDC/FAPI inputs are immutable and fail closed on mutable or altered source/image/input data. | ✓ VERIFIED | `oidf-suite-lock.json` pins commit/checksums/digests; `oidf_inputs.py --validate-only` passed; contracts cover mutable refs, checksum and compose-image drift. |
| 5 | Conformance profiles use the immutable seam and retain bounded redacted evidence. | ✓ VERIFIED | Shared runner prepares first, waits for Compose, invokes the pinned `run-test-plan.py`, classifies runner/setup failures, and deletes raw work; 47 focused contracts passed, including execution-level failure/success tests. |
| 6 | Supplemental conformance is default-branch scheduled, manually runnable, and uploads only receipts. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Workflow has weekly cron/manual dispatch, least privilege, 30-day receipt-only artifacts, and static contracts; actual hosted GitHub/Docker/OIDF execution requires human-run external evidence. |
| 7 | A local tar or exact Hex version drives one package input through both clean-room roles and the real HTTP journey. | ✓ VERIFIED | Package-source contracts pass; the integration partition executed `test.clean-room.e2e` successfully; code validates exact source/checksum, inventories/unpacks it, and verifies both child provenance. |
| 8 | The release manifest binds source SHA, tar identity, and allowlisted runtime/tool versions. | ✓ VERIFIED | `release_artifact.py` has strict schema/regular-file/checksum/source checks; focused manifest substitution and redaction contracts passed. |
| 9 | First publish sends the already-proven tar bytes, rather than rebuilding a package. | ✓ VERIFIED | `publish_hex_idempotently.sh` verifies local manifest/tar then calls `upload_hex_artifact.exs`; focused local-endpoint test captured bytes and proved equality to the supplied tar. |
| 10 | Post-publish verification requires exact Hex checksum, versioned docs, and exact-version clean-room HTTP proof. | ✓ VERIFIED | `verify_install_truth.sh` calls the release-specific API through manifest validation, checks HexDocs, and invokes the exact-version journey; mismatch and topology contracts passed. |
| 11 | Protected release orchestration carries the same checked artifact across prepublish, publish, and post-publish. | ✓ VERIFIED | `.github/workflows/release.yml` uses verified SHA, manifest-bound artifact names, fresh detached publish checkout, protected `hex-publish`, and receipt-only retention; workflow contracts passed. |
| 12 | A production GitHub/Hex release realizes the exact-artifact chain. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Implemented and locally contract-tested, but not safely executable here without protected credentials and external registry state. |

**Score:** 10/12 truths verified (2 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/ci/check_sobelow_routers.sh` | Explicit two-router security gate | ✓ VERIFIED | Substantive two-command fail-closed implementation; wired via `mix qa` and CI. |
| `scripts/ci/{run_test_matrix,aggregate_coverage}.sh` | Once-only exports and strict native merge | ✓ VERIFIED | Exact inventory/SHA/checksum validation; fresh current-HEAD aggregate passed. |
| `.github/workflows/ci.yml` | Required CI evidence topology | ✓ VERIFIED | Fast/integration uploads and `needs`-bound non-test aggregate job are wired. |
| `scripts/conformance/{oidf_inputs.py,prepare_oidf_suite.sh,run_oidf_profile.sh,build_redacted_evidence.py}` | Immutable suite execution and safe evidence | ✓ VERIFIED | Validator, private preparation, pinned runner invocation, and allowlisted receipt flow are linked. |
| `.github/workflows/oidf-conformance.yml` | Scheduled supplemental lane | ✓ VERIFIED | Cron/manual topology, pinned setup/actions, receipt-only uploads; external execution remains human verification. |
| `scripts/acceptance/clean_room/package_input.py` | Exact package provenance for both child roles | ✓ VERIFIED | Source selection, Hex unpack/inventory, copy, and per-role dependency-path checks are substantive and invoked by journey code. |
| `scripts/publish/{release_artifact.py,publish_hex_idempotently.sh,upload_hex_artifact.exs,verify_install_truth.sh}` | Single-byte release proof | ✓ VERIFIED | Manifest validation, byte upload, release API checksum, docs and public journey paths are linked and tested. |
| `.github/workflows/release.yml` | Prepublish → protected publish → postpublish chain | ✓ VERIFIED | Verified-SHA handoff, environment-scoped key, validated data transfer, and bounded receipt retention are wired. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `mix qa` / CI fast job | Both router scans | alias → `check_sobelow_routers.sh` | WIRED | `mix.exs` invokes the script; CI invokes `mix qa`. |
| Test partitions | coverage aggregate | named coverdata/receipts → SHA-bound Actions artifacts → `aggregate_coverage.sh` | WIRED | Current-HEAD fresh run and workflow `needs: [fast, integration]` both confirm the path. |
| OIDC/FAPI wrappers | pinned suite | profile wrapper → verified prepare → Compose readiness → `invoke_oidf_plan.py` | WIRED | Post-review execution test proves the actual runner call and failure classification. |
| Release manifest | outbound Hex payload / public verifier | `verify-local` → supplied bytes → release-specific checksum API → exact-version journey | WIRED | Post-review byte-capture test proves the upload input; workflow passes explicit tar/manifest/SHA. |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Coverage aggregate | `fast` and `integration` `.coverdata` | Real test partitions, SHA/checksum receipts | Merged tree 84.78% | ✓ FLOWING |
| OIDF evidence | receipt identity/status | checked-in lock + actual runner result | Schema-bounded receipt only | ✓ FLOWING |
| Release evidence | manifest/checksum/receipts | built tar + release API + clean-room verifier | Exact identity inputs are validated before each use | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| CI security/dependency gates | `bash scripts/ci/check_sobelow_routers.sh && bash scripts/ci/check_dependency_truth.sh` | Both Sobelow scans completed; no cycles | ✓ PASS |
| Immutable OIDF lock | `python3 scripts/conformance/oidf_inputs.py --lock scripts/conformance/oidf-suite-lock.json --validate-only` | Exit 0 | ✓ PASS |
| Phase contracts, including post-review fixes | focused 14-file ExUnit invocation | 47 tests, 0 failures | ✓ PASS |
| Current complete coverage | fresh matrix fast + integration + native aggregate in `/tmp/lockspire-phase137-merge-coverage.K0EnZi` | fast 1362/0 (6 skipped); integration 284/0; aggregate 84.78% | ✓ PASS |
| Workflow syntax/static supply chain | `bash scripts/ci/lint_workflows.sh` | Exit 0 | ✓ PASS |

### Requirements Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| CI-01 | ✓ SATISFIED | Explicit router wrapper, `mix qa`/CI wiring, live Sobelow run, bypass contracts. |
| CI-02 | ✓ SATISFIED | Exactly two signed same-identity exports, no test execution in aggregator, current 84.78% aggregate. |
| CI-03 | ✓ SATISFIED | Read-only unused-lock and compile-connected cycle gate are live and CI-wired; fixture lock checks remain in workflow. |
| CONF-01 | ✓ SATISFIED | Pinned commit/archive/helpers/OCI digests, verified preparation, and no mutable/source fallback. |
| CONF-02 | ⚠️ NEEDS HUMAN | Schedule and receipt-only policy are implemented/tested; real external scheduled execution needs a GitHub run. |
| REL-01 | ⚠️ NEEDS HUMAN | Built-tar/exact-version clean-room paths and protected workflow are implemented/tested; public publication journey needs protected external execution. |
| REL-02 | ⚠️ NEEDS HUMAN | Manifest, exact-byte upload, checksum comparison, and workflow retention are implemented/tested; a real Hex release is still an external acceptance check. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, placeholder, raw-copy, or broad-ignore debt markers in 46 Phase-137 implementation/test files | ℹ️ Info | No blocker found. The only `latest` strings are expected upstream-compose templates that the validator rejects before use. |

## Human Verification Required

### 1. Scheduled external conformance lane

**Test:** Dispatch the default-branch supplemental workflow with valid repo-native secrets.

**Expected:** Pinned OIDC and FAPI plans run after validated input preparation; only redacted receipt artifacts remain, and any failure is honestly classified.

**Why human:** Requires GitHub Actions, secrets, Docker, and the external suite.

### 2. Protected exact-artifact release lane

**Test:** Run an approved protected release/staging rehearsal through prepublish, Hex upload, and public verification.

**Expected:** One tar checksum persists through manifest, outbound bytes, Hex API, versioned docs, and the exact-version clean-room HTTP journey; only bounded receipts are retained.

**Why human:** Requires protected `HEX_API_KEY` access and public Hex/HexDocs propagation.

## Gaps Summary

No implementation gaps or failed roadmap truths were found. The phase is blocked only on the two normal external acceptance checks above; automated evidence is complete.

---

_Verified: 2026-08-27T23:25:44Z_
_Verifier: the agent (gsd-verifier)_
