# Changelog

All notable changes to Lockspire will be documented in this file.

The format is based on Keep a Changelog, and versions follow Semantic Versioning.

## [1.1.0](https://github.com/szTheory/lockspire/compare/lockspire-v1.0.0...lockspire-v1.1.0) (2026-05-25)

### Added

- DPoP sender-constraining coverage across Lockspire-owned `/token`, Lockspire-owned protected resources, and the shipped Phoenix protected-route plug pipeline, including automatic `DPoP-Nonce` challenge and retry support on those shipped DPoP surfaces.
- Mutual TLS client authentication and sender-constrained token support, including certificate extraction, `tls_client_auth` and `self_signed_tls_client_auth`, certificate-bound access tokens, and truthful `mtls_endpoint_aliases` discovery metadata.
- First-class Phoenix protected-route verification with `Lockspire.Plug.VerifyToken`, optional `Lockspire.Plug.EnforceSenderConstraints`, and `Lockspire.Plug.RequireToken`, including route-level scope and audience restrictions for Lockspire-issued access tokens.
- Dynamic client registration and registration-management support for the existing logout propagation metadata fields, plus a narrow `client_secret_jwt` direct-client authentication slice on Lockspire-owned endpoints with `HS256`, issuer-string `aud`, required `jti`, and replay protection.

### Changed

- The checked-in `1.1.0` release-candidate contract keeps `mix.exs`, `.release-please-manifest.json`, `CHANGELOG.md`, and the expected root tag `lockspire-v1.1.0` on one embedded-library release story before authenticated publish proof begins.
- Hex-facing package metadata, support docs, and release configuration now describe the repo-proven embedded Phoenix surface shipped through milestone `v1.24` without including the current `v1.25` support-burden work.

## [1.0.0](https://github.com/szTheory/lockspire/compare/lockspire-v0.2.0...lockspire-v1.0.0) (2026-05-07)


### Added

- Canonical Phoenix-first install and onboarding documentation.
- Executable onboarding proof for the generated host seam.
- Release-readiness CI, package metadata, changelog, and workflow scaffolding.

### Changed

- The checked-in `1.0.0` release-candidate contract keeps `mix.exs`, `.release-please-manifest.json`, `CHANGELOG.md`, and the expected root tag `lockspire-v1.0.0` on one embedded-library release story before authenticated publish proof begins.
- Hex-facing package metadata, release configuration, and changelog posture now describe one `lockspire` package and defer authenticated publish evidence to the protected `hex-publish` lane.

## [0.2.0](https://github.com/szTheory/lockspire/compare/lockspire-v0.1.2...lockspire-v0.2.0) (2026-04-24)


### Features

* **09-02:** extend preview posture contract coverage ([70107c8](https://github.com/szTheory/lockspire/commit/70107c8ecf8ec9a17f41b4b363a63a76d7d22574))


### Bug Fixes

* **10-01:** restore contributor gate proof ([20d53f7](https://github.com/szTheory/lockspire/commit/20d53f74f01dcf85bc9e674b39301a562a26c2bc))

## [0.1.2](https://github.com/szTheory/lockspire/compare/lockspire-v0.1.1...lockspire-v0.1.2) (2026-04-24)


### Bug Fixes

* **release:** make recovery lane publishable ([cd5e40d](https://github.com/szTheory/lockspire/commit/cd5e40d001a4fda7f35b729edb7ac8c73b5b6f19))
* **release:** run hex tasks before docs ([046a14c](https://github.com/szTheory/lockspire/commit/046a14c7f8712159eb7bd68a945caa718bfc78d3))

## [0.1.1](https://github.com/szTheory/lockspire/compare/lockspire-v0.1.0...lockspire-v0.1.1) (2026-04-24)


### Bug Fixes

* **08-01:** harden trusted release lane contract ([ed52b00](https://github.com/szTheory/lockspire/commit/ed52b007eab256067fd5079c95909c2fef033f74))
* **ci:** bootstrap test db in fast lane ([bcb2ce3](https://github.com/szTheory/lockspire/commit/bcb2ce38d19605b2d37d7761390d587f01944e79))
* **ci:** provide postgres for fast checks ([6b9d761](https://github.com/szTheory/lockspire/commit/6b9d7611bcffad41a092c95c85e5147db5ff3033))
* **test:** avoid brittle key detail id assertion ([a550cbb](https://github.com/szTheory/lockspire/commit/a550cbbd95015ba60a32a28899f3d7faaaf99f49))
