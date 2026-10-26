# Phase 178: Packaged Upgrade Proof & Delivery Handoff - Pattern Map

**Mapped:** 2026-10-26  
**Files analyzed:** 15 planned file groups (inferred from D-06–D-22 and Wave 0 gaps)  
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scripts/acceptance/clean_room/package_input.py` | utility | transform | same file | exact |
| `scripts/acceptance/clean_room/build_provider.py` | utility | transform | same file | exact |
| `scripts/acceptance/clean_room/selected_receipts.py` | utility | request-response | same file | exact |
| New verifier upgrade runner | utility | request-response, file-I/O, event-driven | `scripts/acceptance/clean_room/client_lifetime_upgrade.py` | role-match |
| New verifier receipt/schema | utility | transform, file-I/O | `scripts/acceptance/clean_room/selected_receipts.py` | role-match |
| Clean-room provider template adapter / boundary allowlist | service | request-response, CRUD | `test/clean_room/provider_host/lib/clean_room_provider/lifetime_client_store.ex`; tracked source support `test/support/delegated_verifier_maintenance_store.ex` | role-match |
| PostgreSQL race/fault witnesses | test | event-driven, CRUD | `test/support/client_verifier_maintenance_concurrency.ex` and `test/integration/client_secret_verifier_maintenance_concurrency_test.exs` | exact for PG witness |
| CI wrapper / workflow integration | config | batch | `scripts/ci/run_host_integration_proof.sh`; `.github/workflows/ci.yml` | role-match |
| Upgrade/operator guidance | documentation | request-response | `docs/client-secret-verifier-configuration.md` | role-match |
| JWT host guide updates | documentation | request-response | `docs/client-secret-jwt-host-guide.md` | role-match |
| Supported surface updates | documentation | transform | `docs/supported-surface.md` | role-match |
| Release and exact-main handoff evidence | documentation/utility | batch, file-I/O | `scripts/maintainer/repo_hygiene_check.sh`; `docs/maintainer-release.md` | role-match |
| Focused source/security/integration review records | documentation | transform | `.planning/phases/177-safe-verifier-maintenance-recovery/177-SECURITY.md` and `177-VERIFICATION.md` | role-match |
| Requirement dispositions and milestone audit | documentation | transform | `.planning/milestones/v1.47-phases/174-packaged-proof-delivery-handoff/` artifacts | role-match |
| Resource custody / dated handoff | documentation | transform | `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-CUSTODY.md` | role-match |

Phase context authorizes runner/module/receipt filenames at discretion. The runner must consume installed artifacts and ordinary host-owned modules. The installed host must not import checkout `test/support`, `Lockspire.TestRepo`, or private debug APIs. Phase 177 source tests are witness-pattern references only, not package acceptance.

## Pattern Assignments

### Package identity and source attribution

**Analog:** `scripts/acceptance/clean_room/package_input.py` (tracked)

`PackageIdentity` currently carries `kind`, `version`, `sha256`, optional archive/tree digests, and `source_revision`; `safe_receipt()` emits unavailable markers rather than inventing provenance (lines 32-58). Reuse its immutable identity and SHA helpers, but separate runner revision from each package's proven source and correct external tar/Hex attribution before using it as evidence.

### Generic dependency pair and host build

**Analog:** `scripts/acceptance/clean_room/build_provider.py` (tracked)

Locked/floor versions and lock paths are centralized at lines 47-57. Pair setup computes a lock hash and isolated cache at lines 69-81. Current `configure_proof_pair` couples non-locked pair selection to `admin_proof` (lines 84-100); phase D-06 calls for decoupling generic pair selection while preserving explicit admin overlay opt-in. Keep `FORBIDDEN` host-boundary checks (lines 59-67) and extend narrowly for adapter allowlisting.

### Strict finite receipts

**Analog:** `scripts/acceptance/clean_room/selected_receipts.py` (tracked)

Use exact field allowlists and stable case IDs (`ROOT_FIELDS`, `CANDIDATE_FIELDS`, `SCENARIO_FIELDS`, lines 12-27), scenario-specific required observations (lines 28-71), duplicate JSON key rejection and reconciled integer counts (lines 74-96), and byte/digest/binding validation in `validate_selected_receipt` (lines 99-110 onward). New verifier receipts must fail on omitted required cases; never convert missing evidence into skips.

### Package host runner

**Analog:** `scripts/acceptance/clean_room/client_lifetime_upgrade.py` (tracked)

Copy package construction, child process ownership, captured output/redaction, temporary root cleanup, and receipt assembly conventions. This runner is only setup/provenance precedent: D-03 explicitly says lifetime-schema upgrade is prerequisite, not verifier-upgrade acceptance. Prefer sharing these helpers over duplicating harness logic.

### Delegated host adapter

**Analog:** `test/support/delegated_verifier_maintenance_store.ex` (tracked source; do not import into installed host)

The module implements client/transaction/maintenance behaviours and declares a transaction authority whose participants identify the selected client and transaction stores (lines 1-21). Its maintenance contract gives unsupported, identity-mismatch and participant-mismatch modes (lines 23-45), and delegates inventory/compare-and-rewrap to the repository (lines 47-69). Reproduce the narrow behavior in ordinary host-owned template code and expand the template's explicit boundary allowlist; do not copy its test-only module into host runtime.

### PostgreSQL barrier and contention witness

**Analog:** `test/support/client_verifier_maintenance_concurrency.ex` (tracked source; witness pattern only)

The helper queries `pg_blocking_pids(contender_pid)` in an unboxed independent connection and only succeeds when the expected holder PID is observed (lines 55-78); backend PID is read via `pg_backend_pid()` (lines 81-86). Package witnesses should use distinct connections/PIDs and a reached blocker relation before releasing barriers, adapted to run-owned host state.

**Analog:** `test/integration/client_secret_verifier_maintenance_concurrency_test.exs` (tracked)

The rotation-first case captures persisted state, holds the rotation transaction, starts maintenance on another backend, asserts the observed blocker, releases the holder, then checks conflict and authoritative row values (lines 52-100). Reuse sequencing and persisted-row assertion shape, not `TestRepo` or Sandbox as proof of an installed host.

### CI and exact-main delivery

**Analogs:** `.github/workflows/ci.yml` (tracked), `scripts/maintainer/repo_hygiene_check.sh` (tracked)

CI declares canonical workflow events and environment identity (workflow lines 1-20); jobs check out source and run repo-owned checks (lines 23-75). Preserve existing job graph and record actual workflow run/attempt, job graph, head and checkout identities separately. The exact-main helper's interface accepts a full SHA, bounded wait, explicit warning dispositions, and JSON receipt (`repo_hygiene_check.sh` lines 17-40). Use it only after reviewed integration and synchronized refs per D-20.

### Adopter docs and handoff

**Analogs:** `docs/client-secret-verifier-configuration.md`, `docs/client-secret-jwt-host-guide.md`, `docs/supported-surface.md`, `docs/maintainer-release.md`, `175-CUSTODY.md`, Phase 177 security/verification artifacts (all tracked)

Keep adopter guidance aligned with actual installed commands and supported surface. The configuration guide documents separate dry-run/apply/check and running-release RPC command forms (RESEARCH.md references lines 50-68); retain command semantics and explain observed limits. Delivery artifacts should distinguish candidate proof, hosted CI, integration and exact-main acceptance; reuse the custody inventory's dated identity/custodian/purpose/disposition/retention/blocker/next-action fields. Preserve historical receipts and status rather than rewriting old observations.

## Shared Patterns

### Provenance and strict receipts

Bind candidate and predecessor archive/tree, installed vendor tree, resolved dependency, compiled identity, host lock, and runner SHA independently. Preserve original receipt bytes and failed attempts. Validate exact schemas, case sets, outcomes and safe observations; no omissions-as-skips.

### Clean-room security boundary

Installed host code uses ordinary host-owned modules and documented seams. Reject unsupported or mismatched authority before inventory/fetch/write. Register sensitive sentinels before child output processing; compare sensitive persisted values in memory and emit only safe booleans.

### PostgreSQL evidence

Use committed fixtures, separately checked-out connections, barriers, distinct backend PIDs and observed `pg_blocking_pids` relation. Assert authoritative rows after lock completion. A simulated post-commit unavailable response is indeterminate-result handling, not network fault injection.

### Delivery lifecycle

Pre-merge audit may record integration/main acceptance as pending or blocked. Preserve PR head and synthetic merge checkout separately. After reviewed integration, append dated exact-main acceptance only when `HEAD == local main == refreshed origin/main`, contributor gate, matching push CI and no-publish release graph, and warning dispositions are evidenced.

## No Analog Found

None for scoped file groups. The new finite verifier runner, receipt contract, package-host witnesses and handoff artifacts are new behaviors; listed analogs provide harness or document structure, not pre-existing verifier package acceptance.

## Metadata

**Analog search scope:** `scripts/acceptance/clean_room/`, `scripts/maintainer/`, `scripts/ci/`, `test/clean_room/`, `test/support/`, `test/integration/`, `.github/workflows/`, `docs/`, and prior phase/milestone artifacts.  
**Tracked-source gate:** every source analog named above was confirmed by `git ls-files`; no ignored capability/runtime mirror paths used.  
**Pattern extraction date:** 2026-10-26
