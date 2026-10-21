# Dynamic Client Registration

Lockspire supports Dynamic Client Registration (DCR) via [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591) and [RFC 7592](https://datatracker.ietf.org/doc/html/rfc7592). This allows external ecosystem partners to register their OAuth/OIDC clients programmatically without operator intervention, provided they have been issued an Initial Access Token (IAT).

For the canonical public support contract, see `docs/supported-surface.md`. For the shipped symmetric JWT direct-client slice specifically, see `docs/client-secret-jwt-host-guide.md`. For legacy app lifetime storage, custom adapter requirements, and the old-writer drain boundary, see [Upgrade app lifetime storage](upgrading/client-lifetimes.md).

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
  "lockspire_client_expires_at": 0,
  "lockspire_registration_access_token_expires_at": 0,
  "registration_access_token": "rat_xyz789",
  "registration_client_uri": "https://your-domain.com/oauth/register/cli_abc123"
}
```

### Registration Access Token (RAT)

The `registration_access_token` is the app management token: it lets the partner read, update, or delete the app registration. Lockspire returns it only when the app is created or its token is replaced, so the partner must securely store it. It is separate from the app's client secret.

### App management-token lifetime

The management-token lifetime is an optional host policy. A blank setting or a value of `0` means no automatic expiry; a positive duration applies to newly issued or replaced app management tokens. Changing the setting does not change tokens already issued. Lockspire does not require one universal registration-token timeout. A host may choose a finite duration to reduce the time a copied token remains usable, while accounting for the lockout risk if the partner loses it.

Lockspire stores the expiry and returns it in the server-owned `lockspire_registration_access_token_expires_at` extension. The value is a Unix timestamp in seconds; `0` means no automatic expiry. The related `lockspire_client_expires_at` extension reports the app's expiry in the same format. These extensions are informational: a PUT may omit them or echo their current values, but cannot change them. Registration intake cannot set either extension.

For example, with a 60-second app lifetime, 10-second client-secret lifetime, and 20-second management-token lifetime, a registration issued at time `100` has app expiry `160`, secret expiry `110`, and management-token expiry `120`:

```json
{
  "client_id": "cli_abc123",
  "client_secret_expires_at": 110,
  "lockspire_client_expires_at": 160,
  "lockspire_registration_access_token_expires_at": 120
}
```

The management token is usable strictly before its expiry time. At the exact expiry time and afterward, it cannot read, update, or delete the registration. A GET does not renew the token or change its deadline. If the management token has expired, the app cannot manage its own registration. An expired but enabled app can still be read or deleted with an eligible management token, but it cannot be updated. A disabled app cannot use any registration-management operation.

### Shared-secret lifetime and rotation

`client_secret_expires_at` is the Unix-second expiry of a shared client secret. A value of `0` means that the secret has no automatic expiry; the field is omitted when the app has no client secret. A positive DCR secret-lifetime setting is recorded for newly registered self-managed apps that use a shared secret and for their secrets later replaced through Lockspire's operator rotation workflow. Changing the setting does not change the expiry already stored for existing secrets.

Lockspire accepts a shared secret only before its stored expiry time. At the exact expiry time and afterward, Basic, post, and `client_secret_jwt` authentication using that secret is rejected. A JWT client's assertion lifetime and replay checks remain separate. Expiring a client secret does not revoke access or refresh tokens that were already issued; those tokens keep their own validity rules. Public-key and mutual-TLS authentication do not use a shared-secret expiry.

### Read, Update, and Delete

Partners can read, update, or delete their app through `registration_client_uri` using the app management token. The examples below use `/oauth`; the actual path is `Lockspire.mount_path()` plus `/register`, so use the prefix configured by the host application.

* **Read (GET):** `GET /oauth/register/cli_abc123` with `Authorization: Bearer <RAT>`
* **Update (PUT):** `PUT /oauth/register/cli_abc123` with `Authorization: Bearer <RAT>` and the full JSON representation of the updated app. Include the unchanged `client_id` in every PUT body; it must match the URL. A supplied `client_secret` must match the current secret. Do not send `registration_access_token`, `registration_client_uri`, `client_secret_expires_at`, or `client_id_issued_at` in the body. The Lockspire expiry extensions may be omitted or echoed unchanged. A successful PUT rotates the app management token immediately and returns its replacement once. It preserves the existing client secret; it does not return or rotate that secret. There is no overlap period: the previous app management token stops working immediately.
* **Delete (DELETE):** `DELETE /oauth/register/cli_abc123` with `Authorization: Bearer <RAT>`

PUT is a full replacement of the supported registration metadata, not a patch. Include every value the app needs to retain. A successful response contains the new `registration_access_token`; it does not contain a `client_secret`.

### `client_secret_jwt` metadata shape

Lockspire supports `client_secret_jwt` only as a narrow confidential-client direct-client slice. When a client chooses that mode, send the auth method and signing algorithm together:

- `token_endpoint_auth_method=client_secret_jwt`
- `token_endpoint_auth_signing_alg=HS256`

This shipped slice is confidential-client only, uses issuer-string `aud`, and does not extend to `POST /par`, `HS384`, `HS512`, FAPI, or mTLS equivalence claims.

**Create with explicit `client_secret_jwt` metadata:**

```http
POST /oauth/register HTTP/1.1
Host: your-domain.com
Content-Type: application/json
Accept: application/json
Authorization: Bearer <INITIAL_ACCESS_TOKEN>

{
  "client_name": "Partner direct client",
  "redirect_uris": [
    "https://app.example.com/callback"
  ],
  "token_endpoint_auth_method": "client_secret_jwt",
  "token_endpoint_auth_signing_alg": "HS256"
}
```

```json
{
  "client_id": "cli_abc123",
  "client_secret": "sec_def456",
  "client_id_issued_at": 1610000000,
  "client_secret_expires_at": 0,
  "client_name": "Partner direct client",
  "redirect_uris": [
    "https://app.example.com/callback"
  ],
  "token_endpoint_auth_method": "client_secret_jwt",
  "token_endpoint_auth_signing_alg": "HS256",
  "registration_access_token": "rat_xyz789",
  "registration_client_uri": "https://your-domain.com/oauth/register/cli_abc123"
}
```

### Logout propagation metadata lifecycle

Lockspire's DCR surface can create, read, and update the four existing logout propagation metadata fields:

- `backchannel_logout_uri`
- `backchannel_logout_session_required`
- `frontchannel_logout_uri`
- `frontchannel_logout_session_required`

These settings control logout propagation to the relying party. They are separate from post-logout redirect URIs, which are browser destinations after RP-initiated logout.

These metadata fields manage the existing shipped logout runtime; they do not create a second logout system. After the host app clears its own browser session and returns to `/end_session/complete`, Lockspire persists propagation intent, enqueues back-channel delivery, and renders front-channel cleanup as best effort browser choreography only.

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
  "client_id": "cli_abc123",
  "client_name": "Updated logout fixture client",
  "redirect_uris": [
    "https://app.example.com/callback"
  ],
  "grant_types": ["authorization_code", "refresh_token"],
  "response_types": ["code"],
  "token_endpoint_auth_method": "client_secret_basic",
  "lockspire_client_expires_at": 1610000160,
  "lockspire_registration_access_token_expires_at": 1610001200,
  "scope": "openid profile",
  "backchannel_logout_uri": "https://rp.example.test/replaced-backchannel-logout",
  "backchannel_logout_session_required": false,
  "frontchannel_logout_uri": "https://app.example.test/replaced-frontchannel-logout",
  "frontchannel_logout_session_required": false
}
```

RFC 7592 `PUT` is full-replace, not patch. If logout propagation fields are omitted from an update, the omitted values clear and Lockspire persists `nil` / `false` for those fields on the stored client.

The same full-replace rule applies to auth-method metadata. If a client stays on `client_secret_jwt`, send both `token_endpoint_auth_method` and `token_endpoint_auth_signing_alg` together so the stored `HS256` truth remains coherent. If an update changes auth method away from `client_secret_jwt`, omit the old symmetric JWT signing-alg expectation and let the new method's metadata define the replacement state.

The returned `registration_access_token` replaces the old app management token immediately. This update response does not contain a `client_secret`. To replace a shared secret, use the operator rotation workflow; the new secret is shown once and uses the current DCR secret-lifetime policy when that policy applies to the app.

```json
{
  "client_id": "cli_abc123",
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

If the successful PUT response is lost, replay of the previous token cannot recover it: the previous token has already been invalidated, and the replacement plaintext is not returned again. The provider team must use its existing host-authorized app management-token rotation task to issue and securely deliver another token. For example, if the provider rotates the token at time `125` under a current 40-second policy, the new expiry is `165`.

The existing operator recovery flow is available only to the host-authorized team and requires its confirmation step. It shows the committed replacement token once. Recovery changes management-token authority only: it does not enable a disabled app or extend the app's expiry or client-secret expiry. An expired but enabled app may use an eligible token to read or delete its registration, but must be recovered before it can update it.

Older v0 app records are treated as having no automatic app, client-secret, or management-token expiry. Their legacy expiry values are advisory until an explicit replacement promotes the current row to the current lifecycle format. Custom storage adapters must preserve the complete current client row during management replacement and recovery, including the management-token expiry, secret hash and expiry, app expiry, and enabled state. See [Upgrade app lifetime storage](upgrading/client-lifetimes.md) for the adapter and rollout contract.

## Out of Scope

To ensure a secure and explicit deployment model, the following Dynamic Client Registration features are **not supported**:

* Open Registration
* Software Statements (RFC 7591 §2.3)
* External-IdP federation and FAPI bundles
* JAR-04 encryption
* `jwks_uri` outbound fetch
