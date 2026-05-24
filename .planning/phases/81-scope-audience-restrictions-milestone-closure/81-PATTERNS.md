# Phase 81: Scope/Audience Restrictions & Milestone Closure - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 9 candidate files
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/plug/verify_token.ex` | plug | request-response | `lib/lockspire/plug/enforce_sender_constraints.ex` | role-match |
| `lib/lockspire/plug/require_token.ex` | plug | request-response | `lib/lockspire/plug/require_token.ex` | exact |
| `lib/lockspire/access_token.ex` | model | request-response | `lib/lockspire/access_token.ex` | exact |
| `test/lockspire/plug/verify_token_test.exs` | test | request-response | `test/lockspire/plug/enforce_sender_constraints_test.exs` | role-match |
| `test/lockspire/plug/require_token_test.exs` | test | request-response | `test/lockspire/plug/require_token_test.exs` | exact |
| `test/integration/phase81_protected_route_e2e_test.exs` | test | request-response | `test/integration/phase31_generated_host_verification_e2e_test.exs` | partial |
| `test/support/generated_host_app_web/router.ex` | route | request-response | `test/support/generated_host_app_web/router.ex` | exact |
| `docs/protect-phoenix-api-routes.md` | config/docs | request-response | `docs/install-and-onboard.md` | partial |
| `docs/supported-surface.md` | config/docs | request-response | `docs/supported-surface.md` | exact |

## Candidate Files To Modify

| File | Why |
|---|---|
| `lib/lockspire/plug/verify_token.ex` | Best place to validate `scopes:` / `audience:` / `audiences:` options up front and keep the plug soft by assigning structured restriction failures instead of responding. |
| `lib/lockspire/plug/require_token.ex` | Already owns the only transport boundary; must distinguish `401 invalid_token` from `403 insufficient_scope` and render scheme-aware `WWW-Authenticate`. |
| `lib/lockspire/access_token.ex` | Central contract if Phase 81 needs typed restriction errors or normalized token metadata carried across plugs. |
| `test/lockspire/plug/verify_token_test.exs` | Unit proof seam for option parsing, claim normalization, malformed `aud`, audience mismatch, and scope matching behavior. |
| `test/lockspire/plug/require_token_test.exs` | Regression seam for final `401` vs `403` HTTP semantics and challenge/body formatting. |
| `test/integration/phase81_protected_route_e2e_test.exs` | Real Phoenix router dispatch proof for route-level restrictions, not just struct-level plug tests. |
| `test/support/generated_host_app_web/router.ex` | Existing generated-host router is the cleanest place to add one protected API scope for milestone-closing proof. |
| `docs/protect-phoenix-api-routes.md` | No exact analog exists; Phase 81 needs a narrow executable guide dedicated to the plug pipeline and host responsibilities. |
| `docs/supported-surface.md` | Must replace the old “generic host protected-resource middleware remains out of scope” wording with the new narrow shipped claim. |
| `test/lockspire/release_readiness_contract_test.exs` | Existing docs/support posture contract test; best place to pin the new claim and guide links. |

## Pattern Assignments

### `lib/lockspire/plug/verify_token.ex` (plug, request-response)

**Primary analog for option parsing:** `lib/lockspire/plug/enforce_sender_constraints.ex`

**Why this analog**
- It already validates plug opts in `init/1` with `NimbleOptions`.
- It keeps `call/2` soft by mutating `conn.assigns[:access_token]` instead of halting.

**Options-schema pattern** [`lib/lockspire/plug/enforce_sender_constraints.ex`](/Users/jon/projects/lockspire/lib/lockspire/plug/enforce_sender_constraints.ex:14)
```elixir
@options_schema [
  dpop_replay_store: [
    type: {:or, [:atom, :map]},
    required: false,
    doc: "Replay store implementing record_dpop_proof/1."
  ],
  ...
]

def init(opts) do
  opts = NimbleOptions.validate!(opts, @options_schema)
  ...
end
```

**Soft-plug pattern** [`lib/lockspire/plug/verify_token.ex`](/Users/jon/projects/lockspire/lib/lockspire/plug/verify_token.ex:22)
```elixir
def call(conn, _opts) do
  case extract_token(conn) do
    {:ok, authorization_scheme, token} ->
      access_token = verify_token(token, authorization_scheme)
      assign(conn, :access_token, access_token)

    {:error, reason} ->
      assign(conn, :access_token, %AccessToken{error: reason})
  end
end
```

**Restriction-failure tagging analog** [`lib/lockspire/plug/enforce_sender_constraints.ex`](/Users/jon/projects/lockspire/lib/lockspire/plug/enforce_sender_constraints.ex:67)
```elixir
case maybe_validate_dpop(access_token, conn, opts) do
  {:ok, _proof} -> maybe_validate_mtls(conn, access_token, opts)
  :skip -> maybe_validate_mtls(conn, access_token, opts)
  {:error, sender_error} ->
    assign(conn, :access_token, %AccessToken{access_token | error: sender_error})
end
```

**Concrete recommendation**
- Reuse the `NimbleOptions` pattern from `EnforceSenderConstraints.init/1`.
- Keep restriction evaluation in `VerifyToken.call/2` after JWT verification succeeds.
- Assign structured error maps onto `%AccessToken{}` rather than halting.

### `lib/lockspire/plug/require_token.ex` (plug, request-response)

**Primary analog for failure tagging and final HTTP behavior:** `lib/lockspire/plug/require_token.ex`

**Structured-error dispatch** [`lib/lockspire/plug/require_token.ex`](/Users/jon/projects/lockspire/lib/lockspire/plug/require_token.ex:19)
```elixir
case conn.assigns[:access_token] do
  %AccessToken{error: nil, claims: claims} when not is_nil(claims) -> conn
  %AccessToken{error: :missing_token} -> handle_missing_token(conn)
  %AccessToken{error: error} when is_map(error) -> handle_structured_error(conn, error)
  %AccessToken{error: _reason} -> handle_invalid_token(conn, default_invalid_error())
  _ -> handle_missing_token(conn)
end
```

**Challenge selection pattern** [`lib/lockspire/plug/require_token.ex`](/Users/jon/projects/lockspire/lib/lockspire/plug/require_token.ex:61)
```elixir
defp handle_structured_error(conn, %{category: :sender_constraint} = error),
  do: handle_invalid_token(conn, normalize_sender_error(error))

defp www_authenticate(%{challenge: :dpop, error: error, error_description: description}) do
  algorithms = Enum.join(DPoP.signing_alg_values_supported(), " ")
  ~s(DPoP realm="Lockspire", error="#{error}", error_description="#{description}", algs="#{algorithms}")
end
```

**Concrete recommendation**
- Add a second structured-error branch for scope denial, not a second response plug.
- Keep all HTTP status/header/body rendering here.
- Follow the existing typed-map approach instead of raw atoms so `403 insufficient_scope` can carry required scopes safely.

### `lib/lockspire/access_token.ex` (model, request-response)

**Primary analog:** `lib/lockspire/access_token.ex`

**Contract pattern** [`lib/lockspire/access_token.ex`](/Users/jon/projects/lockspire/lib/lockspire/access_token.ex:6)
```elixir
defstruct [
  :token,
  :claims,
  :client_id,
  :authorization_scheme,
  :binding_type,
  :binding_requirements,
  :error
]
```

**Concrete recommendation**
- Keep Phase 81 additive to this struct.
- If normalized scope/audience metadata is cached, add it here rather than inventing a second assign.
- If not needed, leave the struct unchanged and continue using `claims` plus structured `error`.

### `test/lockspire/plug/verify_token_test.exs` (test, request-response)

**Primary analog:** `test/lockspire/plug/enforce_sender_constraints_test.exs`

**Why this analog**
- It proves the soft-plug matrix with deterministic fixtures and asserts on `conn.assigns.access_token.error`.

**Negative-path matrix pattern** [`test/lockspire/plug/enforce_sender_constraints_test.exs`](/Users/jon/projects/lockspire/test/lockspire/plug/enforce_sender_constraints_test.exs:80)
```elixir
test "records typed sender-constraint failures for wrong scheme and missing proof" do
  ...
  assert %{category: :sender_constraint, challenge: :dpop, reason_code: :invalid_dpop_authorization_scheme} =
           bearer_conn.assigns.access_token.error
  ...
  assert %{reason_code: :missing_dpop_proof} = missing_proof_conn.assigns.access_token.error
end
```

**Existing token-fixture pattern** [`test/lockspire/plug/verify_token_test.exs`](/Users/jon/projects/lockspire/test/lockspire/plug/verify_token_test.exs:31)
```elixir
defp generate_key_and_token(claims \\ %{}) do
  ...
  merged_claims = Map.merge(default_claims, claims)
  ...
  {signed_token, merged_claims}
end
```

**Concrete recommendation**
- Extend `VerifyTokenTest` instead of creating a second unit file.
- Mirror the sender-constraint test style: one passing case, then a typed negative-path matrix for malformed `aud`, audience mismatch, and insufficient scopes.

### `test/lockspire/plug/require_token_test.exs` (test, request-response)

**Primary analog:** `test/lockspire/plug/require_token_test.exs`

**Existing 401 contract pattern** [`test/lockspire/plug/require_token_test.exs`](/Users/jon/projects/lockspire/test/lockspire/plug/require_token_test.exs:45)
```elixir
assert [
  "Bearer realm=\"Lockspire\", error=\"invalid_token\", error_description=\"The access token is invalid or expired\""
] = get_resp_header(conn, "www-authenticate")
```

**Structured challenge proof** [`test/lockspire/plug/require_token_test.exs`](/Users/jon/projects/lockspire/test/lockspire/plug/require_token_test.exs:62)
```elixir
test "halts with DPoP-aware challenge for typed sender-constraint failures" do
  ...
  assert challenge =~ "DPoP realm=\"Lockspire\""
  assert challenge =~ "error=\"invalid_token\""
end
```

**Concrete recommendation**
- Add the `403 insufficient_scope` assertions here, not in router integration tests alone.
- Keep body assertions minimal and machine-readable, matching Phase 81 decision D-26.

### `test/integration/phase81_protected_route_e2e_test.exs` (test, request-response)

**Primary analog:** `test/integration/phase31_generated_host_verification_e2e_test.exs`

**Why this analog**
- It uses the generated-host endpoint, real router dispatch, sandboxed repo setup, and actual HTTP requests.

**Endpoint/sandbox pattern** [`test/integration/phase31_generated_host_verification_e2e_test.exs`](/Users/jon/projects/lockspire/test/integration/phase31_generated_host_verification_e2e_test.exs:14)
```elixir
setup_all do
  Application.put_env(:lockspire, GeneratedHostAppWeb.Endpoint, ...)
  Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
  ...
  start_supervised!(Lockspire.TestRepo)
  start_supervised!(GeneratedHostAppWeb.Endpoint)
end
```

**Real-route proof pattern** [`test/integration/phase31_generated_host_verification_e2e_test.exs`](/Users/jon/projects/lockspire/test/integration/phase31_generated_host_verification_e2e_test.exs:64)
```elixir
conn =
  build_conn()
  |> get("/verify", %{"user_code" => "wdjb-mjht"})

assert conn.status == 200
```

**Secondary router analog:** `test/lockspire/web/discovery_controller_test.exs` uses direct router calls when a smaller integration seam is enough.

**Concrete recommendation**
- Prefer a generated-host integration test if Phase 81 wants milestone-closing “real app” proof.
- Add at least one combined sender-constraint + route restriction case here.

### `test/support/generated_host_app_web/router.ex` (route, request-response)

**Primary analog:** `test/support/generated_host_app_web/router.ex`

**Router organization pattern** [`test/support/generated_host_app_web/router.ex`](/Users/jon/projects/lockspire/test/support/generated_host_app_web/router.ex:15)
```elixir
scope "/", GeneratedHostAppWeb do
  pipe_through(:browser)
  ...
end

scope "/" do
  forward("/lockspire", Lockspire.Web.Router)
end
```

**Generated-router seam precedent** [`test/support/generated_host_app_web/router/lockspire.ex`](/Users/jon/projects/lockspire/test/support/generated_host_app_web/router/lockspire.ex:13)
```elixir
def lockspire_routes do
  """
  scope "/", GeneratedHostAppWeb do
    pipe_through [:browser]
    ...
  end
  ...
  """
end
```

**Concrete recommendation**
- If the generated host proof needs a protected API route, copy the existing generated-host router style instead of inventing a standalone test router module first.

### `docs/protect-phoenix-api-routes.md` (docs, request-response)

**Closest analog:** `docs/install-and-onboard.md`

**Why this analog**
- It is the project’s canonical executable host guide style: narrow scope, explicit host-owned seams, and a “repo proof lives in” section.

**Guide structure pattern** [`docs/install-and-onboard.md`](/Users/jon/projects/lockspire/docs/install-and-onboard.md:52)
```markdown
## 3. Wire the generated files
...
Lockspire owns the OAuth/OIDC protocol flow; your host app owns the human-facing account and policy decisions.
```

**Executable-proof pattern** [`docs/install-and-onboard.md`](/Users/jon/projects/lockspire/docs/install-and-onboard.md:105)
```markdown
## 6. Create a client and prove the flow
...
The executable repo proof lives in:
- `test/integration/install_generator_test.exs`
- `test/integration/phase6_onboarding_e2e_test.exs`
```

**Concrete recommendation**
- New guide should mirror this structure:
  1. canonical plug pipeline
  2. route snippet
  3. assigns contract
  4. host-owned responsibilities
  5. failure matrix
  6. repo-proof section pointing at the new Phase 81 tests

### `docs/supported-surface.md` (docs, request-response)

**Primary analog:** `docs/supported-surface.md`

**Current out-of-scope line to replace** [`docs/supported-surface.md`](/Users/jon/projects/lockspire/docs/supported-surface.md:94)
```markdown
- Generic host protected-resource middleware remains out of scope
```

**Canonical support-contract pattern** [`docs/supported-surface.md`](/Users/jon/projects/lockspire/docs/supported-surface.md:5)
```markdown
This page is the canonical public support contract for what Lockspire currently supports, what it does not support, and what repo-owned proof backs those claims.
```

**Proof-list pattern** [`docs/supported-surface.md`](/Users/jon/projects/lockspire/docs/supported-surface.md:118)
```markdown
Repo-owned proof for this posture lives in:
- `docs/install-and-onboard.md`
- ...
- `test/lockspire/release_readiness_contract_test.exs`
```

**Concrete recommendation**
- Change the claim narrowly: Phoenix host route protection with Lockspire-issued tokens, not generic gateway/multi-issuer middleware.
- Add the new guide and Phase 81 proof tests to the proof list.

### `test/lockspire/release_readiness_contract_test.exs` (test, request-response)

**Primary analog for docs-proof tests:** `test/lockspire/release_readiness_contract_test.exs`

**Support-contract anchor pattern** [`test/lockspire/release_readiness_contract_test.exs`](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:290)
```elixir
assert supported_surface =~ "canonical public support contract"

for doc <- [readme, security, guide] do
  assert doc =~ "docs/supported-surface.md"
end
```

**Positive-claim pinning pattern** [`test/lockspire/release_readiness_contract_test.exs`](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:399)
```elixir
assert supported_surface =~ "Authorization code flow with PKCE S256"
...
assert supported_surface =~ "host-owned device verification seam"
```

**Guide-proof linkage pattern** [`test/lockspire/release_readiness_contract_test.exs`](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:488)
```elixir
assert onboarding =~ "The executable repo proof lives in:"
assert onboarding =~ "test/integration/phase6_onboarding_e2e_test.exs"
```

**Concrete recommendation**
- Add assertions here for the new protected-route support claim, the new guide path, and the proof files referenced by that guide.
- Keep this as string-contract testing, not markdown parsing.

## Shared Patterns

### Soft-to-strict pipeline
**Source:** [`lib/lockspire/plug/verify_token.ex`](/Users/jon/projects/lockspire/lib/lockspire/plug/verify_token.ex:22), [`lib/lockspire/plug/enforce_sender_constraints.ex`](/Users/jon/projects/lockspire/lib/lockspire/plug/enforce_sender_constraints.ex:55), [`lib/lockspire/plug/require_token.ex`](/Users/jon/projects/lockspire/lib/lockspire/plug/require_token.ex:19)

Apply to all Phase 81 protected-route work:
```elixir
VerifyToken -> EnforceSenderConstraints -> RequireToken
```

Rule: upstream plugs only assign `%AccessToken{}` state; `RequireToken` owns all HTTP responses.

### Plug option validation
**Source:** [`lib/lockspire/plug/enforce_sender_constraints.ex`](/Users/jon/projects/lockspire/lib/lockspire/plug/enforce_sender_constraints.ex:14)

Apply to `VerifyToken.init/1`:
```elixir
opts = NimbleOptions.validate!(opts, @options_schema)
```

Use this for `scopes`, `audience`, `audiences`, and the mutual-exclusion check.

### Typed failure tagging
**Source:** [`lib/lockspire/plug/enforce_sender_constraints.ex`](/Users/jon/projects/lockspire/lib/lockspire/plug/enforce_sender_constraints.ex:125), [`lib/lockspire/plug/require_token.ex`](/Users/jon/projects/lockspire/lib/lockspire/plug/require_token.ex:61)

Apply to audience/scope failures:
```elixir
%{
  category: ...,
  challenge: ...,
  reason_code: ...,
  error: ...,
  error_description: ...
}
```

Phase 81 addition should follow this same map shape so `RequireToken` can branch cleanly.

### Generated-host integration proof
**Source:** [`test/integration/phase31_generated_host_verification_e2e_test.exs`](/Users/jon/projects/lockspire/test/integration/phase31_generated_host_verification_e2e_test.exs:14)

Apply to milestone-closing proof:
- configure `GeneratedHostAppWeb.Endpoint`
- start `Lockspire.TestRepo`
- dispatch real routed requests with `Phoenix.ConnTest`
- assert actual status/body/header behavior

### Support-contract truth tests
**Source:** [`test/lockspire/release_readiness_contract_test.exs`](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:290), [`docs/supported-surface.md`](/Users/jon/projects/lockspire/docs/supported-surface.md:5)

Apply to docs changes:
- support claim lives in `docs/supported-surface.md`
- README and SECURITY stay subordinate
- guide docs must point to executable repo proof

## Relevant Testing And Documentation Precedents

| Area | Precedent | Why it matters |
|---|---|---|
| Soft plug negative-path matrix | `test/lockspire/plug/enforce_sender_constraints_test.exs` | Best match for typed error assignment without halting. |
| Final HTTP semantics | `test/lockspire/plug/require_token_test.exs` | Existing `WWW-Authenticate` and JSON error contract seam. |
| Real Phoenix route dispatch | `test/integration/phase31_generated_host_verification_e2e_test.exs` | Generated-host end-to-end pattern for milestone proof. |
| Audience behavior context | `test/integration/phase54_resource_indicators_e2e_test.exs` | Existing repo proof that `aud` is already security-relevant, not a cosmetic claim. |
| Generated-host router seam | `test/support/generated_host_app_web/router.ex` and `test/support/generated_host_app_web/router/lockspire.ex` | Best precedent for route snippets that docs can stay close to. |
| Executable host-guide structure | `docs/install-and-onboard.md` | Existing narrow, host-owned, proof-linked guide pattern. |
| Public support contract | `docs/supported-surface.md` | Canonical place to update the shipped claim. |
| Docs contract enforcement | `test/lockspire/release_readiness_contract_test.exs` | Existing string-based truth tests for support posture and guide references. |

## No Exact Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `docs/protect-phoenix-api-routes.md` | docs | request-response | No existing dedicated host protected-resource guide yet; `docs/install-and-onboard.md` is the closest style analog. |
| `test/integration/phase81_protected_route_e2e_test.exs` | test | request-response | No current generated-host proof for route-level API token enforcement; combine Phase 31 generated-host setup with plug-pipeline assertions. |

## Metadata

**Analog search scope:** `lib/lockspire/plug`, `lib/lockspire/protocol`, `test/lockspire/plug`, `test/integration`, `test/support/generated_host_app_web`, `docs`, `.planning/phases/79-*`, `.planning/phases/80-*`

**Pattern extraction date:** 2026-05-23
