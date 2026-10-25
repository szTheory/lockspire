---
phase: "172"
slug: "authorization-responses"
status: verified
threats_found: 6
threats_closed: 6
threats_open: 0
asvs_level: 1
created: "2026-10-24"
---

# Phase 172 — Security

Independent typed security auditor verified the six plan-authored mitigations at HEAD `8318d001f418b9623e5a2d58b1507d5013c2b1e7`. ASVS level 1, blocking threshold high. This covers the declared scope; it is not a certification or external-profile result.

## Trust Boundaries

Browser input enters protocol validation before host resolution. Error disposition selects escaped first-party HTML, callback delivery or PAR JSON. Host code retains account/session/login and authentication-time authority. Current input identities remain separate from historical qualification observations.

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / evidence | Status |
|-----------|----------|-----------|----------|-------------|-----------------------|--------|
| T-172-01 | Information disclosure | Unsupported mode delivery | high | mitigate | `authorization_request.ex:582` calls browser_error/3; helper clears callback/state. `authorize_controller.ex:34` delivers HTTP 400. Router regression at `authorize_controller_test.exs:116` proves query control, HTML, no Location or structured parameters. | closed |
| T-172-02 | Tampering | Browser HTML | medium | mitigate | `authorize_html.ex:9` escapes description/reason via Plug.HTML. Static description and renderer unchanged. | closed |
| T-172-03 | Tampering | Strict modes and PAR | high | mitigate | Existing allow-set, pushed normalization, defaults/JWT normalization and strict reason retained. Protocol strict owners pass; PAR controller regression verifies JSON, absent redirect, cache headers and no inserted request. | closed |
| T-172-04 | Elevation of privilege | Host authentication seam | high | mitigate | Controller host resolver remains unchanged. Phase 37 absent/stale/fresh session tests pass, preserving host authentication-time authority. | closed |
| T-172-05 | Repudiation | Qualification provenance | medium | mitigate | Independent frozen-content, receipt/probe bytes, audit-prefix, allowed-identities, order and digest checks pass. New summary records separate source-bound RED/GREEN. | closed |
| T-172-SC | Tampering | Dependency inputs | high | mitigate | Diff since `6e160651` changes no dependency/lock inputs. No install, new package or legitimacy exception. | closed |

## Verification Evidence

Auditor ran the following at the audited HEAD with Elixir 1.19.5/OTP 28.5 and the owned database:

```text
ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test --include integration test/lockspire/web/authorize_controller_test.exs test/lockspire/web/pushed_authorization_request_controller_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/pushed_authorization_request_test.exs test/integration/phase37_protocol_strictness_e2e_test.exs test/lockspire/qualification_ledger_contract_test.exs
```

Exit 0: 121 tests, 0 failures, 9.8 seconds, seed 219710, integration included. Independent preservation comparisons and git/source hash checks passed. No unregistered summary threat flags. Auditor made no edits; root persisted this returned verdict.

## Accepted Risks Log

No accepted risks. Blocking open: 0. Below-threshold open: 0.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-24 | 6 | 6 | 0 | Typed gsd-security-auditor; root artifact writer |

## Sign-Off

- [x] Every planned threat has a verified mitigation
- [x] No risk acceptance used to close threats
- [x] threats_open: 0
- [x] status: verified

Approval: verified 2026-10-24.
