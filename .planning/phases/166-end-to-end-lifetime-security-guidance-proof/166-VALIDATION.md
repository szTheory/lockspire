---
phase: "166"
slug: "end-to-end-lifetime-security-guidance-proof"
status: complete
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-21"
---

# Phase 166 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit, Python unittest, real PostgreSQL, existing packaged HTTP lab |
| Config file | mix.exs, test/test_helper.exs, scripts/ci/run_test_matrix.sh, .github/workflows/ci.yml |
| Quick run command | `python3 -m unittest discover -s scripts/acceptance -p 'test_*.py'` (select narrower affected existing modules during implementation) |
| Full suite command | `bash scripts/ci/run_test_matrix.sh --integration .artifacts/ci/integration-timings.json .artifacts/ci/coverage/integration "$GITHUB_SHA"` with CI toolchain/database/cache setup |
| Estimated runtime | Measure and record; packaged builds and PostgreSQL lanes are long-running |

## Sampling Rate

- After every task: run the narrow affected suite with explicit failure direction and positive scenario/test counts.
- After every wave: run the affected integration and package legs; serialize shared policy/database mutations.
- Before phase completion: final candidate canonical required CI plus independent scoped security review and complete case/receipt map.
- Fast feedback target: under 60 seconds for helper/unit checks; measure integration latency separately. No claim that full packaged proof fits this target.

## Per-Task Verification Map

The 24 tasks below are planned checks, not execution evidence. Every command is root-relative except the inherited task-local MIX_HOME/HEX_HOME cache locations, whose existence and Elixir/OTP selection were observed while planning. Run this inherited database setup once before a serial Mix/database lane:

`env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test.setup`

New-file tests are created by their own named task before its verification. The leading tracer must pass before 166-01-02 or any expansion. Only 166-02 Python-only checks may run alongside the 166-03 dedicated database lane; serialize shared Mix compilation, policy changes and the dedicated database. Packaged/CI commands are long checks with measured duration, not sub-minute promises.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 166-01-01 | 01 | 1 | DCR-15, DCR-17, DCR-18 | T-166-01, T-166-02 | A real packaged candidate registers and issues a usable token through production routes; fresh.register_use is passed with positive counts and sanitized receipt; cleanup is observed. | focused / integration / evidence | `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --only integration test/integration/client_lifetime_packaged_journey_test.exs --max-failures 1 --timeout 900000` | existing + explicitly planned outputs | complete; see 166-01-SUMMARY.md |
| 166-01-02 | 01 | 1 | DCR-15, DCR-17, DCR-18 | T-166-01, T-166-02 | All fixed cases and DCR-15–19 map to named evidence; future work is pending; nine edge rows and both unverified prohibitions remain accounted for. | focused / integration / evidence | `python3 -c 'import json; from pathlib import Path; p=Path(".planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-EVIDENCE-MAP.json"); m=json.loads(p.read_text()); c=json.loads(Path(".planning/phases/162-lifetime-semantics-upgrade-contract/162-CASES.json").read_text()); assert {r["case_id"] for r in m["rows"]}=={r["id"] for r in c["cases"]}; assert {x for r in m["rows"] for x in r["requirements"]}=={"DCR-15","DCR-16","DCR-17","DCR-18","DCR-19"}; assert all(r["file"] and r["test"] and r["command"] and r["origin"] in ("inherited","new") for r in m["rows"]); assert {k:m["probe_coverage"][k] for k in ("applicable","explicit","unclassified","unresolved")} == {"applicable":9,"explicit":6,"unclassified":3,"unresolved":3}; print("all contract cases mapped; probe equality 9=6+3")'` | existing + explicitly planned outputs | complete; see 166-01-SUMMARY.md |
| 166-02-01 | 02 | 2 | DCR-17, DCR-18 | T-166-03, T-166-04 | All five targeted stale-input negatives fail closed before execution and the matching-candidate control passes. | unit / package | `python3 -m unittest discover -s test/acceptance -p 'client_lifetime_package_identity_test.py' -v` | existing + explicitly planned outputs | complete; see 166-02-SUMMARY.md |
| 166-02-02 | 02 | 2 | DCR-17, DCR-18 | T-166-03, T-166-04 | Every reuse is checked before execution; all future proof legs can consume the same candidate identity and pinned old identity independently. | unit / package | `python3 -m unittest discover -s test/acceptance -p 'client_lifetime_package_identity_test.py' -v` | existing + explicitly planned outputs | complete; see 166-02-SUMMARY.md |
| 166-03-01 | 03 | 2 | DCR-15, DCR-18 | T-166-05, T-166-06 | New integrated interactions pass independently with fixed C-POL/C-APP/C-TOK/C-MGMT case references and no duplicated complete focused suite. | focused / integration / evidence | `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --include integration test/integration/client_lifetime_interactions_test.exs --max-failures 1 --timeout 55000` | existing + explicitly planned outputs | complete; see 166-03-SUMMARY.md |
| 166-03-02 | 03 | 2 | DCR-15, DCR-18 | T-166-05, T-166-06 | Safe measured focused evidence supplies each selected contract case with positive executed tests and honest exclusions. | focused / integration / evidence | `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --include integration test/lockspire/protocol/app_lifetime_policy_test.exs test/lockspire/protocol/client_secret_lifetime_policy_test.exs test/lockspire/protocol/management_token_lifetime_policy_test.exs test/lockspire/protocol/client_secret_lifetime_auth_test.exs test/lockspire/protocol/client_secret_lifetime_jwt_boundary_test.exs test/integration/client_lifetime_interactions_test.exs --max-failures 1 --timeout 55000` | existing + explicitly planned outputs | complete; see 166-03-SUMMARY.md |
| 166-04-01 | 04 | 3 | DCR-16, DCR-18 | T-166-07, T-166-08 | Each mapped wait schedule executes with positive counts and blocker/current-state assertions; record any uncovered evidence as a gap. | focused / integration / evidence | `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --include integration --include postgres_race test/lockspire/storage/client_lifetime_client_wait_test.exs test/lockspire/storage/client_lifetime_grant_wait_test.exs test/lockspire/storage/client_secret_lifetime_client_wait_test.exs test/lockspire/storage/client_secret_lifetime_grant_wait_test.exs test/lockspire/storage/management_token_client_wait_test.exs --max-failures 1 --timeout 55000` | existing + explicitly planned outputs | complete; see 166-04-SUMMARY.md |
| 166-04-02 | 04 | 3 | DCR-16, DCR-18 | T-166-07, T-166-08 | Measured schedules cover C-RACE-01–06 and legacy canonicalization, with truthful layer/observation limits and no leaked credentials. | focused / integration / evidence | `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --include postgres_race test/lockspire/storage/management_token_client_wait_test.exs test/lockspire/storage/management_token_replacement_race_test.exs test/lockspire/storage/management_token_mutation_race_test.exs test/lockspire/storage/management_token_rollback_test.exs test/lockspire/storage/client_lifetime_conformance_test.exs test/lockspire/storage/client_lifetime_promotion_test.exs --max-failures 1 --timeout 55000`<br>`env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --include integration --include postgres_race test/lockspire/storage/client_secret_lifetime_rotation_race_test.exs test/lockspire/storage/client_lifetime_rollback_test.exs --max-failures 1 --timeout 55000` | existing + explicitly planned outputs | complete; see 166-04-SUMMARY.md |
| 166-05-01 | 05 | 4 | DCR-17, DCR-18, DCR-19 | T-166-09, T-166-10 | A recorded human answer settles the exact public selection seam before code changes. | decision + source preflight | `python3 -c 'import json; from pathlib import Path; d=json.loads(Path(".planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-SELECTOR-DECISION.json").read_text()); assert d["decision"]=="narrow-selectors" and d["confirmed_by"]=="user"; assert d["config_keys"]==["client_store","transaction_store"] and d["user_response_ref"]; print("explicit selector decision recorded")'` | planned decision record | complete; see 166-05-SUMMARY.md |
| 166-05-02 | 05 | 4 | DCR-17, DCR-18, DCR-19 | T-166-09, T-166-10 | The approved selectors work through production token HTTP with callback evidence and fail-closed tests; internal modules remain private. | focused / integration / evidence | `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --include integration test/lockspire/config_test.exs test/integration/client_lifetime_selected_store_test.exs test/lockspire/protocol/token_exchange/dependencies_test.exs --max-failures 1 --timeout 55000` | existing + explicitly planned outputs | complete; see 166-05-SUMMARY.md |
| 166-06-01 | 06 | 5 | DCR-17, DCR-18 | T-166-11, T-166-12 | Configured production registration and management use the selected composition and retain all existing semantics and failure envelopes. | focused / integration / evidence | `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --include integration test/integration/client_lifetime_selected_store_test.exs test/integration/management_token_lifetime_access_test.exs test/integration/management_token_lifetime_update_test.exs --max-failures 1 --timeout 55000` | existing + explicitly planned outputs | complete; see 166-06-SUMMARY.md |
| 166-06-02 | 06 | 5 | DCR-17, DCR-18 | T-166-11, T-166-12 | Selected issuance and replacement paths are ready for packaged proof with no widened datastore claim. | focused / integration / evidence | `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --include integration test/integration/client_lifetime_selected_store_test.exs test/integration/client_secret_lifetime_rotation_test.exs test/integration/management_token_lifetime_recovery_test.exs test/lockspire/storage/client_lifetime_rollback_test.exs --max-failures 1 --timeout 55000` | existing + explicitly planned outputs | complete; see 166-06-SUMMARY.md |
| 166-07-01 | 07 | 6 | DCR-18 | T-166-13, T-166-14 | Positive integrated events/audits and deliberate failure diagnostics pass without leaking actual protected material. | focused / integration / evidence | `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --include integration test/lockspire/protocol/dcr_telemetry_redaction_test.exs test/lockspire/protocol/dcr_audit_attribution_test.exs --max-failures 1 --timeout 55000` | existing inputs | complete; see 166-07-SUMMARY.md |
| 166-07-02 | 07 | 6 | DCR-18 | T-166-13, T-166-14 | Packaged success and failure boundaries use the existing redactor and field allowlist, with a passing deliberate-failure safety check. | unit / package | `python3 -m unittest discover -s test/acceptance -p 'client_lifetime_redaction_test.py' -v` | existing + explicitly planned outputs | complete; see 166-07-SUMMARY.md |
| 166-08-01 | 08 | 7 | DCR-16, DCR-17, DCR-18, DCR-19 | T-166-15, T-166-16 | Packaged normal configuration selects the named adapter, executes successful callbacks and the exact copyable test, and retains restrictive audit controls. | unit / package | `python3 -m unittest discover -s test/acceptance -p 'client_lifetime_boundary_test.py' -v`<br>`env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --only integration test/integration/client_lifetime_packaged_journey_test.exs --max-failures 1 --timeout 900000` | existing + explicitly planned outputs | complete; see 166-08-SUMMARY.md |
| 166-08-02 | 08 | 7 | DCR-16, DCR-17, DCR-18, DCR-19 | T-166-15, T-166-16 | Actual configured adapter issuance/replacement and late rollback are proved from the candidate package, with independent durable observation and safe receipts. | focused / integration / evidence | `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --only integration test/integration/client_lifetime_packaged_journey_test.exs --max-failures 1 --timeout 900000` | existing + explicitly planned outputs | complete; see 166-08-SUMMARY.md |
| 166-09-01 | 09 | 8 | DCR-15, DCR-17, DCR-18 | T-166-17, T-166-18 | All four fresh scenarios have actual observed production-route outcomes, positive event/audit counts and no skipped required scenario. | focused / integration / evidence | `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --only integration test/integration/client_lifetime_packaged_journey_test.exs --max-failures 1 --timeout 900000` | existing + explicitly planned outputs | complete; see 166-09-SUMMARY.md |
| 166-09-02 | 09 | 8 | DCR-15, DCR-17, DCR-18 | T-166-17, T-166-18 | Both prefixes retain inherited migration/cutover proof and add non-skipped legacy HTTP use/promotion linked to the fixed contract and shared candidate. | focused / integration / evidence | `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --only integration test/integration/app_lifetime_packaged_upgrade_test.exs test/integration/client_lifetime_packaged_journey_test.exs --max-failures 1 --timeout 900000` | existing + explicitly planned outputs | complete; see 166-09-SUMMARY.md |
| 166-10-01 | 10 | 9 | DCR-17, DCR-18 | T-166-19, T-166-20 | An active canonical partition executes complete same-candidate lifetime proof and rejects omitted/empty/failed required evidence. | unit / package | `python3 -m unittest discover -s test/acceptance -p 'client_lifetime_receipts_test.py' -v`<br>`env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --only lifetime_package test/integration/client_lifetime_packaged_journey_test.exs --max-failures 1 --timeout 900000` | existing + explicitly planned outputs | complete; see 166-10-SUMMARY.md |
| 166-10-02 | 10 | 9 | DCR-17, DCR-18 | T-166-19, T-166-20 | CI source contracts pass and the active job retains only bounded safe receipts; no claim of live CI success is made here. | focused / integration / evidence | `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test test/lockspire/ci_test_matrix_contract_test.exs test/lockspire/ci_workflow_evidence_contract_test.exs --max-failures 1 --timeout 55000`<br>`bash -n scripts/ci/run_test_matrix.sh` | existing inputs | complete; see 166-10-SUMMARY.md |
| 166-11-01 | 11 | 10 | DCR-19 | T-166-21, T-166-22 | Adopter/maintainer instructions match executed evidence and approved public configuration, with a copyable exercised host test and truthful limits. | focused / integration / evidence | `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test test/lockspire/client_lifetime_guidance_test.exs --max-failures 1 --timeout 55000` | existing + explicitly planned outputs | complete; see 166-11-SUMMARY.md |
| 166-11-02 | 11 | 10 | DCR-19 | T-166-21, T-166-22 | Operator, installation and canonical support guidance are consistent and audience-appropriate; existing admin tasks remain unchanged. | focused / integration / evidence | `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test test/lockspire/client_lifetime_guidance_test.exs test/lockspire/web/live/admin/vocabulary_contract_test.exs test/lockspire/release_readiness_contract_test.exs --max-failures 1 --timeout 55000` | existing + explicitly planned outputs | complete; see 166-11-SUMMARY.md |
| 166-12-01 | 12 | 11 | DCR-15, DCR-16, DCR-17, DCR-18, DCR-19 | T-166-23, T-166-24 | Final candidate has current meaningful security regressions and independent scoped review with no open high/critical findings. | focused / integration / evidence | Candidate c6bc4174: focused isolated-DB regression selection 142 tests, 0 failures; local `mix test.fast` 2 properties, 2,432 tests, 0 failures, 497 excluded, 6 skipped; live canonical Fast Checks and minimum-supported contexts also passed. See 166-SECURITY.md and 166-CI-EVIDENCE.json. | existing + explicitly planned outputs | complete |
| 166-12-02 | 12 | 11 | DCR-15, DCR-16, DCR-17, DCR-18, DCR-19 | T-166-23, T-166-24 | Required live CI, non-skipped candidate receipts and independent review are retained; umbrella closure preserves the explicit unresolved/flagged probe limits. | focused / integration / evidence | Final candidate c6bc4174: canonical run 39762415198 passed all 7 observed main-branch required contexts; package artifact 12418964333 validates 9 scenarios, 49 passed, 0 failed/skipped; independent review SECURED. Umbrella moved to completed with original unresolved probe/prohibition labels retained. See 166-CI-EVIDENCE.json and 166-SECURITY.md. | existing + explicitly planned outputs | complete |

## Wave 0 Requirements

- Build a compact map of Phase 162 cases to inherited/new test evidence before adding suites.
- Add only missing deterministic cross-lifetime cases, stale-candidate negatives and safe failing-output checks.
- Extend existing packaged fresh/legacy/configured-adapter legs and copyable host test example.
- Existing frameworks and transaction/race helpers suffice; do not add dependencies or a parallel harness.

## Manual-Only Verifications

All already automated properties remain automated. Scoped independent security review and observation of current live required CI are completion gates; do not substitute a manual UAT handoff or local green summary.

## Creation Dependencies and Planning Gates

- 166-01-01 creates the runner mode, receipt module and active wrapper before its end-to-end command; 166-01-02 creates the evidence map. All later rows consume those interfaces.
- 166-02 creates package identity tests/helpers; 166-03 creates only missing deterministic interactions; 166-04 reuses existing PostgreSQL schedules without a duplicate suite.
- 166-05 checkpoint must settle the exact new public selectors before implementation. The approved contract is consumed by 166-06 and the named host adapter in 166-08; internal dependency modules remain private.
- 166-07 creates deliberate-failure redaction checks before packaged expansion. 166-08 creates/executes the exact package-included Markdown host example and boundary negatives. 166-09 completes fresh/legacy runtime scenarios.
- 166-10 creates receipt omission/count negatives and active CI wiring; its full proof covers nine required IDs: four fresh, three custom and two legacy-prefix outcomes. Existing Phase 133 skip is not evidence.
- 166-11 reconciles public guidance only after executable evidence. 166-12 reruns final changed-surface/package gates and obtains independent scoped security and live required CI before any conditional umbrella move.
- Estimation calibration: factor 0.5, six samples, high confidence, measured by estimate-calibration. Estimates are planning projections, not execution budgets or actual usage.
- Discovery level 0/1: current research/patterns plus tracked source interfaces supply the established stack; no new dependency or external integration. Graph context skipped because graphify is disabled.
- Schema contribution: none of its Payload/Prisma/Drizzle/Supabase/TypeORM path patterns match this scope; no schema format or migration is added. Do not inject an unrelated schema-push command.
- Assumption-delta detected chosen/custom. Primary noun is the declared shared transaction-authority composition; promote that existing identity as primary, with Repository as default instance. No second independent authority/registry.
- API coverage detector ran on the complete final plan scope plus phase section and returned detected:false with no signals; no external API/SDK/service matrix is required. Production OAuth HTTP tests exercise Lockspire's existing own surface.
- The planning-time coverage audit above makes no execution claim; completed execution evidence is recorded in each plan summary and the final-candidate section below.

## Probe Coverage and Flagged Assumptions

The successful edge probe surfaced nine applicable rows: six explicit predicates are in 166-03/07 truths; three unclassified rows A-EDGE-16, A-EDGE-17 and A-EDGE-19 remain unresolved flagged assumptions in 166-01. Equality: **9 = 6 authored explicit + 3 flagged**. No row was auto-dismissed or converted to a backstop.

Prohibition recall ran per DCR-15–19 with approximately 50 raw candidates. Precision dropped routine correctness/locking/tooling hygiene; generic credential-disclosure, injection and supply-chain canon referred to the scoped security review. Two bespoke transparency constraints survive in 166-01 must_haves.prohibitions, projected through projectProhibitions and intentionally descriptor-less. Equality: **2 = 2 authored flagged-unverified**. No check descriptor was fabricated; verification must report the unresolved disposition rather than silently pass.

## Multi-Source Coverage Audit

Every source item is assigned to executable work. The coverage audit was created at planning time; executed outcomes are recorded in the corresponding per-plan summaries and the final-candidate section below.

| Source | ID | Feature / constraint | Plans | Planning status |
|--------|----|----------------------|-------|-----------------|
| GOAL | Phase 166 | Reproducible complete lifetime journeys and verified guidance | 01–12 | COVERED |
| REQ | DCR-15 | Deterministic before/equality/after policies and interactions | 01,03,09,12 | COVERED |
| REQ | DCR-16 | Observed PostgreSQL schedules and atomic rollback | 04,08,12 | COVERED |
| REQ | DCR-17 | Candidate-bound fresh/legacy/custom packaged journey | 01,02,05,06,08,09,10,12 | COVERED |
| REQ | DCR-18 | Security defaults/redaction/current required CI/scoped review | 01–10,12 | COVERED |
| REQ | DCR-19 | Truthful guidance and copyable host example | 05,08,11,12 | COVERED |
| RESEARCH | R-01 | Reuse existing lab, fixtures, clocks and race schedules; no new dependency | 01–04,07–10 | COVERED |
| RESEARCH | R-02 | Map inherited versus integrated proof; avoid duplicate suite/Cartesian product | 01,03,04,10 | COVERED |
| RESEARCH | R-03 | Archive/extracted/vendor/compiled/resolved identity checked before reuse | 02,09 | COVERED |
| RESEARCH | R-04 | Package actual legacy credentials, both prefixes, checksums and writer drain | 09 | COVERED |
| RESEARCH | R-05 | Configured successful adapter participation and independent late rollback | 05,06,08 | COVERED |
| RESEARCH | R-06 | Narrow audit exception without promoting internals | 05,08 | COVERED |
| RESEARCH | R-07 | Positive events/audits and safe deliberate-failure diagnostics | 07,09 | COVERED |
| RESEARCH | R-08 | Active broad tagged CI, positive counts and 14-day allowlisted receipts | 10,12 | COVERED |
| RESEARCH | R-09 | Copyable package-included example; checkout-only tests labeled honestly | 08,11 | COVERED |
| RESEARCH | R-10 | Current final required checks/security review and conditional closure | 12 | COVERED |
| CONTEXT | D-01 | Locked decision implemented with D-ID truth/task citations | 01,03,04,12 | COVERED |
| CONTEXT | D-02 | Locked decision implemented with D-ID truth/task citations | 03,04,06,09 | COVERED |
| CONTEXT | D-03 | Locked decision implemented with D-ID truth/task citations | 01,03,09 | COVERED |
| CONTEXT | D-04 | Locked decision implemented with D-ID truth/task citations | 03,09 | COVERED |
| CONTEXT | D-05 | Locked decision implemented with D-ID truth/task citations | 04,08 | COVERED |
| CONTEXT | D-06 | Locked decision implemented with D-ID truth/task citations | 04,06,08 | COVERED |
| CONTEXT | D-07 | Locked decision implemented with D-ID truth/task citations | 01,08,09 | COVERED |
| CONTEXT | D-08 | Locked decision implemented with D-ID truth/task citations | 02,09,10 | COVERED |
| CONTEXT | D-09 | Locked decision implemented with D-ID truth/task citations | 02,09 | COVERED |
| CONTEXT | D-10 | Locked decision implemented with D-ID truth/task citations | 05,06,08 | COVERED |
| CONTEXT | D-11 | Locked decision implemented with D-ID truth/task citations | 05,06,08 | COVERED |
| CONTEXT | D-12 | Locked decision implemented with D-ID truth/task citations | 10,12 | COVERED |
| CONTEXT | D-13 | Locked decision implemented with D-ID truth/task citations | 01,07,10,12 | COVERED |
| CONTEXT | D-14 | Locked decision implemented with D-ID truth/task citations | 07,08,09 | COVERED |
| CONTEXT | D-15 | Locked decision implemented with D-ID truth/task citations | 07 | COVERED |
| CONTEXT | D-16 | Locked decision implemented with D-ID truth/task citations | 03,12 | COVERED |
| CONTEXT | D-17 | Locked decision implemented with D-ID truth/task citations | 11 | COVERED |
| CONTEXT | D-18 | Locked decision implemented with D-ID truth/task citations | 08,11 | COVERED |
| CONTEXT | D-19 | Locked decision implemented with D-ID truth/task citations | 11 | COVERED |
| CONTEXT | D-20 | Locked decision implemented with D-ID truth/task citations | 12 | COVERED |

Deferred ideas remain excluded: app renewal, overlapping credentials, public acceptance clocks, other datastores, generalized conformance SDK, parallel harness, visual redesign, distributed activation, dependency upgrades and publication.


## Final Candidate Execution: c6bc4174

Canonical CI run [39762415198](https://github.com/szTheory/lockspire/actions/runs/39762415198) completed successfully on `c6bc4174675173b13c2bd1e95fba43e5f169adb4`. The observed required contexts were Adoption Demo Smoke, Complete Coverage Evidence, Dialyzer, Fast Checks, Integration Checks, Minimum Supported Elixir/OTP and Release Hygiene Drift; all seven completed successfully.

The successful matrix partitions were: Fast Checks 2 properties / 1,935 tests / 0 failures / 6 skipped / 497 excluded; minimum supported Elixir/OTP 2 properties / 2,432 tests / 0 failures / 6 skipped / 497 excluded; broad integration 494 tests / 0 failures / 1,940 excluded; and the dedicated package lane 3 tests / 0 failures. The broad integration lane excluded all three dedicated wrapper tests; the package lane executed those wrappers and the receipt validator accepted all nine positive scenario IDs, 49 passed, 0 failed or skipped, with process/database/temp-root cleanup confirmed.

The focused security selection on the same source candidate passed 142 tests with 0 failures, using a dedicated local database. The local fast suite passed 2,432 tests with 0 failures, 497 excluded and 6 skipped. The independent security review is SECURED, scope digest `a971e2dad1f8526bee667c3cec74ac18593eab2b39befda2457fe1f9bc72d16a`, 25/25 threats closed, 0 open.

### Plan 12 gate status

| Gate | Status | Evidence / disposition |
|---|---|---|
| D-16 current security regressions | Passed | Focused 142-test selection and full fast lane on c6bc4174; live Fast and minimum-supported jobs passed. |
| Independent scoped review | Passed | Separate reviewer verdict SECURED on exact candidate and scope digest; no open high/critical finding. |
| Exact-candidate live required CI | Passed | Canonical run 39762415198; all 7 observed required contexts successful on c6bc4174. |
| Candidate package identity and receipt | Passed | Artifact 12418964333, exact candidate binding, 9/9 scenarios, 49/49 passed, no failed/skipped, cleanup complete. |
| D-12 package-only partition | Passed | Broad integration 494 tests, wrappers excluded; dedicated lane 3 wrapper tests, receipt validates all nine scenarios. |
| A-EDGE-16/17/19 | Explicitly preserved | Remain `unresolved`; independent review acknowledged these spec-less flags and did not clear them by implication. |
| Two descriptor-less prohibitions | Explicitly preserved | Remain `flagged-unverified`; no check descriptors were invented. Their non-claim boundaries are stated in the security review and map. |
| Conditional umbrella | Closed with recorded limits | Original todo metadata/history preserved in completed path. Closure relies on the complete current DCR-15–19 evidence and explicit verifier dispositions; unresolved probe labels remain visible and are not claimed as individually tested predicates. |

Historical pre-final failures are not counted as final evidence. Earlier local and Plan 10 matrix failures were superseded by the exact-candidate run; their details and limits are recorded in `deferred-items.md`. A known clean-room management-token expiry race was diagnosed with a delay after client registration and repaired by increasing only the test fixture TTL from two to ten seconds while preserving expiry assertions.

## Validation Sign-Off

- [x] Finalized per-task verification map covers every task and DCR-15–19.
- [x] Automated checks have failure conditions and observed positive evidence where applicable.
- [x] No consecutive task-check gap invalidates the phase; final canonical partitions cover mapped focused/integration/package files.
- [x] PostgreSQL schedules and durable rollback were exercised by the Phase 166 matrix and focused security lane.
- [x] Candidate-bound non-skipped fresh/upgrade/custom-adapter receipts are credential safe.
- [x] Required live CI and independent review refer to final changed surfaces.
- [x] `nyquist_compliant` is set only after execution evidence.

**Approval:** execution complete for candidate c6bc4174. Probe assumptions and descriptor-less prohibitions retain their explicit unresolved/flagged dispositions; they are not inferred green from adjacent test results.
