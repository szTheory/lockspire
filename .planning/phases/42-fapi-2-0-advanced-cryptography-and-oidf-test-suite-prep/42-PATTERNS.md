# Phase 42: FAPI 2.0 Advanced Cryptography and OIDF Test Suite Prep - Pattern Map

**Mapped:** 2026-05-01
**Files analyzed:** 21
**Analogs found:** 21 / 21

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/protocol/signing_algorithm_policy.ex` or `lib/lockspire/protocol/security_profile.ex` | utility | transform | `lib/lockspire/protocol/dpop.ex` + `lib/lockspire/protocol/security_profile.ex` | composite |
| `lib/lockspire/protocol/jar.ex` | service | request-response | `lib/lockspire/protocol/dpop.ex` | exact |
| `lib/lockspire/protocol/id_token.ex` | service | transform | `lib/lockspire/protocol/id_token.ex` | exact |
| `lib/lockspire/protocol/logout_token.ex` | service | transform | `lib/lockspire/protocol/logout_token.ex` | exact |
| `lib/lockspire/protocol/end_session.ex` | service | request-response | `lib/lockspire/protocol/end_session.ex` | exact |
| `lib/lockspire/protocol/discovery.ex` | service | transform | `lib/lockspire/protocol/discovery.ex` | exact |
| `lib/lockspire/protocol/jwks.ex` | service | transform | `lib/lockspire/protocol/jwks.ex` | exact |
| `lib/lockspire/web/controllers/userinfo_controller.ex` | controller | request-response | `lib/lockspire/web/controllers/userinfo_controller.ex` | exact |
| `lib/lockspire/security/policy.ex` | utility | transform | `lib/lockspire/security/policy.ex` | exact |
| `lib/lockspire/admin/keys.ex` | service | CRUD | `lib/lockspire/admin/keys.ex` | exact |
| `lib/lockspire/storage/key_store.ex` | config | CRUD | `lib/lockspire/storage/key_store.ex` | exact |
| `lib/lockspire/storage/ecto/repository.ex` | service | CRUD | `lib/lockspire/storage/ecto/repository.ex` | exact |
| `lib/lockspire/storage/ecto/client_record.ex` | model | CRUD | `lib/lockspire/storage/ecto/client_record.ex` | exact |
| `test/lockspire/protocol/security_profile_test.exs` | test | transform | `test/lockspire/protocol/security_profile_test.exs` | exact |
| `test/lockspire/protocol/dpop_test.exs` | test | request-response | `test/lockspire/protocol/dpop_test.exs` | exact |
| `test/lockspire/protocol/jar_test.exs` | test | request-response | `test/lockspire/protocol/jar_test.exs` | exact |
| `test/lockspire/protocol/id_token_test.exs` | test | transform | `test/lockspire/protocol/id_token_test.exs` | exact |
| `test/lockspire/protocol/logout_token_test.exs` | test | transform | `test/lockspire/protocol/logout_token_test.exs` | exact |
| `test/lockspire/protocol/end_session_test.exs` | test | request-response | `test/lockspire/protocol/end_session_test.exs` | exact |
| `test/lockspire/release_readiness_contract_test.exs` | test | batch | `test/lockspire/release_readiness_contract_test.exs` | exact |
| `docs/maintainer-conformance.md`, `scripts/conformance/fapi2-check.sh`, `.github/workflows/oidf-conformance.yml` | docs/config/test | batch | existing trio in same paths | exact |

## Pattern Assignments

### `lib/lockspire/protocol/signing_algorithm_policy.ex` or `lib/lockspire/protocol/security_profile.ex`

**Planner recommendation:** Prefer a new protocol-owned truth module only if it stays tiny and purely declarative. If not, extend `SecurityProfile` and keep one exported policy seam. Copy the API shape from `DPoP` rather than scattering constants.

**Analog:** [lib/lockspire/protocol/dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/dpop.ex:42) and [lib/lockspire/protocol/security_profile.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/security_profile.ex:26)

**Truth-export pattern** (`dpop.ex` lines 42-52):
```elixir
  @spec signing_alg_values_supported() :: [String.t()]
  def signing_alg_values_supported(), do: @allowed_algorithms

  @spec signing_alg_values_supported(SecurityProfile.Resolved.t() | :fapi_2_0_security | :none) ::
          [String.t()]
  def signing_alg_values_supported(%SecurityProfile.Resolved{effective_profile: profile}),
    do: SecurityProfile.allowed_signing_algorithms(profile)
```

**Resolved-profile carrier pattern** (`security_profile.ex` lines 26-35, 49-55):
```elixir
  def resolve_effective_profile(%ServerPolicy{} = server_policy, client) do
    client_profile = normalize_client_profile(client)
    effective_profile = effective_profile(server_policy.security_profile, client_profile)

    %Resolved{
      global_profile: server_policy.security_profile,
      client_profile: client_profile,
      effective_profile: effective_profile,
      fapi_2_0_security?: effective_profile == :fapi_2_0_security
    }
  end

  def allowed_signing_algorithms(:fapi_2_0_security), do: ["ES256", "PS256", "EdDSA"]
  def allowed_signing_algorithms(:none), do: ["RS256", "ES256", "PS256", "EdDSA"]
```

**What Phase 42 should copy:** one exported function that accepts either `%Resolved{}` or a profile atom, and every owned signing, verification, JWKS, discovery, and challenge surface should call that one function.

---

### `lib/lockspire/protocol/jar.ex`, `lib/lockspire/protocol/logout_token.ex`, `lib/lockspire/protocol/end_session.ex`, `lib/lockspire/protocol/id_token.ex`

**Planner recommendation:** Keep JOSE decisions protocol-owned and explicit. Do not let controllers or admin code decide allowed algorithms.

**Primary analogs:** [lib/lockspire/protocol/dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/dpop.ex:132), [lib/lockspire/protocol/id_token.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/id_token.ex:17), [lib/lockspire/protocol/logout_token.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/logout_token.ex:11), [lib/lockspire/protocol/end_session.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/end_session.ex:74)

**Strict verification pattern** (`dpop.ex` lines 132-162):
```elixir
  defp verify_signature(jwt, public_jwk, %SecurityProfile.Resolved{effective_profile: profile}) do
    allowed_algs = SecurityProfile.allowed_signing_algorithms(profile)

    case JOSE.JWT.verify_strict(public_jwk, allowed_algs, jwt) do
      {true, %JOSE.JWT{} = jwt_struct, %JOSE.JWS{} = jws_struct} ->
        ...
      {false, _jwt_struct, _jws_struct} ->
        ...
    end
  end
```

**Signer preflight pattern** (`id_token.ex` lines 28-31, 61-66):
```elixir
    security_profile = Map.get(params, :security_profile, :none)
    allowed_algs = SecurityProfile.allowed_signing_algorithms(security_profile)

    with :ok <- ensure_allowed_alg(alg, allowed_algs),
         {:ok, auth_time} <- validate_auth_time(Map.get(params, :auth_time)),
```

**Hardcoded-path drift to replace** (`logout_token.ex` lines 12-25):
```elixir
        signing_key: %{kid: kid, alg: "RS256", private_jwk_encrypted: private_jwk}
...
             %{"alg" => "RS256", "kid" => kid, "typ" => "logout+jwt"},
```

**Publishable-key verification pattern** (`end_session.ex` lines 75-100):
```elixir
    case key_store(request).list_publishable_keys() do
      {:ok, signing_keys} when is_list(signing_keys) ->
        Enum.reduce_while(signing_keys, {:error, default_error}, fn key, _acc ->
          case build_public_jwk(key) do
            {:ok, public_jwk} ->
              case JOSE.JWT.verify_strict(public_jwk, @allowed_algorithms, compact_jwt) do
```

**What Phase 42 should copy:** keep the `with`-based signer guard from `IdToken`, keep the `verify_strict` + typed-error pattern from `DPoP`, and replace local `@allowed_algorithms`/`"RS256"` constants with the canonical policy seam.

---

### `lib/lockspire/protocol/discovery.ex`, `lib/lockspire/protocol/jwks.ex`, `lib/lockspire/web/controllers/userinfo_controller.ex`

**Planner recommendation:** Treat discovery, JWKS, and DPoP challenges as publication surfaces. They should publish only what runtime accepts now, not future intent.

**Primary analogs:** [lib/lockspire/protocol/discovery.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/discovery.ex:75), [lib/lockspire/protocol/jwks.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/jwks.ex:10), [lib/lockspire/web/controllers/userinfo_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/userinfo_controller.ex:53)

**Truthful metadata builder pattern** (`discovery.ex` lines 75-95):
```elixir
  def openid_configuration do
    issuer = Config.issuer!()
    endpoint_metadata = mounted_endpoint_metadata()

    %{
      "issuer" => issuer,
      ...
      "id_token_signing_alg_values_supported" => @id_token_signing_alg_values_supported
    }
    |> Map.merge(endpoint_metadata)
    |> maybe_put_dpop_metadata(endpoint_metadata)
    |> put_bcl_fcl_metadata()
  end
```

**Conditional publication pattern** (`discovery.ex` lines 159-174):
```elixir
  defp maybe_put_dpop_metadata(metadata, endpoint_metadata) do
    if dpop_supported_surface_mounted?(endpoint_metadata) do
      Map.put(
        metadata,
        "dpop_signing_alg_values_supported",
        DPoP.signing_alg_values_supported()
      )
    else
      metadata
    end
  end
```

**JWKS filtering pattern** (`jwks.ex` lines 10-25):
```elixir
  def public_jwk_set(opts \\ []) do
    key_store = Keyword.get(opts, :key_store, Lockspire.Storage.Ecto.Repository)

    with {:ok, keys} <- key_store.list_publishable_keys() do
      {:ok, %{"keys" => Enum.map(keys, &to_public_jwk/1)}}
    end
  end
```

**Challenge-publication pattern** (`userinfo_controller.ex` lines 53-80):
```elixir
  defp www_authenticate_value(%Error{reason_code: reason_code}) when reason_code in [...] do
    algorithms = Enum.join(Lockspire.Protocol.DPoP.signing_alg_values_supported(), " ")
    ~s(DPoP realm="Lockspire Userinfo", error="invalid_token", algs="#{algorithms}")
  end
```

**What Phase 42 should copy:** discovery values, JWKS entries, and `WWW-Authenticate` algorithm hints should all call the same canonical signing-algorithm source that verification and signing use.

---

### `lib/lockspire/security/policy.ex`, `lib/lockspire/admin/keys.ex`, `lib/lockspire/storage/key_store.ex`, `lib/lockspire/storage/ecto/repository.ex`

**Planner recommendation:** Fail fast at write and activation boundaries, then keep runtime checks as defense in depth. Reuse the existing activation seam; do not invent a second lifecycle.

**Primary analogs:** [lib/lockspire/security/policy.ex](/Users/jon/projects/lockspire/lib/lockspire/security/policy.ex:12), [lib/lockspire/admin/keys.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/keys.ex:110), [lib/lockspire/storage/key_store.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/key_store.ex:10), [lib/lockspire/storage/ecto/repository.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/repository.ex:880)

**Compliance-check pattern** (`policy.ex` lines 12-24):
```elixir
  def validate_key_compliance(%SigningKey{alg: alg} = key, :fapi_2_0_security) do
    with :ok <- ensure_fapi_compliant_alg(alg),
         :ok <- ensure_fapi_compliant_strength(key) do
      :ok
    end
  end

  defp ensure_fapi_compliant_alg(alg) when alg in ["ES256", "PS256", "EdDSA", :ES256, :PS256, :EdDSA], do: :ok
  defp ensure_fapi_compliant_alg(alg), do: {:error, {:non_compliant_algorithm, alg}}
```

**Activation guard pattern** (`admin/keys.ex` lines 117-136):
```elixir
  def activate_key(key_id, attrs) when is_integer(key_id) and is_map(attrs) do
    with {:ok, server_policy} <- Repository.get_server_policy(),
         {:ok, %SigningKey{} = key_to_activate} <- Repository.fetch_signing_key_by_id(key_id),
         :ok <- Policy.validate_key_compliance(key_to_activate, server_policy.security_profile),
         {:ok, %{activated_key: key}} <- ...
```

**Publishable/active storage contract** (`key_store.ex` lines 10-24):
```elixir
  @callback list_publishable_keys() :: {:ok, [SigningKey.t()]} | {:error, store_error()}
  @callback fetch_active_signing_key() :: {:ok, SigningKey.t() | nil} | {:error, store_error()}
  @callback activate_signing_key(integer(), DateTime.t()) ::
              {:ok, %{activated_key: SigningKey.t(), retiring_key: SigningKey.t() | nil}}
```

**Repository publication semantics** (`repository.ex` lines 880-918, 934-968):
```elixir
  def list_publishable_keys do
    SigningKeyRecord
    |> where([key], key.status in [:active, :retiring] or (key.status == :upcoming and not is_nil(key.published_at)))
  end

  def fetch_active_signing_key do
    SigningKeyRecord
    |> where([key], key.status == :active)
    |> where([key], key.use == :sig)
  end

  def activate_signing_key(id, activated_at) do
    transact(fn ->
      id
      |> locked_signing_key_query()
      |> repo().one()
      |> activate_signing_key_record(activated_at)
    end)
  end
```

**What Phase 42 should copy:** keep the compliance error at admin/repository boundaries, reuse `list_publishable_keys/0` and `fetch_active_signing_key/0` as the truth for publication vs activation, and expand the same seam for FAPI boot-time/server-policy readiness checks.

---

### `lib/lockspire/storage/ecto/client_record.ex`

**Planner recommendation:** If client algorithm metadata is rejected early under FAPI-effective state, do it in the same durable update path used for `security_profile` and other mutable client policy.

**Analog:** [lib/lockspire/storage/ecto/client_record.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/client_record.ex:143)

**Mutable-operator whitelist pattern** (`client_record.ex` lines 143-171):
```elixir
  def update_changeset(record, attrs) do
    record
    |> cast(attrs, [
      :name,
      ...
      :dpop_policy,
      :security_profile,
      :jwks,
      :jwks_uri,
      :id_token_signed_response_alg,
      ...
    ])
```

**What Phase 42 should copy:** if planner adds stronger FAPI checks around `id_token_signed_response_alg` or similar client metadata, enforce them in the existing mutable changeset/admin path instead of introducing a parallel validation path.

---

### Tests: protocol, publication, integration, and release-contract

**Planner recommendation:** Phase 42 needs four test layers, matching Lockspire’s existing pattern: pure protocol unit tests, HTTP/publication tests, integration flow tests, and release-truth contract tests.

**Protocol unit-test analogs**

- [test/lockspire/protocol/security_profile_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/security_profile_test.exs:9)
- [test/lockspire/protocol/dpop_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/dpop_test.exs:58)
- [test/lockspire/protocol/jar_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/jar_test.exs:73)
- [test/lockspire/protocol/id_token_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/id_token_test.exs:11)
- [test/lockspire/protocol/logout_token_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/logout_token_test.exs:11)
- [test/lockspire/protocol/end_session_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/end_session_test.exs:21)

**Table-driven/typed-reason pattern** (`dpop_test.exs` lines 156-233):
```elixir
    test "returns a typed reason for later invalid_dpop_proof mapping when htm mismatches", %{keys: keys} do
      ...
      assert {:error, :invalid_htm} = DPoP.validate_proof(proof, validation_opts())
    end
```

**Round-trip signer test pattern** (`id_token_test.exs` lines 52-67, `logout_token_test.exs` lines 14-31):
```elixir
    assert {:ok, jwt} = IdToken.sign(signing_params(overrides, keys))
    assert {true, %JOSE.JWT{fields: claims}, _jws} = JOSE.JWT.verify_strict(public_jwk, ["RS256"], jwt)
```

**Request validation seam pattern** (`end_session_test.exs` lines 139-145):
```elixir
  defp request(params) do
    %{
      params: params,
      opts: [client_store: ..., key_store: ...]
    }
  end
```

**HTTP/publication analogs**

- [test/lockspire/protocol/discovery_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/discovery_test.exs:99)
- [test/lockspire/web/discovery_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/discovery_controller_test.exs:62)
- [test/lockspire/web/jwks_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/jwks_controller_test.exs:98)
- [test/lockspire/admin/keys_test.exs](/Users/jon/projects/lockspire/test/lockspire/admin/keys_test.exs:54)

**Truthful-publication assertions** (`web/discovery_controller_test.exs` lines 102-145, `jwks_controller_test.exs` lines 107-116):
```elixir
    assert body["id_token_signing_alg_values_supported"] == ["RS256"]
    refute Map.has_key?(body, "request_object_signing_alg_values_supported")
...
    refute Enum.any?(keys, &Map.has_key?(&1, "d"))
```

**Operator transition/audit pattern** (`admin/keys_test.exs` lines 62-117):
```elixir
    assert {:ok, active_view} = Keys.activate_key(upcoming_key.id, %{...})
    assert_received {:telemetry_event, [:lockspire, :key_activated], %{key_id: ^upcoming_key_id, actor_id: "ops-activate"}}
```

**Integration and release-contract analogs**

- [test/integration/phase41_fapi_2_0_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase41_fapi_2_0_e2e_test.exs:95)
- [test/lockspire/release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:164)

**End-to-end proof pattern** (`phase41_fapi_2_0_e2e_test.exs` lines 95-119, 175-236):
```elixir
    assert authorize_conn.status in [302, 303]
    assert location =~ "error_description=request_uri+from+the+PAR+endpoint+is+required"
...
    assert token_dpop_conn.status == 200
    assert token_resp["token_type"] == "DPoP"
...
    assert userinfo_dpop_conn.status == 200
```

**Executable release-truth pattern** (`release_readiness_contract_test.exs` lines 164-205):
```elixir
    assert oidf_conformance_workflow =~ "workflow_dispatch:"
    assert oidf_conformance_workflow =~ "schedule:"
    assert oidf_conformance_workflow =~ "MIX_ENV=test mix conformance.phase37"
    refute oidf_conformance_workflow =~ "pull_request:"
```

**What Phase 42 should copy:** add protocol tests for every acceptance/rejection surface, HTTP tests for discovery/JWKS truth, one integration test that proves FAPI-effective rejection of RS256 and non-compliant keys, and release-contract tests that pin wording, scripts, mix aliases, and workflow names.

---

### Docs, scripts, and workflow wiring

**Primary analogs:** [docs/maintainer-conformance.md](/Users/jon/projects/lockspire/docs/maintainer-conformance.md:1), [scripts/conformance/fapi2-check.sh](/Users/jon/projects/lockspire/scripts/conformance/fapi2-check.sh:1), [.github/workflows/oidf-conformance.yml](/Users/jon/projects/lockspire/.github/workflows/oidf-conformance.yml:1)

**Maintainer-doc pattern** (`maintainer-conformance.md` lines 14-27, 29-51):
```markdown
## Step 1: Enable the FAPI 2.0 security profile
...
## Step 2: Run the local boundary probe script
...
- `/authorize` returns `302` with `error=invalid_request`
- `/token` returns `400` with `invalid_dpop_proof`
- `/userinfo` returns `401` with `invalid_token`
```

**Probe-script pattern** (`fapi2-check.sh` lines 24-35, 45-68, 86-93):
```bash
failures=0
print_result() { ... }
authorize_code="$(curl ...)"
if [ "$authorize_code" = "302" ] ...; then
  print_result "PASS" ...
fi
...
exit 0 only when all probes pass
```

**Workflow artifact pattern** (`oidf-conformance.yml` lines 21-70, 72-124):
```yaml
jobs:
  repo-native-phase37:
    ...
    - name: Run Phase 37 conformance lane
      run: MIX_ENV=test mix conformance.phase37
    - name: Upload Phase 37 artifacts
      if: always()
```

**What Phase 42 should copy:** deterministic env-var contract, one repo-native mix/script entrypoint, always-uploaded artifacts, and docs that explicitly distinguish preflight from definitive OIDF proof.

## Shared Patterns

### Canonical Algorithm Truth Source
**Source:** [lib/lockspire/protocol/dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/dpop.ex:42), [lib/lockspire/protocol/security_profile.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/security_profile.ex:53)
**Apply to:** `security_profile.ex`, `jar.ex`, `id_token.ex`, `logout_token.ex`, `end_session.ex`, `discovery.ex`, `jwks.ex`, `userinfo_controller.ex`

Use one exported protocol function for both verification and publication. Do not keep per-surface `@allowed_algorithms` lists after Phase 42.

### Fail-Fast Write Boundary
**Source:** [lib/lockspire/admin/keys.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/keys.ex:121), [lib/lockspire/security/policy.ex](/Users/jon/projects/lockspire/lib/lockspire/security/policy.ex:12)
**Apply to:** key activation, key generation defaults, server-policy flips, client algorithm updates, any admin/DCR write that can create FAPI-incompatible state

Reject incompatible state before it becomes publishable or active, then leave runtime guards in place for defense in depth.

### Truthful Publication
**Source:** [lib/lockspire/protocol/discovery.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/discovery.ex:159), [lib/lockspire/protocol/jwks.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/jwks.ex:10), [lib/lockspire/web/controllers/userinfo_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/userinfo_controller.ex:53)
**Apply to:** discovery algorithm metadata, JWKS content, DPoP/auth challenges, any public support claim

Only publish values proven by the exact same runtime path.

### Executable Docs and Release Truth
**Source:** [test/lockspire/release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:164), [docs/maintainer-conformance.md](/Users/jon/projects/lockspire/docs/maintainer-conformance.md:29), [scripts/conformance/fapi2-check.sh](/Users/jon/projects/lockspire/scripts/conformance/fapi2-check.sh:38), [.github/workflows/oidf-conformance.yml](/Users/jon/projects/lockspire/.github/workflows/oidf-conformance.yml:21)
**Apply to:** docs, `mix` aliases, shell entrypoints, workflow names, artifact paths, release-support wording

If documentation claims a conformance lane exists, the repo contract test should pin the exact script/workflow names and invocation strings.

## Prior Phase Plan Decomposition To Copy

### Recommended Phase 42 split

1. **Foundation / truth source first**
   Copy the shape of [41-01-PLAN.md](/Users/jon/projects/lockspire/.planning/phases/41-fapi-2-0-profile-configuration/41-01-PLAN.md:1): durable truth module first, explicit `files_modified`, concrete truth statements, and storage/admin seams ratified before downstream protocol work.

2. **Surface enforcement/publication second**
   Copy the shape of [41-02-PLAN.md](/Users/jon/projects/lockspire/.planning/phases/41-fapi-2-0-profile-configuration/41-02-PLAN.md:13): dispatch-table style requirements, narrow responsibility boundaries, and documented defense-in-depth limitations where boundary code intentionally stays shallow.

3. **Operator and integration proof late**
   Copy the shape of [41-04-PLAN.md](/Users/jon/projects/lockspire/.planning/phases/41-fapi-2-0-profile-configuration/41-04-PLAN.md:13): one plan that extends the end-to-end test, maintainer script, and docs together so the public conformance story stays tied to repo evidence.

### Concrete planner recommendation

- `42-01`: Canonical signing algorithm truth source plus `SecurityProfile` narrowing to `ES256`/`PS256`; update pure protocol callers first.
- `42-02`: Signing/verification surfaces and truthful publication: `jar`, `id_token`, `logout_token`, `end_session`, `discovery`, `jwks`, `userinfo_controller`.
- `42-03`: Key activation/compliance and mixed-mode rejection: `security/policy`, `admin/keys`, `repository`, `key_store`, client metadata/admin validation.
- `42-04`: Release-contract and maintainer conformance wiring: integration test, release contract, conformance doc/script/workflow, artifacts.

This keeps the same dependency logic as Phase 41: foundational truth first, behavior/public surface second, operator/release proof last.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| None | - | - | All Phase 42 surfaces have a usable in-repo analog; the only discretionary choice is whether to create a tiny canonical policy module or keep the truth export inside `SecurityProfile`. |

## Metadata

**Analog search scope:** `lib/lockspire/protocol`, `lib/lockspire/security`, `lib/lockspire/admin`, `lib/lockspire/storage`, `test/lockspire`, `test/integration`, `docs`, `scripts`, `.github/workflows`, `.planning/phases/41-*`

**Key modules to prefer:** `DPoP` for truth-export shape, `Discovery` for truthful publication, `IdToken` for signer preflight, `EndSession` for publishable-key verification, `Admin.Keys` + `Security.Policy` for fail-fast compliance, `ReleaseReadinessContractTest` for public-truth enforcement.

**Pattern extraction date:** 2026-05-01
