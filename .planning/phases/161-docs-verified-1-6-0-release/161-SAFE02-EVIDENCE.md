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
