# Phase 137: Implementation Patterns

**Mapped:** 2026-08-27
**Scope:** CI evidence, immutable OIDF inputs, and exact-package release proof

## Closest Existing Analogs

| New responsibility | Existing analog | Reuse rule |
|---|---|---|
| Explicit public/admin security scans | `scripts/ci/run_credo.sh`, `scripts/ci/check_architecture_topology.sh` | Keep policy in one fail-closed shell entrypoint; let Actions only orchestrate it. |
| Once-per-partition coverage | `scripts/ci/run_test_matrix.sh` and Mix 1.19 exported coverage | Export `fast.coverdata` and `integration.coverdata`; merge only those two named data artifacts. |
| Immutable external evidence | `scripts/ci/lint_workflows.sh` pinned downloads/checksums | Put identities in one checked-in lock and verify bytes before any downloaded helper executes. |
| Safe retained evidence | Phase 133 `Redactor`/sentinel scan | Retain bounded JSON receipts and hashes; never upload raw provider config, tokens, cookies, browser exports, or request logs. |
| Pre/post-publish package proof | `scripts/acceptance/clean_room_saas_journey.py` | Extend only the package-input seam; reuse the real provider/client install, migrate, verify, boot, and HTTP flow. |
| Idempotent publication | `scripts/publish/publish_hex_idempotently.sh` | Carry one tar SHA from build through publish and compare the Hex release API checksum after both first publish and retry. |

## File-to-Pattern Map

### CI gates

- Add `scripts/ci/check_sobelow_routers.sh` beside the existing small gate scripts. It owns two explicit `mix sobelow` invocations with `--router`, `--threshold low`, and `--exit`.
- Extend `scripts/ci/check_architecture_topology.sh` or add one dependency-policy sibling for `mix deps.unlock --check-unused`; do not rewrite locks.
- Change `scripts/ci/run_test_matrix.sh` so `--fast` and `--integration` export unique coverage files while each partition still runs once. Clean-room remains a separate behavioral record.
- Add an aggregation entrypoint that validates exactly two `.coverdata` inputs and their source receipts before calling the native Mix coverage task in complete-suite mode.
- `.github/workflows/ci.yml` transports coverage data with pinned artifact actions and introduces one aggregation job depending on fast and integration.

### Coverage closure

- Keep the existing 73% fast-only developer floor and define 84% only for the complete fast-plus-integration aggregate.
- Do not ignore production modules or sum percentages. Add behavioral tests against the largest real uncovered surfaces, led by refresh rotation, workers, token storage, client authentication, and HTTP delivery adapters.
- Re-measure with fresh exports after every coverage-test batch. A test that only calls private implementation through synthetic hooks is inferior to a protocol, repository, worker, or controller behavior assertion.

### OIDF conformance

- Add `scripts/conformance/oidf-suite-lock.json` for the release tag, full commit, immutable raw/archive URLs, helper/archive SHA-256 values, and digest-qualified server/nginx/Mongo image identities.
- Extract duplicated download/bootstrap behavior from both suite runners into a shared helper. A missing file, checksum mismatch, mutable image reference, or failed prebuilt bootstrap is a hard infrastructure failure; remove the mutable source-build fallback.
- Normalize the pinned upstream compose by supplying tag-plus-digest image values. The pinned compose file alone is insufficient because it still interpolates mutable defaults.
- Produce a safe evidence directory with a schema-bounded manifest. Raw suite working data stays temporary.
- `.github/workflows/oidf-conformance.yml` gets an explicit schedule and uploads only the safe evidence directory. It stays supplemental and must not become a release dependency or certification claim.

### Release proof

- Extend `scripts/acceptance/clean_room/package_input.py` with three mutually exclusive sources: current checkout build (developer default), an exact local Hex tar, or an exact public Hex version. All converge on the existing audited unpacked inventory copied below each child root.
- Make the journey resolve one package input once per run so provider and client cannot silently use different bytes.
- A pre-publish job at the detached verified SHA builds one tar, writes a redacted manifest, checks its SHA, and runs the existing minimal `happy_path` HTTP journey against that tar.
- The protected publish job downloads the exact tar/manifest as data, revalidates SHA and source identity, and publishes from the verified checkout without rebuilding the package bytes.
- The post-publish job compares the Hex API checksum with the recorded tar SHA, fetches exactly that public version, and repeats the same minimal HTTP journey. Retained evidence is the manifest plus safe receipts, not the journey logs.

## Security Invariants

1. Downloaded helpers are not executed until checksum validation succeeds.
2. Artifact transport never grants an artifact authority to choose a command, path, ref, version, or checksum.
3. Coverage aggregation fails on missing, duplicate, extra, or source-mismatched inputs.
4. The release environment receives only a tar whose hash and source SHA were proved before environment approval.
5. No workflow artifact contains credentials, OAuth material, raw hosted URLs, or unredacted request/response bodies.
6. Conformance remains supplemental; CI and release evidence never imply OIDF certification.

## Verification Layers

- Focused contracts exercise argument validation, missing inputs, checksum mismatch, redaction failure, and workflow topology.
- Repository tools validate real Sobelow routers, unused dependencies, compile-connected cycles, workflow syntax, ShellCheck, and native coverage merge behavior.
- The clean-room harness proves package provenance plus real migration, verification, boot, and HTTP behavior for local-tar and exact-version modes.
- Final convergence runs `mix qa`, zero-warning Dialyzer, strict docs, package build, fast/integration partitions, aggregate coverage, workflow lint, and static conformance/release contracts.
