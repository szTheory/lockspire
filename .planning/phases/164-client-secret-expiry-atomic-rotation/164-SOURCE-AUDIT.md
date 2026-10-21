# Phase 164 Source Audit

Planning only. Six plans, eighteen tasks, five waves. No runtime evidence is claimed here. Source authority is 164-CONTEXT and its canonical references, the Phase 162 contract/cases, Phase 163 verified foundations and current tracked source. DISCUSSION-LOG was excluded.

## Dependency and ownership audit

| Plan | Wave | Needs | Creates / expands |
|---|---:|---|---|
| 164-01 | 1 | Phase 163 schema/adapter, supplied runtime, PostgreSQL | Real finite DCR → stored deadline → wire → Basic tracer; bounded policy and metadata cases |
| 164-02 | 2 | 164-01 shared secret helpers | Every auth method, final code/refresh authority and endpoint mappings |
| 164-03 | 2 | 164-01 deadline/promotion helpers | Current-row operator rotation, declared adapter clock transport, conformance/rollback |
| 164-04 | 3 | 164-02 and 164-03 | Authenticated device/CIBA/RFC finalizers and existing-token/queued exemptions |
| 164-05 | 4 | 164-04 (transitively both wave-2 plans) | Independent-session blocker and competing-rotation evidence |
| 164-06 | 5 | 164-05 | Observed-event redaction, truthful docs/copy, complete gate ledger |

Wave 2 has zero files_modified overlap. Both plans use separate VM configuration and rollback-isolated sandbox fixtures with unique clients; neither resets the database or runs committed independent-session races. Any shared singleton fixture writes remain transactional and bounded. Independent committed-session work is serialized into wave 4. Each task modifies at most five declared files; each plan has three tasks. The tracer is the phase's first task; later tasks expand its production path. No strict phase-wide TDD mode is asserted.

Estimate calibration: factor 0.5, sample_count 6, confidence high, clamped true. Raw projections include source reads, implementation and focused verification; estimates multiply raw by 0.5. Reversibility: stored/wire deadline format is a settled one-way decision from D-01/D-04 and Phase 162; no new checkpoint is needed. Adapter transport is costly and preserves existing exported arities. Other local helpers/tests/copy are reversible.

## Multi-source coverage

| Source | ID | Required outcome/constraint | Plans/tasks | Status |
|---|---|---|---|---|
| GOAL | 164 | Apps rely on matching shared-secret metadata, authentication and rotation | 01–06 | COVERED |
| GOAL | SC-1 | Stored/advertised unset/zero/positive/no-secret truth | 01-01/02/03, 03-01/02 | COVERED |
| GOAL | SC-2 | Three methods and independent JWT timing/replay | 02-01/02/03, 04-01/02 | COVERED |
| GOAL | SC-3 | Atomic current-policy rotation, old use, races, rollback | 03-01/02/03, 05-01/02/03 | COVERED |
| REQ | DCR-07 | Effective issuance and metadata | 01, 03, 06 | COVERED |
| REQ | DCR-08 | Authentication and independent assertions | 01, 02, 04, 05, 06 | COVERED |
| REQ | DCR-09 | Atomic operator replacement | 03, 05, 06 | COVERED |
| RESEARCH | R-01 | Existing Elixir/Ecto/PostgreSQL stack; no new packages/schema | all plans | COVERED |
| RESEARCH | R-02 | Shared domain eligibility/effective-deadline and whole-second clocks | 01-01, 02-01/02 | COVERED |
| RESEARCH | R-03 | Validate original secret policy values at write/use/form boundaries | 01-02, 03-01 | COVERED |
| RESEARCH | R-04 | Version/method/provenance-aware shared serializer | 01-01/03 | COVERED |
| RESEARCH | R-05 | Current fingerprint, post-last-lock time, no second JTI consumption | 02-02, 04-01/02, 05-01/02 | COVERED |
| RESEARCH | R-06 | Code/refresh/device/CIBA/RFC requesting-client inventory | 02-02, 04-01/02, 05-02 | COVERED |
| RESEARCH | R-07 | Token issuer/online target/queued work remain secret-independent | 04-01/02/03 | COVERED |
| RESEARCH | R-08 | Post-lock current-row policy/time, existing transaction/audit wrapper | 03-01, 05-03 | COVERED |
| RESEARCH | R-09 | Whole-row legacy normalization and v1 unrelated preservation | 03-02, 05-03 | COVERED |
| RESEARCH | R-10 | Declared adapter/shared transaction conformance; no runtime probing | 03-02, 06-03 | COVERED |
| RESEARCH | R-11 | Real independent sessions, pg_blocking_pids and barrier clocks | 05-01/02/03 | COVERED |
| RESEARCH | R-12 | Real write/audit rollback with full durable comparisons | 03-03, 05-03 | COVERED |
| RESEARCH | R-13 | Nonempty actual finite-secret redaction evidence | 06-01 | COVERED |
| RESEARCH | R-14 | Dedicated database, setup, focused tests, full suite and separate races | 01-01, all verifies, 06-03 | COVERED |
| RESEARCH | R-15 | Accurate changed guidance and PRODUCT contracts | 06-02/03 | COVERED |
| CONTEXT | D-01 | Nil/zero unlimited; finite issuance snapshot; current replacement policy | 01-01/02/03, 03-01 | COVERED |
| CONTEXT | D-02 | Bounded policy and configuration/server errors | 01-02, 02-01/02/03, 03-01 | COVERED |
| CONTEXT | D-03 | Current self-registration provenance controls DCR defaults | 01-01/03, 03-01/03, 05-03 | COVERED |
| CONTEXT | D-04 | Effective Unix/zero/method-aware metadata and plaintext omission | 01-01/03 | COVERED |
| CONTEXT | D-05 | Same strict three-method gate, generic endpoint errors | 01-01, 02-01/03 | COVERED |
| CONTEXT | D-06 | Current identity/time after every required blocking lock | 02-02, 04-01/02, 05-01/02 | COVERED |
| CONTEXT | D-07 | Independent assertions; final JTI not consumed again; remote work outside locks | 02-01/02, 04-01/02, 05-01/02 | COVERED |
| CONTEXT | D-08 | Token validity/issuer/target/queued work stay independent | 02-02, 04-01/02/03 | COVERED |
| CONTEXT | D-09 | All non-secret methods unaffected including dormant material | 01-03, 02-01, 04-03 | COVERED |
| CONTEXT | D-10 | Material/time/deadline/version/audit atomic, no success on failure | 03-01/03, 05-03 | COVERED |
| CONTEXT | D-11 | All old dates canonicalized; authoritative unrelated dates preserved | 01-03, 03-02, 05-03 | COVERED |
| CONTEXT | D-12 | No old proof, app renewal or CAS; serialized final winner | 03-03, 05-03 | COVERED |
| CONTEXT | D-13 | Existing dormant confidential rotation remains supported | 03-03 | COVERED |
| CONTEXT | D-14 | Existing declared adapter/transaction authority; bounded compatibility | 03-02, 06-03 | COVERED |
| CONTEXT | D-15 | Full boundary/value/method/JWT/token matrix per slice | 01–04, 06 | COVERED |
| CONTEXT | D-16 | Actual blocker races and durable rollback | 05-01/02/03 | COVERED |
| CONTEXT | D-17 | Observed nonempty events, no material disclosure | 03-01/03, 06-01 | COVERED |
| CONTEXT | D-18 | Accurate changed docs/copy, PRODUCT vocabulary, preserved host scope | 06-02/03 | COVERED |

All 18 decisions are additionally cited in must_haves.truths and task bodies. No missing source items. Architectural responsibility map is honored: protocol/domain owns eligibility/policy decisions, storage owns current-row/transaction authority, serializer owns wire shape, existing host authorization owns operator access.

Exclusions: management-token lifetime/recovery (165), final packaged cross-phase/CI proof (166), dedicated verifier KEK (SEC-01), overlap, app renewal, zero-downtime bridge, migration/framework/dependencies and new operator concurrency policy. Research's open-question suggestion to add management-duration validation is outside this phase, not authorization. The existing form's bounds are tested; no management enforcement is added.

Source inventory also proves client_credentials is already unsupported in TokenExchange.exchange/1. The dispatcher regression preserves unsupported_grant_type; no invented grant is planned.

## Flagged unresolved edge assumptions

Source: /private/tmp/lockspire164-edge-report.json. Exactly three probe items; 0 resolved, 3 unresolved/unclassified. Preserve that status; do not auto-resolve/backstop or silently drop them.

| ID | Requirement | Status | Explicit treatment |
|---|---|---|---|
| EDGE-DCR-07 | DCR-07 | FLAGGED unresolved/unclassified | must_haves.assumptions in 164-01; concrete source-derived issuance/metadata cases in 01 |
| EDGE-DCR-08 | DCR-08 | FLAGGED unresolved/unclassified | must_haves.assumptions in 164-02; concrete method/final-guard cases in 02/04/05 |
| EDGE-DCR-09 | DCR-09 | FLAGGED unresolved/unclassified | must_haves.assumptions in 164-03; concrete current-row/atomicity/race cases in 03/05 |

These are classifier incompleteness flags, not invented policy choices. Requirements and locked context supply executable behavioral coverage. Probe equality: 3 surfaced = 3 authored flagged assumptions + 0 resolved edges.

## Prohibition recall and precision

Performed per specless-probe-fallback.md and prohibition-probe.md. Raw adversarial candidates:

- DCR-07: forced finite default, zero-as-immediate, legacy rejection, raw advisory wire date, policy-edit retroactivity, direct-policy leakage, dormant metadata, plaintext reads, wrong precision, new migration.
- DCR-08: one-method bypass, skew grace, stale verification, early clock, replay weakening, repeated JTI, issuer-secret gate, token revocation, non-secret gate, expiry disclosure.
- DCR-09: split material/date commit, partial audit, old overlap, stale-row restore, app renewal, proof-of-old-secret requirement, new CAS error, dormant prohibition, policy snapshot, successful failed-write handoff.

Precision drops routine correctness/security hygiene to behavioral tests and the STRIDE register; bespoke product-boundary candidates are already explicit locked decisions, not new omitted prohibitions. Credential disclosure/replay/input-validation canon → existing threat model plus independent secure-phase audit; no duplicate values prohibition is minted. No newly kept prohibition remains: 0 kept = 0 must_haves.prohibitions items + 0 unresolved prohibition flags. No fabricated mechanical check descriptors or silent automatic dismissals.

## Detector decisions

API coverage detector ran against complete 164-CONTEXT + 164-RESEARCH scope: detected false, signals []. No external API/SDK/service integration is introduced. Existing OAuth provider endpoints, PostgreSQL and pre-existing CIBA transport are internal changed surfaces, not a new vendor integration. See 164-COVERAGE.md.

Assumption-delta detector ran on the same scope: detected true; signals second, alongside, fallback, optional, custom. Decision: retain the existing single lifetime-aware adapter/transaction identity model. Seconds are duration units; fallback is the bug being removed; RFC optional JTI does not change Lockspire's stricter required replay policy; custom means the existing explicitly declared adapter. D-01/D-07/D-14 and Phase 163 resolve these semantics. No new product-shaping choice or identity model is introduced.

Graph lookup reports disabled; no graph context assumed. Project skill directories are absent; configured gsd-planner skills are empty. Prior relevant summaries: 163-06 (post-code-lock clock/current fingerprint), 163-12 (independent blockers/rollback); Phase 162 contract/cases and Phase 163 verification supply prior foundations.

## New symbol inventory

Planned, not yet implemented:

| Symbol | Owner | Compatibility |
|---|---|---|
| Client.secret_eligibility/3 | 164-01-01 | New ordinary domain helper |
| Client.effective_secret_deadline/1 | 164-01-01 | New domain representation helper |
| Client.secret_deadline/3 | 164-01-01 | New pure provenance/method-aware issuance calculation |
| GrantPersistence.validate_current_authority/4 | 164-02-02 | Internal helper; preserves existing validate_current_client/3 |
| issuance-context authentication_authority | 164-04-01 | Internal trusted entry-point value; no public struct/arity change |
| Existing rotate_client_secret/4 clock-function input variant | 164-03-01/02 | Existing DateTime callers retained; declaration/conformance tested, no new arity |
| Focused test modules named in each files list | 01–05 | Test-only; created before their commands run |

Any unavoidable extra public symbol must be explicitly listed and checked against the literal compatibility contract; no blanket manifest loosening.

## Verification limits

Revision round 1 addressed exactly two checker blockers in 164-06-03: the focused guidance/architecture/compatibility command and normal mix test.fast now each have an immediate command-specific fails_when sibling covering nonzero exit, zero executed tests and selection failures. Commands, tasks, waves, scope and locked decisions are unchanged. Fresh `check verify-failure-directions 164 --raw` passed all 20 commands with 0 blockers and 0 warnings. The directory-path invocation returned unresolvable (exit 69); the successful rerun used the required phase token 164, so no pass was inferred from that failed invocation. Fresh 164-06 frontmatter and structure checks passed with no warnings, decision coverage remains 18/18, and the closing output tag is present. No implementation tests were run by this revision.

Fresh planning validation: frontmatter.validate --schema plan and verify.plan-structure both passed for all six plans (18 tasks). Decision coverage passed 18/18 with no uncovered decisions. Path/task/wave audit found zero missing input/verify paths (new test files are declared task outputs), zero task file counts above five, zero same-wave file overlaps and zero duplicate numeric threat IDs. All six files end in </output> with no continuation sentinel. git diff --check passed. state.json byte comparison with the preserved original passed. The structure checker emits one expected warning for the settled one-way deadline choice; the task rationale cites D-01/D-04 and Phase 162, so no new checkpoint is inserted. These are planning checks, not implementation test results.

Planning validators establish prompt structure/coverage, not runtime correctness. Executors create the named new test files. Setup uses the fresh dedicated database; no default DB is permitted. Normal mix test.fast and explicit postgres_race selection are both required. Keep prior 398 exclusions/6 skips visible; actual new counts must be recorded. Existing heavy packaged upgrade proof is not rerun unless schema/install/package inputs change. State cache must remain byte-identical to /private/tmp/lockspire-v145-original-state.json and must never be staged.

