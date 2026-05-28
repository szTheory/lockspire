# Phase 99: Signer Extraction + JWT-Default Issuance - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-28
**Phase:** 99-signer-extraction-jwt-default-issuance
**Mode:** assumptions
**Areas analyzed:** AccessTokenSigner module shape; format-policy resolution; per-client field plumbing + admin UI; resource→aud threading (incl. device/CIBA gap); discovery advertisement

## Assumptions Presented

### AccessTokenSigner module shape (SIGNER-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| New `Protocol.AccessTokenSigner` takes `%Token{}`+`client`+`request`, returns existing `{:ok, raw, hash}` triple, owns both `:jwt` (JOSE) and `:opaque` (TokenFormatter) branches; call sites become one-line swaps | Confident | `token_exchange.ex:1387-1418` (`build_access_token/6`), `refresh_exchange.ex:284-310`, `rfc8693_exchange.ex:317-348` (returns same triple) |

### Format-policy resolution (FORMAT-01, SIGNER-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Server-wide `access_token_format` (default `:jwt`) on runtime-editable `ServerPolicy`, NOT `Config`; precedence per-client → server-default → `:jwt`, resolved in one place inside signer | Confident | `server_policy_record.ex:14-25` (runtime Ecto.Enums), `security_profile.ex:29-60` (resolve precedence template), `discovery.ex:159` (get_server_policy) |

### Per-client field plumbing + admin UI (FORMAT-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Nullable `Ecto.Enum [:jwt,:opaque]` (no DB default = `nil` inherit) on `client_record.ex`, threaded through both changesets + to_domain + Domain.Client struct; admin `inherit/jwt/opaque` select + doclink mirroring `dpop_policy` | Confident | `id_token_signed_response_alg` precedent at `client_record.ex:57,129,218,288`/`domain/client.ex:50`; `form_component.ex:95-105`, `show.ex:169-171`, `clients.ex:472-484` |

### resource→aud threading + device/CIBA gap (AUD-01, AUD-02, AUD-03)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Signer derives `aud` from `%Token{}.audience` ([resource] when present, [client_id] when absent); AC/refresh already thread resource, **device/CIBA do NOT** and need net-new validation+threading; RFC 8693 keeps `aud=client_id` with no resource | Confident | `token_exchange.ex:661-689,705` + `refresh_exchange.ex:155-178,306` (AC/refresh thread); `token_exchange.ex:809,955` (device/CIBA hardcode `audience: []`); `rfc8693_exchange.ex:327` |

### Discovery advertisement (DISCOVERY-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add `access_token_signing_alg_values_supported: ["RS256","ES256","PS256"]` to discovery, published unconditionally; do NOT reuse `allowed_signing_algorithms/1` (returns EdDSA for `:none`, only ES256/PS256 under FAPI) | Likely | `discovery.ex:86-96,95,154-156`; `security_profile.ex:62-64` |

## Corrections Made

No corrections — all five assumptions confirmed with "Yes, proceed" (2026-05-28).

## External Research

None performed — analyzer flagged no research gaps. RFC 9068 (`at+jwt`) and RFC 8707 (`resource`→`aud`) are already implemented in the codebase (`rfc8693_exchange.ex:317-348`, `validate_requested_resources/2`).
