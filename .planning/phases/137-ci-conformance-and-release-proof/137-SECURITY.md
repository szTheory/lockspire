---
phase: 137
slug: ci-conformance-and-release-proof
status: verified
threats_open: 0
asvs_level: 1
block_on: high
created: 2026-08-27
audited: 2026-08-27
---

# Phase 137 — Security

> Threat verification for CI evidence, external conformance inputs, clean-room
> package execution, and protected publication. All planned high and critical
> threats are mitigated; five planned low-severity availability risks are
> explicitly accepted with bounded controls.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| CI checkout → security/dependency tools | Repository-controlled scripts invoke Sobelow, Mix, and xref | Source paths and diagnostics |
| Test partitions → coverage aggregator | Separate jobs transport native coverdata as inert artifacts | Source SHA, checksums, coverdata, bounded receipts |
| OIDF lock → external network/containers | Pinned source, helpers, archive, and OCI images are fetched before execution | Public immutable inputs |
| GitHub secrets → conformance runner | Provider JSON is materialized privately for one profile step | OAuth/OIDC provider configuration and client material |
| Package archive → clean-room hosts | One verified package is unpacked and executed by separate provider/client roles | Release code and provenance |
| Prepublish → protected publish → postpublish | SHA-bound tar and manifest cross job/environment boundaries as data | Package bytes, checksum, tool/runtime identity |
| Protected job → Hex/HexDocs | Exact verified tar is uploaded and release-specific public state is checked | `HEX_API_KEY`, package bytes, public checksum/docs |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / Evidence | Status |
|-----------|----------|-----------|----------|-------------|-----------------------|--------|
| T-137-01 | Tampering | Sobelow invocation | high | mitigate | Two explicit low/private/exit router scans and negative contract | closed |
| T-137-02 | Repudiation | Sobelow exclusions | medium | mitigate | Named narrow exclusions; broad ignores rejected | closed |
| T-137-03 | Tampering | dependency lock gate | medium | mitigate | Read-only `deps.unlock --check-unused` contract | closed |
| T-137-04 | Denial of service | architecture cycle gate | medium | mitigate | Compile-connected xref scope and distinct tool failure | closed |
| T-137-05 | Tampering | coverage artifacts | high | mitigate | Exact partition, SHA, checksum, and inventory validation | closed |
| T-137-06 | Repudiation | partition ownership | high | mitigate | Disjoint commands; missing/duplicate/rerun exports rejected | closed |
| T-137-07 | Elevation of privilege | downloaded coverage | high | mitigate | Coverdata/JSON accepted as inert data only | closed |
| T-137-08 | Information disclosure | coverage receipts | low | accept | Receipt schema contains bounded identity and percentage fields only | closed (accepted) |
| T-137-09 | Repudiation | coverage percentage | high | mitigate | Native aggregate, no exclusions, complete-suite contracts | closed |
| T-137-10 | Tampering | security behavior tests | high | mitigate | Observable fail-closed protocol/operator outcomes | closed |
| T-137-11 | Information disclosure | operator/HTTP fixtures | high | mitigate | Sentinel and rendered/log redaction assertions | closed |
| T-137-12 | Denial of service | expanded test suite | low | accept | High-value branch focus and timing visibility bound runtime | closed (accepted) |
| T-137-13 | Tampering | CI artifact handoff | high | mitigate | SHA-bound names, exact paths, checksums, and `needs` edges | closed |
| T-137-14 | Elevation of privilege | CI permissions | high | mitigate | Top-level `contents: read`; no excess job permissions | closed |
| T-137-15 | Repudiation | skipped quality step | high | mitigate | Required steps contracted; bypass and `continue-on-error` rejected | closed |
| T-137-16 | Tampering | minimum-version fixture | medium | mitigate | Immutable fixture check separated from controlled demo update | closed |
| T-137-17 | Tampering | OIDF source/download | high | mitigate | Full commit URLs and SHA-256 validation before use | closed |
| T-137-18 | Tampering | container images | high | mitigate | Digest-qualified server, nginx, and Mongo identities | closed |
| T-137-19 | Elevation of privilege | fetched helpers | high | mitigate | Independently verified bytes and locked execution paths | closed |
| T-137-20 | Denial of service | upstream outage | low | accept | Distinct infrastructure failure; no mutable fallback | closed (accepted) |
| T-137-21 | Information disclosure | conformance artifact | high | mitigate | Allowlisted receipt schema and sentinel leak rejection | closed |
| T-137-22 | Tampering | profile bootstrap | high | mitigate | Shared verified preparation and pinned runner invocation | closed |
| T-137-23 | Repudiation | suite outcome | medium | mitigate | Bounded status/classification, identity, and timestamps | closed |
| T-137-24 | Elevation of privilege | raw suite output | high | mitigate | Private ephemeral work; receipt-only retention | closed |
| T-137-25 | Information disclosure | workflow uploads | high | mitigate | Explicit `receipt.json` artifact paths only | closed |
| T-137-26 | Elevation of privilege | scheduled workflow | high | mitigate | Read-only permissions, pinned actions, no PR-secret path | closed |
| T-137-27 | Repudiation | certification claim | medium | mitigate | Supplemental/non-certifying/non-release-gate contracts | closed |
| T-137-28 | Denial of service | external suite | low | accept | Timeout and concurrency bounds; lane remains supplemental | closed (accepted) |
| T-137-29 | Tampering | package source | high | mitigate | Exact source/version/checksum/inventory/provenance | closed |
| T-137-30 | Elevation of privilege | package archive | high | mitigate | Supported unpack; symlink/path-escape/test-support rejection | closed |
| T-137-31 | Repudiation | clean-room source | high | mitigate | One recorded identity verified in both child dependency paths | closed |
| T-137-32 | Information disclosure | journey evidence | high | mitigate | Sentinel scan and bounded redacted receipts | closed |
| T-137-33 | Tampering | release tar/manifest | critical | mitigate | Immediate SHA/version/checksum check; exact-byte upload | closed |
| T-137-34 | Spoofing | Hex response | high | mitigate | HTTPS release-specific package/version/checksum comparison | closed |
| T-137-35 | Information disclosure | retained manifest | high | mitigate | Strict field/value allowlist and secret-shaped data rejection | closed |
| T-137-36 | Repudiation | first publication | high | mitigate | Mandatory release-specific post-upload checksum verification | closed |
| T-137-37 | Denial of service | registry propagation | low | accept | Bounded classified retries; protected publish is non-canceling | closed (accepted) |
| T-137-38 | Elevation of privilege | preflight artifact | critical | mitigate | Artifact treated as data; fresh exact-SHA checkout executes | closed |
| T-137-39 | Tampering | publish handoff | critical | mitigate | SHA-bound artifact and manifest/tar verification in every job | closed |
| T-137-40 | Information disclosure | release evidence | high | mitigate | Manifest/bounded receipts only; raw logs/config stay ephemeral | closed |
| T-137-41 | Repudiation | release recovery | high | mitigate | Source CI run/SHA and identical artifact required for retry | closed |
| T-137-42 | Denial of service | concurrent publication | medium | mitigate | Non-canceling concurrency and protected environment serialization | closed |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-137-01 | T-137-08 | Bounded coverage receipts expose only revision, hashes, paths, and percentages needed for reproducibility. | Plan 137-02 | 2026-08-27 |
| AR-137-02 | T-137-12 | Focused behavioral additions and timing receipts bound complete-suite cost while preserving the 84% floor. | Plan 137-03 | 2026-08-27 |
| AR-137-03 | T-137-20 | Immutable upstream inputs can be unavailable; failing distinctly is safer than substituting mutable source. | Plan 137-05 | 2026-08-27 |
| AR-137-04 | T-137-28 | The external suite can time out or fail operationally; bounded supplemental execution must not block primary CI or releases. | Plan 137-07 | 2026-08-27 |
| AR-137-05 | T-137-37 | Hex and HexDocs propagation can be delayed; bounded retries preserve a classified failure without unsafe republish. | Plan 137-09 | 2026-08-27 |

## Security Audit Trail

| Audit Date | Threats Total | Mitigated | Accepted | Blocking Open | Run By |
|------------|---------------|-----------|----------|---------------|--------|
| 2026-08-27 | 42 | 37 | 5 | 0 | GSD security auditor, ASVS L1 |

Focused security evidence passed 44 Phase 137 contract tests, both Sobelow
router scans, the dependency/topology gate, immutable OIDF validation, and
workflow linting. No unregistered summary threat flags were found.

## Sign-Off

- [x] All threats have a disposition.
- [x] All planned accepted risks are documented.
- [x] All high and critical mitigations have implementation evidence.
- [x] `threats_open: 0` is confirmed at the configured `block_on: high` threshold.
- [x] `status: verified` is set in frontmatter.

**Approval:** verified 2026-08-27
