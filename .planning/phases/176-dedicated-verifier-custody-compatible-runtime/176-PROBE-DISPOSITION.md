# Phase 176 — Source and Probe Disposition

Planning only, 2026-10-25. No runtime test result is claimed. No SPEC exists; spec-less fallback used the exact seven assigned requirements and `/tmp/lockspire-176-edge-probe.json` (15 proposed edges, three unclassified). All surfaced items are preserved below and lifted into plan must_haves.

## Edge disposition

| ID | Requirement/category | Disposition and explicit acceptance | Plan truth / task |
|---|---|---|---|
| E01 | SEC-01/concurrency | resolved, explicit: immutable node context survives concurrent reads/env changes until restart/redeploy | 02 / 02-01 |
| E02 | SEC-02/unclassified | **unresolved, flagged**; classification absent; no automatic dismissal or probe pass | 02 / 02-02 |
| E03 | SEC-03/empty | resolved, explicit: missing/empty identity or native secret rejects; malformed/null envelope rejects; legacy seal inputs unchanged | 01 / 01-02 |
| E04 | SEC-03/encoding | resolved, explicit: byte_size caps, canonical text, exact UTF-8 identity bytes, no normalization | 01 / 01-02 |
| E05 | SEC-04/adjacency | resolved, explicit: byte-distinct/equivalent-looking IDs do not share an AAD identity | 03 / 03-02 |
| E06 | SEC-04/empty | resolved, explicit: dedicated identity missing/empty fails before client persistence | 03 / 03-01,03-02 |
| E07 | SEC-04/ordering | resolved, explicit: final canonical ID precedes sealing and equals persisted ID | 03,05 / writer tasks |
| E08 | SEC-04/idempotency | resolved, explicit: generation yields new credentials; duplicate-ID registration does not overwrite an existing pair | 03 / 03-01,03-02 |
| E09 | SEC-04/concurrency | resolved, explicit: existing selected locked/transactional writer authority remains; rollback cannot leave half a pair | 05 / 05-02 |
| E10 | SEC-05/adjacency | resolved, explicit: exact identity/audience matching, no normalization or endpoint-audience substitution | 06 / 06-01 |
| E11 | SEC-05/empty | resolved, explicit: absent/empty verifier is missing; malformed is unavailable; required claims/JTI cannot be empty | 06 / 06-01 |
| E12 | SEC-05/ordering | resolved, explicit: preserve assertion/replay then lifecycle/guard ordering and consumed JTI | 06 / 06-02 |
| E13 | SEC-05/concurrency | resolved, explicit: ciphertext-only change rejects guarded issuance and no successful token/grant effect follows | 06 / 06-02 |
| E14 | VUP-01/unclassified | **unresolved, flagged**; detailed frozen age acceptance is planned, but cannot convert an unclassified probe into a pass | 04 / 04-02 |
| E15 | VUP-02/unclassified | **unresolved, flagged**; local rollout acceptance does not resolve the missing classification | 07 / 07-01 |

Conservation: 15 surfaced = 12 resolved with explicit acceptance + 3 flagged unresolved; zero dismissed, zero fabricated backstops. Every resolved criterion appears in a plain must_haves truth; each unclassified item has an explicit flagged truth.

## Prohibition recall and precision

Recall considered, across the seven requirements: centralizing host custody; implicit activation; misleading fleet-readiness claims; accidental partner rotation; deadline reset; widened auth/profile support; widened store support; boot-wide outage; malformed-input downgrade; secret disclosure. The last three are routine/security canon and are routed to the STRIDE tasks and `$gsd-secure-phase`, not minted as values prohibitions. Implicit activation is ordinary explicit state acceptance. Scope variants are grouped with host ownership; credential authority variants are grouped with partner control.

Three bespoke survivors are projected through `projectProhibitions` into 176-07 must_haves.prohibitions: truthful operational authority; no silent partner authority/credential changes; preserve host ownership and bounded support. All have lifecycle `unresolved`, no verification/check descriptor, and downstream disposition **unverified, flagged**. No wired enforcement or authoritative judgment is invented. Their presence does not silently become a green probe result.

## Dependency graph and ownership

| Wave | Plans | Needs / creates |
|---|---|---|
| 1 | 01 | Frozen contract → complete explicit context, native envelope, persisted authentication tracer, strict parser |
| 2 | 02 | 01 → immutable node snapshot, default reader integration and operation-local invalid state |
| 3 | 03,04 | 02 → helpers/direct writer (03); disjoint legacy/native/migrated age expansion (04) |
| 4 | 05,06 | 03 → DCR/operator writers (05); 03+04 → endpoint/guard acceptance (06) |
| 5 | 07 | 05+06 → real local rollout, linked runtime guide and existing full candidate gate |

Same-wave files are disjoint. Every task has at most four modified files; plans have two tasks. Calibration: factor 0.5, sample_count 10, confidence high. Estimates include implementation, canonical reads and verification; raw estimates are not post-calibration numbers. No external setup, new package, schema, toolchain or signing-format change is planned.

## Four-source coverage audit

| Source | Item | Plan/task | Status |
|---|---|---|---|
| GOAL | Independent keys across existing create/rotate/auth, legacy policy and reader-first rollout | 01–07 | COVERED |
| REQ | SEC-01 | 01,02,03,05,07 | COVERED |
| REQ | SEC-02 | 01,02,03,05,07 | COVERED |
| REQ | SEC-03 | 01,04,06,07 | COVERED |
| REQ | SEC-04 | 03,05,07 | COVERED |
| REQ | SEC-05 | 01,04,06,07 | COVERED |
| REQ | VUP-01 | 04,06,07 | COVERED |
| REQ | VUP-02 | 02,07 | COVERED |
| RESEARCH | Narrow OTP crypto/context boundary and tier map | 01,02,04 | COVERED |
| RESEARCH | Exact parser/AAD/limits/no downgrade/signing unchanged | 01-02 | COVERED |
| RESEARCH | Fallible generation with frozen helper success contracts | 03-01 | COVERED |
| RESEARCH | All final-ID writers and existing store/audit authority | 03-02,05 | COVERED |
| RESEARCH | Native/migrated finite age, authenticated safe legacy metadata | 04 | COVERED |
| RESEARCH | Existing endpoint support, claim/replay/lifecycle/fingerprint checks | 06 | COVERED |
| RESEARCH | Local staged rollout; host-owned fleet preconditions | 07-01 | COVERED |
| RESEARCH | New tests; immutable qualification and redaction from introduction | 01–07 | COVERED |
| CONTEXT | D-01 independent exact key setting/reuse | 01-01,02-02 | COVERED |
| CONTEXT | D-02 explicit four states | 02,07-01 | COVERED |
| CONTEXT | D-03 immutable/invalid-present/complete override | 01-01,02 | COVERED |
| CONTEXT | D-04 exact envelope/AAD/strict lengths | 01,04-01 | COVERED |
| CONTEXT | D-05 final-ID coherent writers | 03-02,05 | COVERED |
| CONTEXT | D-06 helper success and typed failure | 03-01,05 | COVERED |
| CONTEXT | D-07 explicit legacy integration/narrow modules | 01,02,03,05 | COVERED |
| CONTEXT | D-08 approved native age | 04 | COVERED |
| CONTEXT | D-09 migrated original deadline and rejection | 04 | COVERED |
| CONTEXT | D-10 unsupported/unchanged inputs and readiness hash check | 04 | COVERED |
| CONTEXT | D-11 shipped five-positive endpoint matrix, PAR/FAPI exclusions | 06 | COVERED |
| CONTEXT | D-12 protocol/lifecycle/error mapping | 01,04,06 | COVERED |
| CONTEXT | D-13 ciphertext fingerprint and fresh-JTI retry | 06-02 | COVERED |
| CONTEXT | D-14 staged writes/rollback limits | 07-01 | COVERED |
| CONTEXT | D-15 stable IDs, immutable evidence, redaction | 01–07,07-02 | COVERED |

Deferred maintenance/full-disclosure/package items are excluded from this audit, with original owners/statuses preserved. No required source item is missing.

## Frozen case mapping

All 22 owner-176 stable rows map here; their original ledger remains pending and immutable until separate runtime evidence is recorded.

| Frozen case ID | Task(s) |
|---|---|
| LEGACY-AGE-BOUNDARIES | 04-01,04-02 |
| LEGACY-UNSUPPORTED-INPUTS | 04-01,04-02 |
| CONFIG-ABSENT-LEGACY | 02-01,07-01 |
| CONFIG-STAGED-READERS | 02-01,07-01 |
| CONFIG-DEDICATED-WRITES-ALLOW | 02-02,07-01 |
| CONFIG-DEDICATED-WRITES-REJECT | 02-02,04-02,07-01 |
| CONFIG-INVALID-PRESENT | 02-02 |
| CONFIG-CONTRADICTION-AND-READER-ONLY | 02-01,02-02 |
| KEY-SET-GRAMMAR | 02-02 |
| ENVELOPE-FORMAT | 01-01,01-02,04-01 |
| ENVELOPE-STRICT-REJECTION | 01-02 |
| MATERIAL-BOUNDS-AND-API-SCOPE | 01-02,03-01 |
| WRITERS-FINAL-ID-AND-HANDOFF | 03-02,05 |
| READERS-AND-AUTH-EXCLUSIONS | 04-02,06 |
| WRITER-DIRECT-REGISTRATION | 03-02 |
| WRITER-DCR | 05-01 |
| WRITER-OPERATOR-ROTATION | 05-02 |
| WRITER-HASH-ONLY-HELPER | 03-01 |
| READER-TOKEN-EXCHANGE | 06-02 |
| READER-INTROSPECTION-REVOCATION | 06-01 |
| READER-PAR-DEVICE-CIBA | 06-01; D-11 preserves existing positive device/CIBA behavior |
| READER-HS256-AUDIENCE-JTI-EXCLUSIONS | 06-01,06-02 |

The owner-177 ROLLOUT-READER-FIRST-ROLLBACK-RETIREMENT row keeps maintenance/retirement/fleet evidence pending; 07 proves only its owned local runtime sequence. Six owner-175 rows remain qualified historical evidence. Eight owner-177 and one owner-178 rows remain pending.
