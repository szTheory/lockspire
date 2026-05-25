# Research Summary: Rich Authorization Requests (RAR - RFC 9328) for Lockspire

**Domain:** Embedded Elixir/Phoenix OIDC Provider
**Researched:** 2024
**Overall confidence:** HIGH

## Executive Summary

Rich Authorization Requests (RAR), defined in RFC 9328 (and refined in RFC 9396), replace or augment traditional, coarse-grained string scopes with structured JSON objects (`authorization_details`). This allows clients to request specific, fine-grained access (e.g., "transfer $50 to account X" instead of just "payment_write").

For Lockspire, an embedded Elixir OIDC provider, RAR is highly valuable for domains like Open Banking (FAPI), Healthcare, and complex enterprise APIs. However, it significantly increases implementation complexity, necessitates Pushed Authorization Requests (PAR) due to URL size constraints, and shifts a large validation burden onto the developer. 

We recommend providing first-class RAR support in Lockspire using idiomatic Elixir features (like polymorphic Ecto changesets and `NimbleOptions` for configuration), but treating it as an opt-in feature tied closely to PAR.

## Core Concepts & Tradeoffs

| Feature | Pros (The "Why") | Cons (The "Cost") |
| :--- | :--- | :--- |
| **Granularity** | Supports "Least Privilege" at the transaction/data level. | **Complexity:** Shifts from simple string array intersections to deep JSON schema validation. |
| **User Consent** | Dynamic consent screens (e.g., "Approve $50 transfer") provide explicit user intent. | **Consent Fatigue:** Overly complex consent screens can confuse end-users. UI implementation is harder. |
| **Scalability** | Eliminates "Scope Explosion" (creating millions of dynamic scopes like `tenant:123:read`). | **Standardization:** Clients and the AS must strictly agree on JSON schemas per `type`. |
| **Security** | Heavily mitigates stolen token impact since tokens are tightly bound to a specific intent. | **Request & Token Bloat:** Large JSON objects break HTTP GET limits and bloat JWTs. |

## Lessons from the Ecosystem

### 1. `node-oidc-provider` (Node.js)
- **Status:** Experimental (requires explicit developer opt-in acknowledgment `ack: 'individual-draft-01'`).
- **Approach:** Validates basic JSON structure but punts deep domain validation to the developer's interaction handler (`ctx.oidc.params.authorization_details`).
- **Lesson:** Provide the raw parsed JSON to the host application's consent callback so the host can enforce its own business rules.

### 2. Keycloak (Java)
- **Status:** Experimental, primarily driven by Verifiable Credentials (OID4VCI).
- **Approach:** Native support is clunky; most teams implement RAR via custom Service Provider Interfaces (SPIs) and Protocol Mappers.
- **Lesson:** Built-in UI for managing RAR types is notoriously difficult. For an embedded provider like Lockspire, we should rely on code-level configuration (`NimbleOptions` or protocols) rather than trying to build a generic Admin UI for RAR definition.

### 3. IdentityServer (C# / .NET)
- **Approach:** Strongly typed validators per RAR `type`. 
- **Lesson:** Strong typing of the `authorization_details` payload prevents runtime errors. Elixir can emulate this nicely with Ecto.

## Idiomatic Elixir Implementation Patterns for Lockspire

To implement RAR in an Elixir/Phoenix environment following the principle of least surprise and excellent DX:

### 1. Parsing & Transport (Plug & PAR)
Because `authorization_details` is a JSON array stringified into a query parameter (or POST body), **Pushed Authorization Requests (PAR - RFC 9126) must be a hard prerequisite** when RAR is enabled.
- Using standard browser redirects (GET `/authorize?authorization_details=[{...}]`) easily breaches URI length limits and exposes sensitive intent data in browser history.
- Lockspire should enforce PAR when `authorization_details` is present.

### 2. Validation Engine (Ecto)
Instead of forcing developers to manually parse JSON maps, Lockspire should provide a structured way to register RAR types using `Ecto.Schema` or embedded schemas.

```elixir
# Lockspire configuration (DX concept)
config :lockspire,
  authorization_details_types: [
    PaymentInit: MyApp.RAR.PaymentInitType,
    PatientRecord: MyApp.RAR.PatientRecordType
  ]

# Host App Implementation
defmodule MyApp.RAR.PaymentInitType do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :type, :string, default: "payment_init"
    field :amount, :decimal
    field :currency, :string
    field :payee, :string
  end

  def validate(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:type, :amount, :currency, :payee])
    |> validate_required([:type, :amount, :currency, :payee])
    |> validate_number(:amount, greater_than: 0)
  end
end
```
Lockspire can route the incoming `type` to the correct validation module, applying `Ecto.Changeset.apply_action/2` to ensure the payload is safe before reaching the consent screen.

### 3. Consent Interaction
Lockspire's interaction/consent API must pass the validated struct (not just raw maps) to the host application's UI layer. This provides type-safety for rendering the consent screen.

### 4. Token Minting vs. Introspection
**Crucial Footgun:** Embedding the full `authorization_details` array directly into the JWT Access Token will cause massive token bloat, leading to `HTTP 431 Request Header Fields Too Large` errors at Resource Servers.
- **Lockspire Pattern:** Store the approved `authorization_details` in the database (associated with the token ID).
- Inject a lightweight reference or hash into the JWT.
- Require Resource Servers to use the `/introspection` endpoint to retrieve the full `authorization_details` payload.

## Critical Footguns to Avoid

1. **"The URI Length Trap":** Allowing large RAR payloads over standard GET `/authorize` redirects. Lockspire should fail fast or explicitly warn if PAR is not used.
2. **"The Token Bloat Trap":** Blindly writing the `authorization_details` map into the JWT payload.
3. **"The Silent Failure Trap":** If a client requests a `type` that Lockspire doesn't recognize, the RFC specifies it must be rejected. Lockspire must not silently drop unknown types, as this subverts the client's explicit intent.

## Implications for Lockspire Roadmap

Based on this research, RAR integration should be phased as follows:

1. **Prerequisite Phase:** Implement Pushed Authorization Requests (PAR) and JWT-Secured Authorization Requests (JAR). These are foundational for safely transporting RAR.
2. **Core RAR Phase:** Implement the ingestion, `Ecto.Changeset` validation plugin system, and database storage for `authorization_details`.
3. **Introspection Phase:** Expose the approved `authorization_details` via the `/introspection` endpoint so Resource Servers can actually enforce the policies.

**Confidence Assessment:**
| Area | Confidence | Notes |
|------|------------|-------|
| Stack/Ecto | HIGH | Ecto polymorphic embedded schemas are perfectly suited for this. |
| PAR Dependency | HIGH | Ecosystem consensus strongly pushes PAR for RAR payloads. |
| Token Storage | HIGH | Avoid JWT bloat; use introspection for heavy data. |