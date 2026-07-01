# Phase 100: Sender-Constraint End-to-End Proof - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-28
**Phase:** 100-sender-constraint-end-to-end-proof
**Mode:** assumptions
**Areas analyzed:** BIND-03 bypass-closure mechanism; DPoP end-to-end proof (BIND-01); mTLS end-to-end proof (BIND-02); bound-token issuance fixture; test placement

## Assumptions Presented

### BIND-03 bypass-closure mechanism
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Initial: contract-test ordering clause only (proof-only) | Confident (as a feasible default) | `access_token.ex` 7-field struct (no verified marker); `enforce_sender_constraints.ex:67-128` no success-marker; `require_token.ex:20-35` never inspects `binding_requirements`; all four canonical blocks already ordered correctly (no content-hash ripple) |
| Revised after research → runtime fail-closed guard + contract test | Confident | RFC 9449 §7.2 MUST-reject; CVE-2024-49755 (Duende); corpus secure-by-default-as-only-default + golden rule (token validation is library-owned) + PKCE-downgrade runtime-rejection precedent; Guardian fail-closed/`Plug.Builder` idiom |

### DPoP end-to-end proof (BIND-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Lift `phase81` harness through `GeneratedHostAppWeb.Endpoint`; mint via `AccessTokenSigner.issue/3` (not hand-signed) | Likely | `phase81...e2e_test.exs:150-215`; `generated_host_app_web/router.ex:19-27`; `access_token_signer.ex` `maybe_put_cnf/2` |

### mTLS end-to-end proof (BIND-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| New test; cert via `conn.private[:lockspire_mtls_cert]`; `cnf["x5t#S256"]` via `MTLSTokenBinding.thumbprint/1` | Confident | `enforce_sender_constraints.ex:178-189`; `mtls_token_binding.ex:7-27`; `enforce_sender_constraints_test.exs:193,238` |

### Bound-token issuance fixture
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `AccessTokenSigner.issue/3` + `KeyCache` publish-then-sign; not a full token-endpoint exchange | Likely | `verify_token_test.exs:39-91`; `access_token_signer_test.exs:21-31,247-256` |

### Test placement
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| New `test/integration/phase100_sender_constraint_e2e_test.exs`; BIND-03 contract clause in `release_readiness_contract_test.exs`; plug-layer negative test | Likely | `phase81` convention; `release_readiness_contract_test.exs:140-157,761-791` |

## Corrections Made

### BIND-03 mechanism
- **Original assumption (recommended default):** Contract-test ordering clause only — "proof only," near-free, no runtime code.
- **User action:** Declined to pick from the binary. Requested deep research using subagents — pros/cons/tradeoffs, idiomatic Elixir/Plug/Phoenix, lessons from successful libraries (incl. other ecosystems), footguns to avoid, DX/least-surprise, and the `prompts/` corpus — to one-shot a single coherent recommendation.
- **Resolution:** Two independent research passes (ecosystem/idiomatic-Elixir advisor + `prompts/` corpus miner) both converged on **runtime fail-closed guard + contract test (defense-in-depth)**. Locked as D-01..D-05. Implementation shape: positive `binding_verified: false` field (not clearing `binding_requirements`); guard fires only for bound-but-unverified tokens (surprise-free for bearer-only routes).
- **Reason:** RFC 9449 §7.2 normative MUST-reject; CVE-2024-49755 precedent; Lockspire's own corpus mandates secure-by-default-as-only-default and treats token-binding enforcement as library-owned protocol truth; Guardian establishes the fail-closed-downstream-plug idiom. Contract-test-only would leave a spec-MUST-violating bypass reachable by any host that omits the enforcement plug — below a 1.x GA auth library's bar.

### Areas B–E (DPoP/mTLS harness, issuance fixture, test placement)
- Confirmed as-is by the user ("All correct — proceed"). No corrections.

## Auto-Resolved
Not applicable (no `--auto`).

## External Research
- **RFC 9449 §7.1/§7.2** — resource-server DPoP handling; §7.2 MUST reject a DPoP-bound token received as a bearer token. (Basis for the BIND-03 runtime guard.)
- **CVE-2024-49755 (Duende IdentityServer)** — insufficient validation of the DPoP `cnf` claim in Local APIs let a bound token be used without proof-of-possession; the materialized form of the bypass-by-omission class.
- **Guardian (`Guardian.Plug.Pipeline` / `EnsureAuthenticated`)** — Elixir precedent: downstream plugs fail closed on absent prerequisite state and compose via `Plug.Builder`; licenses the cross-plug `binding_verified` coupling and points to the deferred single-composed-pipeline end-state.
- **Spring Security filter chain** — canonical "loud on misconfiguration" model; security middleware should make insecure assembly impossible or loud, never silently degraded.
- **Lockspire `prompts/` corpus** — `lockspire-security-posture-and-threat-model.md` ("secure-by-default even when stricter"; "make dangerous policy downgrades explicit and visible"); `Embedding...md` ("ship as the *only* default"; "secure-by-default config, conformance CI" as co-equal disciplines; PKCE-downgrade runtime-rejection precedent); `Oauth server jtbd and domain.md` (golden rule: "what a token says / how it's issued, library owns").
