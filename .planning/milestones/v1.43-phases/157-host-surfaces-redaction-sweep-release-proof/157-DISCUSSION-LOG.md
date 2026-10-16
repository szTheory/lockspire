# Phase 157: Host Surfaces, Redaction Sweep & Release Proof - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-10-16
**Phase:** 157-host-surfaces-redaction-sweep-release-proof
**Mode:** assumptions (user requested full fan-out, one-shot coherent recommendations, auto-follow)
**Areas analyzed:** Redaction sweep, Host surfaces, CI proof & SAFE-01, Docs & release, Plan shape & todos

## Assumptions Presented

### Redaction sweep
| Assumption | Confidence | Evidence |
|---|---|---|
| Sensitive repo queries on all key-material paths (156 residual) | Confident | signing_key_store.ex:12-22,35-44,62-108,268-279; support.ex:40-50; 156-VERIFICATION.md |
| `redact: true` on SigningKeyRecord field for changeset leakage | Likely | signing_key_record.ex:12,30-48; signing_key_store.ex:326-327 |
| Redaction drop-keys + LSK\x01 value guard; keep kid/kek_id | Likely | redaction.ex:8-200; 156 D-24..D-28 |
| Guard JOSE.JWK.from_map at decode boundary | Likely | logout_token.ex:35-43; PITFALLS C8 |
| No Process.flag(:sensitive); document crash dumps | Confident | SUMMARY Other resolutions; ROADMAP pitfalls |

### Host surfaces
| Assumption | Confidence | Evidence |
|---|---|---|
| Generator prints runtime block, never patches runtime.exs | Likely | generators/install.ex:124-136; 155 IN-03/AR-02 |
| Env var `LOCKSPIRE_KEY_ENCRYPTION_KEY`, YYYY-MM ids | Likely | config key name; R1 example; Phoenix SECRET_KEY_BASE precedent |
| Demo: env-with-demo-literal KEK, `:reject`, seeds via public API | Likely | seeds.exs:78-98,209-256; AR-03 |
| Clean-room: per-run random KEK from env, registered secret, `:reject` | Likely | build_provider.py:63-90,229-241,368-369 |

### CI proof & SAFE-01
| Assumption | Confidence | Evidence |
|---|---|---|
| One in-repo integration upgrade journey test (no old-Hex boot) | Likely | envelope_signing_consumers_test.exs; run_test_matrix.sh:124-126 |
| Demo + clean-room run `--check` and doctor | Likely | ci.yml:464-489; build_provider.py:341 |
| SAFE-01 gate at verification vs v1.42 tag | Confident | 156-VERIFICATION.md §SAFE-01; ci.yml:74-75,184-187 |

### Docs & release
| Assumption | Confidence | Evidence |
|---|---|---|
| Topic-named `docs/upgrading/signing-key-encryption.md` | Likely | docs/upgrading/storage-prefix.md; documentation_contract_test.exs |
| Non-breaking `feat` → 1.6.0 | Likely | SUMMARY R8; release-please-config.json; manifest 1.5.1 |
| PRODUCT.md/vocabulary untouched | Confident | ROADMAP SAFE-01 note; KEY-UI-01 deferred |

### Plan shape & todos
| Assumption | Confidence | Evidence |
|---|---|---|
| 4 plans / 2 waves | Likely | ROADMAP suggested plans |
| Neither pending todo folded | Confident | doctor key_encryption uses RepoRunner; DCR excluded by SAFE-01 |

## Corrections Made

No corrections. The user pre-authorized auto-following a coherent research-backed bundle. Orchestrator reconciliations between the two research strands:
- **Dev/test KEK:** codebase analysis proposed an optional env var in dev. The ecosystem research proposed a per-install random literal, following the Phoenix secret_key_base precedent. **Chose:** env var with a per-install random dev/test fallback (best first-run DX), prod fails closed. This stays consistent with IN-03's intent: no shared fixed literal, and prod is env-sourced.
- **Semver:** the ecosystem research flagged `feat!` as an option because `generate_key` is a public API. **Chose:** `feat` → 1.6.0, per the locked R8 compatibility design. The return type is unchanged ({:error, reason}), and an "action required" upgrade note leads the PR body.
- **Upgrade steps:** the ecosystem research proposed six steps. DOC-01 locks four. **Chose:** four steps plus a "Before you start" checklist (KEK backup, DB backup).

## External Research

- **Rotation pattern:** Rails AR Encryption, Ory Hydra, cloak_ecto, Django and Vault all use a key list where the current key encrypts and all keys decrypt, plus a migration-only legacy mode. cloak_ecto has no verification step, and Lockspire's `--check` fills that gap. (guides.rubyonrails.org/active_record_encryption.html; ory.com/docs/hydra/self-hosted/secrets-key-rotation; cloak-ecto.hexdocs.pm/rotate_keys.html)
- **Fail-closed install defaults:** Mastodon refuses to boot without its keys. The Phoenix runtime.exs `|| raise` idiom does the same. (hexdocs.pm/phoenix/releases.html)
- **Leak vectors:** the EEF Security WG recommends closures, stripping args from crypto exceptions, format_status, and attention to crash dumps. (security.erlef.org/secure_coding_and_deployment_hardening/sensitive_data)
- **Backup and key separation wording:** GitLab. Doorkeeper says a DB dump "still yields usable tokens" while its fallback is on.
- **Semver:** Conventional Commits `!` maps to a major bump. Release Please with `bump-minor-pre-major: false` on 1.5.1 would cut 2.0.0.
