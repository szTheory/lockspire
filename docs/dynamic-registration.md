# Dynamic Client Registration

Lockspire supports Dynamic Client Registration (DCR) via [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591) and [RFC 7592](https://datatracker.ietf.org/doc/html/rfc7592). This allows external ecosystem partners to register their OAuth/OIDC clients programmatically without operator intervention, provided they have been issued an Initial Access Token (IAT).

## Operator Setup

DCR is controlled by Lockspire's server policy. Out of the box, DCR might be disabled to ensure secure defaults. To enable it:

1. Navigate to the **Server Policies** section in your Lockspire Admin UI.
2. Ensure the Global Registration Policy is set to `initial_access_token`. This strict setting ensures that only partners explicitly given an IAT can register. Open registration is deliberately not supported to prevent uncontrolled growth and spam.
3. Configure your host application router to rate-limit the Lockspire Registration endpoints. **Lockspire does not provide built-in rate limiting.** It is your responsibility to wrap the Lockspire routes (or at least `/register`) in an Elixir `Plug` that performs appropriate rate limiting.

## Initial Access Token (IAT) Lifecycle

As an operator, you control who can register by issuing Initial Access Tokens (IATs):

1. **Minting:** In the Lockspire Admin UI under Initial Access Tokens, you can create a new IAT for a specific partner. You can assign a name to track who you gave it to, and set an expiration time if you choose.
2. **Distribution:** Once created, you must securely transmit the plain text secret to the partner. Lockspire will only display it once.
3. **Usage:** The partner will include this token as a `Bearer` token in the `Authorization` header of their `POST /register` request.
4. **Revocation/Redemption:** IATs can be configured to be multi-use or explicitly revoked via the admin interface if a partner's access needs to be terminated.

## Partner Integration

Once a partner has an Initial Access Token, they can integrate with your Lockspire provider.

### Client Registration

To register a new client, send a `POST` request to the registration endpoint (e.g., `https://your-domain.com/oauth/register`) with your IAT as the bearer token.

**Request:**

```http
POST /oauth/register HTTP/1.1
Host: your-domain.com
Content-Type: application/json
Accept: application/json
Authorization: Bearer <INITIAL_ACCESS_TOKEN>

{
  "client_name": "My Cool App",
  "redirect_uris": [
    "https://app.example.com/callback"
  ]
}
```

**Response:**

A successful response (HTTP `201 Created`) will return the newly minted client details, along with a `registration_access_token` and `registration_client_uri`.

```json
{
  "client_id": "cli_abc123",
  "client_secret": "sec_def456",
  "client_id_issued_at": 1610000000,
  "client_secret_expires_at": 0,
  "client_name": "My Cool App",
  "redirect_uris": [
    "https://app.example.com/callback"
  ],
  "token_endpoint_auth_method": "client_secret_basic",
  "grant_types": ["authorization_code", "refresh_token"],
  "response_types": ["code"],
  "registration_access_token": "rat_xyz789",
  "registration_client_uri": "https://your-domain.com/oauth/register/cli_abc123"
}
```

### Registration Access Token (RAT)

The `registration_access_token` allows the partner to manage the client they just created. They must securely store both their client credentials (`client_id`, `client_secret`) and the `registration_access_token`.

### Read, Update, and Delete

Partners can read, update, or delete their client via the `registration_client_uri` using the RAT.

* **Read (GET):** `GET /oauth/register/cli_abc123` with `Authorization: Bearer <RAT>`
* **Update (PUT):** `PUT /oauth/register/cli_abc123` with `Authorization: Bearer <RAT>` and the full JSON representation of the updated client. This will rotate both the `client_secret` and the `registration_access_token`.
* **Delete (DELETE):** `DELETE /oauth/register/cli_abc123` with `Authorization: Bearer <RAT>`

### Logout propagation metadata lifecycle

Lockspire's DCR surface can create, read, and update the four existing logout propagation metadata fields:

- `backchannel_logout_uri`
- `backchannel_logout_session_required`
- `frontchannel_logout_uri`
- `frontchannel_logout_session_required`

These settings control logout propagation to the relying party. They are separate from post-logout redirect URIs, which are browser destinations after RP-initiated logout.

Back-channel logout is the durable server-to-server path. Front-channel logout is best effort only and should be treated as browser choreography rather than proof of remote success.

**Create with logout propagation metadata:**

```http
POST /oauth/register HTTP/1.1
Host: your-domain.com
Content-Type: application/json
Accept: application/json
Authorization: Bearer <INITIAL_ACCESS_TOKEN>

{
  "client_name": "My Cool App",
  "redirect_uris": [
    "https://app.example.com/callback"
  ],
  "backchannel_logout_uri": "https://rp.example.test/backchannel-logout",
  "backchannel_logout_session_required": true,
  "frontchannel_logout_uri": "https://app.example.test/frontchannel-logout",
  "frontchannel_logout_session_required": true
}
```

```json
{
  "client_id": "cli_abc123",
  "client_secret": "sec_def456",
  "client_name": "My Cool App",
  "redirect_uris": [
    "https://app.example.com/callback"
  ],
  "backchannel_logout_uri": "https://rp.example.test/backchannel-logout",
  "backchannel_logout_session_required": true,
  "frontchannel_logout_uri": "https://app.example.test/frontchannel-logout",
  "frontchannel_logout_session_required": true,
  "registration_access_token": "rat_xyz789",
  "registration_client_uri": "https://your-domain.com/oauth/register/cli_abc123"
}
```

**Read the stored values:**

```http
GET /oauth/register/cli_abc123 HTTP/1.1
Host: your-domain.com
Accept: application/json
Authorization: Bearer <RAT>
```

The management response returns the same persisted logout propagation fields so the relying party can confirm the server's stored state.

**Update with RFC 7592 full-replace semantics:**

```http
PUT /oauth/register/cli_abc123 HTTP/1.1
Host: your-domain.com
Content-Type: application/json
Accept: application/json
Authorization: Bearer <RAT>

{
  "client_name": "Updated logout fixture client",
  "redirect_uris": [
    "https://app.example.com/callback"
  ],
  "grant_types": ["authorization_code", "refresh_token"],
  "response_types": ["code"],
  "token_endpoint_auth_method": "client_secret_basic",
  "scope": "openid profile",
  "backchannel_logout_uri": "https://rp.example.test/replaced-backchannel-logout",
  "backchannel_logout_session_required": false,
  "frontchannel_logout_uri": "https://app.example.test/replaced-frontchannel-logout",
  "frontchannel_logout_session_required": false
}
```

RFC 7592 `PUT` is full-replace, not patch. If logout propagation fields are omitted from an update, the omitted values clear and Lockspire persists `nil` / `false` for those fields on the stored client.

The returned `registration_access_token` replaces the old RAT immediately. Any returned `client_secret` replaces the old client credential immediately.

```json
{
  "client_id": "cli_abc123",
  "client_secret": "sec_rotated789",
  "client_name": "Updated logout fixture client",
  "redirect_uris": [
    "https://app.example.com/callback"
  ],
  "backchannel_logout_uri": "https://rp.example.test/replaced-backchannel-logout",
  "backchannel_logout_session_required": false,
  "frontchannel_logout_uri": "https://app.example.test/replaced-frontchannel-logout",
  "frontchannel_logout_session_required": false,
  "registration_access_token": "rat_rotated456",
  "registration_client_uri": "https://your-domain.com/oauth/register/cli_abc123"
}
```

## Out of Scope

To ensure a secure and explicit deployment model, the following Dynamic Client Registration features are **not supported**:

* Open Registration
* Software Statements (RFC 7591 §2.3)
* External-IdP federation and FAPI bundles
* JAR-04 encryption
* `jwks_uri` outbound fetch
