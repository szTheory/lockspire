# Phase 36: End-to-End Proof and Milestone Closure - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 14
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/protocol/introspection.ex` | service | request-response | `lib/lockspire/protocol/introspection.ex` | exact |
| `test/lockspire/protocol/introspection_test.exs` | test | request-response | `test/lockspire/protocol/introspection_test.exs` | exact |
| `test/lockspire/web/introspection_controller_test.exs` | test | request-response | `test/lockspire/web/introspection_controller_test.exs` | exact |
| `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs` | test | request-response | `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs` | exact |
| `test/integration/phase15_par_authorization_e2e_test.exs` | test | request-response | `test/integration/phase15_par_authorization_e2e_test.exs` | exact |
| `test/integration/phase32_device_flow_token_exchange_e2e_test.exs` | test | request-response | `test/integration/phase32_device_flow_token_exchange_e2e_test.exs` | exact |
| `test/lockspire/release_readiness_contract_test.exs` | test | transform | `test/lockspire/release_readiness_contract_test.exs` | exact |
| `docs/supported-surface.md` | config | transform | `docs/supported-surface.md` | exact |
| `.planning/PROJECT.md` | config | transform | `.planning/PROJECT.md` | exact |
| `.planning/REQUIREMENTS.md` | config | transform | `.planning/milestones/v1.6-REQUIREMENTS.md` | flow-match |
| `.planning/ROADMAP.md` | config | transform | `.planning/milestones/v1.6-ROADMAP.md` | flow-match |
| `.planning/STATE.md` | config | transform | `.planning/STATE.md` | exact |
| `.planning/EPIC.md` | config | transform | `.planning/EPIC.md` | exact |
| `.planning/MILESTONES.md` | config | transform | `.planning/MILESTONES.md` | exact |

## Pattern Assignments

### `lib/lockspire/protocol/introspection.ex` / `test/lockspire/protocol/introspection_test.exs` / `test/lockspire/web/introspection_controller_test.exs`

**Use for:** active-response shaping, inactive collapse, and controller-thin introspection truth.

**Protocol analog:** [lib/lockspire/protocol/introspection.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/introspection.ex:31)

**Caller gate + inactive collapse** ([lines 31-44](../../../lib/lockspire/protocol/introspection.ex#L31), [75-93](../../../lib/lockspire/protocol/introspection.ex#L75), [102-124](../../../lib/lockspire/protocol/introspection.ex#L102)):
```elixir
with {:ok, token_hash} <- fetch_token_hash(params),
     {:ok, %Client{} = client} <- authenticate_client(params, authorization, request),
     {:ok, response} <- introspection_response(client, token_hash, request) do
  emit_result(client, response)
  {:ok, response}
else
  {:error, %Error{} = error} ->
    emit_failure(error)
    {:error, error}
end
```

```elixir
with {:ok, true} <- validate_confidential_caller(client),
     {:ok, token} <- fetch_lifecycle_token(token_hash, request) do
  classify_token(client, token, now(request))
else
  {:ok, false} -> inactive_response()
  {:error, :lookup_failed} -> raise_lookup_error()
end
```

**Active map builder to extend with `cnf`** ([lines 126-139](../../../lib/lockspire/protocol/introspection.ex#L126)):
```elixir
%{
  active: true,
  client_id: token.client_id,
  token_type: Atom.to_string(token.token_type),
  scope: Enum.join(token.scopes, " "),
  sub: token.account_id,
  aud: empty_to_nil(token.audience),
  exp: DateTime.to_unix(token.expires_at),
  iat: maybe_unix(token.issued_at)
}
|> maybe_put(:jti, token.jti)
|> Enum.reject(fn {_key, value} -> is_nil(value) end)
|> Map.new()
```

Planner guidance: add `cnf` here with the existing `maybe_put/3` pattern. Do not move DPoP shaping into the controller and do not disturb `inactive_response/0`.

**Protocol test setup to copy** ([test/lockspire/protocol/introspection_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/introspection_test.exs:22)):
```elixir
setup do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
  secret = "introspection-secret"
  ...
  {:ok, _access_token} =
    Repository.store_token(%Token{
      token_hash: TokenFormatter.hash_token("introspect-access-token"),
      token_type: :access_token,
      client_id: confidential_client.client_id,
      ...
    })
```

Copy this fixture style and add one DPoP-bound token row with `cnf: %{"jkt" => ...}`. Reuse the existing `assert {:ok, response} = Introspection.introspect(...)` shape at [lines 141-158](../../../test/lockspire/protocol/introspection_test.exs#L141).

**HTTP test shape to reuse** ([test/lockspire/web/introspection_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/introspection_controller_test.exs:113)):
```elixir
conn =
  build_conn(:post, "/introspect", %{"token" => "controller-introspect-access"})
  |> put_req_header("authorization", basic_auth(client.client_id, secret))
  |> put_req_header("accept", "application/json")
  |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

assert conn.status == 200
body = Jason.decode!(conn.resp_body)
assert body["active"] == true
```

Copy this exact controller-test scaffold. Only add new positive assertions for `body["cnf"]["jkt"]` and keep the current `active: false` collapse cases at [lines 135-176](../../../test/lockspire/web/introspection_controller_test.exs#L135) unchanged.

---

### `test/integration/phase15_par_authorization_e2e_test.exs`

**Use for:** browser-style hosted interaction proof through `/authorize`, consent, callback, and `/token`.

**Analog:** [test/integration/phase15_par_authorization_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase15_par_authorization_e2e_test.exs:91)

**Canonical browser interaction path** ([lines 131-230](../../../test/integration/phase15_par_authorization_e2e_test.exs#L131)):
```elixir
par_conn =
  build_conn(:post, "/par", %{...})
  |> put_req_header("accept", "application/json")
  |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

authorize_conn =
  build_conn(:get, "/authorize", %{"client_id" => client.client_id, "request_uri" => request_uri})
  |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

consent_complete_conn =
  build_conn(:post, "/interactions/#{interaction_id}/complete", %{"decision" => "approve", "remember" => "true"})
  |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))
```

**Token exchange tail to copy exactly** ([lines 197-220](../../../test/integration/phase15_par_authorization_e2e_test.exs#L197)):
```elixir
token_conn =
  build_conn(:post, "/token", %{
    "grant_type" => "authorization_code",
    "client_id" => client.client_id,
    "code" => code,
    "redirect_uri" => "https://client.example.com/callback",
    "code_verifier" => code_verifier
  })
  |> put_req_header("accept", "application/json")
  |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))
```

Planner guidance: for auth-code DPoP proof, extend this file or mirror this test shape. Add the `dpop` header only at `/token`; do not invent a second browser harness.

---

### `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs`

**Use for:** full auth-code lifecycle proof including discovery, `/token`, `userinfo`, refresh, and `/introspect`.

**Analog:** [test/integration/phase3_oidc_token_lifecycle_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase3_oidc_token_lifecycle_e2e_test.exs:115)

**Discovery -> token -> userinfo -> introspection chain** ([lines 122-137](../../../test/integration/phase3_oidc_token_lifecycle_e2e_test.exs#L122), [180-258](../../../test/integration/phase3_oidc_token_lifecycle_e2e_test.exs#L180)):
```elixir
token_conn =
  build_conn(:post, "/token", %{
    "grant_type" => "authorization_code",
    "client_id" => public_client.client_id,
    "code" => "phase3-openid-code",
    "redirect_uri" => "https://client.example.com/callback",
    "code_verifier" => "phase3-openid-verifier"
  })
  |> put_req_header("accept", "application/json")
  |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))
```

```elixir
userinfo_conn =
  build_conn(:get, "/userinfo")
  |> put_req_header("authorization", "Bearer " <> token_response["access_token"])
  |> put_req_header("accept", "application/json")
  |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))
```

```elixir
introspect_active_conn =
  build_conn(:post, "/introspect", %{"token" => refresh_response["access_token"]})
  |> put_req_header("authorization", basic_auth(confidential_client.client_id, confidential_secret))
  |> put_req_header("accept", "application/json")
  |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))
```

Planner guidance: reuse this file for the “truth after issuance” part of the browser proof. It already contains the cleanest introspection assertion sequence; add DPoP assertions here instead of creating a separate introspection-only E2E harness.

---

### `test/integration/phase32_device_flow_token_exchange_e2e_test.exs`

**Use for:** CLI/device proof through generated host `/verify` and `/token`, including the existing DPoP redemption seam.

**Analog:** [test/integration/phase32_device_flow_token_exchange_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase32_device_flow_token_exchange_e2e_test.exs:50)

**Generated-host device flow scaffold** ([lines 52-115](../../../test/integration/phase32_device_flow_token_exchange_e2e_test.exs#L52)):
```elixir
device_code_conn =
  build_conn()
  |> post("/lockspire/device/code", %{"client_id" => client.client_id, "scope" => "profile email"})

signed_in_conn =
  build_conn()
  |> init_test_session(%{"current_account_id" => "generated-host-user"})

review_conn = prepare_form(signed_in_conn, "/verify", %{"user_code" => device_code_body["user_code"]})
handle = fetch_handle(review_conn.resp_body)
approve_conn = submit_from(review_conn, "/verify/#{handle}/approve", %{})
```

**Existing DPoP device redemption pattern to reuse exactly** ([lines 117-184](../../../test/integration/phase32_device_flow_token_exchange_e2e_test.exs#L117)):
```elixir
proof = dpop_proof_fixture()

first_token_conn =
  build_conn()
  |> put_req_header("dpop", proof)
  |> post("/lockspire/token", %{
    "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
    "client_id" => client.client_id,
    "device_code" => device_code_body["device_code"]
  })

assert first_token_body["token_type"] == "DPoP"
```

**Do not reinvent proof helpers** ([lines 186-230](../../../test/integration/phase32_device_flow_token_exchange_e2e_test.exs#L186)):
```elixir
defp prepare_form(conn, path, params) do
  token_conn = conn |> get("/verify")
  submit_from(token_conn, path, params)
end

defp dpop_proof_fixture do
  keys = JarTestHelpers.generate_ec_keys()
  now = DateTime.utc_now()
  JarTestHelpers.sign_dpop_proof(keys.private_jwk, %{
    "htm" => "POST",
    "htu" => "https://example.test/lockspire/token",
    "iat" => DateTime.to_unix(now),
    "jti" => Ecto.UUID.generate()
  })
end
```

Planner guidance: Phase 36’s CLI proof should extend this file and then add introspection verification for the issued token. Keep the generated-host seam, CSRF helper flow, and “fresh proof on replay path” pattern.

---

### `test/lockspire/release_readiness_contract_test.exs` and `docs/supported-surface.md`

**Use for:** narrow support-claim updates and repo-truth contract enforcement.

**Contract-test analog:** [test/lockspire/release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:191)

**Support-surface wording assertions** ([lines 206-230](../../../test/lockspire/release_readiness_contract_test.exs#L206)):
```elixir
assert supported_surface =~ "DPoP on token requests and the Lockspire-owned `userinfo` endpoint"
assert supported_surface =~ "bearer clients remain unchanged by default"
assert supported_surface =~ "Generic host protected-resource middleware remains out of scope"
```

**Planning-truth assertion block to copy** ([lines 329-367](../../../test/lockspire/release_readiness_contract_test.exs#L329)):
```elixir
project = File.read!(@project_path)
roadmap = File.read!(@roadmap_path)
requirements = File.read!(@requirements_path)
...
refute supported_surface =~ "Request-object-by-value support is in scope"
```

Planner guidance: extend this same style for Phase 36. Add positive assertions for introspection/runtime truth and keep the “refute broader claim” structure.

**Doc bullet pattern to update, not rewrite** ([docs/supported-surface.md](/Users/jon/projects/lockspire/docs/supported-surface.md:21)):
```markdown
- DPoP on token requests and the Lockspire-owned `userinfo` endpoint, with bearer clients remain unchanged by default unless they explicitly opt into DPoP mode
```

Use the same single-bullet contract style and add introspection truth narrowly. Do not broaden this section into generic host protected-resource support.

---

### `.planning/REQUIREMENTS.md` / `.planning/ROADMAP.md` / `.planning/STATE.md` / `.planning/PROJECT.md` / `.planning/EPIC.md` / `.planning/MILESTONES.md`

**Use for:** milestone-close traceability and synchronized planning truth.

**Requirements outcome table analog:** [.planning/milestones/v1.6-REQUIREMENTS.md](/Users/jon/projects/lockspire/.planning/milestones/v1.6-REQUIREMENTS.md:28)

Copy the shipped-close structure at [lines 28-60](../../../.planning/milestones/v1.6-REQUIREMENTS.md#L28): one outcome table, one traceability table, then a coverage block. Phase 36 should update the active file in this same shape by flipping `DPoP-12` through `DPoP-14` from pending to complete.

**Roadmap shipped-milestone summary analog:** [.planning/milestones/v1.6-ROADMAP.md](/Users/jon/projects/lockspire/.planning/milestones/v1.6-ROADMAP.md:59)

Copy the archive-summary cadence at [lines 59-83](../../../.planning/milestones/v1.6-ROADMAP.md#L59): `Key Decisions`, `Issues Resolved`, `Issues Deferred`, `Technical Debt Incurred`. Use that structure when Phase 36 closes v1.7 narrative truth.

**Milestone ledger entry analog:** [.planning/MILESTONES.md](/Users/jon/projects/lockspire/.planning/MILESTONES.md:3)

Copy the v1.6 entry shape at [lines 3-17](../../../.planning/MILESTONES.md#L3): status line, counts, package posture, key accomplishments, pre-close audit, archives/tag line.

**Current-state transition pattern** ([.planning/STATE.md](/Users/jon/projects/lockspire/.planning/STATE.md:3)):
```yaml
milestone: v1.7
status: planning
stopped_at: Phase 35 execution and verification complete
progress:
  total_phases: 4
  completed_phases: 3
```

Copy this exact YAML-first structure when moving Phase 36 to completed/milestone-closed state; do not invent a separate state format.

**Project and epic narrative update anchors** ([.planning/PROJECT.md](/Users/jon/projects/lockspire/.planning/PROJECT.md:11), [.planning/EPIC.md](/Users/jon/projects/lockspire/.planning/EPIC.md:51)):
```markdown
## Current State
...
## Current Milestone: v1.7 DPoP Core for Public and CLI Clients
```

```markdown
### 2. Adoption-Hardening Milestone
Why likely next:
...
```

Planner guidance: Phase 36 should update these sections in place. Preserve the existing “current state / next leverage point / likely next milestone” voice rather than adding a new retrospective format.

## Shared Patterns

### Browser E2E Proof
**Sources:** `test/integration/phase15_par_authorization_e2e_test.exs`, `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs`

- Reuse the real HTTP seam and consent/callback flow from Phase 15.
- Reuse Phase 3’s downstream assertions for `userinfo` and `/introspect`.
- Add DPoP only at the token-boundary and downstream bound-token consumption checks.

### Device/CLI E2E Proof
**Source:** `test/integration/phase32_device_flow_token_exchange_e2e_test.exs`

- Keep the generated-host `/verify` seam.
- Reuse `prepare_form/3`, `submit_from/3`, and `fetch_handle/1`.
- Reuse the existing `dpop_proof_fixture/0` helper instead of creating a new helper module.

### Introspection Truth
**Sources:** `lib/lockspire/protocol/introspection.ex`, `test/lockspire/protocol/introspection_test.exs`, `test/lockspire/web/introspection_controller_test.exs`

- Extend `active_response/1`; leave inactive semantics and confidential-caller gating intact.
- Add `cnf` only from stored token truth.
- Assert new fields in both protocol and controller tests using the existing fixture style.

### Milestone-Close Traceability
**Sources:** `.planning/milestones/v1.6-REQUIREMENTS.md`, `.planning/milestones/v1.6-ROADMAP.md`, `.planning/MILESTONES.md`, `test/lockspire/release_readiness_contract_test.exs`

- Reuse existing outcome-table and coverage-block structures.
- Keep release/docs assertions narrow and paired with `refute` checks against broader claims.
- Synchronize `PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`, `EPIC.md`, and `MILESTONES.md` in one pass.

## No Analog Found

None. Phase 36 can extend existing repo-native E2E, introspection, release-contract, and milestone-close patterns without inventing new scaffolding.

## Metadata

**Analog search scope:** `lib/lockspire/protocol`, `lib/lockspire/web/controllers`, `test/integration`, `test/lockspire`, `docs`, `.planning`, `.planning/milestones`, `.planning/phases/34-*`, `.planning/phases/35-*`
**Files scanned:** 25+
**Pattern extraction date:** 2026-04-28
