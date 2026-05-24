# Phase 46: Documentation & Security Audit - Pattern Map

**Mapped:** 2024-05-04
**Files analyzed:** 6
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire.ex` | Config / API | config access | `lib/lockspire/config.ex` | exact |
| `lib/lockspire/admin.ex` | Service | CRUD | `lib/lockspire/config.ex` | role-match |
| `README.md` | Documentation | N/A | `docs/getting-started.md` | exact |
| `SECURITY.md` | Policy | N/A | `SECURITY.md` (existing) | exact |
| `mix.exs` | Config | N/A | `mix.exs` (existing aliases) | exact |

## Pattern Assignments

### Public API Documentation (Typespecs + Moduledocs)

**Analog:** `lib/lockspire/config.ex`

**Moduledoc pattern** (lines 2-4):
```elixir
  @moduledoc """
  Runtime configuration helpers for the embedded Lockspire library.
  """
```

**Doc and Typespec pattern** (lines 40-49):
```elixir
  @doc """
  Returns the configured Lockspire mount path.

  Accepts any binary, including the empty string (`""`), which is a deliberate
  signal that Lockspire is mounted at the host's root. Only `nil` (config
  unset) is rejected — host apps must set this explicitly to declare intent.
  """
  @spec mount_path() :: String.t()
  def mount_path do
```
*Note: We should apply `@doc` systematically to public APIs like `Lockspire` and `Lockspire.Admin`, as well as fixing any `@moduledoc` tags.*

### Security & Dependency Audit Configurations

**Analog:** `mix.exs`

**Audit aliases pattern** (lines 90-95):
```elixir
      "docs.verify": ["docs --warnings-as-errors"],
      "deps.audit": ["hex.audit"],
      "package.build": ["hex.build"],
      "package.publish-dry-run": ["hex.publish --dry-run --yes"],
      "release.preflight": ["package.build", "package.publish-dry-run", "docs.verify"],
```
*Note: A `sobelow` audit could be integrated here, or we use `deps.audit` and manual review. We must ensure CI gates are solid for 1.0.*

### Security Policy and Documentation Update

**Analog:** `SECURITY.md` and `README.md`

**Supported surface pattern** (SECURITY.md lines 21-26):
```markdown
Lockspire's supported security surface is limited to the embedded OAuth/OIDC provider behavior shipped in this repo and described in `docs/supported-surface.md`:

- authorization code + PKCE
- pushed authorization requests only through Lockspire-issued `request_uri` references
```
*Note: Updates to `README.md`, `SECURITY.md`, and guides should transition the messaging from "v0.1 preview" to a mature "1.0 readiness" posture, asserting the stabilized boundaries.*

## Shared Patterns

### Module Documentation completeness
**Source:** `lib/lockspire/config.ex`
**Apply to:** All public-facing modules (`Lockspire`, `Lockspire.Admin`, etc.).
Every public module must have a `@moduledoc`. Every exported function intended for public use must have a `@spec` and a `@doc`. Hidden internals must be marked with `@moduledoc false` or `@doc false`.

### Dependency Scanning
**Source:** `mix.exs` aliases
**Apply to:** `ci` alias and local release scripts.
We utilize `mix hex.audit` and `mix dialyzer` (from the `qa` and `deps.audit` tasks) as part of the formal dependency and API surface verification before 1.0.

## Metadata

**Analog search scope:** `lib/lockspire.ex`, `lib/lockspire/admin.ex`, `lib/lockspire/config.ex`, `SECURITY.md`, `README.md`, `mix.exs`
**Files scanned:** 6
