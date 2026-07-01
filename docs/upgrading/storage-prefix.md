# Storage Prefix Upgrade Note

New generated Lockspire installs set:

```elixir
config :lockspire,
  storage_prefix: "lockspire",
  oban_prefix: "lockspire"
```

This is a new-install default only. Existing installs without those keys keep the previous public/default-schema behavior.

Do not add `storage_prefix: "lockspire"` to an existing production app until you have deliberately moved the existing `lockspire_*` tables, Oban tables used by Lockspire, and migration-history expectations. The safe choices are:

- stay public/default by leaving the keys absent, or by setting both prefixes to `"public"`
- use the dedicated `lockspire` schema for a fresh install before the first migration
- run an explicit data-move plan, then rerun `mix lockspire.verify`

Lockspire does not silently move production data during a normal dependency upgrade.
