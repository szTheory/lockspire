# Phase 38: Session Tracking & RP-Initiated Logout - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-29
**Phase:** 38-session-tracking-rp-initiated-logout
**Areas discussed:** sid scope & lifecycle, Host logout seam, /end_session strictness, Admin UI surface

---

## sid scope & lifecycle

### Q1: What scope should `sid` represent?

| Option | Description | Selected |
|--------|-------------|----------|
| Per-interaction | Each authorization flow gets its own sid; no new table; host session not observable | ✓ |
| Per-authentication-session | Single sid spans all authorizations in one host session; requires new Session table or host callback | |

**User's choice:** Per-interaction

---

### Q2: When is sid generated?

| Option | Description | Selected |
|--------|-------------|----------|
| At interaction creation | Generate UUID when interaction row is inserted at /authorize; always present | ✓ |
| At login-complete | Set sid when account_id is posted back; null for unauthenticated interactions | |

**User's choice:** At interaction creation

---

### Q3: How does sid appear on token records?

| Option | Description | Selected |
|--------|-------------|----------|
| Denormalized on token_record | New `sid` field on lockspire_tokens; fast sid lookups without join | ✓ |
| Via interaction join | Tokens look up sid via interaction_id; no token migration, but join-dependent | |

**User's choice:** Denormalized on token_record

---

### Q4: Should sid be emitted in ID tokens?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — always emit in ID tokens | Add `sid` claim to IdToken.sign/1; required for Phase 39 BCL compatibility | ✓ |
| Yes — only when logout is registered | Only include sid for clients with registered BCL/FCL URIs | |
| Not in Phase 38 — addressed in Phase 39 | Track sid in DB but don't emit in ID tokens yet | |

**User's choice:** Yes — always emit in ID tokens

---

### Q5 (more questions): Should Phase 38 include `revoke_by_sid/1`?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — build it now | Add revocation query to TokenStore; Phase 39 calls it without schema changes | ✓ |
| Addressed in Phase 39 | Phase 38 only tracks sid; Phase 39 adds revocation | |

**User's choice:** Yes — build it now

---

## Host logout seam

### Q1: How should Lockspire hand the logout intent to the host?

| Option | Description | Selected |
|--------|-------------|----------|
| Redirect pattern — mirrors redirect_for_login | Signed return_to URL; host clears session and redirects back | ✓ |
| AccountResolver callback inline | clear_session/2 callback; host clears session on conn inline | |
| Generated host controller | Generated logout controller action; host fills in session clearing logic | |

**User's choice:** Redirect pattern — mirrors redirect_for_login

---

### Q2: What information does Lockspire pass to the host?

| Option | Description | Selected |
|--------|-------------|----------|
| account_id + signed return_to | Minimal surface; consistent with login seam | ✓ |
| Full logout context in signed token | account_id, client_id, sid, post_logout_redirect_uri in signed JWT | |

**User's choice:** account_id + signed return_to

---

### Q3: How is the host logout path configured?

| Option | Description | Selected |
|--------|-------------|----------|
| config key — :logout_path in Lockspire config | `config :lockspire, logout_path: "/auth/logout"` | ✓ |
| AccountResolver callback returns the path | logout_path/0 callback on AccountResolver | |
| Convention-based route | Always redirects to fixed path /lockspire/logout | |

**User's choice:** config key — :logout_path in Lockspire config

---

### Q4: Should logout support a host confirmation step?

| Option | Description | Selected |
|--------|-------------|----------|
| Always immediate — no confirmation | Host implements confirmation in its own route if desired | ✓ |
| Support a host opt-in confirmation step | Protocol supports a round-trip confirmation | |

**User's choice:** Always immediate — no confirmation

---

### Q5 (more questions): What happens when return_to token fails validation?

| Option | Description | Selected |
|--------|-------------|----------|
| Treat as logout success anyway | Log failure, revoke sid's tokens, redirect to post_logout_redirect_uri | ✓ |
| Reject with an error page | Return error page if return_to token invalid | |

**User's choice:** Treat as logout success anyway

---

### Q6: When should token revocation happen?

| Option | Description | Selected |
|--------|-------------|----------|
| At end_session completion — after host returns | Tokens valid during brief redirect round-trip | ✓ |
| At end_session start — before redirecting to host | Revoke immediately; tokens revoked even if host session clear fails | |

**User's choice:** At end_session completion — after host returns

---

### Q7: What if logout_path config is not set?

| Option | Description | Selected |
|--------|-------------|----------|
| Raise at compile time or startup | Fail fast; clear error message | ✓ |
| Fall back to Lockspire-owned logout completion page | Revoke tokens directly; generic logged-out page; no host routing | |

**User's choice:** Raise at compile time or startup

---

### Q8: Should the generator emit a host logout route template?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — emit a generated host logout route | Pre-wired to clear session and redirect to return_to | ✓ |
| Document it only — no generated code | Docs show the pattern; host writes the route itself | |

**User's choice:** Yes — emit a generated host logout route

---

## /end_session strictness

### Q1: How strictly should `id_token_hint` be validated?

| Option | Description | Selected |
|--------|-------------|----------|
| Validate signature, tolerate expiry | Verify sig with Lockspire keys; accept expired tokens; extract sub + sid | ✓ |
| Hint-only — no signature validation | Decode JWT without sig verification | |

**User's choice:** Validate signature, tolerate expiry

---

### Q2: Should `post_logout_redirect_uri` require exact pre-registration?

| Option | Description | Selected |
|--------|-------------|----------|
| Exact match against registered post_logout_redirect_uris | New field on client record; same strict model as redirect_uri | ✓ |
| Match against existing redirect_uris | Use existing redirect_uris field; no new client field | |
| No validation — any HTTPS URI allowed | Accept any HTTPS URI; open redirector risk | |

**User's choice:** Exact match against registered post_logout_redirect_uris

---

### Q3: What happens with no `id_token_hint`?

| Option | Description | Selected |
|--------|-------------|----------|
| Proceed without hint — still complete logout | Clear browser session via host; redirect to post_logout_redirect_uri; skip token revocation | ✓ |
| Require id_token_hint — reject without it | Error if no hint provided | |

**User's choice:** Proceed without hint — still complete logout

---

### Q4: What happens with no `post_logout_redirect_uri`?

| Option | Description | Selected |
|--------|-------------|----------|
| Lockspire-owned logged-out page | Minimal "You have been signed out" page; no external redirect | ✓ |
| Redirect to client_uri | Redirect to client's registered client_uri if available | |
| Return 200 with empty body | HTTP 200; appropriate for API callers, poor UX for browsers | |

**User's choice:** Lockspire-owned logged-out page

---

### Q5 (more questions): Should /end_session accept both GET and POST?

| Option | Description | Selected |
|--------|-------------|----------|
| Both GET and POST | OIDC requires it; POST prevents ID token leakage in browser history | ✓ |
| GET only for now | Simpler; POST deferred to a conformance phase | |

**User's choice:** Both GET and POST

---

### Q6: Should `end_session_endpoint` be in discovery now?

| Option | Description | Selected |
|--------|-------------|----------|
| Publish end_session_endpoint now, BCL/FCL as false | Truthful placeholders; Phase 39 flips them to true | ✓ |
| Publish end_session_endpoint only, omit BCL/FCL fields | Cleaner metadata but RPs can't distinguish unsupported from not-yet-supported | |

**User's choice:** Publish end_session_endpoint now, BCL/FCL as false

---

### Q7: Reject if client_id and id_token_hint disagree?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — reject if they disagree | id_token_hint's aud must include client_id; prevents cross-client logout | ✓ |
| Ignore the mismatch — id_token_hint wins | Use id_token_hint's claims; ignore client_id param | |

**User's choice:** Yes — reject if they disagree

---

## Admin UI surface

### Q1: Where should `sid` appear in admin UI?

| Option | Description | Selected |
|--------|-------------|----------|
| In existing token + interaction detail/show views | Minimal surface change; operators drill in to see sid | ✓ |
| In token/interaction list views + detail views | sid as column in token list table | |
| New Sessions admin LiveView | Separate /admin/sessions with unique sids and associated tokens | |

**User's choice:** In existing token + interaction detail/show views

---

### Q2: Should operators be able to revoke a session from admin UI in Phase 38?

| Option | Description | Selected |
|--------|-------------|----------|
| View-only in Phase 38 | Session-level revocation UI handled in Phase 39 | ✓ |
| Add revoke-session action in Phase 38 | Since revoke_by_sid is built anyway, add the UI button now | |

**User's choice:** View-only in Phase 38

---

### Q3: Should `post_logout_redirect_uri` be in the client admin UI?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — add to client edit + show views | Operators need to register the field for the feature to work | ✓ |
| Config-only in Phase 38 — defer UI to Phase 39 | Operators use DCR or direct DB for now | |

**User's choice:** Yes — add to client edit + show views

---

### Q4: What should the "logged out" page be?

| Option | Description | Selected |
|--------|-------------|----------|
| Plain controller render — no LiveView | Minimal static template; consistent with error pages | ✓ |
| LiveView page | Consistent with consent UI but overkill for a terminal static state | |

**User's choice:** Plain controller render — no LiveView

---

## Claude's Discretion

None — all material decisions were made by the user.

## Deferred Ideas

- Session-level revocation UI (admin) — handled in Phase 39 with BCL/FCL tooling
- Back-Channel Logout webhook dispatch — Phase 39 (SLO-03)
- Front-Channel Logout iframe rendering — Phase 39 (SLO-04)
- `backchannel_logout_supported: true` / `frontchannel_logout_supported: true` in discovery — Phase 39
- `check_session_iframe` (OIDC Session Management) — not in scope for Phases 38 or 39
- New Sessions admin LiveView — may be worth adding post-Phase 39
