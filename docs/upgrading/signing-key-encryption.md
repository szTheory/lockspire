# Signing Key Encryption Upgrade Note

The release that adds signing-key encryption stores private signing keys as sealed envelopes under a key-encryption key (KEK) that your app provides at runtime. An app with no key-encryption config keeps booting and signing, but generating signing keys is refused, and `mix lockspire.verify` and `mix lockspire.doctor key_encryption` report the missing KEK until you configure one. See the [CHANGELOG](CHANGELOG.md) for the release that introduced it.

Follow this note in order. Each step says what to run and what you should see. Do not skip the `--check` gate in step 3: it is what proves every stored key opens under your new KEK before you stop accepting plaintext.

## Before you start

1. Generate a KEK. It must be exactly 32 random bytes, base64 encoded:

   ```bash
   openssl rand -base64 32
   ```

   or, without OpenSSL:

   ```bash
   elixir -e 'IO.puts(Base.encode64(:crypto.strong_rand_bytes(32)))'
   ```

   The output of `mix phx.gen.secret` is not 32 bytes and is rejected.

2. Store the KEK in your secret manager, separately from your database backups. A KEK kept next to the data it protects protects nothing.
3. Take a fresh database backup.
4. Avoid generating, publishing or activating signing keys while a deploy is rolling out. Once a KEK is configured, any node that has it seals new keys, even in allow mode. A node that does not have the KEK yet, or that still runs the earlier version, cannot read those sealed keys. Wait until every node runs the new version with the KEK, then generate keys.

## Upgrade in four steps

### Step 1: Add the KEK in allow mode and deploy every node

Put this in `config/runtime.exs`. Use a short id that names the month you created the key (for example `2026-01`); you will need a new id when you rotate.

```elixir
config :lockspire, :key_encryption,
  keys: [
    {"2026-01", System.fetch_env!("LOCKSPIRE_KEY_ENCRYPTION_KEY")}
  ],
  current: "2026-01",
  legacy_plaintext: :allow
```

Deploy every node, then run:

```bash
mix lockspire.doctor key_encryption
```

Expected: the first line reads `key_encryption: configured current=2026-01 ids=2026-01 legacy_plaintext=allow`, followed by a `rows:` line that counts your existing keys under `legacy=`, and a hint to run `mix lockspire.keys.reencrypt`. The command exits 0.

While `legacy_plaintext: :allow` is set, keys that are still plaintext keep signing, and each first use logs a one-time warning and emits a `legacy_read` telemetry event.

### Step 2: Preview, then re-encrypt

```bash
mix lockspire.keys.reencrypt --dry-run
mix lockspire.keys.reencrypt
```

Expected from the dry run: `Dry run: no rows will be changed.`, one `would encrypt` line per legacy key, and a summary such as `scanned=3 would_encrypt=3 would_rewrap=0 already_current=0 failed=0 no_private_key=0`. Nothing is written.

Expected from the real run: a summary such as `scanned=3 encrypted=3 rewrapped=0 already_current=0 failed=0 no_private_key=0 conflicted=0`. A key that cannot be converted is listed as `failed  key=<kid> reason=...` with a `fix:` line, the other keys are still saved, and the command exits 1. Running it again is safe.

**On a release.** The mix task needs Mix, which a release does not ship. On a running node, call the same function through `rpc`:

```bash
bin/app rpc "Lockspire.Admin.Keys.reencrypt(dry_run: true)"
bin/app rpc "Lockspire.Admin.Keys.reencrypt()"
```

Expected: `{:ok, report}`, where the report has the same counts as the task output.

If the VM is stopped, use `eval` and start the repo yourself. A bare release `eval` does not start the repo, so a call without this wrapper returns `{:error, :repo_not_started}`:

```bash
bin/app eval '
Application.load(:my_app)
{:ok, result, _apps} =
  Ecto.Migrator.with_repo(MyApp.Repo, fn _repo ->
    Lockspire.Admin.Keys.reencrypt()
  end)
IO.inspect(result)
'
```

Replace `my_app` and `MyApp.Repo` with your application and repo.

### Step 3: Run the required gate

```bash
mix lockspire.keys.reencrypt --check
```

Expected: `ready=true` and `Ready: every signing key is sealed with key-encryption key 2026-01.`, exit 0. It writes nothing and takes no locks.

This is the required gate. `--check` opens every stored key with your current KEK, which goes further than confirming a column looks encrypted. Each envelope is also bound to the `kid` of its own row, so an envelope copied onto another row is refused. If `--check` exits 1, it lists each pending key with a `fix:` line. Follow those lines and run the check again. Do not continue until it passes. On a release, `Lockspire.Admin.Keys.encryption_status()` through `bin/app rpc` returns the same readiness answer in its `ready?` field.

### Step 4: Switch to reject mode

Change `legacy_plaintext: :allow` to `legacy_plaintext: :reject`, deploy every node, and run the doctor again:

```bash
mix lockspire.doctor key_encryption
```

Expected: `legacy_plaintext=reject`, `legacy=0` on the `rows:` line, exit 0. New signing keys are sealed in every mode, so generating, publishing and activating keys is safe once every node has the KEK. From this point a stored value that is not a sealed envelope is refused before it is parsed.

A `legacy_plaintext` change takes effect on each node's next boot.

## Rotate the key-encryption key

Rotate on your own schedule, or at once if a KEK may have leaked. The order matters: every node must know the new key before any node starts writing with it.

1. Add the new key as a second entry and keep `current` on the old id. Read the new value from `LOCKSPIRE_KEY_ENCRYPTION_KEY_NEXT` (that name is only a convention; any name works). Deploy every node.

   ```elixir
   config :lockspire, :key_encryption,
     keys: [
       {"2026-01", System.fetch_env!("LOCKSPIRE_KEY_ENCRYPTION_KEY")},
       {"2026-07", System.fetch_env!("LOCKSPIRE_KEY_ENCRYPTION_KEY_NEXT")}
     ],
     current: "2026-01",
     legacy_plaintext: :reject
   ```

   Expected: `mix lockspire.doctor key_encryption` shows `ids=2026-01,2026-07` and all rows still under `kek=2026-01`.

2. Set `current: "2026-07"` and deploy every node. Expected: doctor shows `current=2026-07`, and the rows under `kek=2026-01` are reported as needing re-encryption.
3. Run `mix lockspire.keys.reencrypt` (or `bin/app rpc "Lockspire.Admin.Keys.reencrypt()"` on a release). Expected: `rewrapped=` equals the number of keys that were on the old id and `failed=0`. The signing keys themselves do not change, so tokens signed earlier keep verifying.
4. Run `mix lockspire.keys.reencrypt --check`. Expected: `ready=true`, exit 0. Then run `mix lockspire.doctor key_encryption` and confirm there is no `kek=2026-01` line, which means zero rows remain on the old id.
5. Remove the old key from `keys:` and deploy. Expected: doctor lists only the new id and exits 0.

**Never remove an old KEK before `--check` passes, and keep it in your secret manager for as long as you keep any backup that was written under it.** A backup sealed under a key you no longer have cannot be restored to working signing keys.

## Warnings

### Backup remanence

Backups, WAL archives, replicas, snapshots and database dumps taken before re-encryption still hold usable plaintext private keys. Encrypting the rows in place does not change them. Expire those copies on your normal retention schedule. The only full remedy after the switch to `:reject` is to generate new signing keys and retire the keys that were once stored as plaintext, so that anything leaked from an old copy no longer matters.

If your database logs statement parameters (the PostgreSQL settings `log_statement` and `log_min_duration_statement` do, unless `log_parameter_max_length` is set to 0), log files written while keys were still plaintext may also contain key material. Check and expire them too.

### Rollback

Earlier versions of Lockspire cannot read sealed envelopes, and there is no task that turns them back into plaintext. Before you switch to `:reject`, roll back by setting `legacy_plaintext: :allow` again, never by removing the key-encryption config: removing it makes every sealed key unreadable. Rolling the application code itself back to an earlier version after step 2 is not supported without restoring a database backup taken before step 2.

### Losing the KEK

If every configured KEK is lost, the sealed signing keys cannot be recovered. Generate and activate new signing keys. Tokens signed with the lost keys stop verifying once those keys leave your JWKS, so clients must obtain new tokens.

### Keep the KEK backup separate

Keep a copy of every KEK that still protects data, and keep it away from the database backups. As GitLab puts it in its encryption guidance, storing encrypted information in the same location as its key defeats the purpose. Never put a KEK in the same backup, bucket or repository as the database it protects.

## Operational hygiene

- **Crash dumps.** An Erlang crash dump can contain `:persistent_term` values and the memory of every process, and that includes Lockspire's decoded key-encryption keys. Application environment tables are not written to the dump, but anything that copied the key into a process is. Restrict the dump file's permissions and location, or where policy forbids dumps set `ERL_CRASH_DUMP_SECONDS=0` (or `ERL_CRASH_DUMP_BYTES=0`) for the release.
- **Remote shells and Observer.** The raw KEK stays in the application environment, so anyone with a remote shell (`bin/app remote`) or Observer access to the node can read it. Limit who has that access.
- **LiveDashboard.** Never list `LOCKSPIRE_KEY_ENCRYPTION_KEY` (or the `_NEXT` variable) in the `env_keys` option of Phoenix LiveDashboard. It would show the value on the dashboard.
- **Logs and operator pages.** Lockspire never prints key bytes or KEK values in task output, logs, telemetry or admin pages. Keep it that way in any host code that touches the same config.
