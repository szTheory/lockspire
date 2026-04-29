# Phase 40: JWE Support for Request Objects - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-04-29
**Phase:** 40-jwe-support-for-request-objects
**Mode:** assumptions
**Areas analyzed:** Storage and Modeling of Encryption Keys, Key Lifecycle Activation Logic, JWE Decryption Pipeline Location, JWE Algorithm Strictness

## Assumptions Presented

### Storage and Modeling of Encryption Keys
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `Lockspire.Domain.SigningKey` and its associated `KeyStore` database schema will be expanded to support `use: :enc` rather than creating a separate `EncryptionKey` domain model. | Confident | `lib/lockspire/domain/signing_key.ex`, `lib/lockspire/protocol/jwks.ex`, `lib/lockspire/admin/keys.ex` |

### Key Lifecycle Activation Logic
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The `Lockspire.Storage.Ecto.Repository.activate_signing_key/2` function will be updated to isolate its active key retirement logic by the `use` attribute (`:sig` vs `:enc`). | Confident | `lib/lockspire/storage/ecto/repository.ex` logic around `fetch_active_signing_key_records/0` |

### JWE Decryption Pipeline Location
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| JWE decryption will occur in `Lockspire.Protocol.RequestObject` before the inner JWT is passed to `Lockspire.Protocol.Jar.verify_signature/2`, rather than pushing decryption deep into the `Jar` module. | Likely | `lib/lockspire/protocol/request_object.ex` orchestrates the request pipeline. `Protocol.Jar` is a pure verifier of JWS structures. |

### JWE Algorithm Strictness
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The decryption process will strictly enforce an allow-list of JWE `alg` and `enc` algorithms, rejecting deprecated or weak ciphers. | Confident | `Lockspire.Protocol.Jar` currently employs a strict `@allowed_algorithms` list for JWS signatures. |

## Corrections Made

No corrections — all assumptions confirmed.

## External Research

- **JOSE Library Behavior for JWE:** Using `JOSE.JWE.block_decrypt/2` returns a tuple `{decrypted_payload_binary, %JOSE.JWE{...}}`, where the decrypted payload is the raw compact JWS string. We must manually pipe this string into `JOSE.JWT` or `JOSE.JWS` to complete the nested JWT extraction. `JOSE.JWT.decrypt/2` will crash on nested JWTs. (Source: Local testing with `jose 1.11.12`)
- **OIDC/FAPI Required JWE Algorithms:** For `alg`, use `["RSA-OAEP", "RSA-OAEP-256", "ECDH-ES"]`. For `enc`, use `["A128CBC-HS256", "A256CBC-HS512", "A128GCM", "A256GCM"]`. `RSA1_5` is strictly forbidden for FAPI compliance. (Source: OIDC Core 1.0 Specification, FAPI 1.0/2.0 Profiles)