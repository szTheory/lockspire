# Phase 133: Clean-Room SaaS Journey - Pattern Map

**Mapped:** 2026-08-27  
**Scope:** package-clean provider host, separately booted confidential client, real HTTP acceptance journey  
**Files analyzed:** 18 primary analogs  
**Analogs found:** 11 / 11 proposed implementation roles

## File Classification

| Proposed new/modified file | Role | Data flow | Closest analog | Decision |
|---|---|---|---|---|
| `test/integration/phase133_clean_room_saas_journey_test.exs` | integration acceptance test | request-response | `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs` | New; split its lifecycle assertions into named black-box journey steps. |
| `test/support/fixtures/clean_room_provider/*` | generated Phoenix/Ecto host fixture | CRUD/request-response | `test/support/fixtures/generated_host_app` + `priv/templates/lockspire.install/*` | New fixture; create via installer and retain only documented host edits. |
| `test/support/fixtures/clean_room_client/*` | confidential Phoenix client fixture | request-response/CRUD | `examples/adoption_demo/` | New, deliberately small app; do not extend the adoption demo. |
| `test/support/clean_room_saas/*` | harness utilities | request-response/process lifecycle | `scripts/conformance/run_phase37_suite.sh` + `scripts/demo/adoption_smoke.py` | New; owns ephemeral paths/ports/processes and redacted diagnostics. |
| `scripts/acceptance/run_clean_room_saas_journey.sh` | CI entrypoint/process supervisor | batch/process lifecycle | `scripts/conformance/run_phase37_suite.sh` | New; `trap cleanup EXIT`, bounded readiness, no leaked process/log. |
| `scripts/acceptance/clean_room_saas_journey.py` (or an equivalent fixture-local HTTP client) | HTTP orchestrator | request-response | `scripts/demo/adoption_smoke.py` | New; preserve small named steps and stdlib HTTP/cookie behavior. |
| provider generated `router.ex`, config, resolver, login/session, consent, protected API controller | host integration surface | request-response | `priv/templates/lockspire.install/*`, `test/support/generated_host_app_web/*` | Reuse generator output; only add documented host-owned application code. |
| client transaction store + callback controller | server-side OAuth transaction state | CRUD/request-response | no exact durable client analog | New; use ordinary Ecto changeset/repository pattern from the provider fixture, with one-time terminal consumption. |
| client OIDC verifier | HTTP + transform | request-response/transform | `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs` | New fixture-local module; use JOSE verification assertions, not Lockspire protocol internals. |
| provider bootstrap/seeding command | setup/batch | batch | `examples/adoption_demo/priv/repo/seeds.exs` | New bounded host-owned bootstrap; register through supported `Lockspire.Clients.register_client/1` or documented host setup seam. |
| CI workflow / test matrix entry | CI config | batch | `.github/workflows/ci.yml`, `scripts/ci/run_test_matrix.sh` | Modify only after the local command is stable; run in the integration lane with PostgreSQL. |

## Pattern Assignments

### Clean provider installation and generated seam

**Copy from:** `test/integration/install_generator_test.exs` (lines 43-300, 361-520, 649-709) and `lib/mix/tasks/lockspire.install.ex` (lines 1-88).

- The installer invocation takes `--web`, `--scope`, `--path`, `--mount-path`, `--storage-prefix`, and `--oban-prefix`; the acceptance fixture must invoke that public command rather than copy generated source or call generator internals.
- The generated host must import the macro and call `lockspire_routes/0`. `test/support/generated_host_app_web/router.ex` (lines 1-50) is the compiling reference for the generated public/admin/consent mount plus a host-owned resource pipeline.
- Required package-boundary proof is: dependency resolves through the built local package/path artifact, `mix lockspire.install`, host-edited config/router/session/account resolver compile, ordinary migration command applies shipped migrations, then `mix lockspire.verify` succeeds. Do not use `Lockspire.Protocol.*`, `Lockspire.Storage.*`, `Lockspire.TestRepo`, test-support modules, or a replacement router from inside the installed provider app.
- `priv/templates/lockspire.install/config.exs` (lines 1-19) defines the required runtime seam: `repo`, `account_resolver`, issuer, mount path, host logout path, storage prefix, and Oban prefix. `priv/templates/lockspire.install/router.ex` (lines 1-63) is authoritative for route ownership and ordering.

### Provider host login, claims, protected route, and host policy

**Copy from:** `test/support/generated_host_app_web/controllers/session_controller.ex` (lines 1-97), `test/support/generated_host_app/lockspire/test_account_resolver.ex` (lines 1-120), and `test/support/generated_host_app_web/controllers/protected_api_controller.ex` (lines 1-39).

```elixir
pipeline :lockspire_protected_api do
  plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api"
  plug Lockspire.Plug.EnforceSenderConstraints
  plug Lockspire.Plug.RequireToken
end
```

This exact order, visible in `test/support/generated_host_app_web/router.ex` lines 25-29 and `docs/protect-phoenix-api-routes.md` lines 12-22, is mandatory. The controller reads only `Lockspire.AccessToken.subject/1`, `scopes/1`, `audiences/1`, `expires_at/1`, and `confirmation/1`; its `host_authorized_for_billing?/1` remains an independent host product decision. The clean host should follow this structure and expose a deliberately minimal JSON semantic contract.

### Separate process / real listener orchestration

**Copy from:** `scripts/conformance/run_phase37_suite.sh` (lines 1-140) and `.github/workflows/ci.yml` (lines 252-330, 340-405).

```bash
FIXTURE_PID=""
cleanup() {
  local exit_code=$?
  if [[ -n "${FIXTURE_PID}" ]]; then
    kill "${FIXTURE_PID}" >/dev/null 2>&1 || true
    wait "${FIXTURE_PID}" >/dev/null 2>&1 || true
  fi
  rm -rf "${WORK_DIR}"
  exit "${exit_code}"
}
trap cleanup EXIT
```

Retain the conformance script’s `mktemp -d`, `set -euo pipefail`, PID capture, bounded `wait_for_url`, and log-on-failure conventions. Improve its single-fixture shape to track *two* PIDs, two distinct loopback ports/origins, and distinct working/database paths. The local fixture script is an orchestration analog only: its `Lockspire.TestRepo` and generated test modules are explicitly forbidden inside the Phase 133 clean provider.

### HTTP client, cookies, redirect handoff, and small diagnostic steps

**Copy from:** `scripts/demo/adoption_smoke.py` (lines 1-152 and 220-394).

```python
def request(self, method, target, data=None, headers=None, follow=False):
    url = urljoin(self.base + "/", target)
    for _ in range(8):
        response = self._single_request(method, url, data, headers)
        if not follow or response["status"] not in (301, 302, 303, 307, 308):
            return response
        location = response["headers"].get("location")
        if not location:
            return response
        url = urljoin(url, location)
```

Reuse its standard-library HTTP client, explicit cookie jar, form encoding, redirect cap, `assert_status`, JSON parsing, CSRF extraction, S256 helper, and readiness timeout. Keep Phase 133’s client logic separate from this same-origin public-client smoke: it must register/use a confidential client, persist transaction data server-side, and must not print `response["body"]` unredacted when it could contain a sentinel secret.

### Authorization transaction state and callback terminal behavior

**Reference behavior:** `scripts/demo/adoption_smoke.py` (lines 220-290), `test/integration/phase36_auth_code_dpop_e2e_test.exs` (lines 83-195), and `examples/adoption_demo/lib/adoption_demo_web/controllers/oauth_callback_controller.ex` (lines 1-145).

The new client fixture must improve on the adoption callback controller, which is explanatory UI only and currently renders raw callback parameters. Persist generated `state`, `nonce`, and PKCE verifier at authorization start; on callback, look up the transaction, compare `state` before token exchange, and consume/invalidate the transaction for both success and every terminal error. Treat callback data and its error paths as sensitive evidence, unlike the adoption demo’s presentation-oriented receipt.

Use the Phase 36 shape for actual authorization-code/PKCE interaction:

```elixir
"code_challenge" => code_challenge(code_verifier),
"code_challenge_method" => "S256",
"nonce" => nonce,
"state" => state
```

Its consent completion and callback query parsing prove the correct wire sequence, but Phase 133 must perform it through listeners and browser-like HTTP, never `Phoenix.ConnTest` or `Lockspire.Web.Router.call/2`.

### Discovery, JWKS, ID token, and userinfo validation

**Copy assertions from:** `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs` (lines 115-220).

The fixture-local verifier should fetch the discovery document from the advertised URL, then fetch `jwks_uri`, select the JWK by JWT `kid`, and use only discovery-advertised supported signing algorithms. Phase 3’s validation contract is:

```elixir
assert {true, %JOSE.JWT{fields: claims}, _jws} =
         JOSE.JWT.verify_strict(signing_key, ["RS256"], id_token)
assert claims["iss"] == issuer
assert claims["aud"] == client_id
assert claims["nonce"] == original_nonce
```

Translate that *behavior* into a client-owned verifier module. Do not alias `Lockspire.Protocol.*` or reuse `Lockspire.JarTestHelpers`, which are both outside the packaged public surface. After a successful userinfo request, require `userinfo["sub"] == validated_id_token_sub` before marking the client session complete.

### Token lifecycle: refresh, introspection, revocation, and code reuse

**Copy from:** `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs` (lines 222-326).

Use `Authorization: Basic base64(client_id <> ":" <> secret)` for confidential token, introspection, and revocation requests. The acceptance response contract should prove: rotated refresh token differs; old-token replay gives `400`/`invalid_grant`; introspection of the affected token family reports only `%{"active" => false}`; revocation returns the idempotent `200` empty JSON response. Explicitly state in the test text that lifecycle endpoints report authorization-server truth, while an already issued self-contained JWT is not promised to fail offline before expiry.

### DPoP nonce retry and durable replay rejection

**Copy from:** `test/integration/phase81_generated_host_route_protection_e2e_test.exs` (lines 170-264), `test/integration/phase36_auth_code_dpop_e2e_test.exs` (lines 120-190), and `test/integration/protected_resource_dpop_default_store_test.exs` (lines 35-77).

- First resource request with a DPoP-bound access token and no acceptable nonce must yield `401`, `WWW-Authenticate` containing `error="use_dpop_nonce"`, and a `DPoP-Nonce` header.
- Retry with a *new* proof carrying that nonce; require `200` and semantic `confirmation.dpop_jkt` in the host response.
- Replay that exact accepted proof; require rejection over HTTP. The durable-store test proves the default has no injected store and records through configured Ecto repository; Phase 133 must preserve that configuration and prove it externally rather than reading `DpopReplayRecord` directly.

For proof construction, implement equivalent fixture-local JOSE code to `test/support/jar_test_helpers.ex` lines 38-88, but do not import the test helper into either clean application.

### Security-negative matrix and redaction

**Copy from:** `test/integration/phase81_generated_host_route_protection_e2e_test.exs` (lines 104-166), `test/lockspire/redaction/redaction_test.exs` (lines 6-47), and `lib/lockspire/redaction.ex` (lines 1-150).

Assert stable public outcomes only: missing/wrong-audience access token is `401 invalid_token`; under-scoped valid token is `403 insufficient_scope` plus scope challenge; do not assert storage rows or private reason atoms. Place unique sentinel strings in authorization code, access token, refresh token, client secret, PKCE verifier, DPoP key/proof, and cookie test inputs. On failure, scan retained fixture logs and copied evidence for each sentinel, emitting only safe handles/labels. The repository’s shared redactor drops these exact material keys; Phase 133’s harness must also avoid embedding them in Python/Elixir assertion formatting or shell tracing.

### CI command convention

**Copy from:** `.github/workflows/ci.yml` (lines 252-330) and `scripts/ci/run_test_matrix.sh`.

The integration lane already provides PostgreSQL, installs root dependencies with `--check-locked`, waits for readiness, and emits a timing JSON. Phase 133 should add one deterministic invocation to that lane (or a clearly named sibling job only if process isolation warrants it), preserve `if: always()` logs/timings, and keep all generated temp content beneath ignored `tmp/` / `.artifacts/`. Do not make CI depend on Docker; Phase 133 only needs ordinary local processes and PostgreSQL.

## Shared Patterns

### Package boundary

Generated provider code is allowed to use `Lockspire`, documented mix tasks, `Lockspire.Plug.*`, `Lockspire.AccessToken`, `Lockspire.Clients`, and host-owned seams. It must not reference `Lockspire.Protocol.*`, `Lockspire.Storage.*`, `Lockspire.TestRepo`, `test/support`, or source-relative path dependencies. Enforce with textual boundary checks plus the provider fixture’s own compile/test/verify invocation.

### Separate-origin truth

Provider and client need separate Phoenix endpoints, ports, cookie names, app names, workdirs, and databases/schema isolation. Redirects must cross from provider origin to client origin; never simulate this with `ConnTest`, direct `Router.call/2`, or a single session cookie jar scoped as one app.

### Evidence discipline

Keep command output compact and named by journey step. Retain redacted provider/client logs only on failure (or scan before retention); teardown must run on success, test failure, signal, and startup failure. Bootstrap-only plaintext client secret is passed through an ephemeral env/file channel with restrictive permissions and removed in cleanup.

## No Exact Analog Found

| File/concern | Why it needs a new pattern |
|---|---|
| Separate confidential-client Phoenix app with durable OAuth transaction records | Existing adoption demo is same-origin/public-client and only displays callbacks. |
| Package-clean, two-process acceptance supervisor | Conformance script boots one root-source test fixture; it cannot establish the package boundary. |
| Client-side discovery/JWKS verifier | Existing proof validates server-issued JWTs in test code, not as an independently booted client application. |
| Redaction scan for acceptance logs/evidence | Repository redaction unit tests cover metadata, not process-log artifact scanning. |

## Risks to Carry into Planning

1. **False package proof:** a path dependency pointed at repository source can bypass package contents. The harness must build a local artifact or isolated dependency copy, inspect dependency provenance, and prohibit source-relative imports. Exact Hex tarball checksum/publish proof remains Phase 137.
2. **False HTTP proof:** existing integration tests are valuable behavioral analogs but use `ConnTest`; Phase 133 must make every journey claim cross an actual listener.
3. **Secret leak on failure:** common helpers print response bodies. Replace with redacted summaries and sentinel scans before logs are copied/uploaded.
4. **Flaky process/database cleanup:** use unique ports/names, bounded readiness, `trap` cleanup, and per-run temp roots. Do not share the root `Lockspire.TestRepo` or existing adoption-demo database.
5. **Overclaiming JWT revocation:** test lifecycle endpoints as durable server truth; do not promise immediate offline JWT invalidation.
6. **DPoP proof semantics:** `htu` must exactly match the externally visible resource URL and replay must reuse the byte-identical accepted proof, while retry must generate a fresh proof with the challenge nonce.

## Metadata

**Analog search scope:** `priv/templates/lockspire.install`, `lib/mix/tasks`, `test/integration`, `test/support`, `examples/adoption_demo`, `scripts`, `.github/workflows`, `docs`  
**Pattern extraction date:** 2026-08-27
