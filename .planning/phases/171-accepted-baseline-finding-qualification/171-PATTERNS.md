# Phase 171: Accepted Baseline & Finding Qualification - Pattern Map

**Mapped:** 2026-10-24
**Files analyzed:** 4 proposed durable evidence artifacts (names to be finalized by planner)
**Analogs found:** 4 / 4 (two partial document patterns; existing acceptance/conformance authorities are exact)

## Scope and Authority

This is a maintainer evidence phase. It adds no OAuth implementation, new acceptance gate, or general evidence framework. Before this phase, use the reviewed prior-delivery reconciliation to resolve ownership; then the existing `repo_hygiene_check.sh --accept-sha` is the sole accepted-main authority. Conformance receipts are supplemental and the finite ledger/matrix is the case-level decision record. Keep provider/package source identity in the ledger because the current receipt schema does not carry it.

## File Classification

| Proposed artifact | Role | Data flow | Closest tracked analog | Match |
|---|---|---|---|---|
| Prior-delivery / edit / worktree ownership reconciliation (phase artifact; exact filename TBD) | evidence ledger | batch, file-I/O | `.planning/milestones/v1.38-phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` | partial |
| Fresh accepted-main receipt (stdout JSON from existing command; retain with phase evidence if appropriate) | tool receipt | request-response | `scripts/maintainer/repo_hygiene_check.sh`; `.planning/REPO-HYGIENE-CHECKLIST.md` | exact |
| Selected-profile redacted receipt (only if profiles are actually executed) | tool receipt | batch, file-I/O | `scripts/conformance/build_redacted_evidence.py` | exact |
| Canonical finite finding ledger with frozen downstream case matrix (one phase artifact; exact filename TBD) | evidence/decision ledger | batch, transform | `.planning/research/v1.47-core-hardening/INTEROPERABILITY.md`; `.planning/milestones/v1.38-phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` | partial |

The analog paths above are tracked source (`git ls-files` checked); no ignored mirror paths are referenced. `171-VALIDATION.md` seeds the appropriate existing focused contract commands and makes the fresh receipts explicitly outstanding.

## Pattern Assignments

### Prior-delivery / ownership reconciliation (phase artifact)

**Analog:** the baseline inventory snapshot above, especially its provenance and row schema (`baseline-inventory-2026-08-28.md:1-40`). It anchors an observation with source scope, evidence-base SHA, collection time, completeness/limitation, stable IDs, evidence reference, proposed disposition, rationale, confidence, recheck proof, required authority, and whether action occurred.

**Reuse:** keep the reconciliation an observed, reviewable snapshot. Identify each commit/change/worktree/edit, owner, purpose, hashes or snapshot reference, disposition, and unresolved ownership explicitly. Preserve unknowns as blockers; a clean checkout does not establish ownership history. Treat dispositions as review proposals until the responsible maintainer confirms them. The inventory ledger is a format analogy, not an authority to clean, delete, or accept delivery.

### Fresh accepted-main receipt

**Analog:** `scripts/maintainer/repo_hygiene_check.sh` plus `.planning/REPO-HYGIENE-CHECKLIST.md:18-21`.

```bash
bash scripts/maintainer/repo_hygiene_check.sh \
  --accept-sha <40-lowercase-hex-current-main-sha> --format json
```

The script's CLI documents `--accept-sha` as proving local and GitHub acceptance for one synchronized `main` SHA (`repo_hygiene_check.sh:17-40`); its exact-mode validation requires lowercase full 40-hex SHA (`:143-150`). The checklist requires that SHA to match `HEAD`, local `main`, and refreshed `origin/main` before and after gates, plus exact-SHA canonical CI and Release no-publish evidence; every WARN needs a disposition, and no warnings serialize as `"warn_dispositions": []` (`.planning/REPO-HYGIENE-CHECKLIST.md:18-21`).

**Reuse:** record the actual command, supplied SHA, exit status, and unmodified JSON receipt. Run only after separate reconciliation review. Do not mint a second acceptance script, infer evidence from a green branch, or treat historical baseline prose as a receipt. Do not execute this gate during planning/mapping.

### Immutable conformance inputs and redacted receipts

**Analogs:** `scripts/conformance/oidf_inputs.py`, `scripts/conformance/oidf-suite-lock.json`, `scripts/conformance/phase37-plan.json`, `scripts/conformance/fapi2-plan.json`, and `scripts/conformance/build_redacted_evidence.py`.

The validator fixes the suite commit/tag and requires exact lock schema, pinned helpers and image digests (`oidf_inputs.py:11-32,65-94`). Receipt construction allows only bounded statuses/classifications and emits suite identity, input hashes, plan filename/checksum, runtime, result names and timestamps; a forbidden-content check rejects secrets, URLs and raw-log references (`build_redacted_evidence.py:13-16,26-55`). The maintainer contract states raw work/config/logs stay temporary, while durable receipts are allowlisted and bounded (`docs/maintainer-conformance.md:85-99,125-143`).

**Reuse:** preserve exact provider/package source identity separately in the case ledger (the existing suite receipt does not bind it). Keep historical suite, plan and image/helper identities distinct from any reviewed lock refresh. Never put provider configuration, tokens, personal data, raw assertion dumps or browser logs in durable evidence. `integration_only` is not a conformance pass; `success` remains supplemental/non-certifying. Preflight command: `mix lockspire.oidf_conformance --check`; optional execution commands are documented in `docs/maintainer-conformance.md:45-99` and should only be used after acceptance and disposable-host acknowledgement.

### Finite finding ledger and downstream case matrix

**Analogs:** `.planning/research/v1.47-core-hardening/INTEROPERABILITY.md:25-54,73-87` for separating facts, inference and proposals and for bounded decisions; `baseline-inventory-2026-08-28.md:22-40` for stable IDs, evidence references, disposition, rationale, confidence and recheck proof.

**Reuse:** maintain one canonical human-readable artifact with stable case IDs. For each selected case carry source/date and exact run/provider identity; supported surface; safe module/condition; normative and support reference; observed and expected outcomes; cause class; deterministic repo-native repro command/test owner; exclusions/disposition; and verification identity. Mark unavailable historical assertion detail as unavailable; do not reconstruct it from coarse `suite_failure` summaries. Freeze the downstream matrix before Phases 172–174 plans, and if qualification removes the corrective premise, explicitly narrow/replan requirements and roadmap.

Existing proof owners to map into case rows rather than duplicate: `test/integration/phase37_protocol_strictness_e2e_test.exs` (redirect-safe errors, silent auth, `auth_time`); `test/lockspire/web/authorize_controller_test.exs` (callback safety and PAR browser-boundary failures); `test/lockspire/protocol/pushed_authorization_request_test.exs` and `test/integration/phase15_par_authorization_e2e_test.exs` (PAR expiry, binding, replay, required-PAR). The research records specific line ranges and expected behaviors; map only applicable rows.

## Existing Contract Checks

Use the current tests as artifact/tool contract coverage; do not introduce a second conformance framework:

```bash
mix test test/lockspire/release/repository_hygiene_contract_test.exs
mix test test/lockspire/conformance_immutable_inputs_contract_test.exs \
  test/lockspire/conformance_profile_execution_test.exs \
  test/mix/tasks/lockspire/oidf_conformance_test.exs
python3 scripts/conformance/oidf_inputs.py \
  --lock scripts/conformance/oidf-suite-lock.json --validate-only
```

The planning validation seed at `171-VALIDATION.md:36-46,53` already distinguishes contract checks from fresh external receipts. The ledger/matrix consistency check is the one genuine gap; define the smallest check that verifies stable IDs, required fields, references between ledger and matrix, and no duplicate or orphan rows. No external/runtime profile was run for this mapping.

## No Direct Analog

No tracked artifact can establish the case-level cause of the old Phase 137 findings: `INTEROPERABILITY.md:22,29-34` says retained evidence has no raw per-module assertions. Use it as a fact/inference/proposal document pattern only; classify unknown historical detail honestly and require fresh exact-input observations or deterministic repo-native proof.

## Shared Patterns

- **One existing acceptance authority:** exact main SHA plus local and canonical hosted evidence comes only from `repo_hygiene_check.sh`; ownership reconciliation is a prerequisite, not a parallel acceptance verdict.
- **Immutable experiment identity:** checked-in lock + selected plan checksum + digested images/helpers; any input update is a separately reviewed experiment.
- **Evidence minimization:** retain allowlisted receipts and short factual ledger entries; raw diagnostics remain ephemeral.
- **Cause before correction:** separate protocol assertion, harness/origin/TLS/browser, infrastructure, unsupported profile, and already-correct/not-reproduced. External suite labels are run classifications, not per-case diagnoses.

## Metadata

**Analog search scope:** repository hygiene gate/checklist and tests; conformance lock, plans, receipt builder/docs and contracts; tracked v1.38 inventory evidence; v1.47 interoperability research.
**Files scanned:** 10 principal analog files plus phase research/validation.
**Pattern extraction date:** 2026-10-24
