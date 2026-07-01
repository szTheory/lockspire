# Phase 102: Generated-Host Scaffolding + Telemetry + Migration - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-28
**Phase:** 102-generated-host-scaffolding-telemetry-migration
**Mode:** assumptions
**Areas analyzed:** Install scaffolding (SCAFFOLD-01/02), RS telemetry (TELEMETRY-01), Migration guide (MIGRATE-01), Doctor task (MIGRATE-02)

## Assumptions Presented

### A. Install scaffolding (SCAFFOLD-01 / SCAFFOLD-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| SCAFFOLD-01/02 already satisfied by Phases 97/101; commented canonical block renders verbatim into host router | Confident | `priv/templates/lockspire.install/router.ex:11-18`; `release_readiness_contract_test.exs:209-212`; `install_generator_test.exs:65-78` |
| Install task has no token-format prompt today | Confident | `lib/mix/tasks/lockspire.install.ex:16-26` |
| Phase 102 work = two regression guards (no-format-prompt refute + uncomment-ready assert) | Confident | reuse extraction helper `release_readiness_contract_test.exs:745-759` |

### B. RS telemetry (TELEMETRY-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Direct `:telemetry.execute([:lockspire, :rs, :token_format], ...)`, not `Observability.emit/4` | Likely | `observability.ex:29-41` (audit double-emit + redaction) |
| Numeric `%{count: 1}` measurement; categorical `token_format` value in metadata | Likely | `observability.ex:29-31` numeric-measurement convention |
| Two emit sites: JWT-success (~128-136) + opaque-rejection (~111-118) | Likely | `verify_token.ex`; `access_token.ex:6-15` (no top-level audience → read `claims["aud"]`) |
| Emit on opaque-rejection too, not success-only | Likely (judgment call) | `:opaque-rejected` only reachable on rejection path |
| Literal hyphenated atom `:"opaque-rejected"` | Likely (judgment call) | matches REQUIREMENTS.md TELEMETRY-01 text verbatim |

### C. Migration guide (MIGRATE-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Net-new `docs/upgrading/v1.27.md` (directory does not exist) | Confident | no `docs/upgrading/` dir |
| One-line opt-out is runtime `ServerPolicy.put_access_token_format(:opaque)`, NOT config | Confident | `admin/server_policy.ex:65-71`; Phase 99 D-04; no `config :lockspire` format key |
| Affected clients = those with `access_token_format: nil` (inherit `:jwt`) | Confident | `access_token_signer.ex:88-98`; `server_policy.ex:38` |

### D. Doctor task (MIGRATE-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| New `Mix.Tasks.Lockspire.Doctor.TokenFormat` subtask, dispatched by `run(["token_format" \| rest])` | Likely | `lockspire.doctor.ex:11-13` (remote-jwks precedent); `lockspire.doctor.remote_jwks.ex` |
| Enumerate via `Admin.Clients.list_clients/1`, reuse `AccessTokenSigner.resolve_format/2` for effective format | Likely | `clients.ex:82-85`; `access_token_signer.ex:88-98` |
| Read-only, diagnostic-only — flag `nil` clients, no enforcement/non-zero exit | Likely | criterion wording "diagnostic, not enforcement" |

## Corrections Made

No corrections — all assumptions confirmed. User selected "Yes, proceed", explicitly accepting the two flagged telemetry judgment calls (emit-on-opaque-rejection and the literal `:"opaque-rejected"` atom spelling).

## External Research

None performed — the contract is fully internal (shipped Phases 97-101 + REQUIREMENTS.md). The measurement-vs-metadata question was resolved from the in-repo `Observability.emit/4` convention.
