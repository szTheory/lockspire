# `phx_new_host` test fixture

A trimmed, committed capture of a real `mix phx.new` host application, used by
`test/integration/install_host_interaction_test.exs` to prove `mix lockspire.install`
resolves app name, web module, router module, scope module, and repo module from a
real host rather than from a placeholder the test itself supplied.

## Capture provenance

- **Command:** `mix phx.new host_app --database postgres`
- **`phx_new` archive version:** `1.8.9` (pinned)
- **Elixir:** `1.19.5`
- **OTP:** `28`
- **`phx.gen.auth`** was also run against the generated host (`mix phx.gen.auth Accounts User users`),
  which is why `config/config.exs` carries a `:scopes` block and `lib/host_app_web/router.ex` carries
  the authentication routes.
- **Capture date:** 2026-07-29
- **Source:** `tmp/adopter-walk/host_app/` — the Phase 126 adopter-walk harness's real, warm
  `phx.new`/`phx.gen.auth` output (`.gitignore:10` keeps `/tmp/` out of the tracked tree, so this
  snapshot is the only copy of that output that survives in the repo).

## What is committed and why

Only the middle-fidelity file set below is committed. A `mix.exs`-only snapshot is the strict
minimum `Mix.Project.in_project/4` needs to resolve the host, but committing only that would weaken
the claim that this is "a freshly generated Phoenix application" (INSTALL-01). Full fidelity
(`assets/`, `deps/`, `_build/`, `mix.lock`, `test/`, and every `*_test.exs`) is unnecessary for the
proof this fixture backs and would bloat the repo for no evidentiary gain.

```
mix.exs
config/config.exs
config/dev.exs
config/test.exs
lib/host_app/application.ex
lib/host_app/repo.ex
lib/host_app_web/router.ex
lib/host_app_web/endpoint.ex
```

Not committed: `assets/`, `deps/`, `_build/`, `priv/`, `mix.lock`, `test/`, and any `*_test.exs`.

## Wiring stripped from the walk capture

The Phase 126 walk harness's `tmp/adopter-walk/host_app/` is *post*-`mix lockspire.install` — it
already has Lockspire wired into `mix.exs`, `lib/host_app/application.ex`, and
`lib/host_app_web/router.ex` by the walk's own manual-wiring steps. This fixture must represent the
adopter's state *before* running the installer (what `install_host_interaction_test.exs` actually
exercises), so the following walk-added wiring was removed during capture:

- `mix.exs`: the local-path `{:lockspire, path: "..."}` dependency (also a non-portable, machine-local
  absolute path that must never be committed), `included_applications: [:lockspire]`, and the
  `:oban`/`:cachex` additions to `extra_applications`.
- `lib/host_app/application.ex`: the `Lockspire.Oban`, `Cachex.child_spec/1`, and `Lockspire.KeyCache`
  supervision children.
- `lib/host_app_web/router.ex`: the `import HostAppWeb.Router.Lockspire` / `lockspire_routes()` call,
  the `:require_operator` pipeline and admin/consent/interaction scopes it emits, the
  `LOCKSPIRE_PROTECTED_PIPELINE` block, and the walk-harness-only `/api/walk/summary` route.
- `config/config.exs`: the `import_config "lockspire.exs"` line (that file does not exist until the
  installer runs).

None of this affects what the proof exercises — `mix lockspire.install` never reads or writes the
host's `mix.exs`, `application.ex`, or `router.ex` (D-08/D-26, zero-injection by design) — but leaving
walk-specific wiring in a fixture that claims to be a pristine pre-install host would misrepresent
what it is meant to prove.

## Secrets stripped

The host's own generated `secret_key_base` values (`config/dev.exs`, `config/test.exs`) and
`signing_salt` values (`config/config.exs`'s `live_view:` key, `lib/host_app_web/endpoint.ex`'s
`@session_options`) were replaced with obvious placeholder tokens. These were `phx.new`-generated
dev/test-only values with no bearing on any live system, but no generated secret literal is
committed here regardless (T-127-10).

## Placement rationale

`priv/test_fixtures/` sits outside every scope that would otherwise sweep this tree up:

| Tool | Scope | Why safe |
|------|-------|----------|
| `mix format --check-formatted` | `.formatter.exs` `inputs: ["mix.exs", "{config,lib,test}/**/*.{ex,exs}"]` | `priv/` is not an input |
| `credo --strict` | `.credo.exs` `included: ["lib/", "test/"]` | `priv/` is not included |
| `mix test` | default glob `test/**/*_test.exs` | not under `test/` |
| `elixirc_paths(:test)` | `["lib", "test/support"]` | not under `lib/` or `test/support` |
| `mix hex.build` | `package_files/0` wildcards `lib/**` and `priv/templates/**` only | `priv/test_fixtures/` is neither |

`lib/**` and `priv/templates/**` were both disqualified for the same reason: both ship to Hex.

## Refresh procedure

The snapshot is refreshed by hand; there is no automated staleness check. Per D-07, no `mix phx.new`
shell-out enters any automated lane — the Phase 126 walk (`mix adopter.walk`) remains the fully-fresh
end-to-end proof, and automating this refresh is Phase 130's territory. To refresh:

1. Run `mix adopter.walk` (or `mix phx.new host_app --database postgres` directly with the pinned
   `phx_new` archive version above) to produce a fresh host.
2. Optionally run `mix phx.gen.auth Accounts User users` against it, matching the shape this fixture
   already carries.
3. Copy the eight files listed above into this directory, replacing them in place.
4. Re-apply the "Wiring stripped from the walk capture" and "Secrets stripped" steps above.
5. Update the capture date, `phx_new` version, Elixir/OTP versions above if they changed.
6. Run `mix test test/integration/install_host_interaction_test.exs` to confirm the refreshed
   snapshot still resolves correctly.
