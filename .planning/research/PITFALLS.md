# DCR Milestone Research: Pitfalls

**Project:** Lockspire
**Milestone:** v1.5 Dynamic Client Registration
**Domain:** Adding RFC 7591/7592 DCR to an existing operator-tended Phoenix/Elixir OAuth/OIDC provider
**Researched:** 2026-04-25
**Confidence:** HIGH

## Scope and Posture

This file enumerates pitfalls specific to *adding* DCR to a provider that already ships PAR, JAR (signed-by-value request objects), PKCE S256, OIDC discovery, refresh rotation, hashed client secrets, exact redirect-URI matching, and an admin LiveView for clients. It assumes the v1.5 out-of-scope decisions: no software statements (RFC 7591 §2.3), no external-IdP federation, no FAPI bundles, no JAR-04 encryption.

The single biggest risk for v1.5 is **shape drift**: DCR is the first endpoint that lets non-operators create durable trust state, so every weakness in policy, provenance, audit, and discovery truth gets amplified beyond what PAR or JAR exposed. Each pitfall below ends with a phase placement so the roadmapper can pin prevention to a concrete phase.

## Critical Pitfalls

### Pitfall 1: Self-registration left wide open by default

**What goes wrong:**
`POST /register` is mounted as soon as the route exists, with no operator gate, so any unauthenticated caller can mint clients. An attacker scripts thousands of registrations to fill `clients`, exhaust connection pool, drown audit logs, or seed phishing redirect URIs that look like legitimate partner clients in the admin UI.

**Why it happens:**
The RFC describes self-service as a feature, not a default. Implementers read RFC 7591 §3 and ship the endpoint as documented. They miss that production IdPs (Keycloak, PingAM, Connect2id, Curity) all ship DCR *off* or behind initial access tokens, trusted-host policy, or an explicit allowlist. Keycloak ships a Client Registration Policy SPI (Trusted Hosts, Max Clients, Client Scopes, Protocol Mappers) precisely because anonymous DCR is known to be exploitable — there is even an open Keycloak discussion about anonymous-DCR DDoS exhausting the default 300-client realm threshold.

**How to avoid:**
- Lockspire ships with self-registration **off** by default. Operator must flip a server-policy flag (`registration_policy: :disabled | :initial_access_token | :open`) to enable it.
- Default the gated mode to `:initial_access_token` — operator mints an `initial_access_token` from the admin LiveView and hands it to a partner out-of-band; DCR rejects unauthenticated calls.
- Surface global rate limit + per-source-IP rate limit bounded by `Lockspire.Observability` so operators can see the limit firing.
- Honor existing `Lockspire.Admin.ServerPolicy` shape (`get`/`put`) so the new policy field threads through the same audit path PAR/JAR policy uses.

**Warning signs:**
- A registration test passes without any auth header.
- Discovery advertises `registration_endpoint` while server policy says registration is disabled (see Pitfall 9).
- Admin LiveView has no row for "DCR mode" alongside the existing PAR/JAR policy rows.

**Phase to address:**
Phase 1 (DCR policy + intake skeleton). Cannot be deferred — it gates whether the endpoint is safe to mount at all.

---

### Pitfall 2: `registration_access_token` treated like a session cookie

**What goes wrong:**
The `registration_access_token` is stored as plaintext or as a normal bearer token, leaks via logs / error messages / metrics labels, or is rotated on a fixed timer that locks the partner out of their own client. Worst case: the token is shared by reference between client instances, so one compromised instance can `DELETE /register/:client_id` and erase a production partner's registration.

**Why it happens:**
Three RFC interpretation traps converge:
1. RFC 7592 §2 says the token is a Bearer token, so implementers reuse access-token storage. But unlike access tokens, this token's blast radius is *the client's entire trust record*, not a single resource grant.
2. RFC 7592 §3 says the token "MAY be rotated" on read or update. Implementers either skip rotation entirely (long-lived static token = leak risk) or rotate too aggressively (every read), which breaks tooling that polls metadata.
3. RFC 7592 §3 also says the token "SHOULD NOT expire while a client is still actively registered" — implementers either ignore this and watch partners get locked out, or take it as license to never rotate at all.

**How to avoid:**
- Store the registration access token as a **hash** in a dedicated column (mirrors `client_secret_hash` discipline already in `Lockspire.Domain.Client`). The plaintext is shown to the partner exactly once at issuance and on rotation.
- Rotate on **update and delete only**, not on every GET. Return the new token in the response body and document that the previous token is invalidated.
- Never log the token, never include it in telemetry payload values, never put it in error reasons. Add a redaction test.
- Bind the token to one `client_id`. A query for token X must verify both `token_hash` match *and* `client_id` URL match — never look up the client by token alone, never look up the token without the URL `client_id`.
- On `GET/PUT/DELETE /register/:client_id` where the client_id does not exist, return HTTP 401 and treat the presented token as compromised (revoke it and audit it), per RFC 7592 §2.1 guidance.

**Warning signs:**
- A test asserts `token == client.registration_access_token` (means it's stored plaintext).
- Telemetry events include a `registration_access_token` field.
- DELETE works when the URL `client_id` does not match the token's owning client.

**Phase to address:**
Phase 2 (RFC 7592 management endpoints). Token storage and rotation rules belong with the management endpoints themselves; cannot be retrofitted safely after admin UI is built on top.

---

### Pitfall 3: SSRF via `jwks_uri`, `sector_identifier_uri`, `logo_uri`

**What goes wrong:**
A registrant submits `jwks_uri: http://169.254.169.254/latest/meta-data/iam/security-credentials/` or `sector_identifier_uri: http://10.0.0.5/internal-secrets`. Lockspire fetches these URLs at registration time (jwks_uri to validate keys, sector_identifier_uri per OIDC §5 to validate the sector ID), and the response is reflected into client metadata or surfaced in error messages — the IdP becomes a reflective SSRF probe into the host's private network.

**Why it happens:**
The OIDC spec **requires** server-side fetch of `sector_identifier_uri` to validate that registered redirect URIs are in the JSON array. Implementers add the fetch without scheme/host validation. Logo and ToS URIs sound harmless and ship without validation at all, but the admin LiveView loads them as `<img>` and `<a href>` — which opens a separate XSS/clickjacking vector if not constrained.

**How to avoid:**
- All operator-fetched URIs (`jwks_uri`, `sector_identifier_uri`) MUST be `https://` with no scheme exception even in dev (force `http://` only behind a documented test toggle).
- Resolve hostnames before fetch and reject private/loopback/link-local/multicast ranges (`127.0.0.0/8`, `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `169.254.0.0/16`, `::1`, `fc00::/7`, `fe80::/10`, `0.0.0.0`). Reject DNS results that resolve to those ranges.
- Set short connect/read timeouts (~5s), cap response body size (e.g. 1 MiB), follow no redirects, and reject non-JSON content-types for sector_identifier_uri.
- For `logo_uri`, `tos_uri`, `policy_uri`, `client_uri`: validate scheme+host but do **not** fetch them server-side. Render in admin UI through a strict CSP and `rel="noopener noreferrer"` link discipline. Add a Markdown test that confirms admin templates do not auto-load remote logos in unauthenticated views.
- Keep `sector_identifier_uri` enforcement aligned with our existing subject-type posture: discovery advertises only `subject_types_supported: ["public"]` today (see `Lockspire.Protocol.Discovery`), so the safest v1.5 default is to *reject* `subject_type: "pairwise"` and `sector_identifier_uri` outright unless operator policy explicitly opts pairwise in. This avoids a broken half-supported pairwise path.

**Warning signs:**
- A test for "rejects jwks_uri to internal IP" does not exist.
- The admin show page renders `logo_uri` from a partner-controlled URL on an unauthenticated route.
- Discovery still advertises only `public` subjects but `sector_identifier_uri` is accepted at registration anyway.

**Phase to address:**
Phase 1 (intake validation) for `jwks_uri` / `sector_identifier_uri` rejection rules; Phase 4 (admin UI provenance) for safe rendering of registrant-controlled URIs.

---

### Pitfall 4: `jwks` and `jwks_uri` accepted together (or one silently overrides the other)

**What goes wrong:**
A registrant sends both `jwks` (inline) and `jwks_uri` (remote). Lockspire stores both, and the JAR verification path (`Lockspire.Protocol.Jar`) silently picks one — usually whichever the code happens to check first. An attacker controls the unchosen value to confuse later operators or to set up a key-confusion attack against signed request objects.

**Why it happens:**
OIDC Registration §2 says the two parameters MUST NOT be used together, but RFC 7591 alone does not prohibit it explicitly. Implementations that cite RFC 7591 ("we are not OIDC-strict") accept both. Lockspire is OIDC and ships JAR (v1.4) that already trusts inline `jwks` for `jar_policy: :required` clients (see `validate_jar_policy_if_present` in `lib/lockspire/admin/clients.ex`) — so accepting both at registration breaks the JAR trust assumption silently.

**How to avoid:**
- Reject registration with `invalid_client_metadata` if both `jwks` and `jwks_uri` are present.
- Document precedence in the rejection error message and in SECURITY.
- Keep the existing JAR rule that `jar_policy: :required` requires usable inline `jwks` — but only enforce that rule on update *after* DCR has accepted exactly one of `jwks` or `jwks_uri`. Add a JAR-on-DCR test: a self-registered client cannot end up with `jar_policy: :required` and only a `jwks_uri` (because v1.4 mandated inline JWKS for that policy).

**Warning signs:**
- The DCR fixture in tests sends only one of the two — there is no negative test for both.
- A JAR test passes for a self-registered client whose only key material is a `jwks_uri`.

**Phase to address:**
Phase 1 (intake validation), with a JAR-coherence assertion in the same phase so the v1.4 invariant cannot be broken silently.

---

### Pitfall 5: Redirect URI pattern matching sneaking in

**What goes wrong:**
A partner registers `redirect_uris: ["https://partner.example.com/*"]` or `"https://partner.example.com/callback?env=prod"` with extra query string. Lockspire later compares against the auth-request `redirect_uri` with `String.contains?/2` or `URI.parse |> Map.get(:host)` instead of byte-for-byte equality, and a malicious open redirect on the partner's domain is reachable.

**Why it happens:**
RFC 7591 §2 lists `redirect_uris` as an array of strings and does not say "exact match", so DCR-focused implementers may forget Lockspire's wider rule (`PROJECT.md` Constraints: "exact redirect matching"). The temptation grows because `Clients.validate_redirect_uris/1` already exists, but new DCR-specific code paths sometimes bypass it.

**How to avoid:**
- Route DCR redirect URI validation through the **same** `Clients.validate_redirect_uris/1` path the admin code uses today (see `validate_redirects_if_present` in `lib/lockspire/admin/clients.ex`). Add a property test: any URI accepted by DCR must also be acceptable by the admin update path.
- Reject registrations containing wildcards, query strings, fragments, or schemes other than `https://` (with a documented narrow exception for `http://localhost` for native/dev clients if scoped, and `loopback` IP redirects per BCP 212 §7.3 if v1.5 chooses to allow native clients — otherwise reject).
- Reject registration where two redirect URIs canonicalize to the same exact-string form.
- Add a contract test that the existing `/authorize` redirect-URI exact-match rule sees DCR-registered URIs as equal byte-for-byte.

**Warning signs:**
- A test like `assert client.redirect_uris == ["https://example.com/*"]`.
- DCR has its own URI parser separate from `Clients.validate_redirect_uris/1`.

**Phase to address:**
Phase 1 (intake validation). Reuse, do not duplicate.

---

### Pitfall 6: `grant_types` / `response_types` incoherence accepted

**What goes wrong:**
A partner registers `grant_types: ["authorization_code"]` with `response_types: ["token"]` (or vice versa). Lockspire stores it, the auth-code flow refuses the request at runtime with a confusing error, and the partner spends days debugging. Worse: a partner registers `grant_types: ["implicit"]` and Lockspire accepts it even though the project's Constraints say "no implicit flow" — Lockspire now claims to support a grant it does not implement.

**Why it happens:**
RFC 7591 §2 calls grant_types and response_types "partially orthogonal" and tells servers they SHOULD return `invalid_client_metadata` on inconsistent combinations — but does not enumerate every coherent pair. Implementers either skip the check or write an under-specified one. The fastmcp project actually shipped a bug where DCR *required* both `authorization_code` and `refresh_token` because of an over-eager coherence check (issue #2460), so the trap exists in both directions.

**How to avoid:**
- Build the coherence matrix from what Lockspire actually supports today. Discovery already tells the truth: `grant_types_supported: ["authorization_code", "refresh_token"]` and `response_types_supported: ["code"]`. So DCR MUST reject any `grant_types` containing values outside that set, and any `response_types` other than `["code"]`.
- Enforce the OIDC implication: if `grant_types` contains `authorization_code`, `response_types` must contain `code`, and vice versa.
- Reject `implicit`, `password`, `urn:ietf:params:oauth:grant-type:device_code`, and `urn:ietf:params:oauth:grant-type:jwt-bearer` with `invalid_client_metadata` and a reason that names the unsupported grant explicitly (do not silently drop).
- Apply RFC 7591 default: missing `grant_types` defaults to `["authorization_code"]` and missing `response_types` defaults to `["code"]`. Do not invent your own defaults — divergence here is a known interop hazard.
- Make the coherence check live in one function reused by both DCR and the admin update path. Single source of truth or it will drift.

**Warning signs:**
- DCR accepts `implicit` even though `discovery.ex` says only `code` and `authorization_code`/`refresh_token`.
- Different defaults applied at admin vs. DCR (e.g., admin defaults to `["authorization_code","refresh_token"]`, DCR defaults to `["authorization_code"]`).

**Phase to address:**
Phase 1 (intake validation). Coherence rules and defaults must be locked before Phase 4 admin UI surfaces self-registered clients.

---

### Pitfall 7: `token_endpoint_auth_method` registered outside discovery truth

**What goes wrong:**
A partner registers with `token_endpoint_auth_method: "private_key_jwt"`. Lockspire's domain type already has the atom (see `Lockspire.Domain.Client`), but discovery advertises only `["none", "client_secret_basic", "client_secret_post"]` (see `Lockspire.Protocol.Discovery`). The client registration succeeds; the token endpoint then rejects every authentication attempt; the partner is stuck.

**Why it happens:**
Domain enums are wider than discovery enums (because v1.0 anticipated future support without yet shipping it). DCR validation reads `Lockspire.Domain.Client`'s typespec and accepts everything in the typespec, not what the *server* actually advertises.

**How to avoid:**
- DCR validation MUST read the same allow-list the discovery document advertises (`token_endpoint_auth_methods_supported`). Treat discovery as the truth, not the domain typespec.
- Reject `private_key_jwt`, `tls_client_auth`, etc., with `invalid_client_metadata` and a message naming what *is* supported.
- For `client_type` derivation: if the partner specifies `token_endpoint_auth_method: "none"`, mark `client_type: :public` and refuse to issue a `client_secret`; otherwise, generate a confidential client with a hashed secret. Reuse `Clients.rotate_secret_hash/0`.
- Add an invariant test: every value DCR accepts for `token_endpoint_auth_method` is present in `Lockspire.Protocol.Discovery.openid_configuration["token_endpoint_auth_methods_supported"]`.

**Warning signs:**
- DCR test fixtures include `private_key_jwt` and the test passes.
- The phrase "we'll support this later" appears in DCR validation comments.

**Phase to address:**
Phase 1 (intake validation). Truth-binding must exist before Phase 3 (discovery) goes truthful, otherwise the two will drift.

---

### Pitfall 8: PKCE / PAR / JAR policy weakened by DCR-issued clients

**What goes wrong:**
A partner self-registers and Lockspire defaults `pkce_required: false`, `par_policy: :inherit`, `jar_policy: :inherit`. Operator's global policy is `optional`. The self-registered client now operates with weaker security than the operator-tended baseline, and a downstream phishing attack succeeds against authorization-code interception. Lockspire's "PKCE S256 mandatory" Constraint silently no longer holds.

**Why it happens:**
RFC 7591 has no PKCE field. Implementers default `pkce_required` based on the existing `Lockspire.Domain.Client` defaults (which is `pkce_required: true` — good) but then *let DCR override it* via metadata extension fields. Or they apply `:inherit` PAR/JAR policy to a client that operator policy never explicitly approved.

**How to avoid:**
- DCR-created clients MUST have `pkce_required: true` (matching existing Constraint). DCR MUST NOT accept any field that lowers PKCE requirements.
- DCR-created clients inherit PAR and JAR policy via `:inherit` like admin-created clients do, BUT operator policy MUST be able to set a stricter floor for DCR clients specifically, e.g. `dcr_min_par_policy: :required`. If global server policy is `:optional` but DCR floor is `:required`, DCR clients get `:required`.
- DCR-created clients MUST default to `client_type: :confidential` with `token_endpoint_auth_method: :client_secret_basic` unless the registrant explicitly asks for `:none`+`:public`.
- Add an invariant test that no DCR-created client can have `pkce_required: false`.

**Warning signs:**
- A `pkce_required: false` value is reachable on the create path.
- The registration request includes a Lockspire-extension field that toggles PKCE.
- Operator policy has no way to say "DCR clients MUST require PAR" beyond what the global policy says.

**Phase to address:**
Phase 1 (intake validation) for the floor; Phase 2 (RFC 7592) for the same floor on update (a partner cannot lower PKCE via PUT either).

---

### Pitfall 9: Discovery advertising untruth (registration_endpoint vs. policy)

**What goes wrong:**
Two failure modes, both seen in production stacks:

1. `registration_endpoint` is advertised in discovery, but server policy disables registration, so every `POST /register` returns 403. Clients (especially MCP-style tooling) rely on discovery and start failing CI; trust in Lockspire's discovery posture erodes. This is a known recurring complaint in the MCP ecosystem (modelcontextprotocol/inspector#752, vscode#257415, cursor #110638).
2. Registration is enabled in policy, but `registration_endpoint` is missing from discovery, so partners cannot find the endpoint without out-of-band knowledge — the v1.5 wedge is invisible.

**Why it happens:**
`Lockspire.Protocol.Discovery` builds metadata from mounted route paths (`mounted_route_paths/0`) — if the route is mounted, discovery advertises it, regardless of runtime policy. PAR shipped this same pattern, but PAR is on by default; DCR will not be.

**How to avoid:**
- Make discovery's `registration_endpoint` claim depend on **both** the route being mounted and the runtime server policy `registration_policy != :disabled`.
- When `registration_policy == :initial_access_token`, still advertise `registration_endpoint` (the endpoint exists for token-bearing callers) but document the requirement in SECURITY/docs and in the error response when called without a token (HTTP 401, with `WWW-Authenticate: Bearer realm="register"`).
- Add a discovery contract test for each combination: `disabled → no claim`, `initial_access_token → claim present + 401 without token`, `open → claim present + 201 without token`.
- Mirror the pattern PAR uses for truthful claims; do not invent a new mechanism.

**Warning signs:**
- Discovery test asserts `registration_endpoint` is *always* present when the route is mounted.
- No test exercises the "policy disabled but route mounted" combination.
- SECURITY.md describes DCR as "always available" or "always disabled" without naming the policy switch.

**Phase to address:**
Phase 3 (truthful discovery + docs). But it must be planned in parallel with Phase 1 (policy model), because the discovery rule depends on the policy field shape.

---

### Pitfall 10: Provenance confusion between operator-tended and self-registered clients

**What goes wrong:**
Admin LiveView shows all clients in one list. An operator looks at the show page for a partner-registered client, sees the redirect URIs, and believes the operator team approved them. Six months later the partner pivots to a phishing redirect; the audit trail says "client created" with no actor and no provenance, and post-incident review cannot tell whether ops let this through.

**Why it happens:**
Lockspire's `Clients.create_client/1` audit event currently fills `actor` from `actor_from_attrs(attrs)` and defaults to `:operator` (see `lib/lockspire/admin/clients.ex` lines 450-472). DCR-created clients without a provenance fix would log `actor.type == :operator` for an event the operator never performed. This is worse than no provenance: it's *false* provenance.

**How to avoid:**
- Add a `provenance` field to `Lockspire.Domain.Client` with values `:operator | :dcr_initial_access_token | :dcr_open`. DCR registrations set it explicitly; admin creations set it to `:operator`.
- The audit event for DCR creation MUST set `actor.type` to `:dcr` (not `:operator`), and include the IAT id (if any) and the source IP. Update `actor_from_attrs/1` so the `:operator` default cannot be hit by an unauthenticated DCR call.
- Admin LiveView MUST badge DCR-registered clients distinctly. The show page MUST expose: provenance, IAT used (or "anonymous"), source IP (or anonymized), registration timestamp, last `registration_access_token` rotation, last management call.
- Add a filter `provenance: [:operator | :dcr_*]` in the list view so operators can answer "show me everything a partner self-registered this week."
- Telemetry event names: emit `[:lockspire, :client, :dcr_registered]` distinct from `:client_created`, with a metadata field `provenance: :dcr_*`. Do not piggyback on the existing `:client_created` telemetry without a provenance label, or downstream dashboards will conflate the two populations.

**Warning signs:**
- The clients index in admin LiveView shows the same row template for both populations.
- Audit query "give me all DCR registrations from yesterday" cannot be answered without a JOIN.
- Telemetry event `:client_created` has no `provenance` label.

**Phase to address:**
Phase 4 (admin UI provenance + auditing). Schema field added in Phase 1 (intake) so later phases can rely on it.

---

### Pitfall 11: No scope/redirect/grant *enforcement* on the policy allowlist

**What goes wrong:**
Operator configures `dcr_allowed_scopes: ["openid", "profile", "email"]`. A partner registers with `scope: "openid profile email admin write:everything"`. DCR stores the requested scopes verbatim because the validator only warns. Later, the partner gets `admin` scope on every consent because Lockspire trusts `client.allowed_scopes` at the consent step.

**Why it happens:**
RFC 7591 §2 lets the server "replace any invalid values" or "modify the registration metadata", which sounds permissive — implementers ship a version that accepts client-requested values without intersecting them against operator policy. The PingAM and Curity docs both note that operator policy must be *enforced*, not just *advertised*.

**How to avoid:**
- Server policy contains four allowlists: `dcr_allowed_scopes`, `dcr_allowed_redirect_uri_schemes` (default `["https"]`, optionally `["https", "http-localhost"]`), `dcr_allowed_grant_types` (default `["authorization_code", "refresh_token"]`), `dcr_allowed_token_endpoint_auth_methods` (default `["client_secret_basic", "client_secret_post"]` — `none` only when the operator opts in for public clients).
- DCR intake **intersects** registrant-requested values with the allowlist; the stored client gets the intersection, not the requested set.
- If the intersection is empty for a required field, return `invalid_client_metadata` with a message naming the allowlist.
- Admin LiveView surfaces the intersection result on first registration response so the partner sees what they actually got.
- Audit event includes both `requested_*` and `granted_*` so post-hoc forensics can answer "did the partner ask for `admin` scope?"

**Warning signs:**
- A registration test passes with a scope that is not in `dcr_allowed_scopes`.
- The audit log only records the granted set, not the requested set.
- The allowlist is configured in code (compile-time) instead of in operator-tended `ServerPolicy` (runtime).

**Phase to address:**
Phase 1 (policy model) defines the allowlist shape; Phase 1 (intake) does the intersection; Phase 4 (admin UI) makes the allowlist editable.

---

### Pitfall 12: Audit and telemetry blind spots

**What goes wrong:**
After a DCR-related security incident, the operator runs a post-mortem and finds: no record of who issued the IAT used to register the offending client, no record of registration_access_token rotations, no record of the management calls that changed `redirect_uris` last week, no record of the source IP for any DCR call. The "operationally trustworthy" claim collapses.

**Why it happens:**
DCR adds a whole new event surface that the existing telemetry vocabulary does not name. Implementers extend `client_created` and call it done. They miss that DCR has a *lifecycle* — IAT mint, IAT use, registration, every read, every update, every rotation, every delete, every rejected attempt — and the lifecycle must be auditable end-to-end.

**How to avoid:**
Auditable events MUST cover the full DCR lifecycle. At minimum (each as both a telemetry event and a durable audit row):

- `:dcr_initial_access_token_minted` — actor (operator), IAT id, expires_at, allowed_scopes-floor, allowed_redirect-uri-pattern (if any), bound_to_email (optional)
- `:dcr_initial_access_token_used` — IAT id, source IP, resulting client_id, outcome (succeeded/rejected with reason)
- `:dcr_initial_access_token_revoked` — actor, IAT id, reason
- `:dcr_registered` — provenance, source IP, client_id, requested vs granted metadata diff
- `:dcr_registration_rejected` — source IP, IAT id (if any), reason_code (`invalid_client_metadata`, `invalid_redirect_uri`, `policy_violation`, `rate_limited`), rejected fields
- `:dcr_read` — client_id, source IP, registration_access_token rotated? (true/false)
- `:dcr_updated` — client_id, source IP, diff (granted-vs-previous)
- `:dcr_registration_access_token_rotated` — client_id, trigger (`update`/`delete`/`forced_by_operator`)
- `:dcr_deleted` — client_id, source IP, actor (partner via RAT vs operator via admin)
- `:dcr_unauthorized_management_attempt` — client_id from URL, presented_token_hash_prefix (first 8 chars only), source IP — this is the RFC 7592 §2.1 case where token MUST be revoked

**Required properties of the audit row:**
- Every row is durable (Postgres) and immutable.
- Every row has a stable `reason_code` atom that downstream dashboards can group on.
- Telemetry payloads MUST NOT contain the raw IAT or RAT — only their hash prefix or DB id.
- Source IP MUST be captured (with a documented rule for handling `X-Forwarded-For` from trusted proxies).

**Warning signs:**
- Only `:client_created` is emitted on DCR registration.
- Audit row has no `source_ip` column.
- IAT lifecycle has no audit trail at all (no mint event, no revoke event).

**Phase to address:**
Phase 4 (admin UI + provenance + audit). The event vocabulary should be defined alongside the schema in Phase 1, and emitted from Phase 1 onward, but the operator-facing audit *view* lands in Phase 4.

---

### Pitfall 13: Abandoned-client buildup and no expiry

**What goes wrong:**
Partners register clients during integration spikes, then forget. After 18 months, the `clients` table has 5,000 rows of which 200 are real. The admin index is unusable, JWKS rotation cycles take longer than they should, and a half-abandoned client gets its secret rotated by a partner who recovered it via leaked email — and surfaces as an active partner integration.

**Why it happens:**
RFC 7591 has no expiry semantics. RFC 7592 has no idle-cleanup semantics. Implementers ship without lifecycle policy and the durable storage grows without bound. Curity, Connect2id, and the WorkOS DCR write-up all flag this as the long-term operational sting.

**How to avoid:**
- Add an optional `client_expires_at` column. DCR can set a default expiry (operator-policy-controlled, e.g. "DCR clients expire 90 days after creation unless used"). Operator-tended clients have `nil` expiry by default.
- Track `last_used_at` (last successful authorization or token call). A scheduled `Lockspire.Maintenance.Dcr` job (Oban or `Phoenix.Endpoint`-managed periodic task) flags clients with `last_used_at IS NULL AND inserted_at < now() - interval '<grace>'` for review, not auto-delete.
- Admin LiveView surfaces "DCR clients with no recent activity" as a filter and allows bulk-disable (not delete — operator must still confirm delete for audit-trail reasons).
- Auto-delete is opt-in via operator policy; default is operator-confirmed delete after warning, so audit chains are not broken by surprise garbage collection.
- Document the cleanup job in `docs/operator-admin.md` so operators know it runs.

**Warning signs:**
- No `last_used_at` column.
- The "abandoned client" question cannot be answered with one Ecto query.
- Cleanup is auto-delete by default with no operator review.

**Phase to address:**
Phase 4 (admin provenance + auditing) for the visibility; cleanup job can be Phase 5 (closure) if scope-tight, but the schema fields (`client_expires_at`, `last_used_at`) MUST be added in Phase 1 to avoid a migration rush.

---

### Pitfall 14: RFC 7592 deletion that breaks audit chains

**What goes wrong:**
`DELETE /register/:client_id` hard-deletes the client row. The next morning, the audit query "what client_id issued this token?" returns "client not found" and the audit chain breaks. Or worse: a deleted DCR client_id is later reused by a different partner registration, and the auditing aliases two distinct partners under one identifier.

**Why it happens:**
RFC 7592 §2.3 says "The authorization server MAY allow deregistration through this method", and implementers read it as "delete row." But Lockspire already has `disabled_at` / `disabled_by` semantics for operator-tended clients (see `disable_client_with_audit/4`). DCR delete should ride that same rail.

**How to avoid:**
- `DELETE /register/:client_id` performs a soft-disable: sets `active: false`, `disabled_at`, `disabled_by: "dcr_self_delete"`, and revokes the registration_access_token. The row stays.
- The `client_id` is never reused. Generate `client_id` via `:crypto.strong_rand_bytes` so reuse is statistically impossible anyway.
- Hard-delete is operator-only via admin LiveView and only after the operator confirms (existing pattern).
- Audit event `:dcr_deleted` records the soft-disable; a separate `:client_purged` is the operator-only hard delete.
- Add a contract test: `client_id` from a deleted DCR registration cannot be re-registered.

**Warning signs:**
- DCR delete handler calls `Repo.delete/1` directly.
- A test passes that re-registers the same `client_id` after delete.

**Phase to address:**
Phase 2 (RFC 7592 management). Reuses existing `disable_client_with_audit/4` from `lib/lockspire/admin/clients.ex`.

---

### Pitfall 15: Initial access token leakage paths and scope escalation

**What goes wrong:**
The operator mints an IAT scoped to "register one client with redirect_uri matching `https://partnerA.example.com/*`", but the IAT once leaked allows registering N clients with arbitrary redirect URIs. Or: the IAT is single-use but the underlying constraints (allowed scopes, allowed redirects, expiry) are not actually enforced server-side at registration.

**Why it happens:**
RFC 7591 §3 is vague: "How the authorization server initially issues this token to the client or developer is out of scope." Implementers ship the IAT as a generic bearer token without per-IAT constraints and without single-use semantics.

**How to avoid:**
- IATs are durable, hashed, single-use by default (operator can opt for N-use).
- IAT carries optional constraints embedded in the durable record: max number of uses, expiry, allowed redirect-URI scheme/host pattern, allowed scope intersection, expected partner email/contact.
- At registration time, DCR enforces every IAT constraint before accepting metadata. If the registrant requests a redirect URI outside the IAT's allowed pattern, reject — the IAT is the policy carrier, not just an auth token.
- Admin LiveView shows live IATs with: who minted, when, expires_at, uses_remaining, constraints, last use. Operator can revoke any IAT.
- Audit `:dcr_initial_access_token_minted` and `:dcr_initial_access_token_used` events as listed in Pitfall 12.

**Warning signs:**
- An IAT can be reused N times when operator selected "one-shot" at mint.
- IAT redirect-URI constraint is documented but not enforced server-side.

**Phase to address:**
Phase 1 (policy + IAT model) for the durable IAT; Phase 4 (admin UI) for the mint/revoke surface.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Ship DCR enabled by default to look feature-complete | Faster demo of "we have DCR" | Self-registration abuse, false provenance, broken trust posture | Never. v1.5 closes with default-off. |
| Reuse `:client_created` telemetry for DCR | One less event name to plumb | Dashboards conflate operator and DCR populations; provenance lost | Never |
| Skip allowlist intersection, accept registrant request as-is | Smaller validator | Privilege escalation via overscoped registration | Never |
| Hard-delete on RFC 7592 DELETE | Simpler implementation | Broken audit chain, possible client_id reuse | Never — soft-disable |
| Ship without `last_used_at` | One fewer migration | No way to find abandoned clients later | Never — add it now |
| Treat IAT like a session token | Reuse existing bearer plumbing | Leakage = full admin-equivalent self-mint privilege | Never |
| Defer SSRF protection on `jwks_uri` to "later phase" | Faster JAR-trust path | Internal-network compromise via metadata fetch | Never |
| Defer rate limiting to v1.6 | Smaller v1.5 surface | DDoS exhausts client table on day one if `:open` is enabled | Acceptable only if v1.5 ships with default `:disabled` and rate limit blocks the `:open` path from being chosen until v1.6 |
| Discover `registration_endpoint` purely from route mount | Mirror existing PAR pattern | Discovery lies whenever policy disables registration | Never — must factor in policy |
| Accept both `jwks` and `jwks_uri` "to be lenient" | Maximal interop | Key-confusion attack, JAR trust break | Never |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Existing `Clients.create_client/1` | Build a parallel DCR-only create path | Funnel DCR into the same `register_client/1` boundary, with provenance set by the caller |
| Existing audit pipeline (`transact_with_audit/2`) | Skip audit because DCR isn't operator-driven | Wrap every DCR mutation in `transact_with_audit` with a DCR-flavored event |
| Existing PAR policy (`par_policy: :inherit`) | DCR clients silently inherit weakest global setting | Add `dcr_min_par_policy` floor in `ServerPolicy`; the higher of (global, dcr_min) applies |
| Existing JAR policy (v1.4 inline-jwks rule) | Allow `jar_policy: :required` on a client whose only key material is `jwks_uri` | Keep `validate_jar_policy_if_present/2` rule and reject the combination at DCR intake |
| Existing discovery (`mounted_route_paths/0`) | Assume route mount = advertise | Combine route mount with runtime `registration_policy` check |
| Existing `disable_client_with_audit/4` | Bypass for RFC 7592 DELETE | Reuse it, with `actor: %{type: :dcr_self}` |
| Existing telemetry actor defaults | DCR call falls through to `actor_type: :operator` | Make `actor_from_attrs/1` reject `nil` actor on DCR paths and require an explicit `:dcr` actor type |
| Phoenix LiveView admin index | Treat all clients as one population | Filter+badge by `provenance` from day one |
| Existing `client_id` generation | Reuse short or guessable identifiers | Use `:crypto.strong_rand_bytes(16) \|> Base.url_encode64(padding: false)` or equivalent so DCR client_ids are unguessable |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Unbounded `clients` rows from anonymous DCR | Slow admin index, slow client lookups | Default `:disabled`, rate limit, `Max Clients` policy ceiling, abandoned-cleanup job | First DDoS or first runaway integration script (Day 1 of `:open` mode) |
| `sector_identifier_uri` fetch in request path | Slow registration p99 | Fetch once, validate, cache result; do not refetch on read/update | Partner with high-latency CDN |
| Audit row spike from `:dcr_unauthorized_management_attempt` events | Audit table growth from probing scanners | Rate-limit + dedupe by source IP within a window before inserting audit row | First time the issuer is on a public scanner list |
| LiveView `clients` index loading every DCR field | Slow admin page | Lazy-load DCR-only fields (RAT rotation history, IAT history) on show page only | At ~500 clients with full eager-load |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Storing `registration_access_token` plaintext | Token leak = full client config takeover | Hash like `client_secret_hash`, show plaintext only on issue/rotate |
| Looking up RAT without `client_id` URL binding | Cross-tenant management via stolen token | Require both URL `client_id` and token hash to match in one query |
| Returning RAT in any error message or telemetry | Token leak via logs | Redaction filter; test that asserts RAT cannot appear in any `Logger` or telemetry payload |
| Accepting `client_id` chosen by registrant | Squatting on existing client_ids, audit confusion | Always server-generate via `:crypto.strong_rand_bytes/1` |
| Trusting registrant `client_secret` if provided | Bypasses hashing pipeline | Always server-generate, hash with `Clients.rotate_secret_hash/0`, return plaintext once |
| SSRF via `jwks_uri` / `sector_identifier_uri` | IdP becomes private-network probe | https-only, public-IP-only, body-size cap, no redirects, short timeout |
| `logo_uri` / `tos_uri` rendered without CSP | XSS / clickjacking via partner-controlled URL | Validate but never fetch; render under strict CSP |
| Accept `subject_type: pairwise` without sector validation | User correlation attack across sectors | Either reject pairwise outright in v1.5 OR fully implement sector_identifier_uri validation per OIDC §5 |
| RFC 7592 DELETE without revoking RAT | Stale RAT can no-op-fail repeatedly, mask the deletion | Revoke RAT atomically in same transaction as soft-disable |
| Lower PKCE for DCR clients | Auth-code interception attack | Hard-code `pkce_required: true` for all DCR clients with no policy escape |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| RFC 7591 response missing required fields | Partner cannot use the client_secret/RAT they were just issued | Return the full RFC 7591 §3.2.1 response: `client_id`, `client_secret` (if confidential), `client_id_issued_at`, `client_secret_expires_at` (RFC says `0` for non-expiring), `registration_access_token`, `registration_client_uri`, plus echoed metadata |
| RFC 7591 errors in non-standard JSON shape | Partner SDKs cannot parse | Use exactly `{"error": "...", "error_description": "..."}` with RFC-defined error codes (`invalid_redirect_uri`, `invalid_client_metadata`, `invalid_software_statement` — the last only meaningful as a "not supported" rejection in v1.5) |
| Operator must edit code to enable DCR | Bad operator UX, breaks embedded-library promise | Toggle in admin LiveView, durable in `ServerPolicy` |
| Operator cannot tell DCR clients from operator clients | False sense of curated trust | Provenance badge on every client row |
| Partner not told what the allowlist intersected away | Confused partner, support tickets | Response includes the granted (intersected) values; documentation explains operator policy can narrow requests |
| `client_secret_expires_at` returned as something other than `0` for non-expiring secrets | Partner SDKs over-rotate or break | Per RFC 7591 §3.2.1, value `0` means "does not expire" — emit exactly `0`, not `null` or absent |
| Locking partners out by rotating RAT on every read | Partners cannot poll their config | Rotate only on update/delete |

## "Looks Done But Isn't" Checklist

- [ ] **`POST /register`:** Often missing rate limiting and IAT enforcement — verify default mode is `:disabled` and `:initial_access_token` is the recommended on-mode.
- [ ] **`GET/PUT/DELETE /register/:client_id`:** Often missing the URL-`client_id`-vs-token binding check — verify a stolen token cannot operate on a different client_id.
- [ ] **`registration_access_token`:** Often stored plaintext — verify the column is `registration_access_token_hash` and the test for plaintext leakage exists.
- [ ] **Discovery:** Often advertises `registration_endpoint` even when policy disables it — verify the three-mode discovery contract test exists (disabled / IAT / open).
- [ ] **Admin UI:** Often shows DCR and operator clients identically — verify provenance badge present and a filter exists.
- [ ] **Audit:** Often only `:client_created` exists — verify the full DCR lifecycle vocabulary from Pitfall 12 emits durable rows.
- [ ] **Allowlist:** Often advertised but not enforced — verify intersection happens server-side and rejection messages name the allowlist.
- [ ] **`jwks` / `jwks_uri`:** Often both accepted — verify mutual-exclusion test.
- [ ] **`grant_types` / `response_types`:** Often accepted incoherently — verify coherence matrix and unsupported-grant rejection.
- [ ] **`token_endpoint_auth_method`:** Often wider than discovery — verify discovery is the truth source.
- [ ] **PKCE:** Often inheritable — verify DCR clients are always `pkce_required: true`.
- [ ] **SSRF:** Often missed for `jwks_uri` and `sector_identifier_uri` — verify private-IP rejection test exists.
- [ ] **DELETE:** Often hard-delete — verify soft-disable and that deleted client_ids are not reusable.
- [ ] **Cleanup:** Often missing — verify `last_used_at` and `client_expires_at` columns exist and an "abandoned clients" admin filter exists.
- [ ] **`subject_type: pairwise`:** Often half-implemented — verify either fully supported (with `sector_identifier_uri` validation) or explicitly rejected.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Self-registration enabled by accident in production | HIGH | Flip `registration_policy: :disabled`, audit all DCR-created clients in window, soft-disable suspicious ones, force-rotate any RATs, post-incident review of all `:dcr_registered` events |
| `registration_access_token` leaked | MEDIUM | Rotate RAT for the affected client (admin-forced), notify partner, audit `:dcr_*` events for that client_id since suspected leak time |
| Plaintext RAT in logs | MEDIUM | Force-rotate every RAT issued before fix; redact log archives where feasible; add redaction test as regression |
| SSRF via `jwks_uri` confirmed | HIGH | Identify all clients with `jwks_uri` set, fetch and verify each from outside the network, soft-disable any pointing to private ranges, add rejection rule, post-incident review for what the IdP fetched and what was reflected back |
| Phishing redirect URI registered via DCR | HIGH | Soft-disable the client immediately, revoke active tokens for it, audit who issued the IAT (if any), tighten allowlist, notify users who consented |
| `clients` table flooded by anonymous DCR | MEDIUM | Disable `:open` mode, soft-disable rows where `last_used_at IS NULL AND provenance = :dcr_open AND inserted_at > <flood window>`, add rate limit, raise Max Clients ceiling investigation |
| Discovery mismatch (advertised but disabled) | LOW | Fix discovery factory test and ship a patch release; document in CHANGELOG |
| Partner locked out by RAT rotation bug | LOW | Operator-mint a replacement RAT via admin LiveView; document the rotation rule; partner re-issues their automation |

## Pitfall-to-Phase Mapping

Suggested mapping for the v1.5 roadmap. Phase numbering follows the milestone's likely 5-phase shape (intake/policy → 7592 management → discovery+docs → admin UI/audit → closure).

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| 1. Self-registration governance | Phase 1 | Default-off contract test; rate-limit firing test; IAT-required test |
| 2. RAT storage and rotation | Phase 2 | Plaintext-leakage redaction test; rotation-on-update-only test; URL-`client_id`-binding test |
| 3. SSRF via fetched URIs | Phase 1 | Private-IP rejection tests for `jwks_uri` and `sector_identifier_uri`; admin-render CSP test |
| 4. `jwks` vs `jwks_uri` mutual exclusion | Phase 1 | Negative test; JAR-coherence test (`:required` cannot land with only `jwks_uri`) |
| 5. Redirect URI exact matching | Phase 1 | Property test parity between DCR and admin update paths |
| 6. `grant_types`/`response_types` coherence | Phase 1 | Coherence matrix test; default-application test |
| 7. `token_endpoint_auth_method` truth | Phase 1 | Invariant test against discovery enum |
| 8. PKCE/PAR/JAR floor for DCR | Phase 1 (intake), Phase 2 (update) | Cannot-lower-PKCE test; `dcr_min_par_policy` enforcement test |
| 9. Discovery truthfulness | Phase 3 | Three-mode discovery contract test |
| 10. Provenance confusion | Phase 1 (schema), Phase 4 (UI) | Audit-event-actor-type test; admin filter test |
| 11. Allowlist enforcement | Phase 1 | Intersection test; audit-records-requested-vs-granted test |
| 12. Audit/telemetry blind spots | Phase 1 (events), Phase 4 (operator surface) | Each event in vocabulary has a test that asserts it emits |
| 13. Abandoned clients | Phase 1 (schema), Phase 4 (admin filter) | `last_used_at` updates on every successful auth; abandoned-filter test |
| 14. RFC 7592 DELETE soft-disable | Phase 2 | Soft-disable test; cannot-reuse-client_id test |
| 15. IAT leakage and scope escalation | Phase 1 (model), Phase 4 (admin) | IAT single-use test; IAT constraint enforcement test; admin mint/revoke test |

## Sources

- RFC 7591: OAuth 2.0 Dynamic Client Registration Protocol — https://www.rfc-editor.org/rfc/rfc7591
- RFC 7592: OAuth 2.0 Dynamic Client Registration Management Protocol — https://www.rfc-editor.org/rfc/rfc7592
- OpenID Connect Dynamic Client Registration 1.0 (final) — https://openid.net/specs/openid-connect-registration-1_0.html
- OpenID Connect Core 1.0 §5 (sector_identifier_uri) — https://openid.net/specs/openid-connect-core-1_0.html
- Curity DCR Overview — https://curity.io/resources/learn/openid-connect-understanding-dcr/
- Curity Pairwise Pseudonymous Identifiers — https://curity.io/resources/learn/ppid/
- Connect2id Client Registration Endpoint — https://connect2id.com/products/server/docs/api/client-registration
- Keycloak Client Registration Service — https://www.keycloak.org/securing-apps/client-registration
- Keycloak anonymous DCR scalability discussion — https://github.com/keycloak/keycloak/discussions/46037
- PingAM Dynamic Client Registration — https://docs.pingidentity.com/pingam/8/am-oidc1/oauth2-dynamic-client-registration.html
- Okta client-based rate limits — https://developer.okta.com/docs/reference/rl2-client-based/
- Duende IdentityServer DCR — https://docs.duendesoftware.com/identityserver/configuration/dcr/
- WorkOS DCR write-up (incl. abandoned clients) — https://workos.com/blog/dynamic-client-registration-dcr-mcp-oauth
- ScaleKit DCR overview — https://www.scalekit.com/blog/dynamic-client-registration-oauth2
- Descope DCR primer — https://www.descope.com/learn/post/dynamic-client-registration
- MCP discovery+DCR inconsistency report — https://github.com/modelcontextprotocol/inspector/issues/752
- VS Code DCR-disable feature request — https://github.com/microsoft/vscode/issues/257415
- fastmcp grant-types coherence bug — https://github.com/jlowin/fastmcp/issues/2460
- Lockspire `lib/lockspire/admin/clients.ex` (existing audit + validation seams)
- Lockspire `lib/lockspire/admin/server_policy.ex` (existing policy shape to extend)
- Lockspire `lib/lockspire/protocol/discovery.ex` (existing discovery factory to extend)
- Lockspire `lib/lockspire/domain/client.ex` (existing domain typespec — wider than discovery, see Pitfall 7)
- Lockspire `.planning/milestones/v1.3-REQUIREMENTS.md` (PAR policy precedent for DCR policy shape)
- Lockspire `.planning/PROJECT.md` (Constraints: PKCE S256, exact redirect, hashed secrets, no implicit, no `alg=none`)

---
*Research completed: 2026-04-25*
*For: v1.5 Dynamic Client Registration milestone*
*Downstream consumers: v1.5 requirements pass and roadmapper*
