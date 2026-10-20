#!/usr/bin/env python3
"""Validate the Phase 162 design contract and its expected-contract fixtures."""

from __future__ import annotations

import argparse
import copy
import json
import re
import sys
from pathlib import Path


HERE = Path(__file__).resolve().parent
CONTRACT_PATH = HERE / "162-CONTRACT.md"
CASES_PATH = HERE / "162-CASES.json"
SCOPE = "Expected contract behavior; runtime not exercised."
DECISIONS = {f"D-{n:02}" for n in range(1, 28)}
REQUIREMENTS = {"DCR-02", "DCR-03", "DCR-04"}
CONSUMERS = {
    "authorization_intake", "resume_remembered_consent_approval", "par_create_and_use",
    "device_create_verify_approve", "ciba_initiation_poll_push", "code_redemption",
    "refresh_device_ciba_existing_grants", "exchange_requesting_client", "exchange_subject_actor",
    "introspection_caller", "introspection_target", "userinfo", "revocation",
    "management_get_delete", "management_put", "disabled_app", "discovery_jwks",
    "host_rp_sessions_account_policy",
}


class ContractError(ValueError):
    pass


def fail(message: str) -> None:
    raise ContractError(message)


def strict_json(raw: str):
    def pairs(items):
        result = {}
        for key, value in items:
            if key in result:
                fail(f"duplicate JSON key: {key}")
            result[key] = value
        return result

    try:
        return json.loads(raw, object_pairs_hook=pairs,
                          parse_constant=lambda value: fail(f"non-JSON number: {value}"))
    except (json.JSONDecodeError, UnicodeDecodeError) as exc:
        fail(f"invalid JSON: {exc}")


def case_map(data):
    cases = data.get("cases")
    if not isinstance(cases, list):
        fail("cases must be an array")
    result = {}
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            fail("case requires string id")
        if case["id"] in result:
            fail(f"duplicate case id: {case['id']}")
        result[case["id"]] = case
    return result


def require(condition: bool, message: str) -> None:
    if not condition:
        fail(message)


def validate(contract: str, data, stage: str) -> None:
    require(data.get("schema_version") == 1, "unsupported schema_version")
    require(data.get("claim") == "design_contract_only", "fixture claim must be design_contract_only")
    require(data.get("scope_sentence") == SCOPE and SCOPE in contract,
            "missing design-only scope sentence")
    cases = case_map(data)
    decisions = data.get("decisions", {})
    requirements = data.get("requirements", {})
    require(isinstance(decisions, dict) and isinstance(requirements, dict), "maps must be objects")

    active_decisions = {"D-01", "D-02", "D-03", "D-04", "D-05"}
    if stage in {"consumers", "complete"}:
        active_decisions |= {f"D-{n:02}" for n in range(6, 18)}
    if stage == "complete":
        active_decisions = DECISIONS
    for decision in sorted(active_decisions):
        row = decisions.get(decision)
        require(isinstance(row, dict) and f'<a id="{row.get("section")}"></a>' in contract,
                f"missing decision or broken section link: {decision}")
        require(isinstance(row.get("cases"), list) and row["cases"],
                f"decision has no case references: {decision}")
        for case_id in row["cases"]:
            require(case_id in cases, f"decision {decision} references missing case {case_id}")

    if stage in {"consumers", "complete"}:
        for req in sorted(REQUIREMENTS if stage == "complete" else {"DCR-02", "DCR-03"}):
            row = requirements.get(req)
            require(isinstance(row, dict) and f'<a id="{row.get("section")}"></a>' in contract,
                    f"missing requirement owner or broken section link: {req}")
            require(all(cid in cases for cid in row.get("cases", [])) and row.get("cases"),
                    f"requirement {req} has missing/empty case references")

    issuance = cases.get("C-POL-01", {})
    require(issuance.get("deadlines") == {"app": 160, "secret": 110, "management": 120},
            "wrong issuance deadline arithmetic")
    edit = cases.get("C-POL-03", {}).get("replacement", {})
    require(edit.get("secret_deadline") == edit.get("secret_at", -1) + edit.get("secret_duration", -2),
            "wrong secret replacement deadline arithmetic")
    require(edit.get("management_deadline") == edit.get("management_at", -1) + edit.get("management_duration", -2),
            "wrong management replacement deadline arithmetic")
    require(cases.get("C-POL-02", {}).get("deadline") is None,
            "nil/zero must map to unlimited null deadline")
    for cid, deadline in (("C-POL-08", 110), ("C-POL-09", 160), ("C-POL-10", 120)):
        row = cases.get(cid, {})
        require(row.get("deadline") == deadline and row.get("checks") == {
            str(deadline - 1): True, str(deadline): False, str(deadline + 1): False},
            f"equality boundary is not strict for {cid}")
    provenance = cases.get("C-POL-05", {})
    require(provenance.get("dcr_uses_defaults") is True
            and provenance.get("direct_operator_uses_dcr_defaults") is False
            and provenance.get("no_secret_secret_lifetime") == "inapplicable",
            "DCR provenance and no-secret policy boundaries must remain independent")
    policy = cases.get("C-POL-06", {})
    require(policy.get("valid") == [None, 0, 1, 2147483647]
            and set(map(json.dumps, policy.get("invalid", []))) ==
                set(map(json.dumps, [-1, 2147483648, True, "60", 1.5, [], {}])),
            "malformed policy acceptance matrix is incomplete")
    require(cases.get("C-POL-12", {}).get("sample") == "after_locks_and_current_row_reload",
            "operation time must be sampled after waits and current-row reload")

    if stage in {"consumers", "complete"}:
        observed = {case.get("consumer") for case in cases.values() if case.get("kind") == "consumer"}
        require(observed == CONSUMERS, "consumer inventory is missing or adds a selected row")
        consumer_cases = {c["consumer"]: c for c in cases.values() if c.get("kind") == "consumer"}
        required_outcomes = {
            "authorization_intake": "reject_before_login_or_consent",
            "resume_remembered_consent_approval": "no_code",
            "par_create_and_use": "reject_at_both_boundaries",
            "device_create_verify_approve": "reject_create_and_approval",
            "ciba_initiation_poll_push": "recheck_current_worker_state",
            "code_redemption": "reject_without_token_write_or_code_consumption",
            "refresh_device_ciba_existing_grants": "reject_replacement_preserve_grant_rules",
            "exchange_requesting_client": "reject_caller",
            "exchange_subject_actor": "invalid_grant",
            "introspection_caller": "client_authentication_failure",
            "introspection_target": "200_active_false_if_owned",
            "userinfo": "401_invalid_token_before_host_claims",
            "revocation": "reject_caller; eligible_unknown_token_non_disclosing",
            "management_get_delete": "allow_valid_current_token_if_enabled",
            "management_put": "403_registration_expired",
            "disabled_app": "deny_protocol_and_all_self_management",
            "discovery_jwks": "unaffected",
            "host_rp_sessions_account_policy": "unaffected_host_owned",
        }
        require({name: row.get("expired") for name, row in consumer_cases.items()} == required_outcomes,
                "consumer inventory is missing or has an incorrect outcome")
        for name, row in consumer_cases.items():
            require(row.get("state_assumptions") == {
                "app_enabled": True, "app_expired": True, "registration_history_retained": True},
                f"consumer state assumptions are incomplete: {name}")
            require(isinstance(row.get("checkpoint"), str) and row["checkpoint"],
                    f"consumer check point is missing: {name}")
            require(isinstance(row.get("state_effect"), str) and row["state_effect"],
                    f"consumer state effect is missing: {name}")
            require(row.get("response_or_behavior") == row.get("expired"),
                    f"consumer response or unaffected behavior is missing: {name}")
        token = cases.get("C-TOK-01", {})
        require(token.get("stored_expiry") == token.get("jwt_exp") == token.get("app_deadline")
                and token.get("expires_in") == token.get("app_deadline") - token.get("at"),
                "token cap persisted/JWT/response arithmetic disagrees")
        require(cases.get("C-MGMT-01", {}).get("deadline_changed") is False
                and cases["C-MGMT-01"].get("plaintext_returned") is False,
                "GET must be side-effect free and credential-free")
        require(cases.get("C-MGMT-08", {}).get("missing_bearer") == "401 challenge no detail",
                "missing Bearer outcome is wrong")
        require(cases.get("C-MGMT-07", {}).get("extension_omission") == "preserve"
                and cases["C-MGMT-07"].get("changed_extension") == "400 invalid_client_metadata"
                and cases["C-MGMT-07"].get("intake_extension_supplied") == "400 invalid_client_metadata",
                "server-owned extension changes must be rejected and omission preserved")
        require(cases.get("C-MGMT-09", {}).get("disabled") == "401 invalid_token"
                and cases.get("C-APP-16", {}).get("expired") == "deny_protocol_and_all_self_management",
                "disabled apps must not allow management GET or protocol access")
        require("intake rejects either client-supplied extension" in contract.lower()
                and "get never discloses plaintext secret or management token" in contract.lower(),
                "wire contract must reject client-owned extensions and keep GET credential-free")
        require("do not probe callbacks" in contract.lower(),
                "contract must keep adapter probing outside token internals")

    if stage == "complete":
        require(set(decisions) == DECISIONS, "decision map must contain exactly D-01 through D-27")
        require(set(requirements) == REQUIREMENTS, "requirement map must contain exactly DCR-02/03/04")
        require("locked whole-row write" in contract and "lifetime_version" in contract,
                "legacy canonicalization and compatibility version contract missing")
        require(cases.get("C-LEG-04", {}).get("secret_hash_preserved") is True
                and cases["C-LEG-04"].get("secret_deadline") is None,
                "management-only promotion must preserve hash and keep secret unlimited")
        require(cases.get("C-LEG-07", {}).get("dropped_fields") == "configuration_error",
                "adapter dropped-field failure must be explicit")
        require(cases["C-LEG-07"].get("unknown_row_version") == "configuration_error"
                and cases["C-LEG-07"].get("missing_schema") == "configuration_error",
                "unknown version and missing schema must fail as server configuration errors")
        legacy_management = cases.get("C-LEG-04", {})
        require(legacy_management.get("promoted_dates") == {
            "app": None, "secret": None, "management": 127}
            and legacy_management.get("secret_hash_preserved") is True
            and legacy_management.get("current_secret_hash_is_written_unchanged") is True
            and legacy_management.get("audit_atomic") is True,
            "legacy management-only promotion must canonicalize all dates and preserve secret hash")
        require(cases.get("C-RACE-01", {}).get("winners") == 1,
                "same-token PUT schedule must have one winner")
        require(cases["C-RACE-01"].get("presented_token_matches_current_hash") is True
                and cases["C-RACE-01"].get("url_binding_matches") is True,
                "management mutation must bind current hash and URL")
        require(cases.get("C-RACE-02", {}).get("concurrent_secret_hash_preserved") is True
                and cases["C-RACE-02"].get("concurrent_enabled_state_preserved") is True,
                "stale management snapshot must not restore secret or enabled state")
        require(cases.get("C-RACE-03", {}).get("current_fingerprint_rechecked") is True
                and cases["C-RACE-03"].get("after_committed_rotation") == "reject",
                "preverified credential must be rechecked after committed rotation")
        require(cases.get("C-RACE-06", {}).get("old_ingress_time_authorizes") is False
                and cases["C-RACE-06"].get("current_row_reloaded_after_wait") is True,
                "ingress timestamp cannot authorize after a wait crossing equality")
        order = cases.get("C-DEP-01", {}).get("order", [])
        required_order = ["old_code_schema", "additive_prefix_migration", "stage_new_code_no_ingress",
                          "drain_web_admin_jobs_cli_old_writers", "new_ingress_cutover", "first_v1_write"]
        require(order == required_order, "deployment partial order is invalid")
        require(set(cases["C-DEP-01"].get("old_writers", [])) == {"web", "admin", "jobs", "cli"}
                and cases["C-DEP-01"].get("drain_before_ingress_cutover") is True,
                "deployment must drain every old writer before ingress cutover")
        require(cases.get("C-DEP-03", {}).get("after_first_v1_write")
                == "retain_state_fix_forward_or_aware_rollback", "rollback boundary is unsafe")
        require(cases["C-DEP-03"].get("rollback_state_retained_after_v1_write") is True
                and cases["C-DEP-03"].get("old_binary_after_v1_write") == "never_serve_protocol_traffic",
                "rollback must retain authoritative state and keep old binaries out of service")
        require("Phase 163" in contract and "Phase 166" in contract,
                "bounded implementation and proof handoff missing")


def self_test(contract: str, data, stage: str) -> list[str]:
    validate(contract, data, stage)
    checks = []

    def rejected(label, mutate, expected):
        doc, fixture = contract, copy.deepcopy(data)
        try:
            mutate(doc, fixture)
            validate(doc, fixture, stage)
        except ContractError as exc:
            require(expected in str(exc), f"{label} rejected for wrong reason: {exc}")
        else:
            fail(f"self-test unexpectedly accepted {label}")
        checks.append(label)

    def wrong_sum(doc, fixture):
        fixture["cases"][0]["deadlines"]["app"] = 161
    rejected("wrong-sum", wrong_sum, "wrong issuance deadline arithmetic")

    def equality(doc, fixture):
        fixture["cases"][7]["checks"]["110"] = True
    rejected("equality-accepted", equality, "equality boundary")

    def unlimited(doc, fixture):
        fixture["cases"][1]["deadline"] = 0
    rejected("nil-zero-as-issuance-time", unlimited, "unlimited null deadline")

    def malformed(doc, fixture):
        fixture["cases"][5]["invalid"].remove("60")
    rejected("malformed-policy-accepted", malformed, "malformed policy")

    def missing_map(doc, fixture):
        fixture["decisions"].pop("D-01")
    rejected("missing-decision", missing_map, "missing decision")

    def broken_anchor(doc, fixture):
        fixture["decisions"]["D-01"]["section"] = "missing-anchor"
    rejected("broken-section-link", broken_anchor, "broken section link")

    def duplicate_json(doc, fixture):
        strict_json('{"duplicate":1,"duplicate":2}')
    rejected("duplicate-json-key", duplicate_json, "duplicate JSON key")

    def wrong_provenance(doc, fixture):
        next(c for c in fixture["cases"] if c["id"] == "C-POL-05")["dcr_uses_defaults"] = False
    rejected("wrong-dcr-provenance", wrong_provenance, "DCR provenance")

    if stage in {"consumers", "complete"}:
        def missing_consumer(doc, fixture):
            fixture["cases"] = [c for c in fixture["cases"] if c["id"] != "C-APP-01"]
        rejected("missing-consumer", missing_consumer, "references missing case")

        def caller_target(doc, fixture):
            fixture["cases"][next(i for i,c in enumerate(fixture["cases"]) if c["id"] == "C-APP-11")]["expired"] = "401 invalid_token"
        rejected("caller-target-swap", caller_target, "incorrect outcome")

        def token_cap(doc, fixture):
            fixture["cases"][next(i for i,c in enumerate(fixture["cases"]) if c["id"] == "C-TOK-01")]["jwt_exp"] = 161
        rejected("token-cap-disagreement", token_cap, "token cap")

        def extension_accepted(doc, fixture):
            fixture["cases"][next(i for i,c in enumerate(fixture["cases"]) if c["id"] == "C-MGMT-07")]["changed_extension"] = "200 accepted"
        rejected("forbidden-extension-accepted", extension_accepted, "server-owned extension changes")

        def plaintext_get(doc, fixture):
            fixture["cases"][next(i for i,c in enumerate(fixture["cases"]) if c["id"] == "C-MGMT-01")]["plaintext_returned"] = True
        rejected("get-plaintext", plaintext_get, "GET must be side-effect free")

        def expired_put(doc, fixture):
            fixture["cases"][next(i for i,c in enumerate(fixture["cases"]) if c["id"] == "C-APP-15")]["expired"] = "200 accepted"
        rejected("expired-app-put-success", expired_put, "consumer inventory is missing or has an incorrect outcome")

        def disabled_get(doc, fixture):
            fixture["cases"][next(i for i,c in enumerate(fixture["cases"]) if c["id"] == "C-APP-16")]["expired"] = "allow GET"
        rejected("disabled-app-get-success", disabled_get, "consumer inventory is missing or has an incorrect outcome")

    if stage == "complete":
        def dropped_fields(doc, fixture):
            fixture["cases"][next(i for i,c in enumerate(fixture["cases"]) if c["id"] == "C-LEG-07")]["dropped_fields"] = "accepted"
        rejected("adapter-dropped-fields", dropped_fields, "adapter dropped-field")

        def old_writers(doc, fixture):
            fixture["cases"][next(i for i,c in enumerate(fixture["cases"]) if c["id"] == "C-DEP-01")]["order"].remove("drain_web_admin_jobs_cli_old_writers")
        rejected("missing-old-writer-drain", old_writers, "deployment partial order")

        def secret_date_reactivated(doc, fixture):
            fixture["cases"][next(i for i,c in enumerate(fixture["cases"]) if c["id"] == "C-LEG-04")]["promoted_dates"]["secret"] = 110
        rejected("rat-only-reactivates-secret-date", secret_date_reactivated, "canonicalize all dates")

        def unknown_is_legacy(doc, fixture):
            fixture["cases"][next(i for i,c in enumerate(fixture["cases"]) if c["id"] == "C-LEG-07")]["unknown_row_version"] = "legacy"
        rejected("unknown-version-as-legacy", unknown_is_legacy, "unknown version")

        def stale_hash(doc, fixture):
            fixture["cases"][next(i for i,c in enumerate(fixture["cases"]) if c["id"] == "C-RACE-01")]["presented_token_matches_current_hash"] = False
        rejected("stale-management-hash", stale_hash, "bind current hash")

        def prelock_time(doc, fixture):
            fixture["cases"][next(i for i,c in enumerate(fixture["cases"]) if c["id"] == "C-RACE-06")]["old_ingress_time_authorizes"] = True
        rejected("pre-lock-time-authorizes", prelock_time, "ingress timestamp")

        def cleared_rollback(doc, fixture):
            fixture["cases"][next(i for i,c in enumerate(fixture["cases"]) if c["id"] == "C-DEP-03")]["rollback_state_retained_after_v1_write"] = False
        rejected("cleared-rollback-state", cleared_rollback, "retain authoritative state")

        def reversed_cutover(doc, fixture):
            fixture["cases"][next(i for i,c in enumerate(fixture["cases"]) if c["id"] == "C-DEP-01")]["order"].reverse()
        rejected("reversed-cutover", reversed_cutover, "deployment partial order")

    return checks


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--stage", choices=("policy", "consumers", "complete"), required=True)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    try:
        contract = CONTRACT_PATH.read_text(encoding="utf-8")
        data = strict_json(CASES_PATH.read_text(encoding="utf-8"))
        validate(contract, data, args.stage)
        mutations = self_test(contract, data, args.stage) if args.self_test else []
    except (OSError, ContractError) as exc:
        print(f"FAIL {args.stage}: {exc}", file=sys.stderr)
        return 1
    print(f"PASS {args.stage}: design consistency only; {SCOPE}")
    if mutations:
        print("Rejected mutations: " + ", ".join(mutations))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
