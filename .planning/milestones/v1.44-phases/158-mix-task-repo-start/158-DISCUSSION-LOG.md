# Phase 158: Mix Task Repo Start - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-10-18
**Phase:** 158-mix-task-repo-start
**Mode:** assumptions (plus user-requested research fan-out: 1 assumptions analyzer + 3 advisor researchers)
**Areas analyzed:** Repo start, Real failure reasons, Secret and log safety, Tests, Clean-room reproduction

## Assumptions Presented

### Repo start
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Wrap only DB work in RepoRunner.run/2; keep app.config | Confident | repo_runner.ex:12-33; migrator.ex:817-852; application.ex:18-22 |
| Fun computes only; print/raise after run/2 | Confident | repo_runner.ex:19-22; keys.reencrypt.ex:108-124 |
| Ecto defaults, no :lockspire start, no deps | Confident | migrator.ex:162; config.ex:271; policy.ex:255 |

### Real failure reasons
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| RepoRunner unchanged; shared task helper maps DB exceptions to fixed safe reasons | Likely | support.ex:11; PITFALLS m1; policy.ex:190-192 |
| Validation errors one per line, "nothing was saved" | Confident | clients.ex:181-185,515-525; client_record.ex:187 |
| Exit semantics preserved; no inspect of exceptions | Confident | token_format.ex:5-7,64-65; remote_jwks.ex:72-80 |

### Secret and log safety
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Secret printed once after committed write | Confident | client.create.ex:81-111 |
| Inspect derive on RegistrationResult | Confident | registration_result.ex:13 |
| Lower process log level around fun | Likely | client_store.ex:16; Logger.put_process_level/2 |

### Tests
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Cold-path :integration modules per task | Likely | keys_reencrypt_test.exs:64-130,391-450; signing_key_upgrade_journey_test.exs:25-44 |
| Strengthened pool-untouched fingerprint | Confident | migrator.ex:823,847-850; repo_runner_test.exs:22 |

### Clean-room
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Three steps after doctor key_encryption, output-capturing runner | Likely | clean_room_saas_journey.py:910-924; build_provider.py:279-292 |
| Confidential client with register_secret | Likely | clean_room_saas_journey.py:63,336-371 |
| Reproduce-first commit, then fix, steps kept as success assertions | Confident | ROADMAP Phase 158 SC1 |

## Conflicts Resolved Between Researchers
- Where DB exceptions are classified: extend RepoRunner (researcher 1) vs rescue in task fun (analyzer) → shared task-side helper; RepoRunner unchanged.
- Clean-room client type: public (analyzer) vs confidential + register_secret (researcher 3) → confidential (exercises real seal path; secret prints only on success).
- Cold test tagging: untagged (researcher 3) vs :integration (analyzer) → :integration (committed-row precedent).

## Corrections Made

No corrections — all assumptions confirmed.

## External Research
- ecto_sql with_repo restart semantics (deps/ecto_sql/lib/ecto/migrator.ex:817-852; https://hexdocs.pm/ecto_sql/Ecto.Migrator.html#with_repo/3)
- Phoenix Release.migrate pattern (https://hexdocs.pm/phoenix/releases.html)
- Logger.put_process_level/2 (https://hexdocs.pm/logger/Logger.html#put_process_level/2)
- One-time secret display: Ory Hydra (https://www.ory.com/docs/hydra/cli/hydra-create-client); GitHub, AWS IAM, Stripe (prior knowledge)
- ecto_sql ecto.migrate_test.exs stub-repo precedent (https://github.com/elixir-ecto/ecto_sql/blob/master/test/mix/tasks/ecto.migrate_test.exs)
