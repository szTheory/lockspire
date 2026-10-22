# Upgrade app lifetime storage

Lockspire stores three independent lifetimes: an app lifetime, a shared-secret
lifetime, and an app management-token lifetime. Each policy accepts `nil` or
`0` for no automatic expiry and a positive number of seconds for a finite
deadline. The deadline is calculated from that credential's issuance event and
stored with the app; changing policy does not rewrite existing deadlines.
Eligibility ends at the deadline itself. Lockspire checks current stored app
state at online protocol decision points. Existing rows remain compatible
after the additive migration: they are read as legacy records without an app or
management-token deadline. Historical `client_secret_expires_at` values on those
rows remain advisory; nil, past, future, creation-time, or stale post-rotation
values do not create a new rejection deadline for a legacy secret. A legacy
secret continues to work until it is explicitly replaced. Replacement promotes
the current row and uses the current DCR secret-lifetime policy only for
self-registered apps that use a shared secret. Later policy edits do not
rewrite that stored secret deadline.

The renewal events are separate. A new self-registered app receives the app
deadline from the current app-lifetime policy; app expiry has no renewal event,
so the app must be registered again. Operator rotation replaces a shared
secret and snapshots the current secret policy. A successful DCR PUT or the
existing host-authorized recovery task replaces the app management token and
snapshots the current management-token policy. Those operations preserve the
other stored deadlines; GET, authentication, enabling an app, and ordinary
metadata changes do not renew any lifetime. Public-key and mutual-TLS clients
do not have a shared-secret lifetime.

## Install the additive migration

First confirm the configured Lockspire storage prefix and back up the database
using your host's normal procedure. The migration is additive and prefix-aware,
but PostgreSQL must still acquire a table lock to change the client table. Use a
maintenance window appropriate to the size and activity of your database. Do
not assume zero downtime or a universal lock duration.

From the host project, preview and install the packaged migration:

```sh
mix lockspire.upgrade --dry-run
mix lockspire.upgrade
mix ecto.migrate
```

The upgrade task copies missing packaged migrations and refuses conflicting or
changed host migration files. For an intentional non-default schema, configure
the same `storage_prefix` that the host uses at runtime, then preview and apply
with that prefix explicitly, for example:

```sh
mix lockspire.upgrade --dry-run --storage-prefix tenant_auth --oban-prefix tenant_auth
mix lockspire.upgrade --storage-prefix tenant_auth --oban-prefix tenant_auth
mix ecto.migrate
```

Use the host's normal Ecto migration setup so the configured repository and
prefix are used. Keep the packaged migration files already copied to the host
byte-for-byte; Lockspire adds a new migration instead of rewriting historical
files. The installer preflights names, versions, and checksums before copying,
and it does not overwrite host-owned migrations.

## Declare custom client storage support

The built-in `Lockspire.Storage.Ecto.Repository` adapter declares lifetime
contract version `1`, a transaction authority, and `lock_clients/1`. A custom
client store used by token exchange must make the same declaration explicitly:

```elixir
def lifetime_contract do
  %{version: 1, transaction_authority: transaction_authority()}
end

def lock_clients(client_ids) do
  # In the caller's active transaction, deduplicate IDs, lock in stable
  # client_id order, and return the current stored client rows.
end
```

The declared transaction authority must be the same authority declared by the
configured transaction store. Its participant map must identify the actual
client, grant, token, and audit stores used by the operation. Those writes must
share rollback authority; a collection of individually successful callbacks is
not sufficient. Current-row reads must preserve expired and disabled rows so
protocol code can distinguish state from storage failure. Returned clients must
carry an explicit supported lifetime version and valid UTC-second deadlines.
Version `0` rows have nil app and management deadlines; version `1` stores the
selected deadlines (or nil for unlimited). Missing, unknown, or dropped state
fails closed as a storage/configuration error.

The supported selectors are the existing `:client_store` and
`:transaction_store` application configuration keys. A host module can select
both roles when it implements `Lockspire.Storage.ClientStore` and
`Lockspire.Storage.TransactionStore`, declares lifetime contract version `1`,
and reports the same transaction authority and participants from both
behaviors. Lockspire's demonstrated composition is deliberately narrow: the
host adapter delegates the selected client and transaction operations to the
built-in Ecto repository under the same PostgreSQL transaction authority. It
proves that named composition, not arbitrary external databases or every
possible adapter.

```elixir
config :lockspire,
  client_store: MyApp.LifetimeClientStore,
  transaction_store: MyApp.LifetimeClientStore
```

The exact ExUnit/Ecto example executed from the candidate package is in
[`docs/examples/client-lifetime-adapter.md`](../examples/client-lifetime-adapter.md).
Copy its single test module into your host application's `test/` directory,
replace `CleanRoomProvider.Repo` with your host repo module, and run it against
a disposable PostgreSQL test database using your host's normal test setup:

```sh
mix test test/client_lifetime_adapter_test.exs
```

The example checks the configured authority, current-row guards, replacement
rollback, issuance rollback, and fail-closed unsupported state. It uses
`Lockspire.Storage.Ecto.Repository` only to seed and inspect test rows; that
module is not an adapter API. The example is an adopter-run test, not a shipped
conformance SDK. Repository-private files under `test/` and `scripts/` are
maintainer checkout tooling and are excluded from the Hex package.

Maintainers can run the reusable conformance contract and dependency
adaptation checks from a Lockspire checkout:

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test \
  mix test test/lockspire/storage/client_lifetime_conformance_test.exs \
  test/lockspire/protocol/token_exchange/dependencies_test.exs --max-failures 1
```

These checkout-only conformance tests cover explicit declarations, round trips, current-row
guards, participant agreement, and rollback. A custom adapter still needs
adapter-specific evidence that its database and transaction composition meet
those guarantees. The existing `rotate_client_secret/4` adapter operation
accepts either an explicit `DateTime` or a zero-argument clock function without
changing its arity. The default clock function must be evaluated only after the
adapter has locked and reloaded the current row and read the current DCR policy.
The same decision time must determine the replacement timestamp, secret
deadline, and audit time; include this behavior in adapter conformance coverage.

## Roll out and roll back safely

Use this order so no old writer can replace the new lifetime state:

1. Keep the old application version running against the old schema.
2. Apply the additive migration to every configured storage prefix.
3. Stage the candidate application without sending it protocol or admin traffic.
4. Drain every old writer: web nodes, admin processes, Oban jobs, and CLI or
   release tasks. Confirm they have stopped.
5. Cut traffic over to the candidate.
6. Permit the first write that creates authoritative lifetime version `1`
   state only after the drain and cutover.

Before the first version `1` write, the old application can read and write the
expanded schema because its queries ignore the added nullable/defaulted
columns. After that first write, an old binary must not serve protocol traffic:
it does not understand the authoritative fields and can overwrite them. Retain
the expanded schema and lifetime data. Fix forward with a candidate build or
roll back only to a build that understands and preserves these fields. Do not
clear lifetime state or drop the columns as a rollback shortcut.

The migration changes the client table and can wait for or block concurrent
database work. If PostgreSQL reports a lock timeout, stop the migration, inspect
the blocking sessions and active transactions, let or deliberately terminate
the owner under your normal operations policy, then retry during a quieter
window. Do not increase a lock timeout blindly or treat a failed attempt as a
completed migration.

Maintainers can run the packaged acceptance journey for the pinned
pre-lifetime package and candidate in isolated host roots and databases for
`public` and `tenant_auth` from a Lockspire checkout:

```sh
python3 scripts/acceptance/clean_room/client_lifetime_upgrade.py --receipt /tmp/client-lifetime-upgrade.json
python3 scripts/acceptance/clean_room/client_lifetime_upgrade.py --check-receipt /tmp/client-lifetime-upgrade.json
```

The commands above require the repository's private `scripts/` tree; they are
not adopter commands and those scripts are not included in the Hex package.

## Online checks and offline tokens

Lockspire checks current app state on applicable online protocol requests.
For dynamic registration self-management, an expired but enabled app may still
read or delete its registration, while an update is rejected; a disabled app
cannot use those operations. Access tokens already issued are capped by the
app deadline when created. Offline JWT verification does not query current app
state, so a verifier that only checks a JWT cannot learn immediately that its
issuing app was later disabled or expired. Existing cache and offline
verification limits still apply; this upgrade does not promise immediate
revocation of an already-issued JWT.

Shared-secret expiry and operator secret replacement are enforced by the
current Lockspire implementation as described in [Dynamic Client Registration](../dynamic-registration.md).

App management-token expiry is an optional host policy. Blank or zero means no
automatic expiry; a positive duration applies when a self-managed app is
registered or its management token is replaced. Existing tokens keep their
stored deadline when policy changes, and a GET does not extend it. At expiry,
the token can no longer read, update, or delete the registration. An expired
but enabled app can still be read or deleted with an eligible token, while PUT
is rejected; disabled apps cannot use registration management.

Older v0 app records are effectively unlimited for app, shared-secret, and
management-token expiry. Their historical dates remain advisory until an
explicit replacement promotes the current row. Custom storage adapters must
preserve current-row lifecycle fields during app management-token replacement
and host-authorized recovery. See [Dynamic Client Registration](../dynamic-registration.md)
for the required request identity, server-owned expiry extensions, immediate
replacement, and lost-response recovery behavior.

The Phase 166 local packaged lifetime partition completed all nine required
scenarios with 49 checks passed and none failed or skipped. Its observed source
revision was `8050a398`; package archive and extracted-tree digests were checked
against `5709092d`. The broader canonical integration matrix had unrelated
fixture failures, and final-candidate CI plus independent security review are
still pending. See the phase's maintainer evidence record; this local result
does not claim those remaining gates or a release are complete.
