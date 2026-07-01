# Next Release Notes Draft

These notes summarize user-facing changes currently on `main` after `1.2.0`. They are a draft for a future Release Please or release-review pass and do not publish a new Hex package by themselves.

## Adoption Trust

- Lockspire now keeps public OAuth/OIDC routes separate from the host-mounted admin router, making it clearer which surfaces are safe to expose publicly and which must stay behind host-owned operator authentication.
- Installer verification now checks the public mount, guarded admin mount, device verification route, pending migrations, and prefix-aware table presence.
- Package hygiene guards now keep local build artifacts, backup files, and PLT caches out of Hex package inputs.

## Prefix-Isolated Storage

- New generated installs default Lockspire-owned database tables and Oban jobs into a dedicated `lockspire` PostgreSQL schema.
- Existing public-schema installs remain compatible until they explicitly opt in.
- Migration helpers, repository calls, worker queries, install/upgrade CLI options, docs, and the adoption demo now understand the storage prefix.

## CI And Release Hygiene

- Main CI now avoids duplicated security/static work while preserving the release hygiene, QA, docs, dependency audit, package build, fast test, integration, and migration-reversibility gates.
- A minimum supported Elixir/OTP compatibility job now proves compile and fast tests on the supported floor.
- Release workflow cache keys now include OS, OTP, Elixir, and lockfile inputs for more precise reuse.
- Dialyzer remains available as an opt-in maintainer gate until the baseline is clean enough for mandatory PR enforcement.

## Operator And Demo Polish Since 1.2.0

- The admin/operator UI received page-first IA, Support and Operate flow polish, Configure propagation, redaction-safe fixtures, rendered HTML guardrails, browser/manual evidence, and bounded operator docs.
- The adoption demo has a single base URL contract, Docker-first app plus PostgreSQL startup, conflict-resistant project/port controls, optional Traefik routing, redacted startup output, smoke proof, and scoped cleanup helpers.
