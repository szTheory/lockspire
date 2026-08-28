---
phase: 137-ci-conformance-and-release-proof
verified: 2026-08-28T04:41:30Z
milestone_reverified: 2026-08-28T04:41:30Z
status: passed
score: 12/12 must-haves verified
behavior_unverified: 0
overrides_applied: 0
behavior_unverified_items: []
human_verification: []
---

# Phase 137: CI, Conformance, and Release Proof Verification Report

**Phase Goal:** A release carries reproducible security, coverage, conformance, and package-install evidence from immutable inputs.
**Verified:** 2026-08-28T04:41:30Z
**Status:** passed
**Re-verification:** Yes — refreshed after default-branch CI/conformance and the public Lockspire 1.5.0 release

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Both shipped routers are low-severity, fail-closed Sobelow targets. | ✓ VERIFIED | `scripts/ci/check_sobelow_routers.sh` has two explicit `--router`, `--private`, `--threshold low`, `--exit` calls; `mix qa` invokes it; the script and its negative contracts passed. |
| 2 | CI rejects unused locked dependencies and compile-connected cycles. | ✓ VERIFIED | `check_dependency_truth.sh` runs `mix deps.unlock --check-unused` then the `xref --format cycles --label compile-connected` gate; live execution passed and CI calls it. |
| 3 | Fast and integration partitions run once, with a truthful complete-suite >=84% native aggregate. | ✓ VERIFIED | Fresh merged-tree run: fast `1362/0` (6 skipped), integration `284/0`, clean-room `0` failures; each emitted one same-identity export and `aggregate_coverage.sh` reported **84.78%** for merge-candidate tree `cc447d051380ed947e29a0b83bd9aaa76c1680ff`, whose source and test contents were recorded in merge commit `654238d6`. |
| 4 | OIDC/FAPI inputs are immutable and fail closed on mutable or altered source/image/input data. | ✓ VERIFIED | `oidf-suite-lock.json` pins commit/checksums/digests; `oidf_inputs.py --validate-only` passed; contracts cover mutable refs, checksum and compose-image drift. |
| 5 | Conformance profiles use the immutable seam and retain bounded redacted evidence. | ✓ VERIFIED | Shared runner prepares first, waits for Compose, invokes the pinned `run-test-plan.py`, classifies runner/setup failures, and deletes raw work; 47 focused contracts passed, including execution-level failure/success tests. |
| 6 | Supplemental conformance is default-branch scheduled, manually runnable, and uploads only receipts. | ✓ VERIFIED | Default-branch run `33139876101` executed both pinned profiles. Downloaded Phase37 and FAPI2 `receipt.json` artifacts were allowlisted, bound to suite tag `release-v5.1.43`, suite commit `16ad152…`, pinned image digests/helper hashes, and classified `suite_failure`; no raw configuration, keys, tokens, or suite logs were retained. The failures are honest supplemental findings, not a certification claim. |
| 7 | A local tar or exact Hex version drives one package input through both clean-room roles and the real HTTP journey. | ✓ VERIFIED | Package-source contracts pass; the integration partition executed `test.clean-room.e2e` successfully; code validates exact source/checksum, inventories/unpacks it, and verifies both child provenance. |
| 8 | The release manifest binds source SHA, tar identity, and allowlisted runtime/tool versions. | ✓ VERIFIED | `release_artifact.py` has strict schema/regular-file/checksum/source checks; focused manifest substitution and redaction contracts passed. |
| 9 | First publish sends the already-proven tar bytes, rather than rebuilding a package. | ✓ VERIFIED | `publish_hex_idempotently.sh` verifies local manifest/tar then calls `upload_hex_artifact.exs`; focused local-endpoint test captured bytes and proved equality to the supplied tar. |
| 10 | Post-publish verification requires exact Hex checksum, versioned docs, and exact-version clean-room HTTP proof. | ✓ VERIFIED | `verify_install_truth.sh` calls the release-specific API through manifest validation, checks HexDocs, and invokes the exact-version journey; mismatch and topology contracts passed. |
| 11 | Protected release orchestration carries the same checked artifact across prepublish, publish, and post-publish. | ✓ VERIFIED | `.github/workflows/release.yml` uses verified SHA, manifest-bound artifact names, fresh detached publish checkout, protected `hex-publish`, and receipt-only retention; workflow contracts passed. |
| 12 | A production GitHub/Hex release realizes the exact-artifact chain. | ✓ VERIFIED | Protected recovery run `33141484467` passed validation, prepublish proof, exact-byte Hex publication, and public install truth for Lockspire 1.5.0 from source SHA `5d10ce2219c2e687cf9573c8b280abfb118a47d8`. Its manifest and verified receipts identify `lockspire-1.5.0.tar`, 415744 bytes, SHA-256 `30c1f56f0f356be727269ba1a6c1b6be85a3c6c6bc224d781a7c136241ed90de`. |

**Score:** 12/12 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/ci/check_sobelow_routers.sh` | Explicit two-router security gate | ✓ VERIFIED | Substantive two-command fail-closed implementation; wired via `mix qa` and CI. |
| `scripts/ci/{run_test_matrix,aggregate_coverage}.sh` | Once-only exports and strict native merge | ✓ VERIFIED | Exact inventory/SHA/checksum validation; fresh current-HEAD aggregate passed. |
| `.github/workflows/ci.yml` | Required CI evidence topology | ✓ VERIFIED | Fast/integration uploads and `needs`-bound non-test aggregate job are wired. |
| `scripts/conformance/{oidf_inputs.py,prepare_oidf_suite.sh,run_oidf_profile.sh,build_redacted_evidence.py}` | Immutable suite execution and safe evidence | ✓ VERIFIED | Validator, private preparation, pinned runner invocation, and allowlisted receipt flow are linked. |
| `.github/workflows/oidf-conformance.yml` | Scheduled supplemental lane | ✓ VERIFIED | Cron/manual topology, pinned setup/actions, and receipt-only uploads were exercised by default-branch run `33139876101`. |
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
| OIDF evidence | receipt identity/status | checked-in lock + hosted runner result `33139876101` | Two allowlisted, classified receipts only | ✓ FLOWING |
| Release evidence | manifest/checksum/receipts | built tar + release API + clean-room verifier in `33141484467` | One exact SHA-256 identity through publish and public install | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| CI security/dependency gates | `bash scripts/ci/check_sobelow_routers.sh && bash scripts/ci/check_dependency_truth.sh` | Both Sobelow scans completed; no cycles | ✓ PASS |
| Immutable OIDF lock | `python3 scripts/conformance/oidf_inputs.py --lock scripts/conformance/oidf-suite-lock.json --validate-only` | Exit 0 | ✓ PASS |
| Phase contracts, including post-review fixes | focused 14-file ExUnit invocation | 47 tests, 0 failures | ✓ PASS |
| Current complete coverage | fresh matrix fast + integration + native aggregate in `/tmp/lockspire-phase137-merge-coverage.K0EnZi` | fast 1362/0 (6 skipped); integration 284/0; aggregate 84.78% | ✓ PASS |
| Workflow syntax/static supply chain | `bash scripts/ci/lint_workflows.sh` | Exit 0 | ✓ PASS |
| Canonical default-branch CI | GitHub Actions run `33141161205` at `5d10ce2219c2e687cf9573c8b280abfb118a47d8` | All jobs passed; fast 1657/0, integration 286/0, minimum-version 1371/0 (6 skipped), release contracts 13/0 | ✓ PASS |
| Supplemental conformance | GitHub Actions run `33139876101` and downloaded receipt artifacts | Both immutable profiles ran and emitted validated, allowlisted `suite_failure` receipts without raw evidence | ✓ PASS |
| Protected release and public install | GitHub Actions run `33141484467` | Exact-main validation, prepublish, Hex publish, Hex/HexDocs checksum verification, and exact-version clean-room journey all passed | ✓ PASS |

### Requirements Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| CI-01 | ✓ SATISFIED | Explicit router wrapper, `mix qa`/CI wiring, live Sobelow run, bypass contracts. |
| CI-02 | ✓ SATISFIED | Exactly two signed same-identity exports, no test execution in aggregator, current 84.78% aggregate. |
| CI-03 | ✓ SATISFIED | Read-only unused-lock and compile-connected cycle gate are live and CI-wired; fixture lock checks remain in workflow. |
| CONF-01 | ✓ SATISFIED | Pinned commit/archive/helpers/OCI digests, verified preparation, and no mutable/source fallback. |
| CONF-02 | ✓ SATISFIED | Default-branch run `33139876101` exercised both pinned profiles and retained only validated classified receipts; suite failures remain supplemental and non-certifying. |
| REL-01 | ✓ SATISFIED | Protected run `33141484467` passed prepublish built-tar proof and postpublish exact-1.5.0 clean-room install/HTTP proof. |
| REL-02 | ✓ SATISFIED | Run `33141484467` retained the allowlisted manifest and verified pre/post receipts for the same 415744-byte tar and SHA-256 checksum reported by public Hex. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, placeholder, raw-copy, or broad-ignore debt markers in 46 Phase-137 implementation/test files | ℹ️ Info | No blocker found. The only `latest` strings are expected upstream-compose templates that the validator rejects before use. |

## External Acceptance Evidence

### 1. Scheduled external conformance lane

Default-branch run `33139876101` executed the secretless Phase37 and FAPI2 jobs against disposable Billingo providers. Both receipts passed the allowlist/redaction validator and retained immutable suite identity plus `suite_failure` classification only. Phase37 now reaches authorization semantics after the DCR credential-method fix; remaining findings concern authorization error behavior. The FAPI2 receipt preserves broader PAR/TLS/WebRunner interoperability findings. This satisfies reproducible supplemental evidence while explicitly not asserting conformance certification.

### 2. Protected exact-artifact release lane

Release run `33141484467` used canonical green CI run `33141161205` for exact source SHA `5d10ce2219c2e687cf9573c8b280abfb118a47d8`. The release manifest and both verified receipts carry version `1.5.0`, tar size 415744, and SHA-256 `30c1f56f0f356be727269ba1a6c1b6be85a3c6c6bc224d781a7c136241ed90de`. The protected job published those bytes, verified the release-specific Hex checksum and versioned HexDocs, and passed the exact public-version clean-room journey.

## Gaps Summary

No blocking implementation or acceptance gaps remain. The supplemental OIDF `suite_failure` receipts are retained follow-up evidence and deliberately do not become a release gate or certification claim.

---

_Verified: 2026-08-28T04:41:30Z after protected release acceptance and milestone integration audit_
_Verifier: the agent (gsd-verifier)_
