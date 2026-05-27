# Changelog

All notable changes to Lockspire will be documented in this file.

The format is based on Keep a Changelog, and versions follow Semantic Versioning.

## [1.2.0](https://github.com/szTheory/lockspire/compare/lockspire-v1.1.2...lockspire-v1.2.0) (2026-05-27)


### Features

* harden host integration boundary ([#40](https://github.com/szTheory/lockspire/issues/40)) ([2e80589](https://github.com/szTheory/lockspire/commit/2e80589795fa837c518a5708450d8ef0d2aa0032))

## [1.1.2](https://github.com/szTheory/lockspire/compare/lockspire-v1.1.1...lockspire-v1.1.2) (2026-05-27)


### Bug Fixes

* align support truth for CIBA and JAR ([#36](https://github.com/szTheory/lockspire/issues/36)) ([fc6baa6](https://github.com/szTheory/lockspire/commit/fc6baa6d4b107a5f0826f7f98e0bed557b909034))

## [1.1.1](https://github.com/szTheory/lockspire/compare/lockspire-v1.1.0...lockspire-v1.1.1) (2026-05-27)


### Bug Fixes

* isolate test config for logout worker ([#32](https://github.com/szTheory/lockspire/issues/32)) ([ffd922a](https://github.com/szTheory/lockspire/commit/ffd922af19e18839930034bd49d80d5f3370575a))

## [1.1.0](https://github.com/szTheory/lockspire/compare/lockspire-v1.0.0...lockspire-v1.1.0) (2026-05-26)

### Added

- Automatic `DPoP-Nonce` challenge and retry support across the shipped Lockspire-owned DPoP surfaces and the canonical Phoenix protected-route pipeline.
- Dynamic Client Registration and RFC 7592 management support for the existing logout propagation metadata fields.
- A narrow `client_secret_jwt` direct-client authentication slice on the shipped Lockspire-owned endpoints that already reuse the shared verifier.
- Shared remote-`jwks_uri` diagnostics plus `mix lockspire.doctor remote-jwks` and matching admin support surfaces for the shipped `private_key_jwt` and JARM remote-key story.

### Changed

- The canonical advanced-setup support contract now aligns runtime behavior, admin wording, doctor output, and public docs for remote `jwks_uri`, mTLS setup, logout propagation, and the protected-route plug pipeline.
- The public support posture now reflects one near-complete embedded-provider story rather than an actively expanding feature roadmap; new milestones should be trigger-based and evidence-driven.

### Fixed

- Release-truth docs now describe the shipped Phoenix protected-route plug pipeline and stop treating it as future work.

### Features

* **91-01:** add shared remote jwks diagnostics taxonomy ([13064b7](https://github.com/szTheory/lockspire/commit/13064b70bb69193e8ef4c7a74c43791ca3c86761))
* **91-01:** align jarm remote jwks diagnostics ([0fbd363](https://github.com/szTheory/lockspire/commit/0fbd36359f65a00da6979ccc94eeab7f32dddcf4))
* **91-01:** normalize private_key_jwt remote jwks incidents ([93c71a5](https://github.com/szTheory/lockspire/commit/93c71a586752160a8a8a492a5009674024ff811f))
* **91-02:** add remote jwks doctor surface ([445f511](https://github.com/szTheory/lockspire/commit/445f511d42b666759509af845b5a6111cee374d0))
* **91-02:** surface remote jwks truth in admin client detail ([a26dce5](https://github.com/szTheory/lockspire/commit/a26dce52002b6c9b0b9564d445c61dddb0d9a3d2))

### Bug Fixes

* **phase-91:** wire remote jwks operator diagnostics ([ce8f313](https://github.com/szTheory/lockspire/commit/ce8f31383c60d558091e63bdf00af2371c1aacb2))

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
