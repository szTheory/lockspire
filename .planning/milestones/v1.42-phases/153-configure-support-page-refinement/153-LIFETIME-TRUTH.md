# DCR lifetime settings: implemented behavior

Source review: 2026-10-13. This records the built-in behavior, rather than assumptions from field names or storage comments. No protocol or storage changes were made as part of this trace.

## Shared configuration path

All three nullable lifetime settings are persisted in `ServerPolicyRecord` and copied into `DcrPolicy.Resolved`. Resolution does not supply global lifetime defaults. Initial access token policy overrides constrain registration allowlists; they do not implement these lifetime settings.

- [Server policy fields and persistence](../../../lib/lockspire/storage/ecto/server_policy_record.ex), lines 44–46, 69–71, 102–106.
- [Resolved lifetime assignments](../../../lib/lockspire/protocol/dcr_policy.ex), lines 135–139.
- [Initial registration path](../../../lib/lockspire/protocol/registration.ex), lines 68–74 and 476–483.

## App lifetime

`default_client_lifetime_seconds` is stored and resolved, but has no downstream built-in consumer. Registration creates an active client without applying this interval. `Domain.Client` has no app expiry field, and the pruner does not expire client records.

Sources: [client construction](../../../lib/lockspire/client_metadata.ex), lines 41–103; [client domain](../../../lib/lockspire/domain/client.ex); [pruner](../../../lib/lockspire/workers/pruner.ex).

Truthful UI guidance: **“Stored setting. Lockspire does not automatically disable registered apps after this interval.”**

This is missing lifetime implementation, not an implemented expiry conveyed only as metadata.

## Registration access token lifetime

`default_registration_access_token_lifetime_seconds` is stored and resolved, but is not consumed during token creation, rotation, lookup, or management. The token generator returns plaintext and hash without expiry information. Client records have no registration access token expiry field. Management lookup checks the current hash; management operations also require an active client. Updating registration rotates the token, and operator rotation also replaces its current hash. Disabling the app blocks management use.

- [Token generation](../../../lib/lockspire/protocol/registration_access_token.ex), lines 18–25.
- [Initial token generation](../../../lib/lockspire/protocol/registration.ex), lines 446–457.
- [Management update and rotation](../../../lib/lockspire/protocol/registration_management.ex), lines 74–81 and 137–144.
- [Hash lookup](../../../lib/lockspire/storage/ecto/repository/client_store.ex), lines 44–50.
- [Active-client check](../../../lib/lockspire/protocol/registration_management.ex), lines 47–60.

Truthful UI guidance: **“Stored setting. App management tokens do not expire automatically. Rotation replaces the current token; disabling the app blocks its use.”**

This is missing lifetime implementation; no expiry metadata is currently generated for this token.

## Client secret lifetime

`default_client_secret_lifetime_seconds` has one built-in downstream consumer: it sets `client_secret_expires_at` on newly registered clients with a shared secret. Positive values produce registration time plus the interval. **Blank (`nil`) and zero currently produce registration time itself**, not an unlimited-expiry marker. Clients without a shared secret receive `nil`; the registration JSON serializes a nil secret expiry as zero.

- [Persisted client expiry](../../../lib/lockspire/client_metadata.ex), line 100.
- [Date calculation and no-secret case](../../../lib/lockspire/client_metadata.ex), lines 277–284.
- [Registration response metadata](../../../lib/lockspire/web/registration_json.ex), lines 56–61.

The date is persisted and advertised, but authentication does not enforce it. Basic/post authentication checks the secret hash only. Secret JWT authentication verifies the assertion signature, assertion timing, and replay rules; assertion expiry is distinct from secret expiry. Registration management updates preserve the original secret expiry, and operator secret rotation does not renew that date.

- [Basic/post authentication](../../../lib/lockspire/protocol/client_auth.ex), lines 243–254.
- [Secret JWT authentication](../../../lib/lockspire/protocol/client_auth/client_secret_jwt.ex), lines 20–27.
- [Management metadata whitelist](../../../lib/lockspire/client_metadata.ex), lines 106–144.
- [Secret rotation writes](../../../lib/lockspire/storage/ecto/repository/client_store.ex), lines 119–131.

Truthful UI guidance: **“Sets the expiry date reported to newly registered apps. Lockspire currently does not reject authentication based on that date.”**

Expiry metadata is implemented. Expiry enforcement is absent. The UI must not describe the setting as an enforced credential lifetime or describe blank/zero as “no limit.”

## Host seams and limits

Custom storage or surrounding host integration code could impose additional rules. The built-in [client store contract](../../../lib/lockspire/storage/client_store.ex), lines 10–27, exposes persistence and lookup operations, without an automatic lifetime mechanism. The [account resolver](../../../lib/lockspire/host/account_resolver.ex) owns accounts, claims, and login/logout seams; it supplies no client-credential lifetime callback. No global lifetime fallback was found in configuration, registration, management, authentication, or pruning.

These findings describe the supplied implementation. They do not promise that a host app has implemented additional expiry checks. Saved settings alone must not be presented as automatic expiry guarantees.
