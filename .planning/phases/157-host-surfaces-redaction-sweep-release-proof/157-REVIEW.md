---
phase: 157-host-surfaces-redaction-sweep-release-proof
reviewed: 2026-10-16T00:00:00Z
depth: standard
files_reviewed: 33
files_reviewed_list:
  - lib/lockspire/redaction.ex
  - lib/lockspire/storage/ecto/repository/signing_key_store.ex
  - lib/lockspire/storage/ecto/signing_key_record.ex
  - lib/lockspire/protocol/private_jwk.ex
  - lib/lockspire/protocol/id_token.ex
  - lib/lockspire/protocol/logout_token.ex
  - lib/lockspire/protocol/jarm.ex
  - lib/lockspire/protocol/introspection_jwt.ex
  - lib/lockspire/protocol/jar.ex
  - lib/lockspire/protocol/token_exchange/internal/access_token_signer.ex
  - lib/lockspire/generators/install.ex
  - lib/lockspire/config.ex
  - examples/adoption_demo/config/runtime.exs
  - examples/adoption_demo/priv/repo/seeds.exs
  - examples/adoption_demo/docker-compose.yml
  - scripts/acceptance/clean_room/build_provider.py
  - scripts/acceptance/clean_room_saas_journey.py
  - .github/workflows/ci.yml
  - mix.exs
  - docs/upgrading/signing-key-encryption.md
  - test/support/key_material_matcher.ex
  - test/support/signing_consumers.ex
  - test/lockspire/security/key_material_leak_test.exs
  - test/lockspire/storage/ecto/signing_key_record_test.exs
  - test/lockspire/redaction/redaction_test.exs
  - test/lockspire/protocol/private_jwk_test.exs
  - test/lockspire/protocol/envelope_signing_consumers_test.exs
  - test/lockspire/workers/backchannel_logout_delivery_worker_test.exs
  - test/integration/signing_key_upgrade_journey_test.exs
  - test/integration/install_generator_test.exs
  - test/lockspire/config_key_encryption_test.exs
  - test/lockspire/upgrade_guide_contract_test.exs
findings:
  critical: 0
  warning: 3
  info: 3
  total: 6
status: issues_found
---

# Phase 157: Code Review Report

**Reviewed:** 2026-10-16
**Depth:** standard
**Files Reviewed:** 32 (the AGENTS.md and CONTEXT.md entries in the scope list are context, not reviewed code)
**Status:** issues_found

## Summary

I traced the diff against c743e367 for key-material and KEK leakage paths and found no blocker.

- **Public reads.** `list_public_keys` and the two JWKS-style reads select `struct(key, ^@public_fields)`. Each one strips private material afterwards, so no caller loses a field it needs.
- **Private-key reads.** Every read or write that touches `private_jwk_encrypted` goes through `Support` with `sensitive: true`: the active-key fetch, the encryption-key fetch, `fetch_signing_key_by_id`, the `FOR UPDATE` locks, `publish_key`, and the compare-and-set in `replace_material`. The list default flipped to `sensitive: true` safely, and `Admin.Keys` already passed it explicitly.
- **Changeset and Ecto redaction.** `cast` no longer receives the sealed bytes, and the schema field has `redact: true`.
- **Telemetry and audit redaction.** The new drop keys do not collide with any metadata key emitted in `lib/`. The one `"jwk"` hit is the DPoP header parser, which is not a metadata emission.
- **Operator commands and output strings.** The mix tasks and flags the upgrade guide cites exist (`lockspire.keys.reencrypt --dry-run` and `--check`, `lockspire.doctor key_encryption`, `Admin.Keys.reencrypt` and `encryption_status`). The output strings I spot-checked match the code: `ready=`, `Ready:`, `rows:`, `kek=`, `would_encrypt`.
- **CI and clean-room scripts.** The CI steps run after the seeded DB and the smoke test, with `MIX_ENV=dev`. The clean-room KEK is random per run and registered with the redactor.

The warnings below are about the strength of the leak guard, demo seed idempotency, and one operator-doc inconsistency.

## Warnings

### WR-01: `PrivateJwk.to_jwk/1` does not guard the code path that handles private bytes

**File:** `lib/lockspire/protocol/private_jwk.ex:41-54`
**Issue:** The function's comment says it exists so a JOSE exception never carries decoded private bytes. It only calls `from_map` and `to_public`, which exercises the public-key path. The real exposure is `JOSE.JWT.sign` (or `JOSE.JWK.block_decrypt`) running later on the private parameters (`d`, `p`, `q`).
- A map with a valid public half and corrupt private parameters, or a public-only map, returns `{:ok, jwk}`.
- The raise then happens in `IdToken`, `Jarm`, `LogoutToken`, `IntrospectionJwt` and `AccessTokenSigner`, none of which wrap `JOSE.JWT.sign` in a rescue. `Jar.decrypt` does wrap its call.
- An `:crypto`/`:public_key` error there can embed the private key tuple in the exception message and stacktrace, which then flows to crash reports and error trackers.

**Fix:** Either assert a private member is present and consistent inside `to_jwk`, or add a small `PrivateJwk.sign/3` wrapper that holds the rescue and returns `{:error, :invalid_signing_key}`, and have the five signers call it.
```elixir
def sign(jwk, header, claims) do
  {_, compact} = jwk |> JOSE.JWT.sign(header, claims) |> JOSE.JWS.compact()
  {:ok, compact}
rescue
  _ -> {:error, :invalid_signing_key}
catch
  _, _ -> {:error, :invalid_signing_key}
end
```
At minimum, also reject maps with no private member (`d` for RSA/EC/OKP, `k` for oct) in `to_jwk`.

### WR-02: Demo seeds are no longer idempotent and create duplicate key lifecycles on re-run

**File:** `examples/adoption_demo/priv/repo/seeds.exs:77-96`
**Issue:** The old seeds upserted fixed kids through `Repository.publish_key`, so running them twice was harmless. The new seeds always generate four fresh random-kid keys. Running `mix run priv/repo/seeds.exs` twice (without `ecto.reset`) leaves 8 keys. Each run also activates a new key and demotes the previous active key, so the JWKS and the active signing key change underneath running demo clients. Other seed sections in this file (`Repository.register_client`) may fail or upsert on re-run, so the file now mixes idempotent and non-idempotent sections.
**Fix:** Guard the block with a check that no signing keys exist.
```elixir
if match?({:ok, []}, Lockspire.Admin.list_keys()) do
  # ...seed the four keys...
end
```

### WR-03: Upgrade guide contradicts itself on when generating keys is safe

**File:** `docs/upgrading/signing-key-encryption.md:14,100`
**Issue:** "Before you start" step 4 says not to generate, publish or activate keys until step 4 is done, and step 4 says generating "now works". The code (`Admin.Keys.generate_key`) only requires a configured keyset (`Config.key_encryption_keyset()`), not `:reject` mode. After step 1 with `:allow`, generation works and produces sealed keys. An operator reading step 4's wording might think a failure after step 1 is expected, or might take the "do not generate" advice as meaning the system blocks it. The rationale (a rolling deploy with mixed nodes) is correct but is not stated.
**Fix:** Reword step 4 to something like "Generating, publishing and activating keys is safe once every node runs the KEK config. New keys are always sealed." In the "Before you start" list, state the actual risk: a node without the KEK cannot read a sealed key written by another node.

## Info

### IN-01: Install generator prints a fresh random dev KEK, but `kek_id` depends on the run date

**File:** `lib/lockspire/generators/install.ex:125-127`
**Issue:** `instructions/1` calls `DateTime.utc_now()` and `:crypto.strong_rand_bytes/1`, so its output is nondeterministic. Re-running the installer prints a different id and dev key. The generated dev/test block embeds the literal key in source control. That is intentional and labelled "dev/test only", but a host that copies the dev block into a shared staging env would run on a public literal.
**Fix:** The warning comment is adequate. Consider also stating in step 9 that the `config/test.exs` literal must not be reused outside dev and test. Computing the values once in `run/…` and passing them via assigns would make the output testable.

### IN-02: Magic KEK id `"demo-1"` and the public literal appear in two places

**File:** `examples/adoption_demo/config/runtime.exs:7,19`
**Issue:** The id `"demo-1"` is repeated four times across the prod and non-prod branches. The branches are otherwise identical, so a rotation edit can drift. The public fallback literal is clearly labelled, and the non-prod branch means any `MIX_ENV` other than `:prod` (for example a docker build using `MIX_ENV=dev`) silently runs on a public KEK.
**Fix:** Bind `kek_id = "demo-1"` once and branch only on the key source.

### IN-03: `build_provider.py` mutates the process-global environment from a library function

**File:** `scripts/acceptance/clean_room/build_provider.py:242-248`
**Issue:** `prepare_provider` calls `os.environ.setdefault(...)` to cover standalone callers, which has side effects visible to every later subprocess in the same Python process. This is benign now, because `clean_room_saas_journey.main` sets the registered key first and `setdefault` leaves it alone. In the standalone path, however, the key is generated outside the `Redactor` secret registry, so a stray echo of the KEK would not be scrubbed.
**Fix:** Call `register_secret` (or accept the key as a parameter) in the standalone path, or document that standalone callers must provide the env var.

---

_Reviewed: 2026-10-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
