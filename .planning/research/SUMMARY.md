# Research Summary: v1.16 Embedded Adoption Hardening & Sigra Golden Path

**Prepared:** 2026-05-06
**Purpose:** Choose the next milestone from repo truth plus current ecosystem guidance.

## Recommended milestone

**v1.16 Embedded Adoption Hardening & Sigra Golden Path**

Lockspire already has broad protocol depth for an embedded Phoenix authorization server. The highest-leverage next work is not another auth method. It is making the embedded host path boring, trustworthy, executable, and release-truthful.

## Why this is next

- Lockspire's own arc says to prefer real integrator leverage over checklist spec breadth.
- The repo already ships PAR, JAR, DCR, device flow, DPoP, FAPI 2.0 Security, Token Exchange, CIBA, RAR, Resource Indicators, and `private_key_jwt`.
- Current gaps are adoption and proof gaps:
  - the Sigra companion path is documented but not yet proved as a canonical executable golden path
  - public GA/support posture is stronger than current package metadata and changelog truth
  - some conformance/verification debt still affects the trust story

## Option ranking

1. **Embedded adoption hardening**
   - Best fit with Lockspire's embedded-library thesis
   - Highest adoption leverage for Phoenix/Sigra teams
   - Improves host-seam safety without widening protocol scope
2. **Conformance debt retirement**
   - Valuable where it strengthens current public claims
   - Should stay narrow and proof-oriented, not become certification theater
3. **`client_secret_jwt`**
   - Standard and sometimes useful, but lower-value right now
   - Especially unattractive in Lockspire because current client secrets are hashed at rest
4. **External certification work**
   - Useful later, but better deferred until the embedded host path is boring and repeatable

## Key conclusions

### Ecosystem lessons

- **`node-oidc-provider`** is the benchmark for protocol seriousness and explicit conformance posture.
- **OpenIddict** is the best model for an embedded framework: strict defaults, truthful scope, strong host separation.
- **ORY Hydra** reinforces the value of a headless provider that does not own login or user accounts.
- **Keycloak** is useful for operator-policy ideas, but it is the wrong product shape to imitate.
- **Doorkeeper** is a useful DX benchmark, especially for install ergonomics in a host framework.

### Elixir/Phoenix lessons

- Prefer generator-first host seams over compile-time integration between Lockspire and Sigra.
- Keep runtime configuration explicit and host-owned.
- Keep migrations host-applied and versioned.
- Keep observability Telemetry-native and LiveView surfaces operational, not product-like.
- Prove the generated host path end to end instead of relying on demo-app folklore.

### Security and product-shape lessons

- `client_secret_jwt` is a weaker trust step than `private_key_jwt`, and supporting it cleanly would put pressure on Lockspire's hashed-secret posture.
- Broadening into more client-auth methods or certification claims before tightening the embedded host story would move the product away from its thesis.
- The next milestone should make the current support contract more believable, not larger.

## Milestone guardrails

- Do not broaden into hosted auth, federation, or generic protected-resource middleware.
- Do not make Lockspire depend on Sigra at compile time.
- Do not claim certification or broader compatibility than the repo can prove.
- Keep any conformance work tied to executable proof for the already-supported embedded path.

## Primary sources

- Phoenix auth generator: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html
- Plug: https://hexdocs.pm/plug/Plug.html
- Plug router: https://hexdocs.pm/plug/Plug.Router.html
- Ecto repo: https://hexdocs.pm/ecto/Ecto.Repo.html
- Ecto testing: https://hexdocs.pm/ecto/testing-with-ecto.html
- Ecto migration: https://hexdocs.pm/ecto_sql/Ecto.Migration.html
- Oban migration: https://hexdocs.pm/oban/Oban.Migration.html
- Telemetry: https://hexdocs.pm/telemetry/telemetry.html
- OpenTelemetry API: https://hexdocs.pm/opentelemetry_api/readme.html
- LiveView security model: https://hexdocs.pm/phoenix_live_view/security-model.html
- OpenIddict assertion-based client auth: https://documentation.openiddict.com/configuration/assertion-based-client-authentication
- OpenID Connect Core 1.0: https://openid.net/specs/openid-connect-core-1_0-18.html
- OAuth 2.0 Security BCP (RFC 9700): https://www.rfc-editor.org/rfc/rfc9700
- OAuth Authorization Server Metadata (RFC 8414): https://www.rfc-editor.org/rfc/rfc8414
- FAPI 2.0 Security Profile Final: https://openid.net/specs/fapi-security-profile-2_0.html
