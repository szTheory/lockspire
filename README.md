# Lockspire

[![Hex version](https://img.shields.io/hexpm/v/lockspire.svg)](https://hex.pm/packages/lockspire)
[![Docs](https://img.shields.io/badge/hexdocs-api%20%26%20guides-5865F2)](https://hexdocs.pm/lockspire)
[![CI](https://github.com/szTheory/lockspire/actions/workflows/ci.yml/badge.svg)](https://github.com/szTheory/lockspire/actions/workflows/ci.yml)
[![License](https://img.shields.io/hexpm/l/lockspire.svg)](https://github.com/szTheory/lockspire/blob/main/LICENSE)

Lockspire lets partner apps request access to your APIs with OAuth 2.0 and sign in with OpenID Connect (OIDC), all from your existing Phoenix app. Your app keeps its accounts, login, branding, and product rules; Lockspire handles the protocol and tokens.

## Is Lockspire a fit?

Lockspire fits teams that want to connect partner apps without moving user accounts or login into a separate service. Before relying on a feature or deployment shape, check the [supported capabilities and limits](docs/supported-surface.md). That page is the support contract; this README does not repeat its capability list.

## Install in your Phoenix app

Follow the [canonical install and onboarding guide](docs/install-and-onboard.md). It covers the generated host files, migrations, `mix lockspire.verify`, and the host checks still needed after installation. Existing generated apps that still forward the admin router should use the [host admin integration upgrade guide](docs/upgrading/host-admin-integration.md). If the OAuth/OIDC concepts or host responsibilities are new to you, start with [OAuth/OIDC for Phoenix adopters](docs/oauth-oidc-for-phoenix-adopters.md).

## Choose your next task

- Register a first client: [SaaS adoption recipe](docs/saas-adoption-recipe.md)
- Protect Phoenix API routes: [route protection guide](docs/protect-phoenix-api-routes.md)
- Set up device login: [device flow host guide](docs/device-flow-host-guide.md)
- Review the admin pages: [admin guide](docs/operator-admin.md)
- Use the local example: [adoption demo](docs/adoption-demo.md), which uses synthetic Billingo data
- Maintain a release: [maintainer and release guide](docs/maintainer-release.md)

## Work on the Lockspire repository

For repository ownership, local checks, and contributor workflow, see [`CONTRIBUTING.md`](https://github.com/szTheory/lockspire/blob/main/CONTRIBUTING.md). It applies to this repository and is not part of the Hex package documentation.
