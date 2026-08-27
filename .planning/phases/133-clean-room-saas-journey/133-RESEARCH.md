# Phase 133: Clean-Room SaaS Journey - Research

**Researched:** 2026-08-27  
**Domain:** black-box Phoenix/OAuth/OIDC acceptance testing across separately booted origins  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Build an isolated black-box acceptance harness with two separately booted applications on distinct HTTP origins: a generated Phoenix/Ecto provider host that embeds Lockspire and owns the protected API, and a small confidential-client Phoenix application that consumes it.
- **D-02:** The provider host must use the packaged installer, generated migrations/configuration/router seams, `mix lockspire.verify`, and documented host-owned edits. It must not import `Lockspire.Protocol.*`, `Lockspire.Storage.*`, replace Lockspire protocol routes, or rely on test-support modules.
- **D-03:** Phase 133 may consume a locally built package/path artifact through the public package surface. It must prove the boundary is package-clean, but exact Hex tarball checksums and pre-/post-publish installation remain Phase 137.
- **D-04:** Exercise the journey through actual listeners and HTTP clients, not only `ConnTest` or direct protocol calls. Keep the harness deterministic, headless, CI-capable, and self-cleaning without requiring browser automation.
- **D-05:** Persist independently random `state`, `nonce`, and PKCE verifier server-side for each authorization transaction. Use S256, compare callback state before exchanging the code, and consume or invalidate the transaction on every terminal callback outcome.
- **D-06:** Register a real confidential client through a supported host/admin-facing setup seam with authorization code, refresh token, `client_secret_basic`, OIDC scopes, a protected-resource scope, and the intended resource audience. Plaintext secret material may exist only during bootstrap and client-server configuration and must never enter logs or retained evidence.
- **D-07:** The external client must fetch discovery and JWKS from advertised HTTP endpoints, select keys by `kid`, restrict algorithms to the advertised supported set, and validate ID-token signature, issuer, audience, expiration, and original nonce.
- **D-08:** Fetch userinfo with the issued access token and require its `sub` to exactly match the validated ID-token subject before treating login as complete.
- **D-09:** The provider host protects its SaaS API through the documented `VerifyToken -> EnforceSenderConstraints -> RequireToken` path and the Phase 132 semantic `Lockspire.AccessToken` readers. Lockspire owns protocol checks; host code separately owns its illustrative tenant/product authorization decision.
- **D-10:** The successful client journey must call a route requiring the intended audience and scope and assert only the documented HTTP and semantic response contract.
- **D-11:** Prove refresh-token rotation succeeds once, reuse of the previous refresh token revokes the token family, authenticated introspection reports durable server-side lifecycle truth, and authenticated revocation behaves idempotently.
- **D-12:** Keep JWT lifetime semantics truthful: revocation and family state are immediately visible to Lockspire lifecycle endpoints, but an already-issued self-contained JWT is not claimed to become instantly invalid at an offline resource server before expiry.
- **D-13:** Reject, over real HTTP, callback-state mismatch, redirect drift, authorization-code reuse, nonce mismatch, missing access token, wrong audience, insufficient scope, invalid or missing DPoP nonce, and replay of the identical accepted DPoP proof.
- **D-14:** Assert stable wire outcomes—status, OAuth/OIDC error, and authentication challenge where documented—rather than internal structs, repository rows, or private reason codes.
- **D-15:** Run DPoP through the same confidential-client/provider journey: obtain a DPoP-bound access token, receive the resource-server nonce challenge, retry with a new proof carrying that nonce, then replay that exact successful proof and observe rejection.
- **D-16:** Use the configured Ecto repository for DPoP replay recording, with no test-only in-memory or custom replay override. Prove persistence through externally observable behavior and, where necessary, a bounded host-owned verification command rather than internal application calls.
- **D-17:** Redact authorization codes, access/refresh tokens, client secrets, PKCE verifiers, DPoP private keys/proofs, and cookies from logs, failure messages, snapshots, and retained CI artifacts. Negative tests should use sentinels to make leakage failures explicit.
- **D-18:** Keep the acceptance harness narrow and reference-quality; it is executable proof, not a new hosted service, client SDK, general OAuth client library, or replacement adoption demo.

### the agent's Discretion

- Exact fixture directory layout and process supervisor, provided the two applications remain separately booted and package-clean.
- Whether the confidential-client transaction store uses Ecto or another durable server-side store, provided concurrency, one-time consumption, and restart-safe behavior are executable.
- How bootstrap credentials and ports are passed between processes, provided the channel is ephemeral, redacted, deterministic, and CI-safe.
- How ID-token/JWKS verification is factored inside the fixture, provided all required validation steps are explicit and independently testable.

### Deferred Ideas (OUT OF SCOPE)

- Exact Hex package checksum, immutable published-version installation, and release evidence manifests belong to Phase 137.
- Dependency topology restructuring belongs to Phase 134; storage/token decomposition belongs to Phase 135.
- Browser UI acceptance, admin visual review, hosted OAuth service behavior, general client SDKs, and new grants remain outside this phase.
</user_constraints>

## Project Constraints (from AGENTS.md)

- Keep Lockspire a separate embedded companion library for Phoenix/Elixir; do not turn the clean-room proof into a standalone authorization service. [VERIFIED: repository `AGENTS.md`]
- Preserve the boundary between protocol core, storage, generators, Plug/Phoenix integration, and operator/LiveView surfaces. [VERIFIED: repository `AGENTS.md`]
- Keep host seams narrow: host owns accounts, login UX, layouts, branding, and product-specific policy; the fixture must not turn those into Lockspire behavior. [VERIFIED: repository `AGENTS.md`]
- Do not broaden v1 into SAML, LDAP/AD federation, hosted auth, or CIAM/SDK scope. [VERIFIED: repository `AGENTS.md`]
- Preserve secure defaults: S256 PKCE, exact redirect matching, hashed client secrets, short-lived single-use authorization codes, refresh-family revocation on reuse, no implicit flow, no `alg=none`, and strong log/operator redaction. [VERIFIED: repository `AGENTS.md`]
- Use the project stack (Phoenix, LiveView, Ecto/PostgreSQL, Bandit, Oban, OpenTelemetry) and treat install DX, secure OAuth/OIDC defaults, resource/lifecycle endpoints, operator calmness, and executable release hygiene as the priority order. [VERIFIED: repository `AGENTS.md`]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| E2E-01 | Package-clean Phoenix/Ecto host installs, migrates, verifies, tests, and boots. | Provider fixture is generated from the package installer, then patched only through documented host seams and executed as an independent Mix project. |
| E2E-02 | Separate confidential client persists transaction material, completes code+PKCE, rejects bad state. | Client fixture owns durable transaction records, callback state-before-exchange, and one-time terminal consumption. |
| E2E-03 | Discovery/JWKS/ID token/userinfo are validated before protected API use. | A client-local verifier fetches advertised metadata/JWKS, selects `kid`, restricts algorithms, validates claims, then compares `userinfo.sub`. |
| E2E-04 | Refresh rotation/reuse, introspection, revocation, and truthful JWT lifetime are proven. | Journey runner retains only in-memory response material, asserts lifecycle endpoints over HTTP, and does not assert immediate offline JWT rejection after revocation. |
| E2E-05 | Redirect/code/state/nonce/token/audience/scope failures return documented outcomes. | Named negative cases drive real endpoints and compare status/body/challenge only. |
| E2E-06 | DPoP nonce retry and durable replay rejection are proven without leakage. | Same two-process journey issues DPoP-bound tokens, retries on `DPoP-Nonce`, replays the accepted proof, and scans redacted command output/artifacts for sentinels. |
</phase_requirements>

## Summary

Build one maintainer-only acceptance laboratory under a new fixture root, not a third product example. It should create a temporary working directory, construct a local Lockspire package artifact, generate a minimal provider Phoenix/Ecto host from that artifact, apply an intentionally small host-owned patch set, create a separately booted confidential-client Phoenix app, and run a black-box journey against two loopback origins. The existing generated-host fixture is valuable reference material but cannot be the acceptance target because it compiles through the library test path and uses test-support modules. [VERIFIED: repository `mix.exs`, `test/support/generated_host_app_web/`, `133-CONTEXT.md`]

Use the generated install surface as the provider contract: `mix lockspire.install`, generated migrations, `mix ecto.migrate`, `mix lockspire.verify`, the imported router macro, generated account/interaction seams, and public `Lockspire.Clients` registration. Add only a host-owned protected API route/pipeline and a bootstrap command that registers the confidential client and publishes an active signing key. The provider must never import protocol/storage internals or replace the Lockspire router. [VERIFIED: repository `lib/mix/tasks/lockspire.install.ex`, `lib/mix/tasks/lockspire.verify.ex`, `priv/templates/lockspire.install/router.ex`, `docs/protect-phoenix-api-routes.md`]

The client fixture should be deliberately small: HTTP callback route, durable authorization-transaction store, OIDC verifier, session receipt, and test-only orchestration endpoints. It is not a reusable OAuth client library. Make protocol steps independently callable so failures identify authorization, callback, token, verification, resource server, lifecycle, or DPoP stages without retaining sensitive values in output. [VERIFIED: repository `133-CONTEXT.md`, `scripts/demo/adoption_smoke.py`, `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs`]

**Primary recommendation:** implement a dedicated `mix test.integration.clean_room` lane that supervises an ephemeral two-app fixture tree and drives its HTTP-only journey through a small redacting runner; keep provider setup public-surface-only and make every security assertion wire-visible.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Packaged embedded authorization server | Provider-host backend | Database/storage | The generated Phoenix host configures and mounts Lockspire; its Ecto repo persists protocol state. |
| Host account/login/consent/product policy | Provider-host backend | Browser redirects | The host keeps identity/session, consent branding, and tenant authorization ownership. |
| OAuth confidential client transaction | Client backend | Client database/storage | State, nonce, and verifier must remain server-side, durable, one-time, and unavailable to the browser. |
| Discovery/JWKS/ID-token/userinfo validation | Client backend | Provider HTTP endpoints | Client consumes advertised documents and validates returned protocol data before session completion. |
| Protected resource enforcement | Provider-host backend | Provider database/storage | The host route mounts Lockspire’s documented plugs and then performs host tenant policy. |
| Lifecycle operations | Provider HTTP endpoints | Provider database/storage | Token/revocation/introspection behavior is observable via OAuth endpoints and stored server lifecycle state. |
| DPoP nonce/replay | Provider-host backend | Provider database/storage | Resource plug supplies nonce/challenge and configured Ecto repo records accepted proof uniqueness. |
| Test orchestration/redaction | Test runner | Both process stdout/stderr | Runner allocates ports, waits for readiness, drives HTTP, scrubs evidence, and always stops processes. |

## Standard Stack

### Core

| Component | Existing version/contract | Purpose | Why use it |
|---|---|---|---|
| Phoenix + Bandit | Phoenix `~> 1.8.5`; Bandit `~> 1.11` | Independently boot provider and client listeners. | Already the library’s embedded host stack and avoids a test-only HTTP server. [VERIFIED: repository `mix.exs`] |
| Ecto SQL + Postgrex | Ecto SQL `~> 3.13.5` | Provider state and client transaction durability. | Existing installed persistence contract; provider replay protection already relies on its configured repo. [VERIFIED: repository `mix.exs`, `docs/protect-phoenix-api-routes.md`] |
| JOSE + Jason | JOSE `~> 1.11`; Jason `~> 1.4` | JWK/JWS ID-token and DPoP proof verification; JSON HTTP contracts. | Existing protocol implementation and tests use these libraries. [VERIFIED: repository `mix.exs`, `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs`] |
| Elixir `:httpc` or Req already transitive in fixture | OTP supplied HTTP client / existing `Req ~> 0.5` | Black-box HTTP requests from runner/client. | Do not add a client SDK or new dependency; use an ordinary HTTP client with explicit redirect/cookie handling. [VERIFIED: repository `mix.exs`, `scripts/demo/adoption_smoke.py`] |

### Supporting

| Component | Purpose | When to use |
|---|---|---|
| `mix hex.build` local artifact | Produces the installable package input. | Build once per clean-room test run; consume it locally, without asserting published Hex behavior. [VERIFIED: repository `mix.exs`, `133-CONTEXT.md`] |
| `mix lockspire.install` / `mix lockspire.verify` | Generates and verifies documented provider seams. | In the provider fixture setup command, before boot. [VERIFIED: repository `lib/mix/tasks/lockspire.install.ex`, `lib/mix/tasks/lockspire.verify.ex`] |
| Existing `Lockspire.Clients.register_client/1` public facade | Registers the bootstrap confidential client. | In a bounded host-owned bootstrap task; do not call repository/protocol internals. [VERIFIED: repository `priv/templates/lockspire.install/default_smoke_e2e_test.exs`, `docs/supported-surface.md`] |

**Installation:** No new external package is needed. The clean-room fixture consumes the locally built Lockspire artifact and only uses dependencies already required by its generated Phoenix host. [VERIFIED: repository `mix.exs`, `133-CONTEXT.md`]

## Package Legitimacy Audit

Not applicable: Phase 133 should install no new third-party package. Any generated fixture dependencies must be the existing Phoenix/Ecto/Lockspire set, resolved from the project’s existing dependency declarations. [VERIFIED: repository `mix.exs`, `133-CONTEXT.md`]

## Architecture Patterns

### System Architecture Diagram

```text
                         ephemeral bootstrap channel
             runner ───────────────────────────────────────┐
               │                                            │
               │ starts / health-checks                     ▼
               │                               ┌──────────────────────────┐
               ├── HTTP ──────────────────────►│ Provider Phoenix/Ecto host │
               │                               │ - installed Lockspire      │
               │                               │ - host login/consent       │
               │                               │ - protected SaaS API       │
               │                               │ - public bootstrap task    │
               │                               └────────────┬─────────────┘
               │                                            │ configured repo
               │                                            ▼
               │                                      PostgreSQL
               │                                            ▲
               │ browser redirect / callback                │ durable DPoP
               ▼                                            │ lifecycle state
┌──────────────────────────┐  discovery/JWKS/token/userinfo  │
│ Confidential-client app   │◄────────────────────────────────┘
│ - transaction store       │
│ - callback state gate     │──── protected API request ─────► provider API
│ - OIDC verifier           │
│ - session receipt         │◄──── OAuth errors/challenges ─── provider API
└──────────────────────────┘
```

### Recommended Fixture Structure

```text
test/clean_room/
├── runner/                         # orchestration, readiness, redaction, HTTP assertions
│   ├── clean_room_journey_test.exs
│   ├── process_supervisor.ex
│   ├── http_client.ex
│   └── redacted_evidence.ex
├── provider_template/              # minimal fresh Phoenix/Ecto host seed only
│   ├── mix.exs
│   ├── config/
│   └── lib/                        # host-owned login, bootstrap, protected API additions
└── confidential_client_template/
    ├── mix.exs
    ├── config/
    ├── lib/.../oauth_transaction.ex
    ├── lib/.../oidc_verifier.ex
    └── lib/.../controllers/oauth_callback_controller.ex
scripts/clean_room/
└── run_journey.exs                 # optional single command used by the integration test and CI
```

The fixture source is checked in, but every invocation copies it to a unique `tmp/` directory and mutates only that copy. It must use unique database names/schema prefixes and two allocated loopback ports; no fixture state survives a successful or failing run. [VERIFIED: repository `133-CONTEXT.md`; this is the required implementation shape, not a claim about existing code]

### Pattern 1: Package-clean generated provider

**What:** Build a local package artifact, create a fresh provider project, add the package through its public dependency declaration, run `mix deps.get`, execute `mix lockspire.install`, and apply only explicit host-owned source additions.

**When to use:** At the start of every full clean-room journey, never by borrowing the main test application or `test/support` modules.

**Implementation rules:**

- Use the installer to create config, router macro import/mount, resolver, interaction handler, consent view, and migrations.
- Add host-owned router code only for an ordinary login/session flow, operator pipeline required by generated route macro, the documented protected-resource pipeline, and the host API route.
- Prove the boundary with a static source audit that rejects `Lockspire.Protocol.`, `Lockspire.Storage.`, `test/support`, and a direct `forward` replacement for Lockspire’s public router in the generated provider source.
- Run `mix ecto.migrate`, `mix lockspire.verify`, provider compile/test, and boot as child-process steps; command failure must include only redacted output.

The package includes `lib/**/*.ex`, migrations, install templates, and docs, while excluding the library test repo and setup task. This supports an artifact/path installation boundary without asserting Hex publication. [VERIFIED: repository `mix.exs`] 

### Pattern 2: Server-side, one-time confidential-client transaction

**What:** On authorization start, insert one transaction record with a random opaque ID, independently random `state`, `nonce`, PKCE verifier, S256 challenge, expected issuer/client/redirect URI, creation/expiry, and `:pending` status. Browser state carries only the public `state` value.

**When to use:** Every code-flow attempt, including negative callback tests.

**Terminal callback algorithm:**

```elixir
# client-owned pseudocode; do not log `params`, `transaction`, code, verifier, or tokens
with {:ok, tx} <- Transactions.fetch_pending_by_state(params["state"]),
     :ok <- Transactions.consume(tx.id),
     :ok <- require_exact_state(params["state"], tx.state),
     {:ok, token_response} <- OAuth.exchange_code(tx, params["code"]),
     {:ok, id_claims} <- OidcVerifier.verify(token_response.id_token, tx),
     {:ok, userinfo} <- OAuth.userinfo(token_response.access_token),
     :ok <- require_same_subject(userinfo["sub"], id_claims["sub"]) do
  Sessions.complete(tx, id_claims, token_response)
else
  error -> Transactions.finish_failure(tx_id, error)
end
```

Consume/invalidate before the exchange attempt so state mismatch, a provider error, missing code, verification failure, and exchange failure cannot be retried with the original server-side transaction. Use a compare-and-set update (`pending -> consumed`) or transaction/unique constraint so two callbacks cannot both win. This is an implementation recommendation locked by D-05, not an existing-library behavior. [ASSUMED]

### Pattern 3: OIDC verification from discovery as data

**What:** Client fetches the provider’s advertised discovery document, reads `issuer`, `jwks_uri`, and supported ID-token signing algorithms, fetches JWKS, selects exactly the JWK with the JWT’s `kid`, and verifies the compact JWS before accepting claims.

**When to use:** Immediately after token exchange and before creating a client login session or calling the protected API.

**Required checks:** signature; `alg` is in discovery’s supported signing-algorithm set and is never `none`; selected key `kid` exists; `iss == discovery.issuer == stored expected issuer`; `aud` contains the confidential client id; `exp` is in the future with a bounded clock skew; nonce exactly equals the stored original nonce; and `userinfo.sub == id_token.sub`. Do not derive accepted issuer/JWKS URLs from an arbitrary callback parameter. The existing integration proof already uses strict JOSE verification, checks issuer/audience/nonce, and confirms userinfo subject. [VERIFIED: repository `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs`, `test/integration/phase6_onboarding_e2e_test.exs`, `133-CONTEXT.md`]

### Pattern 4: Wire-contract journey steps

Split the runner into named operations and assert stable values only:

1. prepare package + provider + client, run install/migrate/verify, boot listeners;
2. fetch discovery and JWKS;
3. start authorization via the client and follow host login/consent redirects;
4. callback state gate and token exchange;
5. OIDC/userinfo validation and protected API call;
6. refresh/lifecycle checks;
7. negative matrix;
8. DPoP nonce/retry/replay;
9. sentinel leakage scan and teardown.

Use response status, standardized OAuth JSON `error`, documented `WWW-Authenticate`, `DPoP-Nonce`, and safe semantic API JSON. Never assert provider records, `conn.assigns`, protocol result structs, or private reason codes from the runner. [VERIFIED: repository `133-CONTEXT.md`, `docs/protect-phoenix-api-routes.md`, `test/integration/phase81_generated_host_route_protection_e2e_test.exs`]

### Pattern 5: Durable DPoP proof as an HTTP behavior

The DPoP journey must request a DPoP-bound token for a client configured with DPoP policy, call the protected endpoint without a nonce (expect a `401` DPoP nonce challenge), generate a **new** proof with the returned nonce, receive success, then resubmit that exact accepted proof and expect rejection. Do not supply `dpop_replay_store:` in provider route configuration. The installed default resolves to the configured repository and records replay state there. [VERIFIED: repository `docs/protect-phoenix-api-routes.md`, `test/integration/phase81_generated_host_route_protection_e2e_test.exs`, `test/integration/protected_resource_dpop_default_store_test.exs`]

### Anti-Patterns to Avoid

- **Reusing `GeneratedHostAppWeb` or `Lockspire.TestRepo`:** proves a library test fixture, not a clean installed host.
- **`Phoenix.ConnTest` as the acceptance runner:** skips listeners, origin handling, redirects, cookies, and real client behavior.
- **Client transaction material in cookies, URL, or logs:** makes PKCE/state/nonce theft and replay easier and violates D-05/D-17.
- **A generic client abstraction:** expands Phase 133 into an SDK and hides required validation steps.
- **Inspecting provider database records to “prove” replay:** bypasses D-14; replay must be visible at HTTP boundary.
- **Claiming revoked self-contained JWTs are instantly offline-invalid:** only lifecycle endpoints see server state immediately; preserve expiry-bound JWT truth.

## Don’t Hand-Roll

| Problem | Don’t Build | Use Instead | Why |
|---|---|---|---|
| Provider protocol endpoints | A fixture copy of authorize/token/userinfo behavior | Installed Lockspire public router | The phase is acceptance proof of the embedded library, not a mock implementation. |
| Router/migration/config generation | Handwritten substitute provider wiring | `mix lockspire.install` + generated files | The generated implementation is the supported package boundary. |
| Protected-resource protocol verification | Custom JWT/scope/audience/DPoP plug | `VerifyToken -> EnforceSenderConstraints -> RequireToken` | It preserves Lockspire’s canonical failure semantics and configured durable DPoP default. |
| JWS crypto primitives | Custom JWT parser/signature checker | Existing JOSE verification using discovery/JWKS metadata | Key selection, algorithm restrictions, and claim validation are security-sensitive. |
| DPoP replay persistence | In-memory `MapSet`, ETS, or an injected fake store | Installed configured Ecto replay store | Cross-request/nodal replay semantics require the durable uniqueness boundary. |
| Browser automation | Playwright/Selenium | Explicit HTTP redirect/cookie client | The required journey is deterministic/headless and does not need rendered UI assertions. |

## Common Pitfalls

### Pitfall 1: “Clean room” that links back to the checkout

**What goes wrong:** The generated host compiles imports from `test/support`, uses the parent application’s loaded modules, or depends on the source checkout rather than a built artifact.

**How to avoid:** Start child Mix apps in copied temp directories; assert their `mix.exs` Lockspire dependency points at the generated local artifact/path; static-audit sources; run their compile/verify/boot processes independently. Package contents intentionally exclude `lib/lockspire/test_repo.ex` and test setup. [VERIFIED: repository `mix.exs`]

### Pitfall 2: Nonce/state validation after code exchange

**What goes wrong:** The client contacts `/token` before proving callback ownership or leaves a transaction usable after a mismatch/failure.

**How to avoid:** Lookup+consume pending transaction and compare state before any token request. Treat every terminal callback path as consumption; store the nonce for post-exchange ID-token validation. [ASSUMED]

### Pitfall 3: JWKS test that verifies only the first key

**What goes wrong:** Tests pass only because a fixture assumes order or a known signing key.

**How to avoid:** Parse JOSE header first, select JWK by exact `kid`, restrict `alg` to discovery metadata, and include an unknown-`kid`/wrong-algorithm negative unit test in the client verifier. Existing JWKS responses advertise `kid`, `alg`, and public key data. [VERIFIED: repository `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs`]

### Pitfall 4: Misstating resource-server revocation semantics

**What goes wrong:** A test expects a previously minted `at+jwt` to fail immediately at an offline host API after lifecycle revocation, creating a false product claim.

**How to avoid:** Assert inactive introspection and revoked refresh-family behavior; phrase the post-revocation JWT assertion as lifetime-bound and do not use it as instantaneous revocation proof. [VERIFIED: repository `133-CONTEXT.md`, `docs/protect-phoenix-api-routes.md`]

### Pitfall 5: Replaying a newly generated DPoP proof

**What goes wrong:** A test regenerates `jti`/`iat` and never proves replay detection.

**How to avoid:** Save the exact bytes of the proof that produced the successful protected-resource response, then resubmit those bytes unchanged. The current DPoP proof has `jti`, `htu`, `htm`, `ath`, and nonce-bearing claims. [VERIFIED: repository `test/integration/phase81_generated_host_route_protection_e2e_test.exs`]

### Pitfall 6: Security test failure leaks its test secret

**What goes wrong:** Assertion output prints response URLs, bodies, process logs, headers, or fixture configuration containing tokens, Basic credentials, verifier, DPoP key, or cookies.

**How to avoid:** Use distinctive sentinels for every secret category; centralize HTTP/process failure rendering through a redactor; retain only a redacted evidence file on failure; scan it for all sentinels and raw `Authorization`/cookie values. [VERIFIED: repository `133-CONTEXT.md`; implementation details are required design]

## Code Examples

### Provider protected API (host-owned, generated-provider addition)

```elixir
# Source: docs/protect-phoenix-api-routes.md
pipeline :lockspire_protected_api do
  plug Lockspire.Plug.VerifyToken,
    scopes: ["read:billing"],
    audience: "https://api.clean-room.test/billing",
    enforce_audience: true

  plug Lockspire.Plug.EnforceSenderConstraints
  plug Lockspire.Plug.RequireToken
end

scope "/api", CleanRoomProviderWeb do
  pipe_through [:api, :lockspire_protected_api]
  get "/billing/summary", BillingController, :show
end
```

The controller uses `Lockspire.AccessToken.subject/1`, `scopes/1`, `audiences/1`, `expires_at/1`, and `confirmation/1`, then applies its own fixed illustrative tenant decision. It returns those semantic fields only; it never exposes raw claims or token strings. [VERIFIED: repository `docs/protect-phoenix-api-routes.md`, `test/support/generated_host_app_web/controllers/protected_api_controller.ex`]

### DPoP nonce/retry/replay wire proof

```elixir
# runner pseudocode: all values remain in-memory and redacted from failures
first = get(api_url, dpop_headers(access_token, proof_without_nonce))
assert first.status == 401
assert "use_dpop_nonce" in www_authenticate(first)
nonce = header!(first, "dpop-nonce")

accepted_proof = dpop_proof(method: "GET", htu: api_url, ath: access_token, nonce: nonce)
success = get(api_url, dpop_headers(access_token, accepted_proof))
assert success.status == 200

replay = get(api_url, dpop_headers(access_token, accepted_proof))
assert replay.status == 401
assert "invalid_token" in www_authenticate(replay)
```

The documented server behavior supplies `DPoP-Nonce` and exposes it for browser clients; replay persistence is the default configured Ecto store when no override is supplied. [VERIFIED: repository `docs/protect-phoenix-api-routes.md`, `test/integration/phase81_generated_host_route_protection_e2e_test.exs`]

## Dependency and Ordering Constraints

1. **Harness foundation first:** establish temporary workspace, process supervisor, redacted command/HTTP capture, port allocation, package build, readiness probes, and teardown before asserting protocol behavior.
2. **Provider installation before client:** package build → fresh provider dependency setup → installer → host-owned patch → migrations → `lockspire.verify` → provider bootstrap/signing key → listener ready.
3. **Client persistence/verifier before happy journey:** callback transaction storage and OIDC verifier need focused tests before the external redirect flow uses them.
4. **Bearer happy path before lifecycle:** prove discovery/PKCE/ID-token/userinfo/protected API as one baseline before using its confidential-client credentials in refresh/introspection/revocation tests.
5. **Negative cases after baseline:** share only setup helpers, never reuse authorization codes/proofs across cases except the explicit code-reuse and DPoP-replay cases.
6. **DPoP last:** it depends on working package install, client registration, token issuance, protected API pipeline, configured provider repo, and redacted evidence handling.
7. **No Phase 137 artifact assertions:** local package consumption is required now; checksum, immutable public-version installation, and release manifests remain deferred.

## Explicit Requirement Answers

| Requirement | Concrete proof | Required negative proof | Completion boundary |
|---|---|---|---|
| E2E-01 | Fresh provider created from local artifact runs installer, migration, `lockspire.verify`, focused generated smoke, and live HTTP readiness. | Source audit rejects forbidden internal/test-support imports and route replacement. | Public installer/generated/verification surface only. |
| E2E-02 | Client transaction record holds distinct random state/nonce/verifier; auth callback completes code exchange with S256. | Wrong callback state returns a safe failure and transaction cannot later be used. | No tokens before state check; transaction terminally consumed. |
| E2E-03 | Discovery+JWKS HTTP fetch; `kid` key selection; configured-alg signature and `iss`/`aud`/`exp`/nonce checks; matching userinfo `sub`; protected API 200 semantic response. | Wrong nonce, missing/unknown `kid`, signature/issuer/audience mismatch, or userinfo-sub mismatch block session/API use. | No private Lockspire calls/struct inspection from client runner. |
| E2E-04 | One refresh yields replacement; old refresh reuse returns `invalid_grant` and makes family inactive; authenticated introspection/revocation demonstrate state and revocation idempotence. | Old refresh replay produces reuse error; introspection after family revocation is inactive. | No assertion that already issued JWT instantly fails at offline RS. |
| E2E-05 | Redirect drift, code reuse, state mismatch, nonce mismatch, missing token, wrong audience, and insufficient scope each hit actual listener and compare public outcomes. | Each case checks status plus OAuth error/challenge where documented. | No internal reason codes/repository queries. |
| E2E-06 | DPoP-bound token follows missing-nonce challenge → fresh nonce proof success → identical-byte proof replay rejection. | Missing/invalid nonce and exact replay return documented DPoP failure. | No fake replay store; retained logs/artifacts redacted and sentinel-scanned. |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---:|---|---|
| Elixir/Mix | build, generated apps, test lane | Verify in Wave 0 | — | none |
| PostgreSQL | two-app Ecto persistence and configured DPoP store | Verify in Wave 0 | — | no in-memory fallback; durable replay is required |
| `mix hex.build` | local package artifact | Verify in Wave 0 | — | dependency path only if it still consumes package-clean public surface; do not bypass installer |
| loopback TCP ports | separately booted origins | Verify in Wave 0 | — | deterministic dynamic port allocator |

**Missing dependencies with no fallback:** PostgreSQL availability is a blocker because the requirement explicitly demands configured Ecto durable replay behavior. [VERIFIED: repository `133-CONTEXT.md`, `docs/protect-phoenix-api-routes.md`]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit, tagged `:integration` |
| Existing commands | `mix test.integration`, `mix test.fast`, `mix qa`, `mix docs.verify` |
| Phase-focused command | Add `mix test.clean-room.e2e` or equivalently `mix test --include integration test/clean_room/...` |
| Full suite | `mix test.integration` |

Existing integration tests already cover narrower in-process provider behavior, generated-host routing, lifecycle, DPoP nonce retry, and configured-repo replay. Phase 133 must add the independently booted, package-clean composition proof rather than duplicate those tests verbatim. [VERIFIED: repository `mix.exs`, `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs`, `test/integration/phase81_generated_host_route_protection_e2e_test.exs`, `test/integration/protected_resource_dpop_default_store_test.exs`]

### Phase Requirements → Test Map

| Req ID | Behavior | Test type | Automated command | File exists? |
|---|---|---|---|---|
| E2E-01 | Package install, generated host migration/verify/boot, boundary audit | process integration | `mix test.clean-room.e2e --only package_clean` | ❌ Wave 0 |
| E2E-02 | Distinct persisted state/nonce/verifier; callback consumption | client unit + process integration | `mix test.clean-room.e2e --only callback` | ❌ Wave 0 |
| E2E-03 | Discovery/JWKS/ID token/userinfo/API | verifier unit + process integration | `mix test.clean-room.e2e --only oidc` | ❌ Wave 0 |
| E2E-04 | Refresh rotation/reuse/introspection/revocation | process integration | `mix test.clean-room.e2e --only lifecycle` | ❌ Wave 0 |
| E2E-05 | Wire negative matrix | process integration | `mix test.clean-room.e2e --only negative` | ❌ Wave 0 |
| E2E-06 | DPoP nonce/retry/exact replay/redaction | process integration + evidence scan | `mix test.clean-room.e2e --only dpop` | ❌ Wave 0 |

### Sampling Rate

- **Per fixture/code task commit:** compile or focused ExUnit case for changed harness component.
- **Per journey wave:** focused clean-room command with a fresh temp workspace.
- **Phase gate:** `mix compile --warnings-as-errors`, `mix test.fast`, `mix test.integration`, `mix qa`, and `mix docs.verify`, with clean-room E2E included in integration or explicitly invoked by its maintained alias.

### Wave 0 Gaps

- [ ] `test/clean_room/runner/` — process lifecycle, bounded readiness, port/database allocation, redacted evidence, cleanup.
- [ ] `test/clean_room/provider_template/` — new minimal non-test-support Phoenix/Ecto host seed.
- [ ] `test/clean_room/confidential_client_template/` — durable transaction store, OIDC verifier, callback/session endpoints.
- [ ] `test/clean_room/clean_room_journey_test.exs` — requirement-labelled HTTP journey and negative matrix.
- [ ] Mix alias / CI entry for focused, discoverable execution.
- [ ] Environment probe that fails with actionable message when PostgreSQL, package builder, or ports are unavailable.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | Yes | Authorization-code S256 PKCE; confidential `client_secret_basic`; ID-token signature/issuer/audience/nonce validation. |
| V3 Session Management | Yes | Server-side transaction storage, callback state equality, one-time terminal consumption, secure client session handling. |
| V4 Access Control | Yes | Exact audience/scope plug restriction plus host-owned tenant/product decision. |
| V5 Input Validation | Yes | Redirect exactness, callback parameter validation, discovery-derived allowlist, DPoP `htu`/`htm`/nonce/replay checks. |
| V6 Cryptography | Yes | Existing JOSE, S256 SHA-256 PKCE, existing Lockspire signing and DPoP validation; no custom cryptography. |
| V7 Error Handling/Logging | Yes | Stable wire-only failure checks and sentinel-driven redaction of command, HTTP, and artifact evidence. |

### Known Threat Patterns

| Pattern | STRIDE | Required mitigation |
|---|---|---|
| Authorization response mix-up / callback CSRF | Spoofing/Tampering | Independent random server-side state; exact callback comparison before exchange; one-time transaction consumption. |
| ID-token substitution | Spoofing | Discovery-bound issuer/JWKS, `kid` selection, algorithm allowlist, signature/aud/exp/nonce validation. |
| Redirect URI drift | Tampering | Real `/authorize` request demonstrates registered exact URI restriction. |
| Code or refresh replay | Elevation of privilege | Single-use authorization codes; refresh rotation and old-token reuse family revocation asserted over HTTP. |
| Audience/scope confusion | Elevation of privilege | Canonical resource plugs and separate host authorization decision; wrong audience/under-scope tests. |
| DPoP proof replay | Replay/Elevation | Resource nonce challenge plus configured Ecto durable replay store and same-byte proof rejection. |
| Sensitive diagnostic retention | Information disclosure | Central redactor, sentinel scans, no raw response/header/process dump, ephemeral working tree cleanup. |

The repository’s supported contract documents S256 PKCE, exact redirect validation, the canonical protected-route plug order, scope/audience failure semantics, DPoP nonce behavior, and configured-repository durable replay default. [VERIFIED: repository `AGENTS.md`, `docs/protect-phoenix-api-routes.md`, `docs/supported-surface.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | A dedicated client-side Ecto transaction table is the best durable implementation rather than a small file-backed transactional store. | Pattern 2 | Low-medium: the locked requirement is durability/concurrency/restart safety, not Ecto specifically; planner may choose another implementation only if it proves those properties. |
| A2 | A local package artifact can be wired into a temporary fixture through a Mix-supported local dependency form without new package tooling. | Pattern 1 | Medium: implementation must validate the exact supported Mix/Hex shape in Wave 0; Phase 137 owns immutable tarball checks. |

## Open Questions

1. **How should the local package artifact be referenced by a fresh Mix fixture?**
   - What we know: `mix hex.build` is a maintained alias and package contents support the install boundary. [VERIFIED: repository `mix.exs`]
   - What is unclear: whether the harness should use an unpacked local Hex archive/repository or a path dependency while still satisfying D-03’s package-clean condition.
   - Recommendation: make this the first Wave 0 spike; prefer a local built archive/repository if straightforward, otherwise a copied package-only source tree/path dependency with an explicit package-content audit. Do not use the live checkout directly.

2. **What existing CI PostgreSQL service/credentials can child Mix projects reuse safely?**
   - What we know: current integration tests rely on `Lockspire.TestRepo`, but Phase 133 must not. [VERIFIED: repository `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs`]
   - What is unclear: available database provisioning contract for child applications.
   - Recommendation: add a bounded environment probe and dynamic database names; avoid shared schemas and never fall back to in-memory replay state.

3. **Should the fixture client use Ecto?**
   - What we know: D-05 requires durable, concurrent, restart-safe transactions; the choice is discretionary.
   - Recommendation: use its own small Ecto schema/table if it does not materially increase fixture boot time; otherwise a host-owned durable transactional store with equivalent one-time semantics must have explicit tests.

## Sources

### Primary (HIGH confidence)

- [AGENTS.md](/Users/jon/projects/lockspire/AGENTS.md) — embedded-library boundary and security defaults.
- [Phase 133 context](/Users/jon/projects/lockspire/.planning/phases/133-clean-room-saas-journey/133-CONTEXT.md) — locked scope, acceptance contract, and exclusions.
- [Installer](/Users/jon/projects/lockspire/lib/mix/tasks/lockspire.install.ex) and [verifier](/Users/jon/projects/lockspire/lib/mix/tasks/lockspire.verify.ex) — public installation/verification commands.
- [Generated router template](/Users/jon/projects/lockspire/priv/templates/lockspire.install/router.ex) — documented embedding/router ownership boundary.
- [Protected API guide](/Users/jon/projects/lockspire/docs/protect-phoenix-api-routes.md) — canonical plug order and wire errors.
- [Supported surface](/Users/jon/projects/lockspire/docs/supported-surface.md) — supported behavior and explicit non-goals.
- [OIDC lifecycle integration test](/Users/jon/projects/lockspire/test/integration/phase3_oidc_token_lifecycle_e2e_test.exs), [generated-host route integration test](/Users/jon/projects/lockspire/test/integration/phase81_generated_host_route_protection_e2e_test.exs), and [durable DPoP test](/Users/jon/projects/lockspire/test/integration/protected_resource_dpop_default_store_test.exs) — existing narrow proof seams.
- [Adoption smoke](/Users/jon/projects/lockspire/scripts/demo/adoption_smoke.py) — reusable headless redirect/cookie sequencing, with known same-origin/public-client limitation.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — all components and versions originate from the checked-in Mix project.
- Architecture: HIGH — directly constrained by Phase 133’s locked decisions and current public install/resource-server contracts.
- Pitfalls: HIGH for repository-proven protocol behavior; MEDIUM for exact temporary artifact/database orchestration pending Wave 0 implementation probe.

**Research date:** 2026-08-27  
**Valid until:** 2026-09-26, unless the package-install surface or integration test infrastructure changes.
