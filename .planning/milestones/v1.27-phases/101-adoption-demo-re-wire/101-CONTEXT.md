# Phase 101: Adoption-Demo Re-Wire - Context

**Gathered:** 2026-05-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

The adoption demo (`examples/adoption_demo/`) must execute an end-to-end auth-code → `at+jwt` → host-owned protected route (`/api/billing/summary`) → HTTP 200 round-trip in CI, replacing the current "401-on-anonymous" half-proof with executable adopter-facing evidence. The preserved `/userinfo` stored-opaque assertion stays (it correctly exercises the Lockspire-owned RS path). Requirements: DEMO-01, DEMO-02, DEMO-03.

**In scope:** Wiring the demo + `scripts/demo/adoption_smoke.py` to request a resource-bound `at+jwt`, call the host-owned protected route with it, and assert 200; making the canonical pipeline block's `audience:` an absolute URI; keeping the four-file hash-lock intact.

**Out of scope:** Runtime/plug behavior changes (Phases 98–100 are done), generated-host scaffolding / telemetry / migration / doctor (Phase 102), any protocol breadth.
</domain>

<decisions>
## Implementation Decisions

### Audience / `resource=` contract

- **D-01:** The canonical audience/resource value is the absolute HTTPS URI **`https://billing.acme-ledger.test`**. This single string is used byte-identically as (a) `VerifyToken`'s `audience:` in the canonical pipeline block and (b) the `resource=` parameter the smoke sends on the authorize/token requests. It replaces the current bare string `audience: "billing-api"`.
  - **Why:** `authorization_request.ex:594-626` (`valid_resource_uri?`) rejects any `resource` lacking a scheme/host (bare `"billing-api"` → `:invalid_target`). The validated resource flows verbatim into the token `aud` list (`authorization_flow.ex:308` → `access_token_signer.ex:121-145`), and `VerifyToken.validate_audience` does an exact `Enum.member?` against the configured `audience` (`verify_token.ex:211-285`) — no normalization. So both sides must be the same absolute URI or the round-trip 401s.
- **D-02:** The smoke's `exercise_authorization_code()` adds `resource: "https://billing.acme-ledger.test"` to BOTH the `/authorize` request params and the `/token` request params, so the issued `at+jwt` carries that value in its `aud` list. (Resource Indicators on the code request set the audience; the token request must echo it.)

### Canonical-block hash propagation (RECIPE-01 / Phase 97)

- **D-03:** Changing `audience:` is a single-line edit inside the hash-locked `# BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE` block, applied **identically** to all four hash-locked files:
  - `docs/protect-phoenix-api-routes.md`
  - `examples/adoption_demo/lib/adoption_demo_web/router.ex`
  - `priv/templates/lockspire.install/router.ex`
  - the `#`-commented heredoc carried in `scripts/demo/adoption_smoke.py`
  The `release_readiness_contract_test` normalized SHA-256 clause must still pass across all four. Editing fewer than four reds CI on a contract-hash mismatch.
- **D-04:** The smoke's **runtime** Python `resource=` literal is a separate value from the commented block but MUST equal the URI baked into the block (`https://billing.acme-ledger.test`). Drift between them reproduces the audience-mismatch 401.

### Sender constraints / replay store

- **D-05:** The demo's issued token is a plain bearer `at+jwt` (no DPoP, no mTLS, no `cnf`). It passes cleanly through `EnforceSenderConstraints` (pass-through when `binding_requirements` is nil — `enforce_sender_constraints.ex:55-65`). **No `ProtectedApiReplayStore` module is created in the demo.** The block's `MyAppWeb.ProtectedApiReplayStore` reference stays inert — it is never resolved at `init/1` and never touched on the bearer path (`required: false`, read only inside the DPoP branch at line 92).

### Issuance + assigns (already satisfied by Phase 99)

- **D-06:** No per-client config change. `acme-ledger-public` sets no `access_token_format` (seeds.exs:72-87) → server-policy default `:jwt` (`server_policy.ex:38`, wired at `token_controller.ex:24`) → `typ: at+jwt`. `VerifyToken`/`RequireToken` populate `conn.assigns.access_token` with the `.client_id`/`.claims`/`.authorization_scheme` the demo `api_controller` already reads. The smoke already requests `read:billing`, satisfying `VerifyToken`'s `scopes: ["read:billing"]`.

### Smoke assertion shape (DEMO-02)

- **D-07:** `exercise_authorization_code()` adds a `200-with-issued-token` step: `GET /api/billing/summary` with `Authorization: Bearer <issued access_token>` asserting HTTP 200 (mirroring the existing `/userinfo` 200 assertion at smoke line 240). The existing anonymous-401 assertion is **kept** (it still proves rejection of unauthenticated requests) but is no longer the sole RS-protection proof. The existing `/userinfo` stored-opaque assertion is **kept** unchanged.

### Claude's Discretion

- Exact placement/labels of the new smoke assertions and any helper refactor in `adoption_smoke.py`, provided D-04 (runtime literal == block URI) holds and the `/userinfo` + anonymous-401 assertions are preserved.
- Whether to assert specific JSON fields of the `/api/billing/summary` 200 response (e.g. `access_token.audience` echoing the URI) as additional evidence — encouraged but not required by DEMO-01/02.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 101 goal + success criteria; build-order rationale (Phase 99/100 dependencies).
- `.planning/REQUIREMENTS.md` — DEMO-01, DEMO-02, DEMO-03, and RECIPE-01 (four-file hash lock).
- `docs/protect-phoenix-api-routes.md` — the protected-route contract doc; one of the four hash-locked files.
- `examples/adoption_demo/lib/adoption_demo_web/router.ex` — canonical pipeline block (lines 23-30); hash-locked file.
- `priv/templates/lockspire.install/router.ex` — install template; hash-locked file.
- `scripts/demo/adoption_smoke.py` — smoke script; carries the commented block (~lines 244-251) AND the runtime auth-code exercise (`exercise_authorization_code()`).
- `.planning/phases/97-contract-docs-first/97-CONTEXT.md` — canonical-block shape (D-01/D-02), markers, and normalized-hash mechanism.
- `.planning/phases/99-signer-extraction-jwt-default-issuance/99-CONTEXT.md` — JWT-default issuance flip this demo depends on.
- `.planning/phases/100-sender-constraint-end-to-end-proof/100-CONTEXT.md` — sender-constraint pipeline proof upstream of the demo.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/demo/adoption_smoke.py` `exercise_authorization_code()` already drives the full auth-code+PKCE flow, exchanges the code, and asserts `/userinfo` 200 with the bearer token (line 240). The new 200-with-token step extends this same function; the token is already bound to a Python variable.
- The demo `api_controller.billing_summary/2` already returns a JSON body sourced from `conn.assigns.access_token` — no controller change needed for the 200 path.
- The canonical pipeline block already declares `VerifyToken`, `EnforceSenderConstraints`, `RequireToken` in the demo router (lines 23-30) and is already piped through `/api/billing/summary` (lines 66-70).

### Established Patterns
- The four-file content-hash lock (Phase 97) is the load-bearing constraint: the `audience:` change is mechanically simple but MUST be replicated identically across four files or `release_readiness_contract_test` fails.
- Resource Indicators (RFC 8707) drive the token `aud`: absolute-URI `resource=` on authorize/token → verbatim `aud` list → exact-match audience enforcement in `VerifyToken`.
- Issuance default is `:jwt` server-wide (Phase 99); clients with `access_token_format: nil` inherit it — the demo client relies on this, not on explicit config.

### Integration Points
- `examples/adoption_demo/priv/repo/seeds.exs` — `acme-ledger-public` client seed (no `access_token_format`).
- CI `Adoption Demo Smoke` job (`.github/workflows/`) invokes `scripts/demo/adoption_smoke.py`; it must fail loudly if either round-trip assertion regresses.
- `lib/lockspire/web/controllers/token_controller.ex:24` wires `server_policy_store: Repository` so `:jwt` resolution fires for the demo client.
</code_context>

<specifics>
## Specific Ideas

- Canonical audience/resource URI: **`https://billing.acme-ledger.test`** (user-confirmed; absolute HTTPS, reserved `.test` TLD, matches the demo's "Acme Ledger" billing identity).
</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within phase scope. (Generated-host scaffolding mirroring this block, operator telemetry, the v1.27 migration guide, and `mix lockspire.doctor token_format` are all Phase 102.)
</deferred>
