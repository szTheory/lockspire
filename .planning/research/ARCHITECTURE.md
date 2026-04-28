# Architecture Patterns

**Domain:** Embedded OAuth/OIDC Provider (Lockspire)
**Researched:** 2026-04-28

## Recommended Architecture

The new milestone introduces JAR Decryption (JWE), Back-Channel Logout, Front-Channel Logout, and OIDC Session tracking (for RP-Initiated Logout). As an embedded provider, Lockspire must implement these without taking over the host app's web session, while correctly issuing and consuming protocol artifacts.

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `Protocol.Jar` | Decrypts JWE using AS private keys, then verifies JWS signature. | `Storage.KeyStore` (for AS enc keys), `Domain.Client` |
| `Protocol.LogoutToken` | Mints OIDC Back-Channel Logout JWTs. | `Storage.KeyStore` (for AS sig keys) |
| `Protocol.BackChannelLogout` | Orchestrates HTTP POSTs to client `backchannel_logout_uri`s. | `Storage.TokenStore`, `Clients` |
| `Web.EndSessionController` | Validates `GET /end_session` (RP-Initiated Logout) and hands off to host. | `Host.AccountResolver` |
| `Web.FrontChannelLogoutLive` | Renders `<iframe>` elements for RP front-channel endpoints. | `Storage.TokenStore` |
| `Host.AccountResolver` | Provides `sid` during login, and handles clearing the host session during logout. | Host Phoenix App |

### Data Flow

#### 1. JAR Decryption Flow
When an RP sends an encrypted JAR (Request Object):
1. `POST /authorize` or `POST /par` receives the `request` JWT.
2. `Protocol.RequestObject.consume` fetches AS private keys with `use: "enc"` from `Storage.KeyStore`.
3. `Protocol.Jar.decrypt` uses `JOSE.JWE` to decrypt the outer envelope.
4. `Protocol.Jar.verify_signature` uses `JOSE.JWS` and the Client's public keys to verify the inner signature.
5. The request proceeds as normal.

#### 2. Session Tracking Flow
OIDC Logout requires identifying the session to terminate (`sid`).
1. Host app resolves the account and optionally provides a `sid` (Session ID) via `InteractionResult`.
2. Lockspire stores `sid` on the `Interaction` and subsequently on the issued `Token` records.
3. `Protocol.IdToken` includes the `sid` claim in the minted ID Token.

#### 3. RP-Initiated & Logout Flow
When a user logs out from the RP:
1. RP redirects to Lockspire's `GET /end_session?id_token_hint=...&post_logout_redirect_uri=...`
2. `EndSessionController` validates the ID token and extracts `sid` and `account_id`.
3. Lockspire redirects to a new Host seam (e.g. `Host.AccountResolver.redirect_for_logout`) so the host can call `clear_session(conn)`.
4. Host redirects back to Lockspire's Front-Channel Logout page (or calls a Lockspire function).
5. Lockspire executes Back-Channel HTTP POSTs to relevant clients asynchronously.
6. Lockspire renders Front-Channel `<iframe>`s synchronously.
7. Lockspire redirects the user to the RP's `post_logout_redirect_uri`.

## Patterns to Follow

### Pattern 1: Nested JWT (JWE containing JWS) for JAR
**What:** The OIDC spec for Encrypted Request Objects dictates that the payload is a JWS, which is then encrypted into a JWE.
**When:** During JAR processing.
**Example:**
```elixir
def decrypt_and_verify(jwt, as_private_keys, client) do
  with {:ok, jws_binary} <- attempt_jwe_decrypt(jwt, as_private_keys),
       {:ok, jar} <- verify_signature(jws_binary, client) do
    {:ok, jar}
  end
end
```

### Pattern 2: Host-Owned Session Clearing Seam
**What:** Lockspire does not own the Phoenix `conn.private.plug_session`. It cannot log the user out itself. It must hand off to the host.
**When:** Handling `/end_session`.
**Example:**
```elixir
# In Lockspire.Web.EndSessionController
def show(conn, params) do
  # ... validate id_token_hint ...
  interaction_result = AccountResolver.redirect_for_logout(conn, context)
  Interaction.handle_redirect(conn, interaction_result)
end
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Assuming Lockspire can call `clear_session` directly
**What:** Attempting to clear the Phoenix session cookie from within Lockspire's controller.
**Why bad:** The host app may use Guardian, Pow, Ueberauth, or custom session logic. They might need to revoke host-level database tokens or emit metrics.
**Instead:** Expose a `redirect_for_logout` callback in `AccountResolver` so the host manages the actual cookie deletion and then returns control.

### Anti-Pattern 2: Synchronous Back-Channel POSTs in the Web Request
**What:** Blocking the logout HTTP response to make external HTTP POSTs to multiple RP `backchannel_logout_uri`s.
**Why bad:** RPs can be slow or timeout, causing the user's browser to hang during logout.
**Instead:** Enqueue Back-Channel logout tasks to an Oban queue or `Task.Supervisor` while immediately rendering the Front-Channel UI or redirecting.

## Scalability Considerations

| Concern | At 100 users | At 10K users | At 1M users |
|---------|--------------|--------------|-------------|
| Back-Channel POSTs | Sync or simple `Task` | `Task.Supervisor` | Oban or durable queue to handle retries and RP timeouts |
| Front-Channel Iframes | Direct render | Direct render | Direct render (browser executes them in parallel) |
| Session Lookup | Direct Ecto query by `sid` | Indexed query by `sid` | Indexed query, potentially partitioned if `Token` table is massive |

## Suggested Build Order

1. **Phase A: Domain & Storage Foundation**
   - Add `request_object_encryption_*`, `backchannel_logout_*`, `frontchannel_logout_*` to `Client` and `ClientRecord`.
   - Add `sid` to `Token` and `Interaction`.
   - Update LiveView Admin UI to manage these fields.
2. **Phase B: JAR Decryption Core**
   - Support `use: "enc"` in `KeyStore` and `JwksController`.
   - Implement `JOSE.JWE` decryption in `Protocol.Jar`.
   - Update Discovery `/.well-known/openid-configuration`.
3. **Phase C: Session Tracking & ID Token**
   - Update `Host.AccountResolver` seam to accept a `sid`.
   - Issue ID Tokens with `sid`.
4. **Phase D: Back-Channel Logout Core**
   - Implement `Protocol.LogoutToken` and HTTP delivery for Back-Channel Logout.
5. **Phase E: RP-Initiated & Front-Channel Logout**
   - Implement `/end_session` endpoint.
   - Implement Host handoff for session clearing.
   - Implement Front-Channel iframe rendering page.

## Sources

- [OpenID Connect Core 1.0 - Section 10 (Signatures and Encryption)](https://openid.net/specs/openid-connect-core-1_0.html#Signatures) (HIGH)
- [OpenID Connect Back-Channel Logout 1.0](https://openid.net/specs/openid-connect-backchannel-1_0.html) (HIGH)
- [OpenID Connect Front-Channel Logout 1.0](https://openid.net/specs/openid-connect-frontchannel-1_0.html) (HIGH)
- [OpenID Connect RP-Initiated Logout 1.0](https://openid.net/specs/openid-connect-rpinitiated-1_0.html) (HIGH)
