# Phase 137: CI, Conformance, and Release Proof - Research

**Researched:** 2026-08-27  
**Domain:** Reproducible GitHub Actions, Elixir coverage, OIDC conformance, and Hex release evidence  
**Confidence:** HIGH

## User Constraints

- This is an evidence-led readiness milestone. Do not add OAuth/OIDC grants, hosted auth, a standalone service, SAML/LDAP, or CIAM breadth.
- Lockspire remains an embedded Phoenix library. The host retains accounts, login UX, branding, tenant/product policy, and operator authentication.
- Do not make a formal certification claim; conformance evidence is supplemental until reliability history supports a stronger claim.
- Preserve all v1.x public behavior and security defaults, including strong redaction.

## Project Constraints (from AGENTS.md)

- Keep protocol, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces internally bounded.
- Keep the host seam explicit and narrow.
- Preserve S256 PKCE, exact redirects, hashed client secrets, single-use short-lived codes, refresh-family revocation, no implicit flow, no `alg=none`, and redaction.

<phase_requirements>
## Phase Requirements

| ID | Description | Research support |
|---|---|---|
| CI-01 | Explicit low-severity, fail-closed Sobelow scans for both routers | Sobelow supports `--router`, `--exit`, and `--threshold`; add a repository-owned wrapper and characterization contracts. |
| CI-02 | Execute fast/integration once and enforce merged >=84% coverage | Mix 1.19 natively exports `.coverdata` and `mix test.coverage` builds a unified report. |
| CI-03 | Reject unused dependencies/new compile-connected cycles; controlled demo updates | Extend the existing locked-dependency and `mix xref graph --format cycles` gates; retain separate fixture locks. |
| CONF-01 | Immutable OIDC/FAPI images, revisions, downloads, checksums | Lock all inputs to OIDF `release-v5.1.43` commit and SHA-256 values, validate before execution, eliminate `latest`/`master` fallback. |
| CONF-02 | Scheduled supplemental lane with redacted retained evidence | Add a scheduled trigger and a redaction/manifest stage; use least privilege, bounded artifacts, and a non-release-gating workflow. |
| REL-01 | Pre/post-publish clean-room HTTP proof for exact artifact/version | Generalize the existing Phase 133 package-input harness to accept the built tar and exact Hex package, then run the existing HTTP journey. |
| REL-02 | Hex checksum equals produced artifact; redacted version manifest | Produce one release receipt from the detached SHA/tar, verify Hex API checksum after publication, and persist only redacted metadata. |
</phase_requirements>

## Summary

The repository already has the right primitives: a pinned-action workflow style, a lockfile-aware CI matrix, a clean-room provider/client HTTP journey that verifies copied package provenance, an idempotent Hex publisher, and shell/workflow linting. Phase 137 should compose these into an immutable evidence chain rather than replace them or add dependencies. [VERIFIED: repository inspection]

**Primary recommendation:** add small, testable evidence scripts and an immutable OIDF input lock; wire them into separate CI aggregation, supplemental conformance, and release-proof workflow stages with artifacts treated as data, never executable inputs.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Router security scan | CI script | GitHub Actions | A repository script owns exact targets/flags; workflow only invokes it. |
| Coverage collection/merge | Mix + CI script | GitHub Actions artifacts | Mix measures/merges; workflow transports per-job data. |
| Dependency/cycle policy | CI script | Mix xref | The script expresses project policy and asks Mix for compile-connected cycles. |
| Conformance input provenance | Conformance script | Docker/GitLab | Checked-in lock data validates every fetched file/image identity before suite startup. |
| Redacted conformance/release receipts | Script | GitHub Actions artifacts | Scripts create safe evidence; workflow retains it with explicit names/retention. |
| Pre/post publish journey | Acceptance harness | Hex/API + release workflow | The harness proves the package boundary; release jobs select the exact source. |

## Standard Stack

| Component | Version / identity | Purpose | Guidance |
|---|---|---|---|
| Mix built-in coverage | Elixir 1.19.5 / OTP 28 | Export and aggregate line coverage | Use `mix test --cover --export-coverage NAME` per partition, then `mix test.coverage` once in the aggregator. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.Coverage.html] |
| Mix xref | Elixir 1.19.5 | Compile-connected cycle detection | Keep `mix xref graph --format cycles --label compile-connected` behind the existing architecture script. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Xref.html] |
| Sobelow | locked project dependency `~> 0.13` | Phoenix static scanning | Invoke twice with concrete router paths, low threshold, and non-zero exit. [CITED: https://hexdocs.pm/sobelow/0.8.0/Mix.Tasks.Sobelow.html] |
| OIDF Conformance Suite | `release-v5.1.43`, commit `16ad152b1b2c0baacd3d2519128340d95deb2b8c` | Supplemental protocol evidence | Pin the source commit plus every downloaded helper checksum and container digest. [VERIFIED: GitLab tag API] |
| Hex | existing Mix/Hex tooling | Build/publish package artifact | Build one `lockspire-X.Y.Z.tar`; `mix hex.build --unpack` is the supported inspection path. [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html] |

No new external package is needed, so no package legitimacy audit or install step applies.

## Architecture Patterns

### Evidence flow

```text
checked-out immutable SHA
  ├─ fast job: once → fast.coverdata ─┐
  ├─ integration job: once → integration.coverdata ─┼→ aggregate job → >=84% report
  ├─ conformance lock → checksum/digest validation → suite → redact → supplemental artifact
  └─ release SHA → build exact .tar → manifest + clean-room HTTP proof
                                      └→ publish same .tar → Hex checksum + exact-version HTTP proof
```

### Pattern 1: Script-owned policy, workflow-owned orchestration

Add narrow scripts such as `scripts/ci/check_sobelow_routers.sh`, `scripts/ci/aggregate_coverage.sh`, and conformance/release receipt helpers. Test their argument validation and failure modes from ExUnit/shell contracts. Keep YAML declarative: checkout, setup, invoke, upload/download. This keeps security policy reviewable without parsing workflow strings. [VERIFIED: repository inspection]

### Pattern 2: Exported coverage is a partition contract

Use distinct names (for example `fast` and `integration`) and fresh output directories. The fast job runs only its ordinary partition under `--cover --export-coverage fast`; the integration job runs only `test.integration` under the same flags with `integration`; the aggregation job downloads both artifacts, verifies their expected filenames and source SHA receipt, places them in its coverage output, and invokes `mix test.coverage`. Mix documents this exact split-and-unify model and warns that line coverage is not branch coverage. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.Coverage.html]

The clean-room Python journey is still a required acceptance job, but it is not silently included in Mix line coverage: its child processes are separately booted and currently are not instrumented/exported. Label the aggregate honestly as the complete **Mix test partition** (`fast + integration`), retain clean-room HTTP proof as a separate required evidence input, and do not claim it contributes to the 84% denominator. [VERIFIED: `mix.exs`, `scripts/ci/run_test_matrix.sh`, `scripts/acceptance/clean_room_saas_journey.py`]

### Pattern 3: Immutable external-suite lock

Create one checked-in JSON or shell data file (for example `scripts/conformance/oidf-suite-lock.json`) containing:

- tag, full commit, immutable raw URL base, source archive URL and archive SHA-256;
- SHA-256 for each downloaded helper at that commit;
- immutable OCI digests for both OIDF server/nginx images and MongoDB; and
- a schema/version field.

The scripts download into a private temp directory, verify SHA-256 before execution, parse/reject unexpected image references in the fetched compose file, and use only digest references. Delete the current prebuilt-to-source fallback: fallback converts a failure into a distinct, unrecorded suite. A failure to fetch, checksum, pin, or start is a failed conformance run, not a pass. The verified `release-v5.1.43` helper checksums are:

| File at pinned commit | SHA-256 |
|---|---|
| `docker-compose-prebuilt.yml` | `9ca2b63066e6d545edca39c59830c5afb5d569d19e14815a0f53a4682f717f2b` |
| `scripts/run-test-plan.py` | `abf7b2637accfbf06a1b7f370bc16516b5ba303e7784eea387e59c74877827e1` |
| `scripts/conformance.py` | `927709c76c4be48d52abaa36b5e52804803c72155695991df5a9645a9303a49f` |
| `scripts/test_plan_parser.py` | `2b00870b2dc46f1d44d047c715c0ef6978f24ece97a4a9d3b48ceeea8d01830f` |

[VERIFIED: GitLab raw files at commit `16ad152b1b2c0baacd3d2519128340d95deb2b8c`]

The pinned compose file still contains mutable default image tags (`mongo:6.0.13` and `registry.gitlab.com/...:${IMAGE_TAG:-latest}`), so pinning its file checksum alone is insufficient; the local normalized compose or environment must set digest-qualified image references and test them. [VERIFIED: fetched pinned `docker-compose-prebuilt.yml`]

### Pattern 4: Redaction before retention

Reuse the Phase 133 redaction principles: do not upload raw `provider-config.json`, browser exports, fixture logs, compose logs, tokens, cookies, authorization codes, secrets, or hosted URLs. Produce a separately redacted `evidence/` tree and manifest containing only bounded result fields, file hashes, suite identity, runtime/tool versions, exit status, and timestamps. Validate the artifact tree before upload and use `if: always()` only for that safe tree. [VERIFIED: existing conformance scripts and clean-room redactor]

### Pattern 5: Single-byte release chain

At detached `verified_sha`, build exactly one tarball; calculate its SHA-256; create a redacted manifest before publish; run clean-room proof against that tar's unpacked contents; then publish that same tar. After publication, query `https://hex.pm/api/packages/lockspire/releases/VERSION`, require its `checksum` to equal the local SHA-256, and run the minimal journey against a dependency resolution constrained to that exact public version. The existing idempotent publisher already validates checksum in the already-published case; extract this into a reusable verify step so it happens after both first publication and retry. [VERIFIED: `scripts/publish/publish_hex_idempotently.sh`; CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html]

## Concrete File Touchpoints

| Area | Existing files | Recommended change |
|---|---|---|
| CI security/dependencies | `mix.exs`, `.sobelow-conf`, `scripts/ci/check_architecture_topology.sh`, `.github/workflows/ci.yml` | Add explicit two-router Sobelow wrapper; assert mandatory flags/no broad `ignore_files`; invoke unused-dependency and cycle evidence in Fast Checks. |
| Coverage | `mix.exs`, `scripts/ci/run_test_matrix.sh`, `.github/workflows/ci.yml`, `test/lockspire/coverage_baseline_contract_test.exs` | Preserve fast-only local alias at 73%; add exports and an aggregate job/threshold 84 with independent artifact inputs. |
| OIDF | `scripts/conformance/run_phase37_suite.sh`, `run_fapi2_suite.sh`, plans, task docs, `.github/workflows/oidf-conformance.yml` | Deduplicate immutable bootstrap/redaction logic; create lock file and scheduled repo-native lane; amend task/docs truth. |
| Release | `scripts/publish/publish_hex_idempotently.sh`, `verify_install_truth.sh`, clean-room `package_input.py`/journey runner, `.github/workflows/release.yml` | Add release manifest/checksum tool; support tar and exact Hex package inputs; run HTTP journey before and after publish; upload only redacted evidence. |
| Guardrails | focused `test/lockspire/*_contract_test.exs`, `test/mix/tasks/*`, release-proof support | Characterize all flags, lock identities, schedule, secret-safe artifact paths, exact SHA handoff, and no mutable fallback. |

## Common Pitfalls

1. **False coverage aggregation:** `mix test.coverage` only aggregates exported data. Running `mix test --cover` without `--export-coverage`, re-running one partition in the aggregator, or allowing an artifact to be missing makes the result untruthful. Fail if exactly the expected export set is not present. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.Coverage.html]
2. **Sobelow scans only one surface:** default router discovery can miss the embedded routers. Require `--router lib/lockspire/web/router.ex` and `--router lib/lockspire/web/admin_router.ex` in two independent invocations, each with `--exit --threshold low --private`; config ignores must remain named and zero broad files. [CITED: https://hexdocs.pm/sobelow/0.8.0/Mix.Tasks.Sobelow.html]
3. **Pinned source, mutable image:** a tagged/hashed compose download can still interpolate `latest`. Resolve and lock OCI digest strings, do not merely set `IMAGE_TAG=release-v5.1.43`. [VERIFIED: fetched OIDF compose]
4. **Unsafe artifact upload:** GitHub artifacts are durable data sharing, so avoid raw diagnostic captures and do not execute artifact contents. Use explicit artifact filenames, source-SHA receipts, and redaction validation. [CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data]
5. **Release builds different bytes:** a post-publish check of merely “version exists” cannot prove the published payload matches the reviewed tar. Verify Hex API checksum after a first publish as well as idempotent retries. [VERIFIED: current publish/verify scripts]
6. **Schedule treated as release proof:** scheduled workflows run only from the default branch's workflow definition and can be delayed; retain results as supplemental evidence and keep release gates tied to the exact CI SHA. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]

## Don't Hand-Roll

| Problem | Do not build | Use instead |
|---|---|---|
| Cross-process coverage merge | Custom parser/summing percentages | Mix's exported `.coverdata` plus `mix test.coverage`. |
| Dependency graph/cycle engine | Source regex graph | `mix xref graph` with compile-connected labels. |
| Package contents extraction | Tar parsing | `mix hex.build --unpack` and the existing package inventory checks. |
| OAuth HTTP proof | A second minimal client implementation | Phase 133's existing provider/client clean-room journey, extended only at the package-input seam. |
| Secret scrubbing | Ad hoc workflow `sed` | Reuse/centralize structured redaction and a safe evidence manifest. |

## Validation Architecture

| Requirement | Automated proof | Command / contract |
|---|---|---|
| CI-01 | wrapper rejects omitted/mismatched router and broad ignores; real scan both routers | `bash scripts/ci/check_sobelow_routers.sh`; focused ExUnit contract |
| CI-02 | each partition emits one named export; aggregation rejects missing/extra/foreign exports and enforces 84% | focused coverage contract; `bash scripts/ci/run_test_matrix.sh --fast ...`; integration export; aggregate script |
| CI-03 | unused dependency and compile-connected cycle command fail closed; locks unchanged | `mix deps.unlock --check-unused` (or project-compatible audited command), `bash scripts/ci/check_architecture_topology.sh`, CI contract |
| CONF-01 | lock validation rejects any mutable URL/tag/checksum mismatch | helper unit/shell contracts and `bash scripts/conformance/...` with suite skipped only where explicitly labeled |
| CONF-02 | workflow includes cron and uploads only redacted evidence | `bash scripts/ci/lint_workflows.sh`; workflow/artifact policy test |
| REL-01/02 | local tar and exact Hex dependency both execute minimal HTTP journey; receipt/Hex checksum mismatch fails | focused Python/ExUnit contracts; release scripts dry-safe fixtures |

Per task: focused tests and the touched script. Per wave: `mix format --check-formatted`, `mix test.fast`, `bash scripts/ci/lint_workflows.sh`. Phase gate: `mix qa`, `mix docs.verify`, `mix package.build`, `bash scripts/ci/run_test_matrix.sh --fast ...`, `bash scripts/ci/run_test_matrix.sh --integration ...`, and the new static release/conformance contracts. [VERIFIED: repository CI conventions]

## Security Domain

| Threat | STRIDE | Required mitigation |
|---|---|---|
| Mutated upstream suite/image | Tampering | Full commit, file SHA-256, OCI digest, validation before execution, no fallback. |
| Artifact substitution | Tampering/Elevation | Expected source SHA receipt, exact filenames, hash verification, artifacts never executed. |
| Secret/token leakage | Information disclosure | Redact before retention; bounded manifest schema; no raw configs/logs. |
| Scan/coverage bypass | Repudiation/Tampering | Script-owned required targets/flags/exports and fail-closed tests. |
| Wrong package published | Tampering | One tar SHA carried through preflight, publish, Hex API verification, and post-publish proof. |
| Concurrent publishing | Denial/Tampering | Keep non-canceling release concurrency and protected `hex-publish` environment. GitHub environments gate job start and secret access. [CITED: https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/control-deployments] |

## Sources

- [Mix v1.19.5 coverage](https://hexdocs.pm/mix/Mix.Tasks.Test.Coverage.html) — native exported coverage aggregation and limits.
- [Mix xref v1.19.5](https://hexdocs.pm/mix/Mix.Tasks.Xref.html) — graph labels/cycle formats.
- [Sobelow CLI](https://hexdocs.pm/sobelow/0.8.0/Mix.Tasks.Sobelow.html) — explicit router, threshold, and exit options.
- [GitHub workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax) — schedule/concurrency semantics.
- [GitHub artifacts](https://docs.github.com/en/actions/tutorials/store-and-share-data) — artifact sharing/retention model.
- [GitHub environments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/control-deployments) — deployment protections/secrets.
- [Hex build](https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html) — tar creation and `--unpack` inspection.
- [OIDF tag API](https://gitlab.com/api/v4/projects/openid%2Fconformance-suite/repository/tags/release-v5.1.43) — verified tag/commit identity.

## Open Questions

1. Obtain and pin the OCI digest(s) corresponding to the OIDF suite images at the selected release immediately before implementation. The pinned compose exposes only tag interpolation, so the digest must be captured from registry manifest data and verified by a contract rather than guessed. [VERIFIED: fetched OIDF compose]
2. Confirm the project-compatible command for unused locked dependencies against the current Mix version before making it a hard gate; do not assume an option is supported without invoking `mix help deps.unlock` locally. [ASSUMED]

## Metadata

**Confidence breakdown:** standard stack HIGH (official docs/current local toolchain); architecture HIGH (repository plus official docs); external image digests MEDIUM until registry inspection pins them.  
**Valid until:** 2026-09-03 for GitHub/OIDF/Hex operational details.
