---
phase: 138
slug: baseline-inventory-evidence-taxonomy
status: verified
threats_open: 0
asvs_level: 1
block_on: high
created: 2026-09-10
---

# Phase 138 — Security

> Verification of the authored STRIDE register for the completed baseline-inventory gap closure.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Git repository → collector | Local and remote refs, linked worktrees, commit history, and paths enter the inventory process | Untrusted names, legal delimiter bytes, object IDs, lifecycle commits |
| GitHub GraphQL → collector | Authenticated paginated pull-request, check, and issue observations enter evidence generation | Remote titles, URLs, identities, cursors, completeness receipts |
| Maintained records → collector | Active planning and maintenance records enter the durable taxonomy | Paths, subjects, dispositions, archive summaries |
| Canonical identity → rendered output | Exact internal identities are converted into Markdown, YAML, receipts, limitations, and diagnostics | Potential credential material and hostile display content |
| Caller → publication target | CLI arguments identify the durable ledger target and replacement policy | Relative/absolute paths, lock state, file identity |
| Planning lifecycle → relation verifier | Post-publication commits are classified as authorized bookkeeping or unknown mutation | Summary frontmatter, ROADMAP, STATE, state.json, changed-path cardinality |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-138-108 | Tampering | worktree row transport | high | mitigate | NUL porcelain ingestion, structured JSON records, schema validation, partial-on-malformed behavior, and real tab/newline fixtures | closed |
| T-138-109 | Tampering / Elevation of privilege | relative replacement target | high | mitigate | Capture caller cwd before repository `cd`; retain one canonical target through locking and no-follow atomic replacement | closed |
| T-138-110 | Denial of service / Repudiation | dependency preflight | medium | mitigate | Preflight `git`, `python3`, and `jq` before relation or collection work; assert no source work when missing | closed |
| T-138-111 | Information disclosure | path rendering | high | mitigate | Compute exact path identity before centralized final-boundary normalization and redaction | closed |
| T-138-112 | Spoofing | external fingerprint verification | critical | mitigate | Re-observe GitHub and maintained sources; production has no caller-supplied fingerprint override | closed |
| T-138-113 | Tampering | closeout summary metadata | high | mitigate | Parse one bounded frontmatter block with exact key cardinality and exact five-requirement membership | closed |
| T-138-114 | Elevation of privilege | ROADMAP/STATE classifier | high | mitigate | Require exact ROADMAP, STATE, and state.json transition plus exact total diff cardinality | closed |
| T-138-115 | Repudiation | currentness verdict | high | mitigate | Any live receipt mismatch, unavailability, or unknown lifecycle commit yields nonzero `refresh_required` | closed |
| T-138-116 | Information disclosure | rendered source fields | critical | mitigate | One credential predicate protects Markdown, YAML, receipts, limitations, URLs, and diagnostics | closed |
| T-138-117 | Tampering | redaction/dedup ordering | high | mitigate | Generate stable IDs from canonical values before display rendering; assert distinct redacted secrets retain distinct IDs | closed |
| T-138-118 | Denial of service | opaque-secret false positives | medium | mitigate | Bound opaque detection and pin benign SHAs, IDs, UUIDs, versions, URLs, release names, and prose | closed |
| T-138-119 | Repudiation | redacted source completeness | high | mitigate | Unsafe or malformed structured evidence becomes partial and cannot retain a complete aggregate | closed |
| T-138-120 | Tampering / Repudiation | clean-base collection | high | mitigate | Publish from the corrected committed base with one parent and one canonical changed path; verify relation integrity | closed |
| T-138-121 | Spoofing | external currentness | critical | mitigate | Production relation re-observes live external sources without fingerprint injection | closed |
| T-138-122 | Information disclosure | ledger and diagnostics | critical | mitigate | Central redaction plus cross-domain credential matrix and canonical-ledger raw-shape scan | closed |
| T-138-123 | Elevation of privilege | lifecycle/disposition authority | high | mitigate | Exact semantic lifecycle validators reject unknown/surplus mutations; rendered rows remain proposal-only | closed |
| T-138-124 | Tampering | publication target/relation | high | mitigate | Canonical absolute target, lock ownership, identity recheck, no-follow opens, atomic replace, and immutable one-parent/one-path publication | closed |

*Status: open · closed · open below threshold (non-blocking).*

---

## OWASP ASVS Level 1 Coverage

- **V2 Authentication:** authenticated live GitHub collection and removal of caller-supplied receipt authority.
- **V4 Access Control:** exact lifecycle allowlists, bounded bookkeeping transitions, and proposal-only disposition authority.
- **V5 Validation, Sanitization and Encoding:** structured worktree transport, canonical target validation, safe Markdown/YAML encoding, and centralized credential redaction.
- **V7 Error Handling and Logging:** named fail-closed diagnostics, partial/unavailable receipts, redacted diagnostics, and `refresh_required` on uncertainty.

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-10 | 17 | 17 | 0 | gsd-security-auditor |
| 2026-09-12 | 17 | 17 | 0 | execute-phase ASVS L1 short-circuit |
| 2026-09-24 | 17 | 17 | 0 | verify-work ASVS L1 short-circuit |

Plan 138-34 changed coverage metadata, the release-hygiene CI projection, the
derived UAT receipt, and semantic test-fixture labels. It introduced no new
trust boundary or runtime authority. Because the phase has an authored threat
register, `threats_open: 0`, and configured ASVS level 1, the secure-phase
contract accepts the existing verified mitigations without a deeper auditor
dispatch.

### Fresh verification evidence

- Five-tag adversarial suite: exit 0; 5 tests, 0 failures, 28 excluded; 135.2 seconds.
- Shell syntax: `bash -n scripts/maintainer/baseline_inventory.sh` exited 0.
- Legacy fingerprint-hook scan: no matches.
- API coverage: 8/8 integrated, 0 opt-outs, `block: false`.
- Canonical-ledger credential scan: no AWS, Slack, JWT, PEM, bearer, or GitHub credential shapes found.
- Publication commit `891fe796e86a9e803669cc977e96cbeccf6f34aa` has parent `37b08394fbcec49ed92d527a3bad583dedd7283d`, changes only the canonical ledger, and retains blob `e7f91f16538131606bb925f394432a8aa5b80702` with SHA-256 `f0cc1e32a8aef0b2770d63dc828c5ca96dd586b53adc6b98080d6b5b73d384c0`.

### Current relation caveat

The production relation correctly fails closed at the audit-time HEAD because later commit `d78a6a9b` changes only `138-VALIDATION.md` and is not a recognized lifecycle class. The ledger publication and Plan 138-29 closeout remain authorized, the working tree is clean, and the later validation commit is classified `unknown`, so the overall result is `refresh_required`. This is not an open registered mitigation or unsafe authorization; it is an operational currentness blocker for final phase verification.

---

## Sign-Off

- [x] All threats have a disposition.
- [x] No accepted risks require documentation.
- [x] `threats_open: 0` confirmed at the configured `high` threshold.
- [x] `status: verified` set in frontmatter.

**Approval:** verified 2026-09-10


### Verify-work post-hook audit — 2026-09-24

The authored 17-threat register remains closed at ASVS L1. Phase 138 Plan 34 changes only coverage metadata, UAT evidence, workflow CI ownership, and semantic fixture labels; it does not introduce a new trust boundary. The existing operational currentness caveat remains documented above: a later validation bookkeeping commit is classified as unknown by the production relation, so this security result does not refresh canonical phase verification.
