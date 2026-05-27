# Lockspire

[![Hex version](https://img.shields.io/hexpm/v/lockspire.svg)](https://hex.pm/packages/lockspire)
[![Docs](https://img.shields.io/badge/hexdocs-api%20%26%20guides-5865F2)](https://hexdocs.pm/lockspire)
[![CI](https://github.com/szTheory/lockspire/actions/workflows/ci.yml/badge.svg)](https://github.com/szTheory/lockspire/actions/workflows/ci.yml)
[![License](https://img.shields.io/hexpm/l/lockspire.svg)](https://github.com/szTheory/lockspire/blob/main/LICENSE)

Lockspire is an embedded OAuth/OIDC authorization server library for Phoenix and Elixir applications.

It lets a Phoenix SaaS team become an OAuth/OIDC provider inside its existing app without moving accounts, login UX, branding, or product policy into a separate auth service.

The public support contract for the current release lives in [`docs/supported-surface.md`](docs/supported-surface.md).

## Current release posture

Lockspire is on a GA release line for the embedded Phoenix library wedge documented in [`docs/supported-surface.md`](docs/supported-surface.md). That file is the authoritative support contract and proof boundary for the current release.

Normal sustaining releases ride the repo-owned automated release lane from `main`; maintainers verify train readiness with `./scripts/maintainer/repo_hygiene_check.sh` and close each publish with install-truth verification.

## Orientation

- Embedded OAuth/OIDC provider behavior inside an existing Phoenix app, not a hosted auth service or separate control plane
- Generator-backed install and onboarding with host-owned login, account, branding, and product-policy seams
- Core OAuth/OIDC surface for the documented embedded wedge, with exact supported and unsupported claims defined in the canonical support contract
- Maintainer and operator workflows that stay subordinate to the same repo-proven support boundary

## What Lockspire is not

- Hosted auth as a separate service
- SAML or LDAP federation
- A full CIAM suite
- Lockspire-owned account tables or login UX

For exact scope, non-claims, and repo-owned proof, read [`docs/supported-surface.md`](docs/supported-surface.md) before relying on a feature or topology.

## Guides

- [Getting started](docs/getting-started.md)
- [Install and onboard](docs/install-and-onboard.md)
- [SaaS adoption recipe](docs/saas-adoption-recipe.md)
- [Adoption demo](docs/adoption-demo.md)
- [Private key JWT host guide](docs/private-key-jwt-host-guide.md)
- [Operator and admin guide](docs/operator-admin.md)
- [Supported surface and GA contract](docs/supported-surface.md)
- [Maintainer and release guide](docs/maintainer-release.md)
- [Sigra companion host](docs/sigra-companion-host.md)
- [Security policy](SECURITY.md)
