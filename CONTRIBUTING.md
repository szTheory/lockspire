# Contributing to Lockspire

Lockspire is an embedded OAuth/OIDC library for Phoenix applications. This guide maps the repository so contributors can find the maintained inputs, their consumers, and the artifacts that should be retained.

| Area | Purpose | Lifecycle |
| --- | --- | --- |
| `lib/`, `config/`, `priv/repo/migrations/` | Library source, configuration, and installable migrations | Maintained source; library code and migrations are package inputs. |
| `priv/templates/` | Files rendered by the install generator | Maintained generator source and package input; generated host-app files are outputs. |
| `test/` | Unit, integration, and contract tests | Maintained verification source. |
| `compatibility/phoenix_1_8_live_view_1_1/` | Exact supported Phoenix and LiveView compatibility fixture | Maintained verification surface compiled by CI. |
| `examples/adoption_demo/` | Phoenix host-app adoption example | Maintained verification surface compiled and smoke-tested by CI. |
| `docs/`, `README.md`, `SECURITY.md`, and other root Markdown | Guides and repository policy | Maintained documentation source; the configured Markdown pages are package inputs and ExDoc extras. |
| `doc/` | ExDoc output | Generated locally; do not edit as source. |
| `brandbook/` | Lockspire visual source assets | Maintained source; the current package includes only `brandbook/logo/lockspire-favicon.svg`. |
| `_build/`, `cover/`, `.artifacts/`, `deps/`, `node_modules/`, and tool caches | Build, test, coverage, CI, and dependency output | Generated or local output; not durable repository evidence. |
| `tmp/` | Temporary work and retained evidence | Mixed lifecycle: `tmp/admin-ui-polish/` contains retained milestone screenshots governed by `docs/maintainer-release.md`; other contents are not automatically disposable. |
| `.planning/` | Active project records and milestone history | Mixed lifecycle: current planning records and retained historical evidence have different owners and retention needs. |
| `.claude/worktrees/` and Git's linked-worktree registry | Checkouts used for concurrent work | Git-managed worktrees have branch and local-change state separate from tracked repository files. A tracked worktree-shaped snapshot is not the same thing as a registered worktree. |
| Ignored local inputs such as `prompts/` | Checkout-specific material | Local does not mean unused. Check consumers before changing or removing local inputs. |
| Remote CI artifacts | Run-associated test or release evidence | Retained by the workflow for its configured period; distinct from retained evidence tracked in this repository. |

Use the current consumers as the source of truth: `mix.exs` defines package files and ExDoc output, CI workflows identify maintained fixtures and examples, generator code consumes `priv/templates/`, and the maintainer guide records retained repository evidence. A directory name, age, or ignore rule alone does not establish that its contents are disposable.

When adding, moving, or changing the lifecycle of a repository area, update this map and the relevant package, CI, generator, or documentation configuration together. Keep cleanup evidence with the change, and preserve content whose owner, use, or recovery path is unclear.

This is repository contributor guidance and is not included in the current Hex package file list. The README and published-docs navigation are handled separately.
