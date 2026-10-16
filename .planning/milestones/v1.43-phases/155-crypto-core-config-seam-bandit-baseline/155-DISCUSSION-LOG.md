# Phase 155: Crypto Core, Config Seam & Bandit Baseline - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-10-15
**Phase:** 155-crypto-core-config-seam-bandit-baseline
**Mode:** assumptions
**Areas analyzed:** Read seam, Config/boot/diagnostics, Hosts and test fixtures

## Assumptions Presented

### Read seam
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Map-form decode replaces the binary clause; all six sites already hold `kid` | Confident | `private_jwk.ex:5-16`, `id_token.ex:26,36`, `logout_token.ex:19,35`, `jarm.ex:55`, `introspection_jwt.ex:36`, `access_token_signer.ex:206-208`, `jar.ex:43` |
| JAR keeps `:decryption_failed`; others `:invalid_signing_key` | Confident | `jar.ex:38-55`, `request_object.ex:88-95` |
| KeyCache/JWKS/discovery never touch private material | Confident | `key_cache.ex:53,75`, `signing_key_store.ex:29,55,253` |

### Config, boot and diagnostics
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `key_encryption!/0` validates fresh; only boot caches in `:persistent_term` | Likely | `lockspire.verify.ex:10`, `lockspire.doctor.token_format.ex:18` (`app.config` only) |
| Verify KEK check uses `:ok | :error`; missing KEK fails verify | Likely | `verify.ex:45,48-76`, `verify/check.ex:6-12` |
| Doctor needs a new `key_encryption` subcommand | Confident | `lockspire.doctor.ex:10-27` |

### Hosts and test fixtures
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Clean-room provider gets a test KEK in 155 | Confident | `bootstrap.ex:5`, `build_provider.py:51-75,335`, `run_test_matrix.sh:124-126`, `ci.yml:345` |
| `config/test.exs` keeps `:allow`; only two shared helpers seal | Confident | `config/test.exs:29-34`, ~25 direct-insert fixtures |

## Roadmap/Research Discrepancies Found
1. Clean-room KEK scheduled in 157-02 but needed in 155 (CI would be red in between).
2. "Token exchange" read site is the JWT access-token signer for all grants.
3. JAR surfaces `:decryption_failed`, not `:invalid_signing_key`.
4. Doctor has no general run; needs a new subcommand.
5. Verify `Check` has only `:ok | :error`.
6. Demo Bandit is `~> 1.11`, compat fixture has bandit only transitively.
7. `private_jwk_test.exs` also uses binary-form decode.
8. KeysLive maps every generate error to generic copy (left as is).
9. No existing `@derive Inspect` or Redaction coverage for new fields.

## Corrections Made

No corrections — all assumptions confirmed. User explicitly confirmed verify failing on a KEK-less host (option "Yes, proceed (Recommended)" over "Verify warns only").
