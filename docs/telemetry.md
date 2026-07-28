# Lockspire Telemetry

Lockspire leverages the [telemetry](https://hexdocs.pm/telemetry/) library for observability, instrumentation, and audit logging. 

All core domain events are emitted using the internal `Lockspire.Observability.emit/4` and `Lockspire.Observability.emit_logout/3` helpers. This ensures uniform event structure, consistent measurements, and mandatory secret redaction before any event reaches reporters or audit sinks.

## Event Structure

Every event emitted by Lockspire produces two paths:

1. **Standard Telemetry Path:** `[:lockspire, <entity>, <action>]`
2. **Audit Mirror Path:** `[:lockspire, :audit, <entity>, <action>]`

Both paths carry the exact same measurements and metadata.

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
