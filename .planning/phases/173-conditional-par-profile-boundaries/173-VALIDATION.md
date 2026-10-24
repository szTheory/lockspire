---
phase: "173"
slug: "conditional-par-profile-boundaries"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-24"
---

# Phase 173 — Validation Strategy

## Test Infrastructure

Existing ExUnit, Phoenix.ConnTest, integration fixtures and ledger contract suffice. No install, migration or framework change. Prefix every Mix invocation with `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b`.

Quick feedback: tagged new Phase 15 PAR integration regression with `--include integration`. Shared checks: Phase 15 integration, authorization-request protocol, pushed-authorization-request protocol and authorization/PAR controllers. Retained metadata owner: discovery controller. Ledger contract, strict Credo and edited-file formatting are phase gates. Focused feedback target below 60 seconds; record actual timing.

## Sampling Rate

- New candidate must fail normatively before production correction after a valid independently pushed control. Record source/file identities and actual assertion/output; setup/replay failures do not establish RED.
- Run identical regression after correction and retained shared-path owners before task completion.
- Run ledger after selective reviewed test/roadmap hash reconciliation. Final completion metadata can require another audit and verification-owner regeneration.
- No old intentional-RED probe, optional profile or baseline acceptance rerun is part of the green command.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 173-01-01 | 173-01 | 1 | PARB-02 | T-173-01, T-173-04 | Two real independent PAR references; reference-only control first; conflicting outer scope preserves pushed client/scopes/state/nonce at exact relative consent route; actual same-test RED/GREEN | Router/integration | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test --include integration test/integration/phase15_par_authorization_e2e_test.exs --trace --only phase173_par_authority` | yes; named/tagged regression executed | green |
| 173-01-01 | 173-01 | 1 | PARB-01, PARB-02 | T-173-01, T-173-02, T-173-03 | Existing client lookup/policy/eligibility, binding/expiry/one-use/wrong-client burn, required-PAR, distinct request/request_uri collision and stored redirect/PKCE/nonce/state authority | Protocol/controllers | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test --include integration test/lockspire/web/authorize_controller_test.exs test/lockspire/web/pushed_authorization_request_controller_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/pushed_authorization_request_test.exs` | yes | green |
| 173-01-02 | 173-01 | 1 | PARB-01, PARB-02, PARB-03 | T-173-02, T-173-03, T-173-04 | Reuse P171-001/004 complete required-PAR/S256/replay owner and P171-006 configured issuer/mounted discovery metadata; external profiles stay unavailable | Integration/controller | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test --include integration test/integration/phase15_par_authorization_e2e_test.exs test/lockspire/web/discovery_controller_test.exs` | yes | green |
| 173-01-02 | 173-01 | 1 | PARB-02 | T-173-03 | Retain strict profile and existing prompt/max_age/auth_time/host-seam outcomes after shared validator change | Integration | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test --include integration test/integration/phase37_protocol_strictness_e2e_test.exs` | yes | green |
| 173-01-02 | 173-01 | 1 | PARB-02 | T-173-03 | Phase 172 supported-mode control and unsupported-mode first-party HTTP 400 remain intact | Router/regression | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test test/lockspire/web/authorize_controller_test.exs --trace --only phase172_response_mode` | yes | green |
| 173-01-02 | 173-01 | 1 | PARB-01, PARB-02, PARB-03 | T-173-04 | Edited source/test formatting | Static | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix format --check-formatted lib/lockspire/protocol/authorization_request.ex test/lockspire/protocol/authorization_request_test.exs test/integration/phase15_par_authorization_e2e_test.exs` | yes | green |
| 173-01-02 | 173-01 | 1 | PARB-01, PARB-02, PARB-03 | T-173-03, T-173-04 | Strict lint without new suppression or dependency | Static | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix credo --strict` | yes | green |
| 173-01-02 | 173-01 | 1 | PARB-01, PARB-02, PARB-03 | T-173-04 | Cases, source observations, frozen fields and historical bytes preserved; owned manifest/audit chain only | Provenance invariant | Exact executable Python command in Provenance invariant below (identical to plan Task 173-01-02) | Existing ledger and historical artifacts | green |
| 173-01-02 | 173-01 | 1 | PARB-01, PARB-02, PARB-03 | T-173-04 | Actual reviewed Phase 15 and roadmap selector hashes/digest match canonical ledger | Contract | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test test/lockspire/qualification_ledger_contract_test.exs` | yes | green |
| 173-01-02 | 173-01 | 1 | PARB-01, PARB-02, PARB-03 | T-173-04 | Owned diff has no whitespace/conflict-marker diagnostics | Static | `git diff --check -- lib/lockspire/protocol/authorization_request.ex test/lockspire/protocol/authorization_request_test.exs test/integration/phase15_par_authorization_e2e_test.exs .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json .planning/phases/173-conditional-par-profile-boundaries/173-01-SUMMARY.md` | yes; sources and summary present | green |

### Failing directions

Every runnable command has an immediately adjacent `<fails_when>` in 173-01-PLAN.md. At final GREEN, non-zero exit, zero selected/runnable tests or missing named regression are unacceptable. Normative RED is only the candidate HTTP 400 versus required consent assertion after both successful PAR POSTs and the independent reference-only control; fixture/runtime/replay faults do not qualify. Static checks require zero exit; provenance requires its final success line and zero exit. Record actual selected counts and timings; no numeric test-count baseline is invented.

### Provenance invariant

Planning baseline a820635e5d9f23ab67aa0573401b5c5a2e0a6f2a: the read-only invariant below passed. This is a preservation check, not behavioral RED/GREEN evidence. Canonical171ledger ownership is limited to existing Phase 15 whole-file identity and phases-172-173-contract roadmap selector, their ordered digest and appended attributed audits. The protocol test has no manifest entry and receives no invented entry. Future completion metadata requires the completion owner to repeat its selective audit and ledger check; covered report regeneration belongs to the verifier owner.

```sh
python3 -c 'import copy,json,subprocess; from pathlib import Path; p=".planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json"; rev="a820635e5d9f23ab67aa0573401b5c5a2e0a6f2a"; old=json.loads(subprocess.check_output(["git","show",rev+":"+p])); new=json.loads(Path(p).read_text()); a=copy.deepcopy(old); b=copy.deepcopy(new); [(j["matrix"].pop(k)) for j in (a,b) for k in ("input_manifest","input_digest","input_manifest_audits")]; assert a==b,"Frozen qualification changed"; keys=lambda j:{(e["path"],e.get("selector")):e["sha256"] for e in j["matrix"]["input_manifest"]}; before=keys(old); after=keys(new); allowed={("test/integration/phase15_par_authorization_e2e_test.exs",None),(".planning/ROADMAP.md","phases-172-173-contract")}; assert list(before)==list(after),"Manifest identities/order changed"; assert all(before[k]==after[k] for k in before if k not in allowed),"Unowned manifest changed"; prior=old["matrix"]["input_manifest_audits"]; audits=new["matrix"]["input_manifest_audits"]; assert audits[:len(prior)]==prior,"Old audits changed"; chain=before.copy(); identity=lambda x:(x["path"].split("#",1)[0],x.get("selector") or (x["path"].split("#",1)[1] if "#" in x["path"] else None)); added=audits[len(prior):]; assert all(identity(x) in allowed and x.get("date") and x.get("source_sha") and x.get("reason") for x in added),"Unowned or unattributed audit"; [(chain.__setitem__(identity(x),x["sha256"]) if chain[identity(x)]==x["previous_sha256"] else (_ for _ in ()).throw(AssertionError("Broken old/new audit chain"))) for x in added]; assert chain==after,"Missing identity audit"; root=Path(p).parent; names=("171-MAIN-ACCEPTANCE.json","171-QUALIFICATION-PROBE.json","171-QUALIFICATION-PROBE-20261024T204101Z.json","171-qualification_probe_test.exs"); assert all((root/n).read_bytes()==subprocess.check_output(["git","show",rev+":"+str(root/n)]) for n in names),"Historical receipt/probe bytes changed"; print("Frozen content/history preserved; owned manifest audit chain verified")'
```

Fails when non-zero exit, any frozen/unowned/audit-chain/historical-byte assertion, or the final `Frozen content/history preserved; owned manifest audit chain verified` line is absent.

### Explicit fallback limits

A-EDGE-PARB-01 and A-EDGE-PARB-03 generic interrupted/parallel probes remain unresolved and flagged; A-EDGE-PARB-02 remains unclassified, unresolved and flagged. No broad concurrency or external-wrapper guarantee is inferred from selected tests. Both descriptor-less prohibition projections remain flagged-unverified until an explicit scoped review disposition; no check fields or fabricated approvals are introduced. T-173-05 records the unselected external execution boundary; T-173-SC records zero selected package installs.

## Wave 0 Requirements

Existing infrastructure covers all selected requirements. No missing framework/config. New regression belongs in existing implementation work.

## Manual-Only Verifications

All selected behavior has automated owners. Unavailable external transport/browser profiles are supplemental and unselected, not manually waived selected behavior. Review audit ownership and actual evidence identities.

## Validation Sign-Off

- [x] Plan task IDs, threats and executable commands mapped
- [x] All tasks have automated verification, no three-task sampling gap
- [x] Actual normative RED and identical-test GREEN recorded
- [x] Shared lifecycle/policy/metadata behavior preserved
- [x] Historical evidence preserved and selective ledger audit passes
- [x] Actual timings recorded; final validation audit sets status and Nyquist fields

Approval: green and audit.

## Validation Audit 2026-10-24

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
