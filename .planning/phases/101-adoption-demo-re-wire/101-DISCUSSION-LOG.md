# Phase 101: Adoption-Demo Re-Wire - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-28
**Phase:** 101-adoption-demo-re-wire
**Mode:** assumptions
**Areas analyzed:** Audience/resource contract, Canonical-block hash propagation, Sender-constraint pass-through, Issuance format + assigns wiring

## Assumptions Presented

### Audience / `resource=` contract
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `audience: "billing-api"` must become an absolute URI used byte-identically as the smoke's `resource=`; bare string cannot work | Confident | authorization_request.ex:594-626 (`valid_resource_uri?` rejects no-scheme/host); authorization_flow.ex:308 → access_token_signer.ex:121-145 (resource→aud); verify_token.ex:211-285 (exact `Enum.member?`) |

### Canonical-block hash propagation
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `audience:` edit is one line inside the hash-locked block, must propagate identically to all 4 files; smoke runtime `resource=` literal must equal block URI | Confident | Phase 97 `release_readiness_contract_test` normalized SHA-256 across docs/protect-phoenix-api-routes.md, demo router.ex:23-30, install template router.ex, smoke heredoc |

### Sender-constraint pass-through
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Plain bearer at+jwt passes EnforceSenderConstraints; `MyAppWeb.ProtectedApiReplayStore` need not exist; no module added to demo | Confident | enforce_sender_constraints.ex:55-65 (pass-through when binding_requirements nil), :92 (store read only in DPoP branch, required:false), init/1 lines 38-53 (no store resolution); repo search: only `GeneratedHostAppWeb.ProtectedApiReplayStore` defined |

### Issuance format + assigns wiring
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No per-client config change; acme-ledger-public issues at+jwt by server default; assigns.access_token carries fields api_controller reads; scope read:billing already requested | Confident | seeds.exs:72-87 (no access_token_format); server_policy.ex:38 (:jwt default); token_controller.ex:24 (policy store wired); verify_token.ex:124-136; require_token.ex:30-31; smoke line 181 (scope) |

## Corrections Made

No corrections — all four assumptions confirmed.

## Discretionary Decision Confirmed

- Canonical audience/resource URI string: user selected the recommended default **`https://billing.acme-ledger.test`** (the one genuine taste choice; absolute HTTPS, reserved `.test` TLD).

## External Research

None performed — every decision was resolvable from internal runtime code, tests, seeds, CI config, and the Phase-97 locked canonical block. The analyzer flagged no research gaps.
