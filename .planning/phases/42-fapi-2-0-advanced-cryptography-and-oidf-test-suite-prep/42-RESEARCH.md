# Phase 42: FAPI 2.0 Advanced Cryptography and OIDF Test Suite Prep - Research

**Researched:** 2026-05-01
**Domain:** Elixir/Phoenix, OAuth 2.0 / OIDC / FAPI 2.0 Cryptographic Enforcement
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Canonical algorithm truth:** Under `security_profile: :fapi_2_0_security`, Lockspire must
  expose one protocol-owned algorithm policy and reuse it for every Lockspire-owned signing,
  verification, activation, publication, and discovery surface.
- **Supported FAPI subset:** Phase 42 supports exactly `ES256` and `PS256` under FAPI-effective
  behavior. `RS256` and `EdDSA` must not leak into FAPI-effective runtime or publication paths.
- **Mixed-mode semantics:** Existing legacy non-FAPI clients and keys may remain durable in
  storage, but they must not be activatable, publishable, selectable, or discoverable for
  FAPI-effective use.
- **Write-boundary fail-fast:** Admin, repository, and dynamic-registration paths should reject
  obviously non-compliant configuration early, with runtime checks retained as defense in depth.
- **Truthful publication:** Discovery, JWKS, and DPoP challenge surfaces must publish only what
  runtime behavior actually supports.
- **OIDF harness scope:** Phase 42 adds repo-native harness wiring, documented entrypoints, and
  release-truth tests, but does not claim full end-to-end conformance completion.

### the agent's Discretion
- Whether the canonical policy lives in a new module such as
  `Lockspire.Protocol.SigningAlgorithmPolicy` or remains in
  `Lockspire.Protocol.SecurityProfile`, provided the exported API stays tiny and protocol-owned.
- The exact split between admin-boundary validation, repository guards, and runtime signer/verifier
  checks, provided fail-fast behavior exists for FAPI-effective state.
- The exact `mix` alias/script/wrapper naming for the OIDF lane, provided it is deterministic and
  artifact-backed.

### Deferred Ideas (OUT OF SCOPE)
- Full FAPI discovery/compliance claim closure for FAPI-06 (Phase 43)
- New legacy-key quarantine workflows or compatibility subsystems
- Additional FAPI algorithm families beyond `ES256` and `PS256`
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FAPI-04 | Restrict allowed signing algorithms to `PS256` or `ES256` exclusively under the profile, rejecting `RS256` and weak curves. | Verified drift exists in protocol, admin, storage, discovery, and tests; one shared policy seam can close it. |
</phase_requirements>

## Summary

Phase 42 is not one isolated crypto tweak. The repo already has a resolved-profile carrier
(`Lockspire.Protocol.SecurityProfile.Resolved`), profile-aware ID token signing, DPoP algorithm
publication, key activation compliance checks, release-contract tests, and a conformance script
pattern. The work is to make those existing pieces agree on one FAPI-effective algorithm policy and
push that truth through every Lockspire-owned surface that signs, verifies, publishes, or activates
JWT material.

The current drift is concentrated and well defined:
- `Lockspire.Protocol.SecurityProfile.allowed_signing_algorithms/1` still allows `EdDSA` under
  FAPI and `RS256` under the baseline list.
- `Lockspire.Security.Policy.validate_key_compliance/2` still treats `EdDSA` as FAPI-compliant.
- `Lockspire.Protocol.Discovery` still publishes `["RS256"]` for
  `id_token_signing_alg_values_supported`.
- `Lockspire.Protocol.LogoutToken` and `Lockspire.Protocol.EndSession` are hardcoded to `RS256`.
- Existing tests and scripts still encode `RS256` assumptions across discovery, logout, end
  session, token exchange, and JWKS surfaces.

**Primary recommendation:** Decompose the phase into four plans that follow the existing Lockspire
delivery pattern:
1. Canonical algorithm truth + key/admin/storage fail-fast seams
2. Signing/verification/publication surface alignment for JAR, ID token, logout, end session,
   discovery, JWKS, and DPoP challenge metadata
3. Client metadata / mixed-mode rejection paths and targeted operator remediation coverage
4. OIDF harness wiring, release-readiness contract updates, and integration proof lane prep

This preserves Phase 42’s narrow boundary: make cryptographic posture trustworthy now, and make
Phase 43 use the harness for full milestone proof instead of first assembling tooling.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Canonical signing algorithm policy | Protocol | Security | Must stay protocol-owned and be reused by both signer/verifier and publication surfaces. |
| Key compliance / activation gating | Admin + Storage | Security | Fail fast before a FAPI-effective server/client can rely on a non-compliant key. |
| JWT signing and verification | Protocol | Storage | JOSE decisions belong in protocol modules; storage supplies keys but not policy. |
| Discovery/JWKS/challenge truth | Protocol + Web adapter | — | Published metadata must derive from runtime truth, not hand-maintained constants. |
| OIDF harness / release truth | Docs + scripts + CI + tests | Integration | Maintainer workflow must be executable and guarded against support-claim drift. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | 1.8.5 | Web/controller/router integration | Existing HTTP/adaptor layer for discovery and conformance wiring. |
| Ecto SQL | 3.13.5 | Durable client and key policy state | Existing persistence layer for mixed-mode and activation semantics. |
| JOSE | repo default | JWT/JWK/JWS/JWE operations | Existing signing and verification library used by DPoP, JAR, ID tokens, and logout. |
| ExUnit | repo default | Unit/integration/release-contract verification | Existing verification stack with fast targeted coverage. |

## Architecture Patterns

### Recommended Project Structure
```text
lib/lockspire/
├── protocol/
│   ├── security_profile.ex            # or new signing_algorithm_policy.ex truth seam
│   ├── id_token.ex                    # signer preflight against policy
│   ├── jar.ex                         # verifier uses same allow-list
│   ├── logout_token.ex                # replace RS256-only path
│   ├── end_session.ex                 # replace RS256-only verifier path
│   ├── discovery.ex                   # truthful alg publication
│   └── jwks.ex                        # truthful alg publication for publishable keys
├── security/
│   └── policy.ex                      # FAPI-compliant key algorithm and strength checks
├── admin/
│   └── keys.ex                        # generation / activation remediation-friendly errors
└── storage/
    ├── key_store.ex                   # contract remains source for publishable/active keys
    └── ecto/
        ├── repository.ex              # activation/publication guards if needed
        └── client_record.ex           # durable metadata rejection for FAPI-effective updates

docs/
└── maintainer-conformance.md          # OIDF harness entrypoint and artifact contract

scripts/conformance/
└── fapi2-check.sh                     # preflight / wrapper updates

.github/workflows/
└── oidf-conformance.yml               # artifact-backed CI lane truth
```

### Pattern 1: One protocol-owned truth export
Copy the `DPoP.signing_alg_values_supported/1` shape: one exported function that can accept either
`%SecurityProfile.Resolved{}` or a profile atom, and every signer/verifier/publication surface
calls it.

### Pattern 2: Signer/verifier preflight inside protocol modules
Reuse the `IdToken` and `DPoP` patterns: compute allowed algorithms from resolved profile, reject
before JOSE operations where possible, then still verify strictly against the same list at runtime.

### Pattern 3: Fail fast at admin/repository boundaries
Reuse `Admin.Keys.activate_key/2` plus `Security.Policy.validate_key_compliance/2`. Add any missing
write-time checks for global FAPI enablement, client FAPI opt-in, or publish/activate operations so
operators get remediation-friendly errors before broken state becomes runtime-visible.

### Pattern 4: Truthful publication from runtime truth
Copy `Discovery` and `UserinfoController` DPoP-challenge behavior. Discovery metadata, JWKS
entries, and challenge `algs="..."` hints should come from the same canonical algorithm policy.

### Pattern 5: Executable support truth
Copy the release-contract and conformance pattern already used in Phase 41: docs, script, CI
workflow, and tests move together so support wording cannot claim more than the repo proves.

## Repo Findings

### Confirmed Drift
- `lib/lockspire/protocol/security_profile.ex`
  - `allowed_signing_algorithms(:fapi_2_0_security)` currently returns
    `["ES256", "PS256", "EdDSA"]`
- `lib/lockspire/security/policy.ex`
  - FAPI-compliant key check still permits `EdDSA`
- `lib/lockspire/protocol/discovery.ex`
  - `@id_token_signing_alg_values_supported ["RS256"]`
- `lib/lockspire/protocol/logout_token.ex`
  - signing path only matches `%{alg: "RS256"}` and signs with `"RS256"`
- `lib/lockspire/protocol/end_session.ex`
  - `@allowed_algorithms ["RS256"]`
- `lib/lockspire/protocol/fapi20_enforcer_plug.ex`
  - `WWW-Authenticate` DPoP challenge still publishes `ES256 PS256 EdDSA`

### Reusable Assets
- `Lockspire.Protocol.SecurityProfile.Resolved` already carries effective-profile truth.
- `Lockspire.Protocol.DPoP` already demonstrates the correct truth-from-validator publication
  pattern.
- `Lockspire.Protocol.IdToken` already shows profile-aware signing preflight.
- `Lockspire.Admin.Keys` and `Lockspire.Security.Policy` already provide a natural activation guard
  seam.
- `docs/maintainer-conformance.md`, `scripts/conformance/fapi2-check.sh`, and
  `.github/workflows/oidf-conformance.yml` already establish the executable-docs pattern this phase
  should extend instead of replacing.

## Common Pitfalls

### Pitfall 1: Fixing only signer surfaces
**What goes wrong:** ID token or logout signing gets updated, but discovery, JWKS, JAR verification,
or DPoP challenge metadata still advertise older algorithms.
**How to avoid:** Treat Phase 42 as a contract-alignment phase. Every owned verification and
publication surface should be audited against the one policy export.

### Pitfall 2: Over-tightening storage instead of runtime boundary semantics
**What goes wrong:** Existing non-FAPI rows become impossible to retain, violating the locked
mixed-mode decision.
**How to avoid:** Keep storage tolerant for legacy `:none` paths, but reject activation,
publication, server FAPI enablement, or client FAPI opt-in when they would depend on non-compliant
algorithms.

### Pitfall 3: Hiding remediation behind generic errors
**What goes wrong:** Operators get `:invalid_signing_alg` or `:non_compliant_algorithm` with no
next-step guidance.
**How to avoid:** Reuse the admin error-tuple style from prior phases and make tests pin messages
that point to generating/activating an `ES256` or `PS256` key, rotating away from `RS256`, or
changing the client/profile setting.

### Pitfall 4: Letting OIDF harness work blur milestone truth
**What goes wrong:** Docs or CI suggest full certification/proof is already complete.
**How to avoid:** Keep Phase 42 docs explicit that the harness is preparatory wiring and artifact
lane setup; Phase 43 is still the release-claim closure phase.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test --stale` |
| Full suite command | `mix test` |
| Estimated runtime | ~45 seconds |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FAPI-04 | FAPI-effective signer/verifier/publication surfaces allow only `ES256` / `PS256` and reject `RS256` / `EdDSA` | unit | `mix test test/lockspire/protocol/security_profile_test.exs test/lockspire/security/policy_test.exs test/lockspire/protocol/id_token_test.exs test/lockspire/protocol/jar_test.exs test/lockspire/protocol/logout_token_test.exs test/lockspire/protocol/end_session_test.exs test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs` | mixed |
| FAPI-04 | Admin/repository/key lifecycle rejects non-compliant activation/publication under FAPI-effective state with actionable remediation | unit | `mix test test/lockspire/admin/keys_test.exs test/lockspire/storage/repository_test.exs test/lockspire/admin/server_policy_test.exs test/lockspire/admin/clients_test.exs` | mixed |
| FAPI-04 | OIDF harness workflow, docs, and release-truth statements stay aligned with shipped repo behavior | integration / contract | `mix test test/integration/phase41_fapi_2_0_e2e_test.exs test/lockspire/release_readiness_contract_test.exs` | yes |

### Wave 0 Gaps
- [ ] Add/extend focused tests for canonical signing-algorithm truth export and FAPI subset
  (`security_profile_test.exs`, `security_policy_test.exs`)
- [ ] Add focused tests for `LogoutToken` and `EndSession` profile-aware algorithm enforcement
- [ ] Add/update release-contract assertions for OIDF harness wording and artifact expectations

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Validation, Sanitization and Encoding | yes | Reject non-compliant client/server/key metadata before runtime use |
| V7 Error Handling and Logging | yes | Operator/admin errors must explain the remediation without leaking secrets |
| V8 Data Protection | yes | Signing keys remain durable and redacted while activation/publication stays policy-compliant |
| V9 Communications | yes | JWT algorithm allow-lists and discovery metadata must reflect actual supported cryptography |
| V14 Config | yes | Global/client FAPI posture should fail closed when required cryptographic dependencies are absent |

### Known Threat Patterns for This Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Algorithm confusion / downgrade | Tampering | Use explicit allow-lists via `JOSE.JWT.verify_strict/3` and signer preflight from one canonical policy source |
| Non-compliant key activation | Elevation of Privilege | Reject key activation/publication under FAPI when alg or strength is non-compliant |
| Truth drift between docs/discovery/runtime | Repudiation | Guard support claims with release-contract tests and artifact-backed OIDF harness workflow |
| Legacy key leakage into FAPI runtime | Information Disclosure / Tampering | Keep durable storage tolerant but block activation, publication, selection, and discovery use under FAPI-effective state |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/42-fapi-2-0-advanced-cryptography-and-oidf-test-suite-prep/42-CONTEXT.md`
- `.planning/phases/42-fapi-2-0-advanced-cryptography-and-oidf-test-suite-prep/42-PATTERNS.md`
- `lib/lockspire/protocol/security_profile.ex`
- `lib/lockspire/security/policy.ex`
- `lib/lockspire/protocol/discovery.ex`
- `lib/lockspire/protocol/logout_token.ex`
- `lib/lockspire/protocol/end_session.ex`
- `lib/lockspire/admin/keys.ex`
- `docs/maintainer-conformance.md`
- `scripts/conformance/fapi2-check.sh`
- `.github/workflows/oidf-conformance.yml`

## Metadata

**Confidence breakdown:**
- Repo drift identification: HIGH
- Architectural split recommendation: HIGH
- OIDF harness prep scope: HIGH

**Research date:** 2026-05-01
**Valid until:** 2026-06-01
