---
phase: 99
phase_name: "signer-extraction-jwt-default-issuance"
project: "Lockspire"
generated: "2026-05-28"
counts:
  decisions: 12
  lessons: 9
  patterns: 12
  surprises: 6
missing_artifacts:
  - "99-UAT.md"
---

# Phase 99 Learnings: signer-extraction-jwt-default-issuance

## Decisions

### Server default is concrete `:jwt`; per-client override is nullable `nil`-as-inherit
The server-wide `ServerPolicy.access_token_format` defaults to `:jwt` and is never nullable; the per-client `Client.access_token_format` override is nullable where `nil` means "inherit" — with no `:inherit` sentinel atom stored anywhere (D-06).

**Rationale:** Two different shapes for two different needs — a deployment-wide flip (always concrete) versus a per-client opt-out (tri-state, inherit/jwt/opaque). A sentinel atom would desync storage from display; `nil` is the canonical inherit state in both storage and the normalizer.
**Source:** 99-01-PLAN.md, 99-01-SUMMARY.md, 99-06-SUMMARY.md

### Per-client override cast in BOTH changesets, no `validate_required`, no FAPI coupling
`access_token_format` is cast in both `changeset/2` and `update_changeset/2` (the admin-mutable path) so the admin form can set it; it is deliberately excluded from `validate_required` and not coupled to `validate_fapi_metadata/1`.

**Rationale:** The admin-mutable path runs through `update_changeset/2`; omitting it there would render the form control inert. Nullability and FAPI-independence keep "inherit" a first-class state.
**Source:** 99-01-SUMMARY.md

### Unknown setter/normalizer values return a structured `{:error, _}`, never `{:ok, nil}`
`Admin.ServerPolicy.put_access_token_format/1` and the admin `normalize_access_token_format/1` reject unknown values with a structured `{:error, [%{field:, reason: :invalid_access_token_format, detail:}]}` tuple rather than silently coercing to `nil`.

**Rationale:** A forged form value (e.g. `client[access_token_format]=admin`) must not be coerced into a valid-looking inherit state; a clean field error beats a raw Ecto.Enum changeset error for operators (T-99-19).
**Source:** 99-01-SUMMARY.md, 99-06-SUMMARY.md

### Discovery alg triple is a bare literal, published unconditionally
`access_token_signing_alg_values_supported: ["RS256","ES256","PS256"]` is a static module-attribute literal in `openid_configuration/0`, NOT derived from `SecurityProfile.allowed_signing_algorithms/1`, and is present unconditionally (not gated on `token_endpoint` mounting).

**Rationale:** `allowed_signing_algorithms/1` returns the `none`/`EdDSA` superset for `:none` and the `["ES256","PS256"]` FAPI subset — neither matches the truthful triple the active signing key actually uses (D-11 / Pitfall 4). The true sibling `id_token_signing_alg_values_supported` is unconditional, so this key is too.
**Source:** 99-02-PLAN.md, 99-02-SUMMARY.md

### `aud` carve-out lives at the caller boundary, not inside the signing core
A single private `sign_jwt/2` JOSE site serves both callers: `issue/3` (grants) passes a LIST aud, `issue_exchange/4` (RFC 8693) passes a BARE STRING aud and applies the `~w(iss sub aud exp iat jti client_id)` restricted-claim drop on custom claims.

**Rationale:** Keeps exactly one `JOSE.JWT.sign` site (SC5) while preserving the RFC 8693 string-aud contract (`rfc8693_exchange_test.exs` sentinel). The signing core stays aud-agnostic.
**Source:** 99-03-PLAN.md, 99-03-SUMMARY.md

### `exp = iat + 3600` via integer arithmetic
The signer computes `exp` as `iat + 3600` directly rather than the original `DateTime.add(issued_at, 3600) |> to_unix`.

**Rationale:** Both resolve from the same `issued_at`, so integer arithmetic is exactly equivalent, keeps `exp == iat + 3600` exact for assertions, and avoids re-deriving `now` twice (the WR-02 double-`now/1` defect class).
**Source:** 99-03-SUMMARY.md, 99-VERIFICATION.md

### `Policy.hash_token/1` used for both `:jwt` and `:opaque` branches
The signer hashes both formats with `Lockspire.Security.Policy.hash_token/1` (identical SHA-256 hex to `TokenFormatter.hash_token/1`).

**Rationale:** A single hash convention keeps introspection/revocation-by-hash working regardless of issued format.
**Source:** 99-03-SUMMARY.md

### `build_access_token/6` returns a bare success 2-tuple disambiguated by a struct guard
The seam returns `{%Token{}, raw}` on success and `{:error, %Error{}}` on signer failure; callers match `{%Token{} = access_token, raw}` so the error 2-tuple falls through to the `with` `else` clause rather than being mis-bound as success.

**Rationale:** The internal contract is a 2-tuple (Pitfall 1), and `{:error, %Error{}}` is also a 2-tuple — a struct-guarded first element is the cleanest split without inventing a tagged success shape.
**Source:** 99-04-PLAN.md, 99-04-SUMMARY.md

### Device/CIBA empty-authorized set accepts any binary resource
`validate_grant_resources/2` accepts any binary resource when the grant's authorized audience set is empty (matching AC's `requested == [] -> {:ok, authorized}`), and rejects out-of-set resources only when a recorded audience exists.

**Rationale:** Device and CIBA grants record no authorized audience today (no domain field), so AUD-01 must still work; the rejection branch (T-99-11) is reachable through AC and exercised on device/CIBA via a `@doc false` test seam.
**Source:** 99-04-PLAN.md, 99-04-SUMMARY.md

### Sign the refresh access token BEFORE the rotation transaction
`rotate_refresh_token_with_audit/6` builds the rotated `%Token{}`, calls the signer, re-points `token_hash` to the signer's hash, THEN runs the rotation transaction.

**Rationale:** The signer needs the assembled `%Token{}` to derive `sub`/`scope`/`aud`/`cnf`, and the persisted hash must equal `Policy.hash_token(jwt)` (Pitfall 1). The refresh token itself is still minted via `TokenFormatter`; only the access token moved to the signer.
**Source:** 99-05-PLAN.md, 99-05-SUMMARY.md

### Reversible override does NOT borrow the `lockspire-admin-warning` block
The admin `access_token_format` surface deliberately omits the `lockspire-admin-warning` styling used by the FAPI mixed-mode security downgrade.

**Rationale:** This override is reversible and non-destructive (UI-SPEC Color); the warning block is reserved for irreversible/security-downgrade actions.
**Source:** 99-06-PLAN.md, 99-06-SUMMARY.md

### CR-01 resolved by fix-now rather than accept-and-track
The latent `MatchError` on a corrupt stored signing key was fixed (with/else mirroring `IdToken.sign/1`, structured `:token_signing_failed` 500, regression tests), not deferred.

**Rationale:** The code review rated it Critical because the JWT-default flip made the crash reachable on every grant path; the user elected to fix it (commits 6134f75, 9b05f46) rather than accept the error-path risk for v1.27.
**Source:** 99-VERIFICATION.md

---

## Lessons

### Flipping the default to `:jwt` broke every test that minted without a seeded signing key
Existing AC/device/CIBA/refresh success tests began returning `500 :signing_key_not_found` because they never published an active signing key — the opaque default had never needed one.

**Context:** The fix split tests into two groups: shape-agnostic tests publish a signing key (exercising the JWT default); opaque-shape tests opt clients into `access_token_format: :opaque` and look up the persisted token by the issued token's hash. This breakage is a direct, expected consequence of the deliverable, not scope creep.
**Source:** 99-04-SUMMARY.md, 99-05-SUMMARY.md

### The CIBA Push worker signs with `request == %{}`, exposing a TestRepo gap
The Push worker issues tokens with an empty request, so `AccessTokenSigner` falls back to `Config.repo!()` (= `Lockspire.TestRepo` in tests) for the key store — and `TestRepo` did not define `fetch_active_signing_key/0`, so signing crashed and the Push authorization never reached `:consumed`.

**Context:** Production `Config.repo!()` is the real `Repository` (which has the function), so this was a test-infra-only gap surfaced by the JWT default. Fixed by delegating `fetch_active_signing_key/0` from `TestRepo` to `Repository`, matching its existing delegation pattern.
**Source:** 99-04-SUMMARY.md

### A rendered LiveView form `<select>` is inert until wired through `edit_attrs/2`
Adding the override `<select>` to `form_component.ex` was not enough — the admin edit-form submit is bridged to `Admin.update_client` exclusively through `edit_attrs/2` in `show.ex`, which did not extract `access_token_format`.

**Context:** Without `access_token_format: params["access_token_format"]` in `edit_attrs/2`, the must-have "saving it persists nil/:jwt/:opaque" silently failed. This was a plan gap (Task 2 listed only `form_component.ex`), auto-fixed within the plan's declared file set.
**Source:** 99-06-SUMMARY.md

### The rotated refresh token has `account_id: nil` (Pitfall 5)
`build_rotated_access_token` set `account_id: nil`, which would mint an at+jwt with `sub: nil` and fail the Phase 98 verifier's `:missing_sub` check.

**Context:** The subject (and scopes) must be sourced from `presented_refresh_token` before signing. The rotated refresh token's own `account_id` stays `nil` — the Repository back-fills it at persistence — so only the access-token assembly needed the explicit source.
**Source:** 99-05-PLAN.md, 99-05-SUMMARY.md

### The five mint seams did not share a return shape (Pitfall 1)
`build_access_token/6` returns a 2-tuple `{%Token{}, raw}`, not the signer's `{:ok, raw, hash}` — so re-pointing required setting `%Token{token_hash: hash}` from the signer's returned hash, not a literal one-liner swap.

**Context:** Misreading this would have stored a hash that didn't match the issued token, breaking introspection/revocation-by-hash (T-99-12).
**Source:** 99-04-PLAN.md

### Device and CIBA needed NET-NEW resource validation, not propagation (Pitfall 2)
Both `build_device_grant` and `build_ciba_grant` hardcoded `audience: []`; neither `redeem_device_grant/5` nor `redeem_ciba_grant/5` called any resource validator — unlike AC, which already threaded `resource`.

**Context:** AUD-01 for device/CIBA was genuinely new wiring (a `validate_requested_resources`-shaped guard), not a propagation of existing AC behavior. The plan explicitly warned against inventing a parallel validator — reuse the AC `cond` shape.
**Source:** 99-04-PLAN.md, 99-04-SUMMARY.md

### A hard match on a decoded JWK raises `MatchError` on a corrupt key (CR-01)
`{:ok, jwk_map} = decode_private_jwk(private_jwk)` had no `with`/`else`; `fetch_signing_key/1` only guarantees the encrypted blob is a binary, not that it decodes — so a stored-but-corrupt active key raised an uncaught 500 with a stacktrace instead of the promised structured error.

**Context:** The JWT-default flip routed AC/refresh/device/CIBA through this match, widening the blast radius from one path to all of them. No test covered the error path until the fix. `IdToken.sign/1` already had the correct `with`/`else` shape to mirror.
**Source:** 99-VERIFICATION.md

### Behaviour-arity drift can pass tests yet break a faithful host (WR-01)
The signer called `fetch_active_signing_key()` at arity 0 while the KeyStore behaviour contract is arity 1 — it works because `Repository` has a default-arg and the test mock defined arity 0, but a faithful arity-1 host `:key_store` would raise `UndefinedFunctionError`.

**Context:** Fixed to call arity-1 per the contract, with mocks updated as a regression guard. A pre-existing sibling at `token_exchange.ex:1232` (ID-token path) remains arity-0 and was deferred as out-of-scope.
**Source:** 99-VERIFICATION.md

### Full-form submits trip unrelated validations
The edit-form persist test initially failed because the test client's pre-filled `allowed_scopes: ["openid"]` is rejected on update (`"openid"` is reserved), and the form submit carries all fields — so the unrelated scope validation short-circuited the update before the `access_token_format` write.

**Context:** A test-fixture issue, not a code defect — resolved by submitting a valid `allowed_scopes: "email"`. Worth remembering when testing a single field on a LiveView form that posts the whole record.
**Source:** 99-06-SUMMARY.md

---

## Patterns

### Single JOSE sign site with boundary-level aud carve-out
One private `sign_jwt/2` is the only `JOSE.JWT.sign` site in the library; list-aud and string-aud callers both funnel through it, and the aud shape is decided by the caller (`issue/3` vs `issue_exchange/4`).

**When to use:** Whenever multiple callers need slightly different claim shapes but must share one signing implementation — keep the divergence at the boundary, not in the core (SC5 single-signer invariant).
**Source:** 99-03-SUMMARY.md

### Precedence resolver adapted from `SecurityProfile`, `:inherit` → `nil`
`resolve_format/2` copies the `SecurityProfile.resolve_effective_profile/2` precedence shape but branches on `nil` (per-client override → server default → `:jwt`) instead of an `:inherit` sentinel.

**When to use:** Resolving a per-client-overridable runtime policy backed by a nullable column.
**Source:** 99-03-PLAN.md, 99-03-SUMMARY.md

### `maybe_put_cnf/2` — conditional claim copy
The minted JWT copies `%Token{}.cnf` only when non-nil, so opaque/no-binding tokens stay clean and DPoP/mTLS-bound tokens carry the confirmation claim.

**When to use:** Copying an optional binding/claim that must be absent (not null) when not present — prerequisite for Phase 100 sender-constraint verification.
**Source:** 99-03-SUMMARY.md

### `%Token{}`-guarded `with`-clause to split success from error 2-tuples
When a function returns a bare success 2-tuple and an `{:error, %Error{}}` 2-tuple, match the success with a struct guard on the first element (`{%Token{} = t, raw}`) so the error tuple routes to the `with` `else`.

**When to use:** Disambiguating two same-arity tuples without introducing a tagged `{:ok, ...}` wrapper that would ripple through callers.
**Source:** 99-04-SUMMARY.md

### Shared resource-validation `cond` reused across grant paths with a carve-out clause
AC/device/CIBA all reuse the AC `validate_requested_resources/2` `cond` shape; the carve-out is a single clause: empty authorized set → accept any binary, non-empty set → enforce membership.

**When to use:** Adding `resource=`→`aud` validation to additional grant paths — extend the shared validator, do not fork a parallel one.
**Source:** 99-04-SUMMARY.md

### Mint-before-persist for refresh rotation
Build the rotated `%Token{}`, sign it, re-point `token_hash` to the signer's hash, then run the persistence transaction.

**When to use:** Any mint path where the signer needs the fully-assembled token AND the persisted hash must equal the hash of the issued artifact.
**Source:** 99-05-SUMMARY.md

### Per-client nullable `Ecto.Enum` override cast in both changesets
A nullable `Ecto.Enum` field (`nil` = inherit) that mirrors `id_token_signed_response_alg` field-for-field: schema, `changeset/2`, `update_changeset/2`, and `to_domain/1` — paired with a `:text` DB column.

**When to use:** Adding a tri-state per-client policy override that an operator can edit and that round-trips record↔domain.
**Source:** 99-01-SUMMARY.md

### Runtime `ServerPolicy` `Ecto.Enum` with concrete default + `put_X/1` setter
A server-wide policy field with a concrete (never-nil) default, mirroring `security_profile`/`dpop_policy`, plus an `Admin.ServerPolicy.put_X/1` runtime setter that normalizes and persists via `update_server_policy/1`.

**When to use:** A deployment-wide, operator-flippable policy knob that must always resolve to a concrete value.
**Source:** 99-01-SUMMARY.md

### Hybrid mutable-field normalizer (atom-cast + nil-cast)
`normalize_access_token_format/1` combines two existing idioms: the `dpop_policy` select-idiom for `jwt`/`opaque` → atoms, and the `authorization_signed_response_alg` nil-cast idiom for `inherit`/`nil`/`""` → `nil`; unknown → `:error`.

**When to use:** Normalizing a nullable enum override where one option ("inherit") must collapse to `nil` and the rest map to atoms.
**Source:** 99-06-SUMMARY.md

### nil-aware select-default helper for a sentinel-free nullable override
`format_default_for_select/1` maps stored `nil → "inherit"`, `:jwt → "jwt"`, `:opaque → "opaque"` for form pre-selection — unlike sibling atom-storing overrides that use plain `Atom.to_string/1`.

**When to use:** Pre-selecting a form control for a nullable field where `nil` is a meaningful displayed option rather than "not configured".
**Source:** 99-06-SUMMARY.md

### SHOW-page global/override/effective trio
Three rows mirroring the security-profile/PAR display: global (`<code>`, server default), override (`<code>`, `nil` rendered as `inherit`), effective (`<strong>`, resolved) — with the effective value using the SAME precedence as the signer.

**When to use:** Surfacing a per-client-overridable policy on a detail page so operators see what is actually in effect (T-99-20 display/mint coherence).
**Source:** 99-06-SUMMARY.md

### Static module-attribute literal for truthful, profile-independent discovery metadata
A discovery key whose value is a fixed literal published unconditionally, deliberately NOT derived from a profile-dependent helper that returns a superset/subset.

**When to use:** Advertising a capability that is true across all profiles and must match what the runtime actually does — avoid reusing a profile-gated resolver that would over- or under-state the value.
**Source:** 99-02-SUMMARY.md

---

## Surprises

### Plan 04 took ~35 min versus 4–12 min for the other plans
The AC/device/CIBA seam plan ran roughly 3–9× longer than its siblings.

**Impact:** The JWT-default flip cascaded breakages across existing tests (no seeded signing key) and surfaced the `TestRepo`/CIBA-Push-worker gap mid-execution. The interdependence of the flip and the existing tests is why each task was committed as one atomic `feat` rather than separate RED/GREEN commits.
**Source:** 99-04-SUMMARY.md

### The CIBA Push worker break was latent since Task 1 but only surfaced in Task 2
The `fetch_active_signing_key/0` gap on `TestRepo` was introduced by Task 1's signer wiring yet didn't manifest until the Task 2 CIBA delivery-modes e2e ran.

**Impact:** A test-infra-only crash (production uses the real `Repository`) that blocked the Push authorization from transitioning to `:consumed`. Reinforces running the full e2e suite, not just unit suites, after a default-behavior flip.
**Source:** 99-04-SUMMARY.md

### Verification went to `human_needed` with zero failed must-haves
Initial status was `human_needed` solely because the code review raised one Critical (CR-01) whose disposition was a human risk decision — all 8 requirements and all 5 ROADMAP success criteria were observably true with a green 1030-test suite.

**Impact:** Distinguishes "a must-have failed" from "a reviewer flagged a risk requiring a human accept-or-fix call." The user chose fix-now, flipping status to `passed`.
**Source:** 99-VERIFICATION.md

### A sibling of the fixed WR-01 defect was knowingly left in place
`token_exchange.ex:1232` (the ID-token path) still calls the host key_store at arity 0 — the same WR-01 class — but was pre-existing and outside the approved remediation scope, so it was explicitly deferred for follow-up.

**Impact:** Documents a known, scoped-out robustness gap so a later phase can address it without re-discovering it.
**Source:** 99-VERIFICATION.md

### A benign `KeyCache` repo-lookup error recurs across async suites
`could not lookup Ecto repo Lockspire.TestRepo` appears during async unit runs — pre-existing infrastructure noise unrelated to the signer (the signer tests inject their own stores).

**Impact:** Harmless log noise that showed up in three consecutive plan summaries (03/04/05); flagged repeatedly as out-of-scope so it isn't mistaken for a signer regression.
**Source:** 99-03-SUMMARY.md, 99-04-SUMMARY.md, 99-05-SUMMARY.md

### `issue_exchange/4` shipped fully-implemented but intentionally unwired for two plans
Plan 03 delivered `issue_exchange/4` as a complete public function with no caller; Plan 05 re-pointed `rfc8693_exchange.ex` at it and deleted the old in-file signing block.

**Impact:** A deliberate cross-plan staging (build the shared surface first, migrate callers later) — not a stub. The extraction-source body was left intact in Plan 03 by design.
**Source:** 99-03-SUMMARY.md, 99-05-PLAN.md
