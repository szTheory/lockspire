# Phase 28 Discussion & Architectural Research

**Goal:** Provide a cohesive, one-shot recommendation for Phase 28 gray areas (DCR Policy UI, IAT Lifecycle, Client Provenance, RAT Rotation UX) that emphasizes idiomatic Elixir/Phoenix, developer ergonomics (DX), principle of least surprise, and great UX.

## 1. DCR Policy Configuration UX (Opaque JSONB)

**Context:** The `put_dcr_policy/1` core API expects a string-keyed map for opaque JSONB overrides. LiveView forms need to edit complex, nested allowlists (scopes, grant types).
**Recommendation:** **Dedicated UI-only `Ecto.Schema` (Form Object)**
- **Why:** Schemaless changesets and direct map manipulation in LiveView assigns result in brittle form state and poor validation ergonomics. An embedded `Ecto.Schema` integrates flawlessly with LiveView's `to_form/1` and `inputs_for`, providing type casting, atom-keyed safety, and clear validation boundaries.
- **Tradeoff:** Minor boilerplate to map the struct back to a string-keyed map before calling the core API.
- **Ecosystem validation:** Auth0 and Keycloak use structured, validated forms over their raw JSON backends to give operators immediate, field-level feedback.

## 2. "Copy-Once" Secret Display (IAT Minting)

**Context:** An IAT is minted, stored strictly as a hash, and must be displayed to the operator exactly once.
**Recommendation:** **Dedicated Modal (Assigns + Explicit Clear)**
- **Why:** `put_flash` sends data in session cookies (a security footgun). LiveView `assigns` are strictly server-side memory. Rendering the plaintext in a modal with an explicit "I have copied this" button that actively clears the assign (`assign(socket, iat_secret: nil)`) minimizes the secret's memory residency and prevents shoulder surfing.
- **Ecosystem validation:** AWS IAM and GitHub Personal Access Tokens rely on explicit "copy once" interfaces that aggressively clear transient state after operator acknowledgement.

## 3. Client Provenance & RAT Rotation UX

**Context:** DCR introduces self-registered clients with Registration Access Tokens (RATs) that operators can rotate.
**Recommendation:** **Unified Index with Faceted Filter + Detail Modal Rotation**
- **Why:** Treating self-registered clients identically to operator-created clients causes confusion, but separate dashboards fragment the experience. A single index with a robust `provenance` filter (`:operator_created` vs `:self_registered`) provides the best UX.
- **Rotation UX:** Silent inline rotation risks accidental API breakage. Rotation must occur on the Client Detail page via an explicit Confirmation Modal. Upon confirmation, the new RAT is displayed using the exact same "Copy-Once" secure mechanism designed for IAT minting.
- **Ecosystem validation:** Keycloak and Okta unify client lists but aggressively quarantine destructive or credential-rotation actions behind explicit, consequence-warning modals.

## Telemetry Emission (DCR-21)

**Recommendation:**
- Adhere strictly to the existing `Lockspire.Observability` patterns. All DCR lifecycle events (`[:lockspire, :dcr, ...]`) and IAT lifecycle events (`[:lockspire, :iat, ...]`) will be emitted at the domain/protocol boundary, completely decoupled from the LiveView UI layer. This ensures telemetry fires accurately whether an action is triggered by an operator or an automated API client.