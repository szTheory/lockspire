# Client Secret Verifier Configuration and Rollout

Lockspire can encrypt the verifier used by `client_secret_jwt` with keys dedicated to that purpose. The client secret itself remains hashed at rest. The verifier encryption keys belong to the host deployment and are independent of Phoenix endpoint/session secrets and Lockspire signing-key encryption keys.

## Configuration

Set this application option with exactly four keys:

```elixir
config :lockspire, Lockspire.Security.ClientSecretVerifier,
  keys: [{"verifier-2026-01", System.fetch_env!("LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY")}],
  current: "verifier-2026-01",
  write_mode: :legacy,
  legacy_read: :allow
```

`keys` is a non-empty ordered list of `{key_id, encoded_key}` pairs. Key IDs must be unique ASCII letters, digits, `.`, `_`, or `-`, from 1 to 32 bytes. Each encoded key must decode to exactly 32 bytes. Lockspire accepts the existing standard Base64 or URL-safe Base64 encodings, padded or unpadded. Decoded keys must be unique and must not reuse endpoint/session or signing-key-encryption bytes. Keep key values in the host's secret manager; do not commit them or place them in logs.

The four settings are:

| Setting | Meaning |
|---|---|
| `:keys` | The dedicated key ring. Every key that may still protect a stored verifier must remain available for reads. |
| `:current` | Optional key ID selected for new dedicated writes. It may be omitted or `nil` while staging readers. |
| `:write_mode` | `:legacy` keeps new writes in the existing endpoint-secret format; `:dedicated` explicitly activates the dedicated envelope. |
| `:legacy_read` | `:allow` continues to read legacy rows; `:reject` refuses them. |

The setting is validated at application startup and kept as an immutable node snapshot until restart or redeploy. Editing application environment at runtime does not reload the snapshot. If the setting is absent, Lockspire retains legacy compatibility. A present but invalid setting fails closed for verifier operations; it does not fall back to the absent state. Staging keys, whether or not `current` names one, does not activate dedicated writes. Dedicated writes require a configured current key. `write_mode: :legacy` with `legacy_read: :reject` is invalid.

An explicit operation override must provide the complete four-setting context. It is validated as a whole and is never partially merged with the node setting. Existing legacy helper calls still use their explicit endpoint secret selection. Dedicated reads and writes do not search application configuration for fallback keys.

Configuration diagnostics expose state and safe reason codes only. Typical internal reasons include `:client_secret_verifier_configuration_invalid`, `:client_secret_verifier_key_missing`, `:client_secret_verifier_key_unknown`, `:client_secret_verifier_identity_missing`, `:client_secret_verifier_unsupported_format`, `:client_secret_verifier_unavailable`, and `:client_secret_verifier_legacy_rejected`. Client authentication retains its bounded public `invalid_client` response; key values and configuration details are not returned to the client. A verifier operation failure is local to that operation; unrelated authentication that uses the stored client-secret hash remains available.

The legacy helper that only creates a client-secret hash remains hash-only: it does not create verifier ciphertext. Legacy seal/unseal helpers retain their existing binary-key and keyword call forms and their existing unseal error result.

## Reader-first deployment

Use this sequence for a host fleet:

1. Distribute compatible Lockspire code and every required dedicated read key to all nodes. Keep `write_mode: :legacy` and `legacy_read: :allow`. Staging keys with no `current`, `current: nil`, or a configured current key still produces legacy writes.
2. Establish reader readiness using host-owned evidence that covers every node and every required retained key. Lockspire's local tests cannot establish fleet parity, deployment quiescence, backup quality, or a safe rollback plan.
3. After the host has established that readiness, explicitly set `write_mode: :dedicated`. Keep `legacy_read: :allow` while any legacy verifier rows remain. When changing the dedicated current key, retain all old read keys needed by stored envelopes.

The rollout test exercises real generated legacy and dedicated ciphertext with the unchanged legacy decrypt helper and compatible readers. Dedicated ciphertext is unreadable to the old helper. If the host switches writes back to legacy before any dedicated verifier is stored, old-code compatibility can be restored after redeploying old code. Once a dedicated verifier has been written, old code cannot read that row, even if new writes have switched back to legacy. Continue running compatible readers with all required keys, or use a separately planned recovery procedure. Changing configuration does not convert existing rows.

Native dedicated verifier material is checked against the configured client-secret lifetime. Migrated verifier material keeps its authenticated original finite deadline and does not receive a fresh age window. This setting does not silently rotate partner credentials or change their stored lifetime.

## Supported authentication surface

`client_secret_jwt` remains limited to HS256 on the five existing direct-client endpoints that share the verifier: `/token`, `/revoke`, `/introspect`, `/device/code`, and `/backchannel/authentication`. `/par` remains unsupported for this method. The configuration does not add HS384/HS512, FAPI support, or generic JWT client authentication.

This guide describes local runtime configuration and a bounded reader-first sequence. It does not provide a fleet readiness command, retirement workflow, recovery command, or packaged deployment journey. Those operational workflows belong to the later maintenance and package delivery phases.
