# Release notes: signing-key encryption at rest

## Squash title

feat(keys): encrypt private signing keys at rest under a host-held key (v1.43)

## Version

This is a backward-compatible minor feature. The version in the title is `{VERSION}`; it is filled at ship time (see Ship note).

## PR body

### Upgrade notes - action required

Private signing keys are now stored as sealed envelopes under a key-encryption key (KEK) that your app provides at runtime. Configure a KEK. Until you do, Generate refuses to create signing keys, and `mix lockspire.verify` and `mix lockspire.doctor key_encryption` report the missing KEK. Existing apps keep booting and signing in the meantime.

Upgrade in four steps (full guide: `docs/upgrading/signing-key-encryption.md`):

1. Generate a KEK with `openssl rand -base64 32`, store it in your secret manager (not with your database backups), take a fresh backup, then add the `:key_encryption` block to `config/runtime.exs` with `legacy_plaintext: :allow` and deploy every node. Run `mix lockspire.doctor key_encryption` to confirm.
2. Run `mix lockspire.keys.reencrypt --dry-run`, then `mix lockspire.keys.reencrypt`. On a release use `bin/app rpc "Lockspire.Admin.Keys.reencrypt()"` on a running node.
3. Run `mix lockspire.keys.reencrypt --check`. It must succeed before you continue.
4. Switch to `legacy_plaintext: :reject`, deploy, and run `mix lockspire.doctor key_encryption` again.

Rollback: earlier versions cannot read sealed envelopes and there is no decrypt task. Before step 4, roll back by setting `legacy_plaintext: :allow`; never remove the key-encryption config.

Backups: backups, WAL archives, replicas and snapshots taken before re-encryption still hold usable plaintext private keys. Expire them, or generate new signing keys and retire the old ones after the switch to `:reject`.

New installs: `mix lockspire.install` now prints the runtime and dev/test KEK blocks to add to your config.

### What changed

- Signing keys are stored as AES-256-GCM envelopes bound to each key's ID and opened only at signing time.
- New operator tools: `mix lockspire.keys.reencrypt [--dry-run | --check]` and `mix lockspire.doctor key_encryption`.
- New key telemetry events, documented in `docs/telemetry.md`.

## Ship note

Release PR #121 (v1.42 only) is open. Whether it ships first decides the version number. Decide at ship time, then replace `{VERSION}` and the version in the squash title if it differs. Re-run the commit-marker check on the final branch:

```
git log origin/main..HEAD --format=%B | grep -nE 'BREAK[I]NG|^[a-z]+(\(.*\))?!:'
```

It must print nothing. This is a note only: do not touch release PRs from this phase.
