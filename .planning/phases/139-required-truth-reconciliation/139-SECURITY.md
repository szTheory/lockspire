---
phase: "139"
slug: "required-truth-reconciliation"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-09-13"
---

# Phase 139 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Caller and host input -> acceptance authority | CLI arguments and sealed lifecycle state are untrusted until their phase, mode, SHA, hook, writer, and transformation identities validate exactly. | Commit identities, phase numbers, bounded dispositions, sealed receipts |
| Git and GitHub observations -> acceptance verdict | Mutable local refs, remote refs, workflow runs, and job pages cannot authorize acceptance without exact identity, completeness, and before/after checks. | Repository identity, refs, workflow metadata, job outcomes |
| Workflow and command output -> durable receipts | Only explicit allowlisted scalar fields may cross into deterministic receipts; raw responses and environment values remain private. | Redacted release, CI, hygiene, and historical evidence |
| Tracked source -> installed lifecycle execution | The installed capability is authoritative only when it matches tracked source and dispatches a fixed validated argv without a shell. | Capability version, hook envelope, child path, phase and mode |
| Mutable repository -> immutable ledger and synchronized main | Publication and ref movement require agreeing observations, a one-path commit, exact ancestry, compare-and-swap, and post-write identity checks. | Ledger bytes, commit graph, local and remote main refs |
| Executable release behavior -> maintained prose | Maintained documentation must describe current event ownership and ordering while preserving shipped historical evidence as a distinct truth class. | Release workflow structure, active milestone state, shipped release facts |
| Supplemental evidence -> required acceptance | OIDF/FAPI evidence is redacted and non-certifying and cannot become authority for a required release gate. | Bounded conformance classifications |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-139-01 | Spoofing | canonical CI and Release run selection | high | mitigate | `repo_hygiene_check.sh` selects one stable run ID for the exact SHA and validates workflow, repository, event, branch, status, conclusion, and complete job pages; hostile selection fixtures pass. | closed |
| T-139-02 | Tampering | local/main identity during long gates | high | mitigate | Exact HEAD, local `main`, and refreshed `origin/main` equality is checked around `mix ci` and polling; moving-identity fixtures fail closed. | closed |
| T-139-03 | Repudiation | compact acceptance receipt | medium | mitigate | `emit_acceptance_receipt` produces a deterministic allowlisted schema containing SHA, run IDs, URLs, outcomes, and WARN dispositions. | closed |
| T-139-04 | Information disclosure | API and command diagnostics | medium | mitigate | Raw command/API bodies remain private; receipt projection and hostile disclosure fixtures permit only bounded scalar fields and class-only errors. | closed |
| T-139-05 | Denial of service | workflow polling | low | accept | Polling uses a caller-bounded deadline and a stable run ID; timeout and candidate-change paths return a blocking result. Residual GitHub latency is accepted. | closed |
| T-139-06 | Elevation of privilege | Release no-publish evaluation | critical | mitigate | Push-event evidence requires Release Please success and protected publication jobs skipped; the acceptance path exposes no workflow dispatch or publication command. | closed |
| T-139-07 | Tampering | shell lint policy | high | mitigate | Source findings were repaired without suppressions or fallback exits; the unchanged workflow/ShellCheck lane and repository-hygiene contract pass. | closed |
| T-139-08 | Spoofing | generated phase fixtures | medium | mitigate | Active fixture values compose from semantic phase attributes while tests assert the exact rendered lifecycle and receipt bytes. | closed |
| T-139-09 | Repudiation | claimed gate repair | medium | mitigate | Each repair is tied to a recorded finding and the summary retains successful workflow lint, proof-quality, readiness, and repository-hygiene commands. | closed |
| T-139-10 | Denial of service | oversized cleanup diff | low | accept | The cleanup stayed within the enumerated lint/proof inventory and three owned files; the bounded review cost is accepted. | closed |
| T-139-11 | Elevation of privilege | release workflow event split | critical | mitigate | Structural tests require push-only Release Please, dispatch-only validation/publication, exact dependency edges, and package-before-GitHub-release ordering. | closed |
| T-139-12 | Tampering | external action references | high | mitigate | The workflow and repository-controlled composite scan permits local actions or exact lowercase 40-hex external action refs only. | closed |
| T-139-13 | Spoofing | static no-publish evidence | medium | mitigate | Static tests establish graph shape only; the final acceptance path separately binds live runs to the sealed exact SHA. | closed |
| T-139-SC | Tampering | package-manager installs | low | accept | No package installation or dependency change occurred; verification used the existing Mix/ExUnit and Node stacks. The residual existing-toolchain risk is accepted. | closed |
| T-139-14 | Tampering | historical 1.5.0 chain | high | mitigate | Maintained tests pin the shipped source, CI and Release run IDs, tag, version, checksum, and package facts; historical source was not rewritten. | closed |
| T-139-15 | Spoofing | active versus shipped status | medium | mitigate | Source assertions distinguish active v1.38/Phase 139 planning truth from shipped v1.37/1.5.0 release truth. | closed |
| T-139-16 | Elevation of privilege | prose release instructions | high | mitigate | Guidance and contract tests require push/dispatch separation, exact current-main input, canonical CI, and protected package-first ordering. | closed |
| T-139-17 | Information disclosure | supplemental OIDF evidence | medium | mitigate | Maintained prose and conformance contracts keep OIDF evidence redacted, supplemental, non-certifying, and outside the release gate. | closed |
| T-139-18 | Repudiation | selective prose reconciliation | low | accept | The plan enumerated the contradictions, the summary records the exact five-file scope, and focused source assertions cover the reconciled claims. Residual editorial omission risk is accepted. | closed |
| T-139-19 | Spoofing | stale inventory currentness | high | mitigate | The pre-verifier requires two complete agreeing observations, publishes one new ledger-only commit, and immediately proves the Phase 139 relation. | closed |
| T-139-20 | Tampering | ledger/history | critical | mitigate | Finalization requires a regular non-symlink target, a Git-common-dir lock, one exact staged path, no amend/force behavior, and immutable prior commits. | closed |
| T-139-21 | Repudiation | lifecycle authorization | high | mitigate | Relation validators require exact subjects, authors, path cardinality, bounded metadata, receipt hashes, and before/after Git identities. | closed |
| T-139-22 | Information disclosure | recollected evidence | high | mitigate | Phase 138 allowlists/redaction are reused and two normalized complete observations must agree before publication. | closed |
| T-139-23 | Denial of service | concurrent finalizer | medium | mitigate | A Git-common-dir lock, bounded children, signal-safe cleanup, and exact idempotent retry prevent overlapping or abandoned finalization. | closed |
| T-139-24 | Elevation of privilege | main/ref authorization | high | mitigate | The post-transition relation permits only paired fast-forward `main`/`origin/main` movement to the host-sealed candidate and rejects all other topology changes. | closed |
| T-139-25 | Spoofing | final main and workflow evidence | high | mitigate | Final acceptance binds the host-sealed SHA to HEAD, local and remote main, repository identity, and exact workflow/run metadata before and after checks. | closed |
| T-139-26 | Tampering | main ref landing | high | mitigate | Local main uses expected-old `git update-ref`; origin uses an exact non-force push followed by re-fetch, with ancestry, race, and concurrent-advance rejection. | closed |
| T-139-27 | Repudiation | final acceptance receipt | high | mitigate | The durable receipt records schema, SHA, run IDs/URLs, job outcomes, gates, WARN dispositions, historical chain, timestamp, and repository identity. | closed |
| T-139-28 | Information disclosure | live API/command output | high | mitigate | The finalizer validates and projects allowlisted fields, suppresses raw bodies/logs, and writes the receipt atomically with mode 0600 outside tracked history. | closed |
| T-139-29 | Denial of service | long CI/workflow wait | medium | mitigate | Inner polling is bounded to 1,800 seconds, the outer capability to 2,400 seconds, and pending-state recovery plus idempotent retry covers interruption. | closed |
| T-139-30 | Elevation of privilege | release publication | critical | mitigate | The finalizer has no dispatch/publish command, requires push-event no-publish evidence, and tests assert no release-owned mutation. | closed |
| T-139-31 | Tampering | self-invalidating receipt | high | mitigate | The receipt is written only under the resolved Git common directory after final ref/gate checks, and fixtures prove worktree, index, and HEAD remain unchanged. | closed |
| T-139-32 | Spoofing | capability/version/hook identity | high | mitigate | Tracked capability source, supported installation, active-version checks, exact ordered hooks, and sealed hook hashes bind installed execution. | closed |
| T-139-33 | Tampering | phase/mode child dispatch | critical | mitigate | The router validates the exact four-element argv, project root and child paths, uses a closed phase matrix, fixed arrays, and `shell: false`; route tests pass. | closed |
| T-139-34 | Repudiation | lifecycle ordering/recovery | high | mitigate | Real host-state tests bind counters, identities, hook hashes, pending state, and same-phase recovery, completing only after successful post-transition acceptance. | closed |
| T-139-35 | Information disclosure | router/finalizer diagnostics | medium | mitigate | Router errors are class-only, child output inherits the redacted finalizer stream, and child output is never parsed as routing authority. | closed |
| T-139-36 | Denial of service | long final acceptance and retry | medium | mitigate | The router applies the 2,400,000 ms outer deadline, children use bounded polling, failures retain distinct statuses, and pending recovery is idempotent. | closed |
| T-139-37 | Elevation of privilege | later-phase execution | high | mitigate | Strictly numeric phases other than 138/139 return inert success without spawning; malformed phases reject and Phase 140/141 fixtures prove isolation. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-139-01 | T-139-05 | Caller-bounded polling and stable run identity limit the impact; temporary GitHub latency remains an operational risk without weakening authority. | Phase 139 plan-time decision | 2026-09-13 |
| AR-139-02 | T-139-10 | The repair inventory and changed-file scope bound review cost; residual cleanup-size risk is low and non-security-authoritative. | Phase 139 plan-time decision | 2026-09-13 |
| AR-139-03 | T-139-SC | No package installation or dependency change was needed, so existing toolchain risk remains unchanged and is accepted for this phase. | Phase 139 plan-time decision | 2026-09-13 |
| AR-139-04 | T-139-18 | Enumerated contradiction coverage and exact changed-file evidence reduce selective-edit risk; residual editorial omission risk is accepted. | Phase 139 plan-time decision | 2026-09-13 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-13 | 38 | 38 | 0 | Codex secure-phase orchestrator (ASVS L1 plan-register verification) |

### Security Audit 2026-09-13

| Metric | Count |
|--------|-------|
| Threats found | 38 |
| Closed | 38 |
| Open | 0 |

The register was authored at plan time. Phase summaries reported no additional threat flags, and source-level inspection found each mitigation or bounded accepted-risk control in the planned implementation and proof files. With `asvs_level: 1` and `threats_open: 0`, the secure-phase workflow's L1 short-circuit applied; no deeper boundary-placement or end-to-end auditor pass was required.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-13
