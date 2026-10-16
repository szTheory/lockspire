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
4. Do not generate, publish or activate signing keys until step 4 below is done. During a rolling deploy some nodes have the KEK and some do not, and a key written by one kind of node can be unreadable to the other.

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

Expected: `legacy_plaintext=reject`, `legacy=0` on the `rows:` line, exit 0. Generating, publishing and activating signing keys now works. From this point a stored value that is not a sealed envelope is refused before it is parsed.

A `legacy_plaintext` change takes effect on each node's next boot.
