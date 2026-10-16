# Lockspire Telemetry

Lockspire leverages the [telemetry](https://hexdocs.pm/telemetry/) library for observability and instrumentation.

All core domain events are emitted using the internal `Lockspire.Observability.emit/4` and `Lockspire.Observability.emit_logout/3` helpers. This ensures uniform event structure, consistent measurements, and mandatory secret redaction before any event reaches reporters or audit sinks.

## Event Structure

Every operator and protocol event emitted through `Lockspire.Observability.emit/4` produces two paths. The one exception is the pair of signing-path key events listed in the Signing Key section below, which are emitted directly on the standard path only and have no audit mirror:

1. **Standard Telemetry Path:** `[:lockspire, <entity>, <action>]`
2. **Audit Mirror Path:** `[:lockspire, :audit, <entity>, <action>]`

Both paths carry the exact same measurements and metadata. The audit mirror is still a telemetry event; it is not a durable audit record. Security-sensitive state transitions separately persist normalized `Lockspire.Audit.Event` records so incident evidence can commit with the state change that produced it.

### Measurements

Measurements will always include at least:

```elixir
%{
  count: 1
}
```

Some events may include additional measurements (e.g., the `:pruner, :completed` event includes the `count` of deleted records).

### Metadata and Redaction

To prevent accidental leakage of sensitive credentials or PII into logs and external telemetry sinks, all metadata is passed through `Lockspire.Redaction.for_telemetry/1`.

**Dropped Keys:**
The redaction sieve completely removes keys containing sensitive data, such as:
- `access_token`, `refresh_token`, `authorization_code`, `initial_access_token`, `rat`, `iat`
- `client_secret`, `client_secret_hash`, `iat_secret`
- `code`, `code_challenge`, `code_verifier`, `state`
- `raw_request`, `raw_response`, `request_body`, `response_body`
- `logout_token`, `raw_logout_token`

**Handled Keys:**
Some keys are irreversibly hashed (using SHA-256 and truncated) to allow correlation without exposing the raw identifier:
- `family_id` becomes `family_handle`

## Emitted Events

Below is an exhaustive list of the telemetry events emitted by Lockspire, categorized by their entity.

### Authorization Code (`[:lockspire, :authorization_code, ...]`)
- `[:lockspire, :authorization_code, :redeemed]`
- `[:lockspire, :authorization_code, :replay_detected]`

### Authorization Request (`[:lockspire, :authorization_request, ...]`)
- `[:lockspire, :authorization_request, :accepted]`
- `[:lockspire, :authorization_request, :rejected]`

### Client Registration (`[:lockspire, :client, ...]`)
- `[:lockspire, :client, :registration_rejected]`
- `[:lockspire, :client, :registration_succeeded]`

### Dynamic Client Registration & Management (`[:lockspire, :dcr, ...]`)
- `[:lockspire, :dcr, :client_created]`
- `[:lockspire, :dcr, :delete]`
- `[:lockspire, :dcr, :read]`
- `[:lockspire, :dcr, :register]`
- `[:lockspire, :dcr, :rotate]`
- `[:lockspire, :dcr, :unauthorized]`
- `[:lockspire, :dcr, :update]`

### DPoP (`[:lockspire, :dpop, ...]`)
- `[:lockspire, :dpop, :failed]`

### FAPI 2.0 (`[:lockspire, :fapi20, ...]`)
- `[:lockspire, :fapi20, :failed]`

### Initial Access Token (`[:lockspire, :iat, ...]`)
- `[:lockspire, :iat, :mint]`
- `[:lockspire, :iat, :revoke]`
- `[:lockspire, :iat, :use]`

### Introspection (`[:lockspire, :introspection, ...]`)
- `[:lockspire, :introspection, :failed]`

### Signing Key (`[:lockspire, :key, ...]`)

Operator events go through `Lockspire.Observability.emit/4`, so each one also has an audit mirror at `[:lockspire, :audit, :key, <action>]`. They carry no key material.

| Event | Audit mirror | When |
| --- | --- | --- |
| `[:lockspire, :key, :generated]` | yes | A signing key was generated. |
| `[:lockspire, :key, :published]` | yes | A key was published to the JWKS. |
| `[:lockspire, :key, :activated]` | yes | A key became the active signing key. |
| `[:lockspire, :key, :retired]` | yes | A key was retired. |
| `[:lockspire, :key, :encrypted]` | yes | Re-encryption sealed a plaintext key (one event per key, after its row commits). |
| `[:lockspire, :key, :rewrapped]` | yes | Re-encryption moved a sealed key to the current key-encryption key (one event per key). |
| `[:lockspire, :key, :reencrypt_failed]` | yes | A key could not be re-encrypted. Metadata: `kid`, `key_id`, `reason`. |
| `[:lockspire, :key, :reencrypt_completed]` | yes | A re-encryption run, dry run or `--check` finished. |

The lifecycle and per-key events carry `key_id`, `kid`, `status` and the acting `actor_type` and `actor_id`; `encrypted` and `rewrapped` also carry `kek_id` (the id the key is now sealed under), and `rewrapped` adds `previous_kek_id`. `reencrypt_completed` carries `current_kek_id`, `actor_type`, `actor_id` and `mode` (`apply`, `dry_run` or `check`) in metadata, and the same measurement keys in every mode: `scanned`, `encrypted`, `rewrapped`, `already_current`, `no_private_key`, `conflicted`, `failed`, `pending`, `stranded_retired` and `duration`.

Two events fire on the request path whenever Lockspire reads a stored signing key to sign. They are telemetry only: there is no audit mirror and no persisted audit record, so a busy node does not write a record per signature.

| Event | Audit mirror | When |
| --- | --- | --- |
| `[:lockspire, :key, :legacy_read]` | no | A signing key stored as legacy plaintext was read while `legacy_plaintext: :allow` is set. Metadata: `kid`, `legacy_plaintext`. Alert on this to find keys that still need `mix lockspire.keys.reencrypt`. |
| `[:lockspire, :key, :decode_failed]` | no | A stored signing key could not be read. Metadata: `kid`, `reason`, and `kek_id` when the stored envelope names one. |

`decode_failed` reasons:

- `invalid_signing_key`: the stored value is not a usable key
- `kek_not_configured`: no key-encryption key is configured
- `unknown_kek`: the envelope names a key id that is not configured
- `malformed_envelope`: the envelope is damaged
- `decryption_failed`: the configured key material does not open the envelope
- `kid_mismatch`: the envelope belongs to a different key row
- `plaintext_key_refused`: the value is plaintext and `legacy_plaintext: :reject` is set

Plaintext refusal surfaces as a `decode_failed` event with reason `plaintext_key_refused`; it has no event of its own. Each `decode_failed` and `legacy_read` condition is also logged once per key and reason on a node, without key material. The reader used by re-encryption (`read_stored/2`) emits no hot-path event, so a re-encryption run never produces `legacy_read` or `decode_failed`.

### Backchannel Logout (`[:lockspire, :logout, ...]`)
- `[:lockspire, :logout, :requested]`
- `[:lockspire, :logout, :delivery_enqueued]`
- `[:lockspire, :logout, :delivery_attempted]`
- `[:lockspire, :logout, :delivery_succeeded]`
- `[:lockspire, :logout, :delivery_failed]`
- `[:lockspire, :logout, :delivery_discarded]`

### Pruner (`[:lockspire, :pruner, ...]`)
- `[:lockspire, :pruner, :completed]` - Includes the count of pruned records in measurements.

### Refresh Token (`[:lockspire, :refresh_token, ...]`)
- `[:lockspire, :refresh_token, :issued]`
- `[:lockspire, :refresh_token, :reuse_detected]`

### Revocation (`[:lockspire, :revocation, ...]`)
- `[:lockspire, :revocation, :failed]`

### Token (`[:lockspire, :token, ...]`)
- `[:lockspire, :token, :introspected]`
- `[:lockspire, :token, :issued]`
- `[:lockspire, :token, :revoked]`

### Token Exchange (`[:lockspire, :token_exchange, ...]`)
- `[:lockspire, :token_exchange, :failed]`
