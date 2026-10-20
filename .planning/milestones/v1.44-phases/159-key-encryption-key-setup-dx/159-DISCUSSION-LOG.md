# Phase 159: Key-Encryption Key Setup DX - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-10-19
**Phase:** 159-key-encryption-key-setup-dx
**Mode:** assumptions
**Areas analyzed:** Shared snippet builder and gen.kek, {:system, "VAR"} resolution, Redaction and guidance sweep, Scope boundary

## Assumptions Presented

### Shared snippet builder and gen.kek
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Extract snippet into `Lockspire.Generators.KekSnippet`, shared by installer and gen.kek | Confident | lib/lockspire/generators/install.ex:124-157; research ARCHITECTURE.md:97-100 |
| Output = env line + prod block + dev note; no dev block with real key; `--raw` value only | Likely | install.ex:152-157; FEATURES.md:116,126 |
| Keep `System.get_env || raise` in snippet; document `{:system}` as alternative | Likely | ARCHITECTURE.md:127 vs PITFALLS.md:66 |
| Plain Mix.Task, no app.config/repo/logs | Confident | lib/mix/tasks/lockspire.install.ex; STACK.md:26 |
| `--id` reuses KeySet regex via public predicate | Confident | key_set.ex:48,99-101 |

### {:system, "VAR"} resolution
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Resolve in `Config.key_encryption!/0`; KeySet stays pure | Confident | config.ex:253-266; application.ex:15,29-45 |
| Missing/empty var raises ArgumentError with `invalid config :key_encryption` prefix naming var only | Confident | task_error.ex:21-26; verify.ex:86-92 |

### Redaction and guidance sweep
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Inspect redaction already correct; add proof tests only | Confident | key_set_inspect.ex; key_encryption_test.exs:148-155 |
| Replace openssl guidance at 9 locations + 4 pinned tests; add contract test | Confident | grep openssl lib docs scripts test |

### Scope boundary
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| keys.reencrypt RepoRunner todo stays out | Likely | 158-CONTEXT.md:142 |

## Corrections Made

No corrections — all assumptions confirmed. Todos: user chose to fold none.
