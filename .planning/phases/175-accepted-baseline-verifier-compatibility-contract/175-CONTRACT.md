# Phase 175 Verifier Compatibility Contract

This is the finite input contract for Phase 176–178 acceptance. It describes
required behavior and proof ownership; it does not claim that those runtime or
maintenance behaviors exist today. `175-COMPATIBILITY.json` is the machine
ledger. Every row carries its caller, lifecycle, processing stage, storage
composition, result, permitted mutation, preserved fields, redaction, owner,
evidence status, and blocker.

## Qualified premises

The entry baseline is `173059a166e9ade0f5f57c9980b7b2400a98538c`. Plan 02's
persisted caller and public metadata-reader gates are qualified against tested
source `8df8c479e97b25d28910509e0bbb6dfbad4d421b` and Plug.Crypto 2.2.1; the
owner-approved policy revision is `175-POLICY-REVISION.md`. These are premises
for this contract, not acceptance of the changed source by main. The final
source gate remains in `175-FINAL-SOURCE.json`.

Observed through `ClientAuth.authenticate/3`, a valid 23-hour legacy verifier
authenticates before JTI insertion, while a two-day-old or future-dated
verifier fails before JTI insertion. Authenticated metadata supported by the
qualified reader is `{data, signed_ms, max_age_seconds}`, `{data, signed_ms}`
with 86,400 seconds, and `%{data: data, signed: signed_ms}` with 86,400
seconds. Decode only after public authenticated decrypt and safe term decoding.
The timestamp is integer milliseconds; the observed producer stores seconds
as milliseconds. Positive finite fractional ages are seconds (0.5 seconds was
qualified as 500 ms); deadlines are `signed_ms + trunc(max_age_seconds *
1000)`. Plug legacy expiry is strict-after-deadline and rejects future times.
Configured client and secret deadlines reject at equality on the separately
injected lifecycle clock. Never replace this behavior with infinity.

The approved native policy follows configured client-secret lifetime, while
client-app expiry remains separate. A `nil`/`0` or v0-unlimited secret lifetime
can remain eligible beyond 24 hours. Migrated legacy material retains its
authenticated original finite deadline and cannot gain a fresh age window.
Future, malformed, tampered, wrong-key, unsupported-shape, and nonpositive or
infinite migration-age inputs remain unchanged and unsupported; recovery is
authorized secret rotation/reprovision. A missing/invalid/divergent stored
hash-verifier pair is migration-not-ready; this does not introduce a per-request
hash comparison.

## Configuration and failure contract

The future purpose-specific application setting is
`config :lockspire, Lockspire.Security.ClientSecretVerifier, ...` with exactly
these keys:

| Key | Type and meaning |
|---|---|
| `:keys` | Non-empty ordered list of `{key_id, encoded_key}` pairs. IDs are unique ASCII `[A-Za-z0-9._-]{1,32}`; key bytes decode to exactly 32 bytes. Use the existing `KeySet` base64/base64url conventions; reject malformed encodings, duplicate decoded bytes, duplicate options, and unknown options. |
| `:current` | Optional key ID in `:keys`. Omitted or `nil` is valid for legacy writes and reader-only staging; if present it must name a configured key and still does not activate dedicated writes. Dedicated writes require it. |
| `:write_mode` | Required enum `:legacy` or `:dedicated`; no implicit activation from merely staging keys. |
| `:legacy_read` | Required enum `:allow` or `:reject`. |

The setting is resolved into an immutable node context through restart/redeploy.
It is separate from endpoint/session secrets and signing KEKs. Explicit operation
overrides must supply a complete valid context rather than partially merging
with ambient configuration. Legacy endpoint-secret selection remains explicit
at the integration boundary; dedicated crypto does not scan application
configuration for fallback secrets.

Valid states are: absent setting for declared legacy compatibility; keys staged
with legacy writes and reads; dedicated writes with legacy reads; and dedicated
writes with legacy rejection. Reader-only staging can omit a current write key.
Legacy-write mode may omit `:current` or provide a configured key ID for staging;
the latter never activates dedicated writes. Dedicated writes require a
configured current key. Legacy writes plus rejecting
legacy reads is invalid. Present-but-invalid configuration remains diagnosable
as invalid and never falls back to absence or a legacy writer. Affected verifier
reads, verifier-producing writes, and maintenance fail locally with typed
internal reasons; unrelated supported hash authentication stays available.
Startup diagnostics expose state and safe reason codes, not values or keys.

The dedicated internal error atoms are `:client_secret_verifier_configuration_invalid`,
`:client_secret_verifier_key_missing`, `:client_secret_verifier_key_unknown`,
`:client_secret_verifier_identity_missing`, `:client_secret_verifier_unsupported_format`,
`:client_secret_verifier_unavailable`, and `:client_secret_verifier_legacy_rejected`.
The legacy public unseal helper retains its existing
`{:error, :invalid_client_secret_jwt_verifier}` result. Client JWT authentication preserves
the existing public protocol boundary: missing verifier maps through
`client_secret_verifier_missing`; malformed, missing-key, wrong-key, policy
rejection, and invalid configuration map to `invalid_client` with the existing
allowlisted `client_secret_verifier_unavailable` reason. No key/config detail
is returned to the peer. Maintenance/task callers receive typed operation
results with no raw input values. The contract does not add error names to the
currently exported API until their owning implementation plan.

## Dedicated envelope and bounded inputs

Dedicated verifier text is ASCII:

```text
LSCV1.<key_id>.<base64url-unpadded(payload)>
```

The decoded envelope payload is exact: `iv:12 bytes || tag:16 bytes ||
ciphertext`. AES-GCM ciphertext decrypts to the exact plaintext
`version:u8 (= 1) || secret_length:u32be || secret_bytes || age_kind:u8`.
`age_kind = 0` is native material and has no suffix. `age_kind = 1` is migrated
material followed by `signed_at_ms:i64be || deadline_ms:i64be`. Reject unknown
age kinds, truncated or trailing bytes, a length mismatch, and
timestamps/deadlines outside the authenticated metadata representation. Native
material is checked against configured client-secret lifetime. Migrated
material is checked against its stored authenticated deadline and the existing
client/secret lifetime rules.

Use AES-256-GCM with a fresh 12-byte IV and exactly 16-byte tag. The AAD is the
exact byte sequence:

```text
lockspire-client-secret-jwt-verifier NUL LSCV1 NUL key_id NUL client_id_utf8
```

There is no Unicode normalization or identity substitution. The exact purpose,
version, header, key ID, and canonical persisted client ID are authenticated.
The legacy signing envelope is unchanged. The entire `LSCV` family prefix is
reserved: `LSCV1.` is the only supported version and any other or malformed
`LSCV` input is handled only as dedicated input. Bad version/header,
noncanonical base64url, wrong key/purpose/client, tag failure, substitution,
and trailing bytes reject without legacy retry.

For this new format only, client ID and secret each have a 1,048,576-byte
maximum, measured in bytes. This is a generous parser/allocation bound compared
with generated credentials, not a claim about a legacy or database maximum.
Lockspire-generated secrets are 32 random bytes encoded to 43 unpadded
Base64URL characters; generated IDs are `ls_` plus 24 random bytes encoded to
32 characters (35 total). Existing direct IDs and helper inputs outside those
generated lengths remain accepted by the legacy contract. An oversized legacy
row is blocked from migration/activation and remains unchanged; never truncate,
normalize, or retry it through another format. If the implementation requires
a different supported legacy input boundary, return to GSD revision.

The maximum migrated plaintext is 1,048,576 + 6 + 16 = 1,048,598 bytes.
Including the 12-byte IV and 16-byte tag, the encoded payload is at most
1,048,626 bytes. Its unpadded Base64URL length is 1,398,168 bytes; the maximum
key ID is 32 bytes; therefore the maximum ASCII envelope is 6 + 32 + 1 +
1,398,168 = 1,398,207 bytes. Enforce total encoded length before decoding and
decoded component lengths before use. The cap is an opt-in dedicated-format engineering bound;
it does not narrow the current legacy seal helper, which accepts any binary
secret, or alter its nonempty authenticated-read behavior.

## Helper and writer contract

Preserve `Clients.rotate_secret_hash/0` as `{hash, plaintext}` with no identity
or verifier configuration requirement; it is hash-only and must not generate
discarded verifier material. Preserve `Clients.rotate_secret_material/1` as a
map containing `client_secret`, `client_secret_hash`, and
`client_secret_jwt_verifier_encrypted`. Preserve the binary `secret_key_base`
and keyword overloads of `Policy.seal_client_secret_jwt_verifier/2` and
`Policy.unseal_client_secret_jwt_verifier/2` in legacy mode. Existing
unseal failure remains `{:error, :invalid_client_secret_jwt_verifier}`.
Dedicated material requires an explicit final client ID; missing identity is a
clear typed failure before persistence. Breaking current helper arities,
returns, or accepted legacy inputs requires GSD revision.

Direct registration, DCR, and operator rotation all choose or retain the final
persisted client ID before sealing. Hash and verifier are persisted coherently.
The existing plaintext handoff remains one-time, including Basic/post clients
that receive verifier material. No temporary ID, identity-free dedicated
fallback, or persisted plaintext is permitted. Preserve current HS256,
issuer/audience, assertion lifetime, JTI/replay, app/secret expiry, PAR/FAPI,
introspection/revocation/device/CIBA method boundaries. JTI may already be
consumed when a later lifecycle failure occurs, as qualified; successful
maintenance between JWT authentication and guarded issuance must preserve the
ciphertext-sensitive fingerprint, reject changed credentials without token or
grant success, and require a fresh assertion/JTI on retry.

## Finite proof ownership

The JSON ledger names each acceptance case and distinguishes qualified Phase
175 evidence from pending implementation proof. Phase 176 owns exact config,
envelope, helper, writer, reader, protocol, and rollout tests. Phase 177 owns
maintenance, store authority, concurrency, rollback, recovery, status, and
success/failure disclosure sentinels. Phase 178 owns the existing package pairs,
declared adapter composition, focused review, and delivery evidence. Pending
rows remain pending: planning assertions and validator success do not certify
runtime behavior, fleet parity, backups, quiescence, or rollback safety.
