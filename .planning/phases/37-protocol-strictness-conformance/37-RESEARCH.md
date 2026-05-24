# Phase 37: Protocol Strictness & Conformance - Research

**Researched:** 2026-04-28 [VERIFIED: system date]  
**Domain:** Embedded OpenID Connect provider strictness, silent-auth behavior, durable freshness truth, and automated OP conformance proof [VERIFIED: .planning/ROADMAP.md]  
**Confidence:** HIGH [VERIFIED: codebase grep][CITED: https://openid.net/specs/openid-connect-core-1_0-31.html][CITED: https://openid.net/certification/about-conformance-suite/]

<user_constraints>
## User Constraints (from CONTEXT.md) [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]

### Locked Decisions [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]

- **D-01:** Lockspire should implement **strict non-interactive `prompt=none` semantics**. When `prompt=none` is present, Lockspire must never redirect into host login, Lockspire consent, or any other UI-producing step. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- **D-02:** `prompt=none` should be treated as a **hard gate**, not a soft preference. If the request cannot complete silently, Lockspire should return an OIDC error rather than falling back to interactive host behavior. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- **D-03:** Lockspire should reject `prompt=none` combined with any other prompt value as `invalid_request`. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- **D-04:** Silent failure taxonomy is locked:
  - `login_required` when no usable authenticated browser session exists, or when freshness rules such as `max_age` require re-authentication. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
  - `consent_required` when the user is authenticated but the exact request still requires consent. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
  - `interaction_required` for other policy or UX blockers that would require UI (account chooser, tenant selection, legal interstitial, step-up requirement, upstream hop). [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- **D-05:** Silent success should only occur when authentication, freshness, consent, and product policy are all satisfiable without UI and with truthful durable state. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- **D-06:** The host seam for silent checks should be **read-only and decision-oriented**: Lockspire may inspect current browser-session/account state through the host seam, but must not broaden that seam into redirect orchestration or Lockspire-owned session control. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- **D-07:** Lockspire should introduce **durable protocol-owned `auth_time` truth** rather than deriving freshness from generic Phoenix session state, page hits, consent timestamps, or request time. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- **D-08:** `auth_time` should represent the last time the host performed a **fresh end-user authentication event** acknowledged by Lockspire, not the last time an existing host session was reused. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- **D-09:** Only an explicit fresh-auth event should advance `auth_time`. Consent reuse, consent approval, authorization code issuance, token exchange, refresh, and silent session reuse must not mutate it. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- **D-10:** `max_age` evaluation must use that durable `auth_time` as its sole freshness source. This keeps behavior truthful across redirects, retries, node restarts, and conformance tests. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- **D-11:** ID tokens should include `auth_time` when required by OIDC behavior: `max_age` requests and explicit essential-claim demand. Do not make always-on `auth_time` emission the default in this phase. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- **D-12:** The host seam should carry explicit freshness data rather than forcing inference. Downstream planning should prefer a narrow contract equivalent to “fresh auth occurred at time T” over implicit session heuristics. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- **D-13:** Phase 37 should use a **repo-native conformance harness** as the center of gravity, not a maintainer-memory workflow and not an every-PR full hosted-suite dependency. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- **D-14:** The harness should encode Lockspire's real embedded assumptions in checked-in code: generated host app, deterministic login behavior, exact redirect URIs, durable Postgres truth, fixed client fixtures, and reproducible result capture. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- **D-15:** Conformance should run in **two lanes**:
  - a primary checked-in harness lane for local/CI use and repeatable regression proof [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
  - a maintainer-triggered or scheduled hosted/staging OIDF lane for fuller certification-grade evidence [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- **D-16:** Do not make the full hosted browser-driven OIDF suite a required path on every PR. That would add too much flake, public-reachability coupling, and contributor friction for an embedded Phoenix library. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- **D-17:** Lockspire's public support posture must stay truthful: repeated conformance evidence can justify stronger protocol claims, but Phase 37 should not automatically broaden marketing to “broad certification coverage” unless the repo can keep proving it. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- **D-18:** The conformance host app used by the harness should be intentionally boring and narrow. It exists to prove Lockspire's protocol seams, not to test arbitrary host UX variation. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- **D-19:** Favor explicit, narrowly named seams over “magic inference” for both silent auth and freshness. This is the least surprising model for Phoenix teams embedding a provider into an existing app. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- **D-20:** Error behavior should be deterministic and standards-shaped, with public behavior that SDKs and RP implementers can rely on without Lockspire-specific folklore. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- **D-21:** Conformance tooling should optimize for maintainable DX: one obvious script/task path, clear fixture setup, saved artifacts, and strong docs about browser-cookie limitations and hosted-suite prerequisites. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]

### Claude's Discretion [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]

- Exact schema shape for durable freshness state may be chosen during planning so long as `auth_time` remains protocol-owned, durable, and not derived from ambient session churn. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- Exact module/file boundaries for silent-session inspection, freshness checks, and conformance helpers may be chosen during planning as long as Plug/Phoenix adapters stay thin. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- Exact conformance-plan scope may start with the most relevant OP cases for `prompt=none`, `max_age`, `auth_time`, and strict authorization validation before broadening further. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- Future GSD work should default to assumption-first, research-backed recommendations and only escalate to the user on genuinely high-impact product choices or when evidence is insufficient. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]

### Deferred Ideas (OUT OF SCOPE) [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]

- Broad public certification-mark usage or “broad conformance coverage” positioning beyond what the repo can repeatedly prove [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- Full hosted OIDF conformance execution on every PR [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- Solving browser third-party-cookie limitations from inside Lockspire itself [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- Broader session/logout product work beyond what is already scoped into Phases 38 and 39 [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- Generalized host protected-resource or CIAM-scope expansion unrelated to Phase 37 [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
</user_constraints>

<phase_requirements>
## Phase Requirements [VERIFIED: .planning/REQUIREMENTS.md]

| ID | Description | Research Support |
|----|-------------|------------------|
| CONF-01 | Implement strict numeric type enforcement (integer vs string) for token timestamps (`iat`, `exp`, `auth_time`). [VERIFIED: .planning/REQUIREMENTS.md] | Reuse the repo’s existing strict integer guards in `Protocol.DPoP` and `Protocol.Jar`, then extend the same no-coercion rule to all Phase 37 token-facing timestamp claims. [VERIFIED: lib/lockspire/protocol/dpop.ex][VERIFIED: lib/lockspire/protocol/jar.ex] |
| CONF-02 | Enforce exact `redirect_uri` matching for authorization requests per OIDC specifications. [VERIFIED: .planning/REQUIREMENTS.md] | Current `AuthorizationRequest.validate_redirect_uri/2` already performs membership-based exact matching; planning should preserve this path and add conformance regression proof instead of replacing it. [VERIFIED: lib/lockspire/protocol/authorization_request.ex][CITED: https://openid.net/specs/openid-connect-core-1_0-31.html] |
| CONF-03 | Enforce strict validation of `prompt=none`, `max_age`, and `nonce` parameters. [VERIFIED: .planning/REQUIREMENTS.md] | OIDC Core requires non-interactive `prompt=none` handling, exact silent error taxonomy, durable `auth_time` for `max_age`, and nonce pass-through into ID tokens. [CITED: https://openid.net/specs/openid-connect-core-1_0-31.html][VERIFIED: lib/lockspire/protocol/authorization_request.ex][VERIFIED: lib/lockspire/protocol/authorization_flow.ex][VERIFIED: lib/lockspire/protocol/id_token.ex] |
| CONF-04 | Setup verifiable automated integration with the OIDF Conformance Test Suite. [VERIFIED: .planning/REQUIREMENTS.md] | The OIDF suite officially supports local Docker installation and a CI-oriented Python runner; the current wiki also provides a prebuilt-image quick-start path that avoids local Java. [CITED: https://openid.net/certification/about-conformance-suite/][CITED: https://gitlab.com/openid/conformance-suite/-/wikis/Developers/Build-%26-Run][VERIFIED: GitLab API] |
</phase_requirements>

## Project Constraints [VERIFIED: AGENTS.md]

- Lockspire must remain a separate embedded Phoenix/Elixir companion library rather than a standalone auth service. [VERIFIED: AGENTS.md]
- Host apps keep ownership of accounts, login UX, branding, layouts, and product policy; Phase 37 must not broaden Lockspire into host session ownership. [VERIFIED: AGENTS.md]
- Strong boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces are mandatory. [VERIFIED: AGENTS.md]
- Security defaults that must remain true in this phase include PKCE S256 by default, exact redirect matching, no implicit flow, no `alg=none`, short-lived single-use authorization codes, hashed client secrets, and refresh rotation. [VERIFIED: AGENTS.md]

## Summary

Phase 37 is a protocol-correctness phase, not a new product-surface phase. The repo already has two important foundations: `AuthorizationRequest` performs exact `redirect_uri` membership checks and `nonce`-on-`openid` validation, while `DPoP` and `JAR` already reject non-integer timestamp claims instead of coercing them. The gaps are elsewhere: `prompt=none` is currently treated as unsupported, `AuthorizationFlow` only distinguishes interactive login/consent states, `IdToken` has no `auth_time` support, and `Host.Claims` does not currently reserve `auth_time` from host override. [VERIFIED: lib/lockspire/protocol/authorization_request.ex][VERIFIED: lib/lockspire/protocol/authorization_flow.ex][VERIFIED: lib/lockspire/protocol/id_token.ex][VERIFIED: lib/lockspire/host/claims.ex][VERIFIED: lib/lockspire/protocol/dpop.ex][VERIFIED: lib/lockspire/protocol/jar.ex]

The OIDC Core rules are unambiguous for the behaviors this phase cares about: `prompt=none` must not produce UI, mixed `none` plus another prompt value is an error, `max_age` measures time since the user was actively authenticated, `max_age` requires `auth_time` in the returned ID token, `redirect_uri` matching is exact simple string comparison, and `nonce` should be passed through unmodified and returned in the ID token when supplied. [CITED: https://openid.net/specs/openid-connect-core-1_0-31.html]

For conformance proof, the current OpenID Foundation guidance supports both a local Docker-installed suite and an automation-oriented Python runner, and the current 2026 wiki adds a prebuilt-image quick-start path that does not require building Java locally. That matches the locked two-lane strategy: a checked-in repo-native lane for repeatable regressions, plus a maintainer-triggered hosted/staging lane for stronger certification-grade evidence. [CITED: https://openid.net/certification/about-conformance-suite/][CITED: https://gitlab.com/openid/conformance-suite/-/wikis/Developers/Build-%26-Run][VERIFIED: https://gitlab.com/api/v4/projects/4175605/releases/permalink/latest]

**Primary recommendation:** Plan Phase 37 as four coordinated slices: strict request parsing, silent-auth decisioning, durable `auth_time` propagation, and a Docker-first OIDF conformance harness with optional hosted follow-up. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md][CITED: https://openid.net/specs/openid-connect-core-1_0-31.html][CITED: https://openid.net/certification/about-conformance-suite/]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `redirect_uri`, `prompt`, `max_age`, and `nonce` request validation | API / Backend | Frontend Server (SSR) | The existing validation entry point is `Lockspire.Protocol.AuthorizationRequest`, and Phoenix controllers already behave as thin delivery adapters over protocol results. [VERIFIED: lib/lockspire/protocol/authorization_request.ex][VERIFIED: lib/lockspire/web/controllers/authorize_controller.ex] |
| Silent `prompt=none` completion vs OIDC error taxonomy | API / Backend | Frontend Server (SSR) | The decision is protocol policy, not host-page orchestration; the current state machine already lives in `AuthorizationFlow`. [VERIFIED: lib/lockspire/protocol/authorization_flow.ex][VERIFIED: AGENTS.md] |
| Truthful `auth_time` freshness state | Database / Storage | API / Backend | The repo already persists interaction lifecycle timestamps in Ecto/Postgres, and the phase decisions require durable protocol-owned freshness truth rather than ambient session inference. [VERIFIED: lib/lockspire/domain/interaction.ex][VERIFIED: lib/lockspire/storage/ecto/interaction_record.ex][VERIFIED: AGENTS.md][VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md] |
| ID token `auth_time` / `nonce` claim emission | API / Backend | Database / Storage | Claim shaping is done in `IdToken` and `Host.Claims`, but truthful values must come from durable protocol state. [VERIFIED: lib/lockspire/protocol/id_token.ex][VERIFIED: lib/lockspire/host/claims.ex] |
| OIDF conformance execution | API / Backend | Browser / Client | The suite primarily exercises Lockspire’s runtime endpoints, but selected OP tests also require browser interaction and cookie-visible login behavior. [CITED: https://openid.net/certification/connect_op_testing/][CITED: https://gitlab.com/openid/conformance-suite/-/wikis/Developers/Build-%26-Run] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | `1.8.5` [VERIFIED: mix.exs] | Host-facing web adapters, controllers, and generated conformance host seams. [VERIFIED: mix.exs] | Already the repo’s locked runtime and the right layer for thin delivery adapters only. [VERIFIED: AGENTS.md][VERIFIED: mix.exs] |
| Ecto SQL | `3.13.5` [VERIFIED: mix.exs][VERIFIED: mix.lock] | Durable interaction and token truth, including any `auth_time`-related schema changes. [VERIFIED: mix.exs][VERIFIED: mix.lock] | Phase 37 decisions explicitly prefer durable protocol truth over request-time inference. [VERIFIED: AGENTS.md][VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md] |
| Postgrex / PostgreSQL | `0.22.0` / `14+` [VERIFIED: mix.lock][VERIFIED: AGENTS.md] | Persistence for interaction and token lifecycle state used by silent auth and freshness. [VERIFIED: mix.lock][VERIFIED: AGENTS.md] | Existing default durable path; no phase value in changing the datastore. [VERIFIED: AGENTS.md] |
| JOSE | `1.11.12` [VERIFIED: mix.lock] | Strict JWT/JWS claim typing, ID token signing, DPoP proof validation, and request-object verification. [VERIFIED: mix.lock][VERIFIED: lib/lockspire/protocol/dpop.ex][VERIFIED: lib/lockspire/protocol/jar.ex][VERIFIED: lib/lockspire/protocol/id_token.ex] | The repo already uses JOSE everywhere protocol-sensitive; do not introduce a second JWT stack. [VERIFIED: mix.lock][VERIFIED: codebase grep] |
| OIDF Conformance Suite | `release-v5.1.43` released `2026-04-28` [VERIFIED: https://gitlab.com/api/v4/projects/4175605/releases/permalink/latest] | Official OpenID Provider conformance execution and evidence capture. [CITED: https://openid.net/certification/about-conformance-suite/] | It is the authoritative interoperability referee; custom ExUnit coverage is necessary but not sufficient for CONF-04. [CITED: https://openid.net/certification/about-conformance-suite/] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Prebuilt Docker stack for OIDF suite | `latest` by default, pin via `IMAGE_TAG` [CITED: https://gitlab.com/openid/conformance-suite/-/wikis/Developers/Build-%26-Run][VERIFIED: https://gitlab.com/openid/conformance-suite/-/raw/master/docker-compose-prebuilt.yml] | Fast local suite startup without a local Java build. [CITED: https://gitlab.com/openid/conformance-suite/-/wikis/Developers/Build-%26-Run] | Use for the repo-native lane and any contributor setup that should avoid Java/Maven friction. [CITED: https://gitlab.com/openid/conformance-suite/-/wikis/Developers/Build-%26-Run] |
| Python runner `run-test-plan.py` | current `master` script; depends on `httpx` and `pyparsing` [VERIFIED: https://gitlab.com/openid/conformance-suite/-/raw/master/scripts/run-test-plan.py][VERIFIED: https://gitlab.com/openid/conformance-suite/-/raw/master/scripts/requirements.txt] | Automates plan creation, module execution, retries, and HTML export for CI-like execution. [VERIFIED: https://gitlab.com/openid/conformance-suite/-/raw/master/scripts/run-test-plan.py] | Use in the maintainer or scheduled lane once the generated host app can be stood up with deterministic config. [VERIFIED: https://gitlab.com/openid/conformance-suite/-/raw/master/scripts/run-test-plan.py] |
| Existing Mix aliases `test.fast`, `test.integration`, `test.phase3` | current repo aliases [VERIFIED: mix.exs] | Fast/unit, broader integration, and focused OIDC protocol proof. [VERIFIED: mix.exs] | Extend this pattern with a dedicated conformance alias or script instead of inventing a parallel test entrypoint style. [VERIFIED: mix.exs][VERIFIED: .github/workflows/ci.yml] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Repo-native OIDF harness | Hosted suite only | Faster initial setup, but it conflicts with the locked requirement for repeatable local/CI proof and adds external reachability and flake to every regression run. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md][CITED: https://openid.net/certification/about-conformance-suite/] |
| JOSE + current protocol modules | A new validation wrapper library | Would duplicate already-shipped strict claim validation paths for DPoP and JAR and widen the protocol core unnecessarily. [VERIFIED: lib/lockspire/protocol/dpop.ex][VERIFIED: lib/lockspire/protocol/jar.ex] |
| Durable protocol-owned `auth_time` | Deriving freshness from the host web session | Simpler to start, but it directly violates the locked decisions and fails conformance-grade truthfulness across retries and resumed flows. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md][CITED: https://openid.net/specs/openid-connect-core-1_0-31.html] |

**Installation:** [CITED: https://gitlab.com/openid/conformance-suite/-/wikis/Developers/Build-%26-Run][VERIFIED: https://gitlab.com/openid/conformance-suite/-/raw/master/scripts/requirements.txt]
```bash
# Repo/runtime deps already come from mix.lock
mix deps.get

# OIDF suite local quick start
curl -O https://gitlab.com/openid/conformance-suite/-/raw/master/docker-compose-prebuilt.yml
IMAGE_TAG=release-v5.1.43 docker compose -f docker-compose-prebuilt.yml up -d

# OIDF automation helper deps
python3 -m pip install httpx pyparsing
```

**Version verification:** Use repo-pinned Elixir dependencies from `mix.exs` / `mix.lock`, and pin the conformance suite with `IMAGE_TAG=release-v5.1.43` for reproducible Phase 37 runs. [VERIFIED: mix.exs][VERIFIED: mix.lock][VERIFIED: https://gitlab.com/api/v4/projects/4175605/releases/permalink/latest]

## Architecture Patterns

### System Architecture Diagram

The primary Phase 37 data flow should stay inside protocol-core seams, with Phoenix remaining a thin shell and durable freshness truth feeding token issuance. [VERIFIED: AGENTS.md][VERIFIED: lib/lockspire/protocol/authorization_request.ex][VERIFIED: lib/lockspire/protocol/authorization_flow.ex]

```text
/authorize request
  -> AuthorizationRequest.validate
     -> exact redirect_uri check
     -> prompt/max_age/nonce parse
     -> request-object merge (if present)
  -> AuthorizationFlow.start_authorization
     -> read-only host account/session inspection
     -> silent gate?
        -> yes, all conditions satisfied -> reuse/issue code
        -> no, prompt=none -> OIDC redirect error
        -> no, interactive allowed -> pending_login / pending_consent
  -> durable Interaction / auth_time state
  -> authorization code issuance
  -> /token exchange
     -> existing strict DPoP/JWT integer validation
     -> load protocol-owned freshness truth
     -> IdToken.sign emits nonce/auth_time when required

Repo-native conformance lane
  -> generated host fixture
  -> OIDF suite (Docker)
  -> saved HTML/log artifacts

Hosted/staging lane
  -> same fixture shape + public/staging reachability
  -> OIDF hosted/staging run
  -> release-grade evidence
```

### Recommended Project Structure

```text
lib/lockspire/protocol/          # strict authorize parsing, silent-flow decisions, ID token claims
lib/lockspire/domain/            # durable interaction/auth freshness domain state
lib/lockspire/storage/ecto/      # migration + record changes for protocol-owned freshness truth
test/lockspire/protocol/         # parser, error taxonomy, and token-claim unit/integration coverage
test/lockspire/web/              # redirect-safe/browser-safe authorize and token endpoint behavior
test/integration/                # generated-host and end-to-end OIDC flow proof
scripts/conformance/             # suite bootstrap, plan config, result export helpers
```
[VERIFIED: existing lib/test layout][VERIFIED: codebase grep]

### Pattern 1: Validate Strictly Before Any Host Handoff

**What:** Keep `redirect_uri`, `prompt`, `max_age`, `nonce`, PKCE, and request-object projection inside `AuthorizationRequest` before any host login or consent seam is touched. [VERIFIED: lib/lockspire/protocol/authorization_request.ex][CITED: https://openid.net/specs/openid-connect-core-1_0-31.html]

**When to use:** Every `/authorize` path, including PAR/JAR-fed requests, because the public error shape depends on whether the request is browser-safe or redirect-safe. [VERIFIED: lib/lockspire/protocol/authorization_request.ex][VERIFIED: lib/lockspire/protocol/request_object.ex]

**Example:**
```elixir
# Source: lib/lockspire/protocol/dpop.ex [VERIFIED: codebase grep]
defp check_iat(%{"iat" => iat}, now, max_age, clock_skew) when is_integer(iat) do
  now_unix = DateTime.to_unix(now)

  cond do
    iat > now_unix + clock_skew -> {:error, :future_iat}
    iat < now_unix - max_age -> {:error, :stale_iat}
    true -> :ok
  end
end

defp check_iat(%{"iat" => _}, _now, _max_age, _clock_skew), do: {:error, :invalid_iat}
```

### Pattern 2: Persist Fresh-Auth Truth at the Login-Resume Boundary

**What:** Record protocol-owned fresh-auth time exactly when the host returns from a real authentication step and Lockspire transitions an interaction from `:pending_login` toward completion. [VERIFIED: lib/lockspire/protocol/authorization_flow.ex][VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]

**When to use:** For `max_age`, `prompt=none`, and any later feature that needs truthful authentication-event timing across redirects and token exchange. [CITED: https://openid.net/specs/openid-connect-core-1_0-31.html]

**Example:**
```elixir
# Source rationale: OIDC Core + existing interaction lifecycle
# [CITED: https://openid.net/specs/openid-connect-core-1_0-31.html]
# [VERIFIED: lib/lockspire/protocol/authorization_flow.ex]
with {:ok, interaction} <- load_active_interaction(interaction_id, opts),
     {:ok, fresh_auth_at} <- host_fresh_auth_at(subject_context),
     {:ok, interaction} <- persist_fresh_auth(interaction, fresh_auth_at, opts) do
  continue_authorization(interaction, subject_context, opts)
end
```

### Pattern 3: Keep Conformance Automation Outside Core Runtime Modules

**What:** Put suite bootstrap, plan JSON, result export, and host-fixture startup into scripts and integration helpers, not into runtime protocol modules. [VERIFIED: AGENTS.md][CITED: https://gitlab.com/openid/conformance-suite/-/wikis/Developers/Build-%26-Run]

**When to use:** Any workflow that starts Docker, calls `run-test-plan.py`, or saves HTML artifacts. [VERIFIED: https://gitlab.com/openid/conformance-suite/-/raw/master/scripts/run-test-plan.py]

**Example:**
```bash
# Source: OIDF suite Build & Run wiki + docker-compose-prebuilt.yml
# [CITED: https://gitlab.com/openid/conformance-suite/-/wikis/Developers/Build-%26-Run]
# [VERIFIED: https://gitlab.com/openid/conformance-suite/-/raw/master/docker-compose-prebuilt.yml]
IMAGE_TAG=release-v5.1.43 docker compose -f docker-compose-prebuilt.yml up -d
python3 scripts/conformance/run_lockspire_plan.py
```

### Anti-Patterns to Avoid

- **Treating `prompt=none` as “try silent, then redirect to login anyway”:** OIDC Core says no UI when `none` is used; falling back to host login breaks interoperability. [CITED: https://openid.net/specs/openid-connect-core-1_0-31.html]
- **Deriving `auth_time` from generic session churn:** Reused browser sessions, consent reuse, and request time are not fresh-auth events. [CITED: https://openid.net/specs/openid-connect-core-1_0-31.html][VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- **Letting host claims overwrite protocol claims:** `Host.Claims` already reserves several protocol claims; `auth_time` needs the same treatment if emitted from protocol-owned truth. [VERIFIED: lib/lockspire/host/claims.ex][VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]
- **Making contributors build the OIDF suite from source for every run:** the current wiki explicitly documents a prebuilt Docker quick start. [CITED: https://gitlab.com/openid/conformance-suite/-/wikis/Developers/Build-%26-Run]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| OP conformance verification | A custom negative-path test matrix that tries to mimic the OIDF suite | The OIDF Conformance Suite plus focused ExUnit regressions [CITED: https://openid.net/certification/about-conformance-suite/] | The official suite is the external interoperability referee; local tests complement it but do not replace it. [CITED: https://openid.net/certification/about-conformance-suite/] |
| JWT timestamp coercion | Manual `String.to_integer/1` fallback logic for claims like `iat`, `exp`, `auth_time` | Existing strict JOSE claim validation style used by `DPoP` and `JAR` [VERIFIED: lib/lockspire/protocol/dpop.ex][VERIFIED: lib/lockspire/protocol/jar.ex] | Conformance failures often come from permissive JSON typing, not missing happy-path behavior. [VERIFIED: .planning/research/PITFALLS.md][VERIFIED: lib/lockspire/protocol/dpop.ex][VERIFIED: lib/lockspire/protocol/jar.ex] |
| Silent-auth error taxonomy | Ad hoc app-specific redirect or flash behavior | OIDC authorization-endpoint error codes: `login_required`, `consent_required`, `interaction_required`, `invalid_request` [CITED: https://openid.net/specs/openid-connect-core-1_0-31.html] | Client SDKs already understand these codes; Lockspire-specific behavior adds friction without value. [CITED: https://openid.net/specs/openid-connect-core-1_0-31.html] |
| Conformance runner orchestration | Bespoke browser scripting from scratch | OIDF `run-test-plan.py` and checked-in plan/config wrappers [VERIFIED: https://gitlab.com/openid/conformance-suite/-/raw/master/scripts/run-test-plan.py] | The runner already handles plan creation, module execution, retries, and result export. [VERIFIED: https://gitlab.com/openid/conformance-suite/-/raw/master/scripts/run-test-plan.py] |

**Key insight:** This phase should reuse existing strict protocol seams and add missing truth, not replace proven modules with a larger abstraction. [VERIFIED: lib/lockspire/protocol/authorization_request.ex][VERIFIED: lib/lockspire/protocol/dpop.ex][VERIFIED: lib/lockspire/protocol/jar.ex]

## Common Pitfalls

### Pitfall 1: `prompt=none` Still Enters Interactive Host Login

**What goes wrong:** A request that should fail silently produces a redirect into host login or consent. [CITED: https://openid.net/specs/openid-connect-core-1_0-31.html]  
**Why it happens:** The current `AuthorizationFlow` only models interactive login/consent requirements and does not yet have a silent branch. [VERIFIED: lib/lockspire/protocol/authorization_flow.ex]  
**How to avoid:** Add a protocol-level silent decision path before any redirect orchestration, and map blockers to locked OIDC errors. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md][CITED: https://openid.net/specs/openid-connect-core-1_0-31.html]  
**Warning signs:** Controller tests start asserting redirects for `prompt=none`, or browser-safe tests depend on `/sign-in` for non-interactive requests. [VERIFIED: test/lockspire/web/authorize_controller_test.exs]

### Pitfall 2: `auth_time` Tracks Session Reuse Instead of Real Authentication

**What goes wrong:** `max_age` appears to work in happy paths but silently accepts stale sessions after reloads or retries. [CITED: https://openid.net/specs/openid-connect-core-1_0-31.html]  
**Why it happens:** Teams reuse Phoenix session timestamps or interaction timestamps instead of recording a host-confirmed fresh-auth event. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]  
**How to avoid:** Treat `auth_time` as protocol-owned durable data and advance it only when the host explicitly signals fresh authentication. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]  
**Warning signs:** Tests can only pass by stubbing `DateTime.utc_now/0`, or `auth_time` changes on consent-only resumes. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]

### Pitfall 3: Host Claims Override Protocol Claims

**What goes wrong:** The host can inject conflicting `auth_time`, `nonce`, or other reserved claims into ID tokens. [VERIFIED: lib/lockspire/host/claims.ex]  
**Why it happens:** `Host.Claims` currently reserves `iss`, `aud`, `exp`, `iat`, `nonce`, `at_hash`, and `sub`, but not `auth_time`. [VERIFIED: lib/lockspire/host/claims.ex]  
**How to avoid:** Extend the reserved protocol-claim set before adding protocol-owned `auth_time` emission. [VERIFIED: lib/lockspire/host/claims.ex][VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]  
**Warning signs:** ID-token tests pass only when host claims omit freshness fields. [VERIFIED: lib/lockspire/host/claims.ex]

### Pitfall 4: Conformance Harness Depends on Undocumented Local Machine State

**What goes wrong:** The suite passes only on one maintainer laptop because hostname, Docker state, cookies, or externally reachable URLs are implicit. [CITED: https://gitlab.com/openid/conformance-suite/-/wikis/Developers/Build-%26-Run][CITED: https://openid.net/certification/connect_op_testing/]  
**Why it happens:** The suite uses specific redirect URIs, aliases, browser interaction, and a base URL that must match how the OP is reachable. [CITED: https://openid.net/certification/connect_op_testing/][VERIFIED: https://gitlab.com/openid/conformance-suite/-/raw/master/scripts/run-test-plan.py]  
**How to avoid:** Check in fixture clients, deterministic host setup, one launcher script, explicit artifact paths, and docs for local vs hosted lanes. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md][CITED: https://openid.net/certification/about-conformance-suite/]  
**Warning signs:** The plan requires “just click around in the hosted suite” or “use your own alias and remember the callback URL.” [CITED: https://openid.net/certification/connect_op_testing/]

## Code Examples

Verified patterns from official sources and the current repo:

### Exact Redirect URI Matching
```elixir
# Source: lib/lockspire/protocol/authorization_request.ex [VERIFIED: codebase grep]
defp validate_redirect_uri(client, %{"redirect_uri" => redirect_uri})
     when is_binary(redirect_uri) and redirect_uri != "" do
  if redirect_uri in client.redirect_uris do
    {:ok, redirect_uri}
  else
    {:browser_error,
     browser_error(
       :invalid_request,
       "redirect_uri must match a registered URI",
       :invalid_redirect_uri
     )}
  end
end
```

### `prompt=none` and `max_age` Spec Constraints
```text
# Source: OpenID Connect Core 1.0 errata set 2
# [CITED: https://openid.net/specs/openid-connect-core-1_0-31.html]
prompt=none:
  - no authentication or consent UI may be shown
  - mixed "none" with other prompt values is an error
  - failures map to login_required / consent_required / interaction_required

max_age:
  - measures seconds since the user was actively authenticated
  - requires auth_time in the ID token when used
```

### OIDF Suite Docker-First Startup
```bash
# Source: OIDF Build & Run wiki + docker-compose-prebuilt.yml
# [CITED: https://gitlab.com/openid/conformance-suite/-/wikis/Developers/Build-%26-Run]
# [VERIFIED: https://gitlab.com/openid/conformance-suite/-/raw/master/docker-compose-prebuilt.yml]
curl -O https://gitlab.com/openid/conformance-suite/-/raw/master/docker-compose-prebuilt.yml
IMAGE_TAG=release-v5.1.43 docker compose -f docker-compose-prebuilt.yml up -d
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Build the OIDF suite locally from source with Java/Maven as the main onboarding path | Use the 2026 prebuilt Docker quick start for routine local runs; reserve source builds for suite development. [CITED: https://gitlab.com/openid/conformance-suite/-/wikis/Developers/Build-%26-Run] | Wiki updated 2026-02-24; latest suite release verified 2026-04-28. [VERIFIED: GitLab wiki history search][VERIFIED: https://gitlab.com/api/v4/projects/4175605/releases/permalink/latest] | Lockspire can automate Phase 37 without making Java a contributor prerequisite. [CITED: https://gitlab.com/openid/conformance-suite/-/wikis/Developers/Build-%26-Run] |
| “Best effort” auth freshness inferred from app session state | Durable protocol-owned `auth_time` tied to active authentication events. [CITED: https://openid.net/specs/openid-connect-core-1_0-31.html] | OIDC Core rule; still current in errata set 2. [CITED: https://openid.net/specs/openid-connect-core-1_0-31.html] | This is the only truthful base for `max_age` and conformance-grade silent auth behavior. [CITED: https://openid.net/specs/openid-connect-core-1_0-31.html] |
| Hosted conformance runs as the only proof source | Two-lane proof: checked-in harness for regressions plus hosted/staging runs for higher-assurance evidence. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md] | Locked in Phase 37 context on 2026-04-28. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md] | Preserves contributor DX while still supporting stronger release-grade proof. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md] |

**Deprecated/outdated:**
- Treating `prompt=none` as unsupported is outdated for Lockspire’s stated Phase 37 goal because the spec defines both behavior and error taxonomy, and the current repo explicitly wants automated conformance proof. [VERIFIED: lib/lockspire/protocol/authorization_request.ex][CITED: https://openid.net/specs/openid-connect-core-1_0-31.html][VERIFIED: .planning/ROADMAP.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The cleanest persistence shape is to capture fresh-auth time on the interaction/login-resume path and also make it available to token issuance without re-reading host session state. [ASSUMED] | Architecture Patterns | Could require a different migration shape or an extra token/code persistence field during planning. |
| A2 | Adding `auth_time` to the host-claim reserved set is the right Phase 37 boundary rather than introducing a broader claim-namespace policy. [ASSUMED] | Common Pitfalls | Planner could under-scope a future claim-policy concern if broader host-claim conflicts already exist. |
| A3 | A checked-in `scripts/conformance/` area is the best home for suite wrappers in this repo. [ASSUMED] | Recommended Project Structure | Planner may choose a different docs/test tooling location to match repo conventions. |

## Open Questions (RESOLVED)

1. **What exact host callback contract reports “fresh auth happened at time T”?**
   - Resolution: The host seam reports fresh authentication through explicit `subject_context[:auth_time]` or `subject_context["auth_time"]` input when Lockspire resumes a pending-login interaction. [RESOLVED: 37-03-PLAN.md]
   - Why this was chosen: It matches the locked decision to use an explicit read-only freshness seam and avoids inferring truth from ambient session churn. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]

2. **Should `auth_time` live only on interactions, or also on issued authorization-code/token records?**
   - Resolution: Phase 37 stores `auth_time`, `max_age`, and `auth_time_requested` on `Interaction` and loads that durable state during token exchange instead of duplicating freshness state onto authorization-code or token rows. [RESOLVED: 37-03-PLAN.md]
   - Why this was chosen: It keeps freshness truth protocol-owned and durable while preserving the existing interaction-linked token exchange path. [VERIFIED: lib/lockspire/protocol/token_exchange.ex][VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Docker | Local OIDF suite lane | ✓ [VERIFIED: local command] | `29.4.0` [VERIFIED: local command] | — |
| Docker Compose plugin | Local OIDF suite lane | ✓ [VERIFIED: local command] | `v5.1.2` [VERIFIED: local command] | `docker-compose` V1 syntax where needed [CITED: https://gitlab.com/openid/conformance-suite/-/wikis/Developers/Build-%26-Run] |
| Java runtime | Source-building the OIDF suite locally | ✗ [VERIFIED: local command] | — | Use the prebuilt Docker quick start instead. [CITED: https://gitlab.com/openid/conformance-suite/-/wikis/Developers/Build-%26-Run] |
| Python 3 | `run-test-plan.py` automation | ✓ [VERIFIED: local command] | `3.14.4` [VERIFIED: local command] | — |
| Node.js | Existing repo workflows and any hosted-fixture helpers | ✓ [VERIFIED: local command] | `v22.14.0` [VERIFIED: local command] | — |
| Mix / Erlang | Repo tests and generated host app | ✓ [VERIFIED: local command] | `Erlang/OTP 28` [VERIFIED: local command] | — |
| PostgreSQL client | Local DB inspection / generated host setup | ✓ [VERIFIED: local command] | `14.17` [VERIFIED: local command] | CI already provisions PostgreSQL 16 service. [VERIFIED: .github/workflows/ci.yml] |

**Missing dependencies with no fallback:**
- None for the Docker-first local lane. [CITED: https://gitlab.com/openid/conformance-suite/-/wikis/Developers/Build-%26-Run]

**Missing dependencies with fallback:**
- Java is missing locally, but the current OIDF prebuilt-image flow explicitly avoids a local Java build. [CITED: https://gitlab.com/openid/conformance-suite/-/wikis/Developers/Build-%26-Run][VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with repo-level integration tagging [VERIFIED: test/test_helper.exs] |
| Config file | `test/test_helper.exs` [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test.fast` [VERIFIED: mix.exs] |
| Full suite command | `mix ci` or at minimum `mix test.integration && mix test.phase3` for Phase 37 protocol work [VERIFIED: mix.exs][VERIFIED: .github/workflows/ci.yml] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CONF-01 | Reject string timestamps where integer claims are required at token-facing boundaries | unit + integration | `mix test test/lockspire/protocol/dpop_test.exs test/lockspire/protocol/token_endpoint_dpop_test.exs test/lockspire/web/token_controller_test.exs` [VERIFIED: mix test usage][VERIFIED: files exist] | ✅ |
| CONF-02 | Exact `redirect_uri` match remains enforced and conformance-proofed | unit + controller | `mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/web/authorize_controller_test.exs` [VERIFIED: files exist] | ✅ |
| CONF-03 | `prompt=none`, `max_age`, `nonce`, and `auth_time` behavior match OIDC rules | unit + controller + integration | `mix test --include integration test/lockspire/protocol/authorization_flow_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/web/authorize_controller_test.exs` [VERIFIED: test/test_helper.exs][VERIFIED: files exist] | ✅ |
| CONF-04 | Repo-native OIDF suite lane runs clean and exports artifacts | integration / external | New phase-specific script or alias to be added in Wave 0. [VERIFIED: gap identified by codebase grep] | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test.fast` [VERIFIED: mix.exs]
- **Per wave merge:** `mix test.integration` plus any new conformance fixture smoke test. [VERIFIED: mix.exs][VERIFIED: gap identified by codebase grep]
- **Phase gate:** Existing CI checks plus a green repo-native OIDF lane before `/gsd-verify-work`. [VERIFIED: .github/workflows/ci.yml][VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md]

### Wave 0 Gaps

- [ ] `test/lockspire/protocol/auth_time_*` or equivalent new test file for durable freshness semantics and ID-token emission. [VERIFIED: gap identified by codebase grep]
- [ ] `test/integration/phase37_*_e2e_test.exs` for generated-host silent auth and `max_age` proof. [VERIFIED: gap identified by codebase grep]
- [ ] `scripts/conformance/` runner, plan JSON, and artifact export path. [VERIFIED: gap identified by codebase grep]
- [ ] CI job or manual workflow for the Docker-first OIDF lane. [VERIFIED: gap identified by codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: phase scope] | Durable `auth_time` plus explicit fresh-auth signaling rather than ambient session reuse. [VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md][CITED: https://openid.net/specs/openid-connect-core-1_0-31.html] |
| V3 Session Management | yes [VERIFIED: phase scope] | Read-only session inspection seam; no Lockspire-owned host session takeover. [VERIFIED: AGENTS.md][VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md] |
| V4 Access Control | yes [VERIFIED: phase scope] | Exact redirect matching and deterministic silent-failure taxonomy prevent client mix-ups and confused-deputy flows. [CITED: https://openid.net/specs/openid-connect-core-1_0-31.html][VERIFIED: lib/lockspire/protocol/authorization_request.ex] |
| V5 Input Validation | yes [VERIFIED: phase scope] | No-coercion JWT claim parsing, exact string comparison for `redirect_uri`, and explicit prompt parsing. [VERIFIED: lib/lockspire/protocol/dpop.ex][VERIFIED: lib/lockspire/protocol/jar.ex][VERIFIED: lib/lockspire/protocol/authorization_request.ex] |
| V6 Cryptography | yes [VERIFIED: project stack] | Keep using JOSE for JWT/JWS processing; do not hand-roll claim decoding or signature validation. [VERIFIED: mix.lock][VERIFIED: lib/lockspire/protocol/dpop.ex][VERIFIED: lib/lockspire/protocol/id_token.ex] |

### Known Threat Patterns for Lockspire's Phase 37 Surface

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Redirect URI substitution / client mix-up | Spoofing | Exact pre-registered URI comparison and browser-safe error handling when no trusted redirect exists. [CITED: https://openid.net/specs/openid-connect-core-1_0-31.html][VERIFIED: lib/lockspire/protocol/authorization_request.ex] |
| Silent-auth downgrade from non-interactive to UI flow | Tampering | Treat `prompt=none` as a hard gate and return OIDC error codes instead of host redirects. [CITED: https://openid.net/specs/openid-connect-core-1_0-31.html][VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md] |
| Timestamp confusion from permissive JSON typing | Tampering | Accept only integer claim values for protocol timestamps. [VERIFIED: lib/lockspire/protocol/dpop.ex][VERIFIED: lib/lockspire/protocol/jar.ex] |
| False freshness from reused browser session | Repudiation | Persist protocol-owned authentication-event time and make `max_age` depend on that durable value only. [CITED: https://openid.net/specs/openid-connect-core-1_0-31.html][VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md] |
| Overstated conformance claims without repeatable proof | Repudiation | Tie public support posture to repo-owned proof and retain a separate hosted evidence lane. [VERIFIED: docs/supported-surface.md][VERIFIED: .planning/phases/37-protocol-strictness-conformance/37-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `https://openid.net/specs/openid-connect-core-1_0-31.html` - `prompt=none`, `max_age`, `auth_time`, `redirect_uri`, `nonce`, and authorization error semantics. [CITED: https://openid.net/specs/openid-connect-core-1_0-31.html]
- `https://openid.net/certification/about-conformance-suite/` - official suite operating model, local Docker availability, and CI runner recommendation. [CITED: https://openid.net/certification/about-conformance-suite/]
- `https://openid.net/certification/connect_op_testing/` - OP profile scope, alias/redirect requirements, and profile pass criteria. [CITED: https://openid.net/certification/connect_op_testing/]
- `https://gitlab.com/openid/conformance-suite/-/wikis/Developers/Build-%26-Run` - current quick-start, Docker, and local suite setup guidance. [CITED: https://gitlab.com/openid/conformance-suite/-/wikis/Developers/Build-%26-Run]
- `https://gitlab.com/api/v4/projects/4175605/releases/permalink/latest` - latest suite release tag and release timestamp. [VERIFIED: GitLab API]
- Repo files under `lib/lockspire/protocol/`, `lib/lockspire/host/`, `lib/lockspire/domain/`, `lib/lockspire/storage/ecto/`, `test/`, `mix.exs`, and `.github/workflows/ci.yml`. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- `https://raw.githubusercontent.com/panva/node-oidc-provider/main/README.md` - current embedded-provider precedent and certification posture. [CITED: https://github.com/panva/node-oidc-provider]
- `https://raw.githubusercontent.com/doorkeeper-gem/doorkeeper-openid_connect/master/README.md` - embedded-library precedent for explicit `auth_time` and reauthentication hooks. [CITED: https://github.com/doorkeeper-gem/doorkeeper-openid_connect]

### Tertiary (LOW confidence)

- None. All important implementation claims above were verified in the repo or cited from official sources. [VERIFIED: research log]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - almost entirely locked by repo truth plus official OIDF suite docs. [VERIFIED: mix.exs][VERIFIED: mix.lock][CITED: https://gitlab.com/openid/conformance-suite/-/wikis/Developers/Build-%26-Run]
- Architecture: HIGH - current module boundaries already show where validation, silent flow, and token claim shaping live. [VERIFIED: lib/lockspire/protocol/authorization_request.ex][VERIFIED: lib/lockspire/protocol/authorization_flow.ex][VERIFIED: lib/lockspire/protocol/id_token.ex]
- Pitfalls: HIGH - directly grounded in OIDC Core rules, current repo gaps, and official suite operating guidance. [CITED: https://openid.net/specs/openid-connect-core-1_0-31.html][CITED: https://openid.net/certification/about-conformance-suite/][VERIFIED: codebase grep]

**Research date:** 2026-04-28 [VERIFIED: system date]  
**Valid until:** 2026-05-05 for conformance-tooling details; 2026-05-28 for OIDC Core behavior rules. [CITED: https://openid.net/specs/openid-connect-core-1_0-31.html][VERIFIED: https://gitlab.com/api/v4/projects/4175605/releases/permalink/latest]
