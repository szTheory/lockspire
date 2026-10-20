---
phase: "158"
slug: "mix-task-repo-start"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-10-19"
---

# Phase 158 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Mix task → terminal / CI log | Task output is read by the developer and captured by CI | Client secret (once, on success); failure reasons (fixed phrases only) |
| Mix task → host repo pool | Task may start a temporary pool or call a running one | DB connection lifecycle; client rows |
| Mix task → Logger | Ecto query logs emitted while the task writes | Query text and parameters (secret hash material) |
| Clean-room harness → CI evidence | Harness captures child mix output | Client secret in captured stdout |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-158-01 | Information disclosure | client.create success printer | high | mitigate | `client_secret=` printed only after a successful `TaskError.run` (`lib/mix/tasks/lockspire.client.create.ex:117-118`); cold test counts exactly one line | closed |
| T-158-02 | Information disclosure | TaskError.classify/1 | high | mitigate | fixed phrases; no `inspect(`/exception message in `task_error.ex`; ArgumentError passthrough limited to `@config_message_prefixes` (line 24, 102); `catch` → unexpected phrase (line 91) | closed |
| T-158-03 | Information disclosure | Ecto query logs during register_client | medium | mitigate | process level raised to `:warning` and restored (`task_error.ex:85,98-99`; strengthened from `:info` by WR-03 fix) | closed |
| T-158-04 | Denial of service | already-running host pool | high | mitigate | tasks route through unchanged RepoRunner; no `Migrator`/`with_repo` in task code (grep empty); pool fingerprint tests | closed |
| T-158-05 | Information disclosure | clean-room evidence | high | mitigate | `register_secret` + `assert_redaction_guard` right after parsing (`clean_room_saas_journey.py:856-858`); `_run_mix` redacts `client_secret=` on the failure path (WR-02 fix) | closed |
| T-158-06 | Information disclosure | token_format / remote-jwks failure lines | high | mitigate | `inspect(` count 0 in both doctor tasks; TaskError phrases asserted by RaisingRepo tests | closed |
| T-158-07 | Tampering | cold test cleanup | medium | mitigate | deletes only `mix-cold-` prefixed rows; foreign-row guard counts non-prefix rows and aborts (WR-04 fix keeps foreign rows untouched) | closed |
| T-158-08 | Information disclosure | Postgrex connection-process logs on unreachable DB | low | accept | see accepted risks | closed |
| T-158-09 | Denial of service | already-running pool in warm doctor runs | high | mitigate | `assert_pool_untouched!` in both doctor test modules, repo_runner_test and clients_test | closed |
| T-158-10 | Information disclosure | RegistrationResult inspect | high | mitigate | `@derive {Inspect, except: [:client_secret]}` (`registration_result.ex:13`); refute in clients_test | closed |
| T-158-11 | Information disclosure | :base persistence error detail | medium | mitigate | fixed phrase for `:base`, detail never rendered (`client.create.ex:142-144`) | closed |
| T-158-12 | Information disclosure | query debug logs during client.create | high | mitigate | cold log-capture test at `:debug` and `:info` with a non-vacuous control asserting INSERT is visible without the guard (`lockspire_client_create_cold_test.exs:163,214-215`) | closed |
| T-158-13 | Information disclosure | config ArgumentError passthrough | low | mitigate | allowlist only; value-carrying ArgumentError withheld (task_error_test) | closed |
| T-158-14 | Repudiation | crash after committed write | low | accept | see accepted risks | closed |
| T-158-SC | Tampering | npm/pip/cargo installs | high | accept | see accepted risks; `mix.exs`/`mix.lock` unchanged | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-158-01 | T-158-08 | Connection errors for an unreachable DB are logged by DBConnection/Postgrex pool processes (host:port, no credentials), the same as `mix ecto.migrate`; not controllable from the caller. Documented in RESEARCH and the TaskError comment. | plan 158-02 | 2026-10-19 |
| AR-158-02 | T-158-14 | A crash after the committed write prints no secret; help text tells the developer to rotate, and `created_by` on the row is the CLI audit trail. | plan 158-03 | 2026-10-19 |
| AR-158-03 | T-158-SC | Phase installs no packages; no dependency changes (SAFE-02). | plans 158-01..03 | 2026-10-19 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-19 | 15 | 15 | 0 | secure-phase orchestrator (ASVS L1 grep-depth, plan-time register) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-19
