---
phase: 132
slug: public-api-and-resource-server-truth
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-26
---

# Phase 132 — Validation Strategy

> Per-phase contract for public API, client-shape, DPoP durability, and documentation truth.

## Test Infrastructure

| Property | Value |
|---|---|
| **Framework** | ExUnit with Plug/Phoenix fixtures and Ecto SQL Sandbox |
| **Config** | `mix.exs`, `test/test_helper.exs`, `config/test.exs` |
| **Quick run** | `mix test test/lockspire/access_token_test.exs test/lockspire/plug/verify_token_test.exs test/lockspire/clients_test.exs test/lockspire/protocol/registration_test.exs test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/protocol/protected_resource_dpop_test.exs` |
| **Integration run** | `mix test --include integration test/integration/protected_resource_dpop_default_store_test.exs test/lockspire/storage/ecto/repository_dpop_replay_test.exs test/integration/install_generator_test.exs` |
| **Full gate** | `mix test.fast && mix test.integration && mix qa && mix docs.verify` |
| **Feedback target** | Focused task checks under 90 seconds; full gate before verification |

## Sampling Rate

- After every task commit: run the task's exact `<automated>` command.
- After Wave 1: run all token, registration, Plug/protocol replay, and repository integration files in this document.
- After Wave 2: run install/release documentation contracts plus `mix docs.verify`.
- Before phase verification: run `mix compile --warnings-as-errors`, `mix test.fast`, `mix test.integration`, `mix qa`, and `mix docs.verify`.
- No three consecutive implementation tasks may pass without behavioral automated evidence.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure behavior | Test type | Automated command | Status |
|---|---|---:|---|---|---|---|---|---|
| 132-01-T1 | 132-01 | 1 | API-01 | T-132-01 | Public scope/audience reads and actual Plug enforcement share normalization while missing/invalid audience errors remain distinct. | unit + signed-JWT Plug | `mix test test/lockspire/access_token_test.exs test/lockspire/plug/verify_token_test.exs` | ⬜ pending |
| 132-01-T2 | 132-01 | 1 | API-01 | T-132-02, T-132-03 | NumericDate and allowlisted confirmation readers are total and match sender-binding interpretation. | unit + signed-JWT Plug | `mix test test/lockspire/access_token_test.exs test/lockspire/plug/verify_token_test.exs` | ⬜ pending |
| 132-02-T1 | 132-02 | 1 | API-02 | T-132-04 | Direct OIDC/device-only success and mixed/code redirectless rejection are persisted and deterministic. | repository-backed facade | `mix test test/lockspire/clients_test.exs` | ⬜ pending |
| 132-02-T2 | 132-02 | 1 | API-02 | T-132-05, T-132-06, T-132-07 | Direct private_key_jwt is confidential, key-complete, HTTPS constrained, persisted, and redaction-safe. | repository-backed facade | `mix test test/lockspire/clients_test.exs` | ⬜ pending |
| 132-02-T3 | 132-02 | 1 | API-02 | T-132-04, T-132-05 | DCR service/HTTP boundaries and discovery share capability truth while runtime authorization retains exact redirect membership. | protocol + HTTP + runtime | `mix test test/lockspire/clients_test.exs test/lockspire/protocol/registration_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/discovery_test.exs test/lockspire/web/controllers/registration_controller_test.exs` | ⬜ pending |
| 132-03-T1 | 132-03 | 1 | API-03 | T-132-09 | Omitted replay override reaches Config.repo!/Repository and duplicate proof fails across requests. | Plug + Ecto integration | `mix test --include integration test/integration/protected_resource_dpop_default_store_test.exs` | ⬜ pending |
| 132-03-T2 | 132-03 | 1 | API-03 | T-132-10, T-132-11 | Compatible custom stores work and unavailable/invalid stores never accept or fall back. | Plug + protocol unit | `mix test test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/protocol/protected_resource_dpop_test.exs` | ⬜ pending |
| 132-04-T1 | 132-04 | 2 | API-03, API-04 | T-132-14, T-132-15 | Canonical/generated pipeline uses configured durable default and remains template/fixture aligned. | generator compile + docs | `mix test test/integration/install_generator_test.exs && mix docs.verify` | ⬜ pending |
| 132-04-T2 | 132-04 | 2 | API-01, API-04 | T-132-13 | Generated controller executes all semantic readers and a separate host policy decision. | generated-host integration | `mix test test/integration/install_generator_test.exs test/lockspire/access_token_test.exs` | ⬜ pending |
| 132-04-T3 | 132-04 | 2 | API-01, API-02, API-03, API-04 | T-132-13, T-132-14, T-132-15 | Supported surface, upgrade guide, and test inventory agree with compiled names and bounded behavior. | release/docs contract | `mix test test/lockspire/release/support_surface_contract_test.exs test/lockspire/release_readiness_contract_test.exs test/integration/install_generator_test.exs && mix docs.verify` | ⬜ pending |

## Wave 0 Requirements

Existing infrastructure covers the phase; implementation adds tests alongside behavior.

- [x] Signed at+jwt fixture helpers and Plug connection harness exist in `verify_token_test.exs`.
- [x] TestRepo, SQL Sandbox, durable DPoP migration, and repository replay tests exist.
- [x] Direct and DCR repository-backed fixtures exist.
- [x] Actual installer template rendering and generated-host compilation harness exists.
- [x] Release/support-surface and exact test-name inventory contracts exist.
- [ ] `test/integration/protected_resource_dpop_default_store_test.exs` is created by 132-03-T1 before its first green integration gate.

## ASVS L1 Blocking Gate

All high-severity threats are blocking. A plan may not create its summary while its named command is red, and Phase 132 may not complete while any high-severity row lacks current automated evidence.

| ASVS L1 area | High threats | Named evidence |
|---|---|---|
| V4 Access Control / V5 Validation — common token semantics | T-132-01, T-132-02 | AccessToken and VerifyToken focused suites with signed JWT parity and malformed cases. |
| V2 Authentication / V6 Cryptography — safe client shapes | T-132-04, T-132-05, T-132-06 | Direct/DCR capability matrices, persisted key assertions, and AuthorizationRequest exact mismatch tests. |
| V3 Session Management — durable replay | T-132-09 | Configured-TestRepo Plug integration accepts once and rejects identical proof on a fresh call. |
| V4/V7 — store failure remains closed | T-132-10, T-132-11 | Plug/protocol custom-store tests assert unavailable/invalid overrides never verify binding or fall back. |
| V4/V14 — adoption guidance cannot omit policy or replay controls | T-132-13, T-132-14, T-132-15 | Actual generated-host integration plus bounded support/release contracts and `mix docs.verify`. |

## Required Negative Cases

- AccessToken: missing/blank/non-binary subject; malformed scope; audience nil/blank/empty/non-string-list; non-integer/out-of-range expiry; empty/unknown/malformed confirmation.
- VerifyToken: normalized list/scalar audiences and scopes; `:missing_audience` versus `:invalid_audience`; invalid confirmation never becomes a sender requirement.
- Registration: direct and DCR `openid`; device-only/no redirect; code and mixed/no redirect; incoherent grant/response; wildcard, fragment, and exact runtime mismatch.
- private_key_jwt: no key, both key sources, unsafe URI, public client, unsupported/none algorithm, redacted error/telemetry; successful inline and remote source persistence.
- DPoP: absent override durable default, repeated proof, accepting/replaying/unavailable custom store, invalid override, and no fallback after error.
- Documentation: no custom-store prerequisite, no nonexistent AccessToken fields, no suggestion that protocol validation replaces tenant/object/product authorization, and no breaking raw-claims removal claim.

## Multi-Source Coverage Audit

| Source | ID | Feature / constraint | Plan | Status | Notes |
|---|---|---|---|---|---|
| GOAL | — | Documented client and resource-server APIs require no raw claims or unsupported internals | 132-01..04 | COVERED | Behavior first, canonical documentation last. |
| REQ | API-01 | Normalized subject/scopes/audiences/expiration/confirmation readers | 132-01, 132-04 | COVERED | Additive API plus executable examples. |
| REQ | API-02 | Register advertised OIDC/private_key_jwt/device-only shapes with exact redirects | 132-02, 132-04 | COVERED | Shared validation and boundary-specific results. |
| REQ | API-03 | Durable repository replay default plus custom injection | 132-03, 132-04 | COVERED | Actual configured-repo Plug integration. |
| REQ | API-04 | Resource-server docs/API/boundary/deprecation truth | 132-04 | COVERED | Canonical guide, fixture, support surface, upgrade guide, drift proof. |
| CONTEXT | D-01..D-04 | Additive shared AccessToken semantic contract and preferred examples | 132-01, 132-04 | COVERED | Raw claims preserved. |
| CONTEXT | D-05..D-08 | Coherent capability-aware registration and errors | 132-02 | COVERED | Direct and DCR matrix. |
| CONTEXT | D-09..D-12 | Durable fail-closed default and injectable store | 132-03, 132-04 | COVERED | No process-local fallback. |
| CONTEXT | D-13..D-16 | Canonical docs, host boundary, compatibility, focused phase proof | 132-04 | COVERED | Phase 133/134 boundaries retained. |
| RESEARCH | — | Total readers with strict verifier error helper | 132-01 | COVERED | Missing/malformed audiences stay distinct. |
| RESEARCH | — | One pure registration capability matrix and persisted keys | 132-02 | COVERED | No endpoint exception drift. |
| RESEARCH | — | Nil-mask repair through real configured repo | 132-03 | COVERED | Integration file is explicit. |
| RESEARCH | — | Template/fixture/docs/release drift proof | 132-04 | COVERED | Actual compile/behavior, not string-only substitution. |

Excluded by source: Phase 133 clean-room external client/full HTTP lifecycle, Phase 134 broad dependency topology, new grants, hosted auth, host product-policy APIs, and admin redesign.

## Manual-Only Verifications

None. Phase 132 has no visual redesign or external-service setup; all acceptance behavior is automatable in the repository.

## Validation Sign-Off

- [x] Every task declares an automated command.
- [x] Every high-severity STRIDE threat maps to named ASVS L1 evidence.
- [x] Tests exercise actual Plug, Repository, registration, authorization-request, generated-template, and docs behavior rather than string-only substitutes.
- [x] Wave 1 plans have no file overlap and may execute in parallel; Wave 2 consumes their final public names and behavior.
- [x] All four requirements and all sixteen locked decisions are covered.
- [x] Nyquist auditor confirmed implemented coverage and set `status: validated`, `nyquist_compliant: true` on 2026-08-27.

**Approval:** validated by post-execution Nyquist audit.

## Nyquist Audit — 2026-08-27

**Status:** CLOSED — 10/10 validation checks green.

The auditor added `test/lockspire/access_token_test.exs` coverage for an `aud`
claim containing both a valid identifier and a blank member:

```elixir
%{"aud" => ["billing-api", "   "]}
```

Required behavior is `[]` from `AccessToken.audiences/1` and
`{:error, :invalid_audience}` from `AccessToken.normalize_audiences/1`, because
the documented contract accepts only a nonempty list of nonblank strings.
Commit `e48bcb8` makes list validation atomic: every member must be a nonblank
binary before the list is deduplicated. The adversarial test is now green.

All independent targeted coverage passed:

- Core API/registration/DPoP suites: 267 tests, 0 failures.
- Durable default replay, generated-host behavior, release contracts: 57 tests,
  0 failures.
- Re-audit of AccessToken and VerifyToken semantics after the repair:
  `mix test test/lockspire/access_token_test.exs test/lockspire/plug/verify_token_test.exs`
  — 84 tests, 0 failures.

Validation is now `validated`, `wave_0_complete: true`, and
`nyquist_compliant: true`. The adversarial test remains as regression coverage.
