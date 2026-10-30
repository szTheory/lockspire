# Client Secret Verifier Configuration and Rollout

Lockspire can encrypt the verifier used by `client_secret_jwt` with keys dedicated to that purpose. The client secret itself remains hashed at rest. The verifier encryption keys belong to the host deployment and are independent of Phoenix endpoint/session secrets and Lockspire signing-key encryption keys.

## Configuration

`mix lockspire.install` generates the host integration file `config/lockspire.exs`,
but it does not generate or provision verifier keys. Add this separate
host-owned application configuration only when the host enables
`client_secret_jwt`:

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

## Inspect, re-wrap, and check custody

The task `mix lockspire.clients.verifier.rewrap` scans every client through the selected client store. With no mode flag it applies eligible re-wraps. Use `--dry-run` to inspect pending work without writing, or `--check` for a fresh, read-only custody check. `--limit` sets a page size from 1 through 500. `--after-client-id` resumes apply or preview traversal after an exclusive client ID; it is progress only and cannot be used with `--check`.

```sh
mix lockspire.clients.verifier.rewrap --dry-run --limit 100
mix lockspire.clients.verifier.rewrap --limit 100
mix lockspire.clients.verifier.rewrap --check --limit 100
```

For a running release, use the serving node's startup configuration through RPC:

```sh
bin/app rpc "Lockspire.Admin.ClientVerifierMaintenance.run(mode: :dry_run, limit: 100)"
bin/app rpc "Lockspire.Admin.ClientVerifierMaintenance.run(mode: :apply, limit: 100)"
bin/app rpc "Lockspire.Admin.ClientVerifierMaintenance.run(mode: :check, limit: 100)"
```

The release call runs inside the node and uses its immutable startup snapshot. Restart or redeploy a node to change that snapshot. A bare Mix task loads its local application configuration and starts only the selected Repo for its operation; it does not start Lockspire supervision or inspect a running release. `mix run --no-start -e ...` also does not start the host supervision tree, so it cannot infer the serving node's startup context.

Each run reports scan completion, committed progress, conflicts, failures, and clients that could not be inspected. A non-zero result means the requested operation did not complete cleanly; committed apply work is retained. If an apply result is partial or indeterminate, do not assume all work rolled back: inspect the report, rerun apply as needed (it is safe to repeat), then run a separate fresh `--check`. Conflicts mean the stored hash or verifier changed while that client was being processed; inspect current client state before retrying. `--after-client-id` resumes preview or apply traversal after an exclusive client ID and is progress only. It cannot be combined with `--check` and never establishes readiness. Only a successful `--check` that starts at the beginning, reaches the end, and reports no pending, failed, conflicting, or uninspected clients establishes current custody for that local store.

The report distinguishes a legitimate `no_material` client (for example, a public client that does not use a secret) from `missing_expected_material`, which needs authorized secret recovery. `expired_migrated` describes authenticated custody whose original migration deadline has passed; it is not proof that the client remains eligible to authenticate. Client expiry and authentication checks still apply independently.

## Reader-first rollout, activation, and recovery

Use this order across the host deployment:

1. Deploy compatible reader code and every key required by existing verifier rows to all serving nodes. Keep `write_mode: :legacy` and `legacy_read: :allow` while readers are being staged. A configured `current` key does not activate dedicated writes.
2. Use host-owned rollout evidence to confirm every serving node has the compatible code and complete read-key ring. A local check proves custody only for its selected store; it cannot prove fleet parity, deployment drain/quiescence, backups, or rollback readiness.
3. After the host has established reader readiness, explicitly set `write_mode: :dedicated` and the intended `current` key. Keep `legacy_read: :allow` while any legacy verifier rows remain. Retain old read keys while stored rows may still use them.
4. Run `--dry-run`, then apply (no mode flag is the apply mode), then a separate fresh `--check`. If apply is partial or its result is uncertain, committed work is retained; inspect current state and repeat apply as needed. If the check is partial or fails, resolve each reported condition and repeat the check from the beginning. A cursor-resumed traversal is not a readiness check.
5. Before removing a live read key, have the host verify fleet state, a usable backup, and its rollback plan. Removing a live key stops that node from opening rows protected by it. Destroying a backup is a separate retention decision; do not infer that it is safe from a live-store check.

The installed rollout proof observes compatible readers while writers remain in legacy mode, then drains the old writer before dedicated activation. Returning writes to legacy does not convert dedicated rows; old code still cannot read a dedicated verifier that was already stored. Preserve compatible readers and their required keys, or follow a separately planned recovery path.

Native dedicated verifier material follows the configured client-secret lifetime. Migrated material keeps its authenticated original finite deadline and does not receive a fresh age window during re-wrap. An expired migrated verifier may be re-wrapped for custody, but remains ineligible to authenticate. Re-wrap does not rotate the partner credential or change its stored lifetime.

If a required key is missing, affected `client_secret_jwt` authentication fails closed with `invalid_client`; Basic and post authentication continue to use their existing credential checks. Restoring the original key restores access to the existing verifier and preserves the partner's client secret. If the original key cannot be restored, use the existing authorized client-secret rotation or partner re-provisioning process. That action replaces the partner secret and returns the replacement once through the existing one-time handoff; it is not a verifier-key restoration. The replacement still follows its configured lifetime. An expired migrated verifier cannot be made usable by re-wrapping it, and an original key restoration does not extend its deadline. Do not try to recover a partner secret from its stored hash.

## Diagnostic boundaries

Lockspire suppresses its sensitive Ecto query Logger output and raw query telemetry for operations that bind or return stored verifier material. It maps owned crypto and storage failures to fixed safe reasons before formatting reports. This does not control host-installed telemetry handlers, custom instrumentation, or PostgreSQL server logging. Hosts must review those channels under their own logging and retention policies; Lockspire does not change host-global logging settings.

## Supported authentication surface

`client_secret_jwt` remains limited to HS256 on the five existing direct-client endpoints that share the verifier: `/token`, `/revoke`, `/introspect`, `/device/code`, and `/backchannel/authentication`. `/par` remains unsupported for this method. The configuration does not add HS384/HS512, FAPI support, or generic JWT client authentication.

The selected shared-PostgreSQL repository and its declared delegating client/transaction composition are covered by installed proof on the locked Phoenix 1.8.13 / LiveView 1.2.10 and floor Phoenix 1.8.5 / LiveView 1.1.28 pairs. This does not imply support for arbitrary stores. A custom store must declare the same selected client, transaction, and audit authority and implement the maintenance capability; unsupported or inconsistent declarations fail closed.
