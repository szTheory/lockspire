# Phase 161 SAFE-02 Evidence: v1.44 milestone diff

## Scope

- Base: `038df080748c046829f9f98297da8403c47b4d89` (origin/main, v1.43 squash)
- Head (git rev-parse HEAD at run time): `9471f0981a3686597717b10453de19b03bbfa60f`
- Plan 161-04 re-binds this evidence to the v1.44 squash SHA by confirming the pushed branch tip has the same tree as the squash commit. Only `.planning/` files are added after this head.

## Claim

No change to protocol code (lib/lockspire/protocol), schema, dependencies or security defaults; additive key-encryption-key config feature work only.

## Diff checks

### Forbidden paths (expected empty)

```
git diff --stat 038df080748c046829f9f98297da8403c47b4d89..HEAD -- mix.exs mix.lock priv/repo/migrations lib/lockspire/protocol config examples compatibility
```

Output: (empty)

### lib/lockspire/domain, security, storage

```
git diff --name-only 038df080748c046829f9f98297da8403c47b4d89..HEAD -- lib/lockspire/domain lib/lockspire/security lib/lockspire/storage
lib/lockspire/security/key_encryption/key_set.ex
```

| Path | Justification |
|------|---------------|
| lib/lockspire/security/key_encryption/key_set.ex | Adds public `valid_id?/1` and moves the module attribute `@id_pattern` (same regex `~r/\A[A-Za-z0-9._-]{1,32}\z/`) above it; `check_id/1` now calls `valid_id?/1`. Same accept/reject rule as before; lets `mix lockspire.gen.kek` validate `--id` with the one rule `KeySet.new/1` enforces. Confirmed by reading the full diff. |

No change under lib/lockspire/domain or lib/lockspire/storage.

### Changed paths outside .planning/, by top-level directory

```
git diff --name-only 038df080..HEAD | grep -v '^\.planning/' | awk -F/ '{print $1"/"$2}' | sort | uniq -c
   1 PRODUCT.md/
   1 docs/install-and-onboard.md
   1 docs/operator-admin.md
   1 docs/upgrading
  12 lib/lockspire
   6 lib/mix
   2 scripts/acceptance
   1 scripts/maintainer
   2 test/integration
   9 test/lockspire
   6 test/mix
   3 test/support
```

The scripts/maintainer and test/support changes (plus the matching test/lockspire release-train assertions) come from the D-16 release-gate repair in plan 161-02. They sit outside the SAFE-02 forbidden categories (protocol code, schema, dependencies, security defaults). The 18 changed lib files are: admin.ex, application.ex, clients/registration_result.ex, config.ex, generators/install.ex, generators/kek_snippet.ex, install/repo_runner.ex, install/task_error.ex, install/verify.ex, security/key_encryption/key_set.ex, web/live/admin/keys_live/index.ex, web/live/admin/keys_live/protection.ex, and the mix tasks client.create, doctor.key_encryption, doctor.remote_jwks, doctor.token_format, gen.kek, keys.reencrypt.

### Security-default check

```
git diff -U0 038df080..HEAD -- lib | grep -nEi '^[+-][^+-].*(pkce|S256|redirect_uri|hash|ttl|rotation|alg|none)'
223:+    "invalid :signing_alg for :lockspire.",
```

The single hit is an added prefix string in the `@config_message_prefixes` allow-list of `lib/lockspire/install/task_error.ex` (it matches an existing config error message so the Mix task can show it; it configures no algorithm). No PKCE, redirect-match, secret-hash, code TTL, refresh rotation or algorithm setting was added, removed or changed. lib/lockspire/protocol and config/ are unchanged (see the empty forbidden-path diff).

## No-leak sweep

Command (added lines of the v1.44 lib/ diff, with file:line from the hunk headers):

```
git diff -U0 038df080..HEAD -- lib | <keep single-plus lines> | grep -E 'Logger\.|:telemetry|IO\.puts|IO\.inspect|Mix\.shell|inspect\(|raise'
```

There are no hits for `:telemetry`, `IO.puts` or `IO.inspect`: no telemetry event and no direct IO output was added.

| File:line | What is emitted | Verdict |
|-----------|-----------------|---------|
| lib/lockspire/config.ex:254 | comment mentioning "raises" | comment, no output |
| lib/lockspire/config.ex:325, 332 | `raise ArgumentError` with fixed phrase naming the env var NAME (`LOCKSPIRE_KEY_ENCRYPTION_KEY`), never its value | allowed (names a variable, not a value) |
| lib/lockspire/generators/kek_snippet.ex:23 | `raise ArgumentError` fixed phrase about key id rules | allowed |
| lib/lockspire/generators/kek_snippet.ex:33 | text inside generated config snippet: `raise("<VAR> is missing...")`, written into a heredoc, not executed here | allowed (snippet text, env var name only) |
| lib/lockspire/install/repo_runner.ex:13, task_error.ex:6, 8, 16; keys_live/index.ex:190, 289; client.create:45; doctor.token_format:75 | comments | comment, no output |
| lib/lockspire/install/task_error.ex:84, 85, 98, 99 | `Logger.get/put/delete_process_level` only; lowers log noise from the repo start, emits nothing | allowed |
| lib/mix/tasks/lockspire.client.create.ex:57, 60, 134 | `Mix.raise` with fixed phrase from `TaskError` or formatted domain errors | allowed (no secret interpolated) |
| lib/mix/tasks/lockspire.doctor.remote_jwks.ex:83, 87 | `Mix.raise("Could not inspect client: " <> classified phrase)` | allowed (fixed phrase) |
| lib/mix/tasks/lockspire.doctor.token_format.ex:68, 71 | `Mix.shell().info` with classified fixed phrase | allowed |
| lib/mix/tasks/lockspire.gen.kek.ex:33 | prints help text | allowed |
| lib/mix/tasks/lockspire.gen.kek.ex:34 | `--raw` prints the freshly generated key | allowed: this is the one key output path (stdout of `mix lockspire.gen.kek`) |
| lib/mix/tasks/lockspire.gen.kek.ex:64, 67, 73 | `Mix.raise` echoing option names / argv typed on the command line, or a fixed id-rule phrase | allowed (user-typed CLI args, no key) |
| lib/mix/tasks/lockspire.gen.kek.ex:83, 87, 88, 89, 91, 95, 97 | guidance text; line 88 prints `VAR=<freshly generated key>` | allowed: freshly generated key shown once on stdout, the only key output |

The only place key material is printed is `mix lockspire.gen.kek` stdout (lines 34 and 88). No hit interpolates an existing key, KEK, client secret or JWK value. `lockspire.doctor.key_encryption.ex` and `lockspire.keys.reencrypt.ex` have no hits.

### Key-material grep over the non-.planning diff

```
git diff -U0 038df080..HEAD -- . ':!.planning' | <added lines> | grep -E '<PEM private-key header>|private_jwk|"d" *=>|"d":|LOCKSPIRE_KEY_ENCRYPTION_KEY=[A-Za-z0-9+/=]{20,}|[A-Za-z0-9+/]{40,}={0,2}'
test/support/lockspire/release_proof/package_assertions.ex:  "source `5d10ce2219c2e687cf9573c8b280abfb118a47d8`",
test/support/lockspire/release_proof/workflow_assertions.ex:  "source `5d10ce2219c2e687cf9573c8b280abfb118a47d8`",
```

Both hits are a 40-hex git commit SHA of the public 1.5.0 release inside release-proof assertions. They are public source identifiers, not keys. No PEM header, private JWK member, private_jwk reference or KEK assignment appears in the non-planning diff. (An unrestricted grep also matches planning documents that quote the names `private_jwk_encrypted`, PEM header names and similar as prose; those are descriptions of what tests forbid, not values.)

## Test and gate runs (Elixir 1.19.5-otp-28, Erlang 28.5, Postgres at /tmp:5432)

All 13 targeted paths are tracked by git (`git ls-files --error-unmatch` succeeded for each), so none were dropped.

| Command | Result |
|---------|--------|
| `MIX_ENV=test mix test test/lockspire/redaction/redaction_test.exs test/mix/tasks/lockspire_gen_kek_test.exs test/lockspire/kek_guidance_contract_test.exs test/lockspire/config_key_encryption_test.exs test/lockspire/web/live/admin/vocabulary_contract_test.exs test/lockspire/web/live/admin/keys_live/protection_test.exs test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/upgrade_guide_contract_test.exs test/lockspire/documentation_contract_test.exs test/mix/tasks/lockspire_doctor_key_encryption_test.exs test/mix/tasks/lockspire_keys_reencrypt_test.exs test/mix/tasks/lockspire_client_create_cold_test.exs test/lockspire/install/task_error_test.exs` | `199 tests, 0 failures` |
| `mix qa` | exit 0 |
| `mix docs.verify` | exit 0 |
| `MIX_ENV=test mix test.fast` | exit 0, `2 properties, 1875 tests, 0 failures, 6 skipped (324 excluded)` |
| `bash scripts/maintainer/repo_hygiene_check.sh --ci` | exit 0, `Summary: 18 PASS, 0 WARN, 0 BLOCK` |

`mix test.integration` was not run locally; CI's Integration Checks job covers it and plan 161-04 records that job's result.

Prior evidence: `.planning/phases/158-mix-task-repo-start/`, `.planning/phases/159-key-encryption-key-setup-dx/` and `.planning/phases/160-admin-key-protection-missing-kek-copy/` SECURITY and VERIFICATION files (for example 160-SECURITY.md and 160-VERIFICATION.md).

Verdict: SAFE-02 PASS at 807802b693c2aa8a76d8b70c4db9bfebd13f557e
