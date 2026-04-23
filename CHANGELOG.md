# Changelog

All notable changes to Lockspire will be documented in this file.

The format is based on Keep a Changelog, and versions follow Semantic Versioning.

## 1.0.0 (2026-04-23)


### Features

* **01-01:** add base otp application skeleton ([c839753](https://github.com/szTheory/lockspire/commit/c839753ec7149cb2f3ff5eca17e114800e977a9c))
* **01-01:** define public api and host seam contract ([8897c5d](https://github.com/szTheory/lockspire/commit/8897c5d7f5ecfba577e2e3a355e4514f6c2381a0))
* **01-02:** add core oauth domain structs ([c669f4d](https://github.com/szTheory/lockspire/commit/c669f4d3a8f28a89936d5ef8841dd6f007eabaed))
* **01-02:** add domain storage contracts and ecto adapter ([4884589](https://github.com/szTheory/lockspire/commit/488458956d835ce38b256907c12c812a07366c31))
* **02-01:** add authorize controller and safe error handling ([e74e963](https://github.com/szTheory/lockspire/commit/e74e963ed10eb8992d3dce6fecb6844b5c4c59ff))
* **02-01:** add durable client registration API ([0443c1b](https://github.com/szTheory/lockspire/commit/0443c1bc28a96ae039df51ef070807e8a9bf4b7d))
* **02-01:** add strict authorization request validator ([8e0bd1d](https://github.com/szTheory/lockspire/commit/8e0bd1df903f2c41d033ffdc7a407c9285ee2b34))
* **02-02:** extend durable authorization core state ([f6c6f7b](https://github.com/szTheory/lockspire/commit/f6c6f7ba437221f342c6756e4279f1fdfaa636b1))
* **02-02:** implement authorization interaction orchestration ([0ccb8d8](https://github.com/szTheory/lockspire/commit/0ccb8d88e2075566b74bf4dad20338bdb040f693))
* **02-03:** align generated consent surfaces ([71d5d4c](https://github.com/szTheory/lockspire/commit/71d5d4c20d5026199e50153967a861ddcd090dbc))
* **02-03:** wire authorize happy path ([a6cd155](https://github.com/szTheory/lockspire/commit/a6cd155dc15c0147e4121ae88d5b56d9e0a2bbd3))
* **02-03:** wire consent review and finalization ([1f4b520](https://github.com/szTheory/lockspire/commit/1f4b520705fe9e51b5f202bc8fe5fadecc270154))
* **02-04:** add authorization code token exchange ([453d2d5](https://github.com/szTheory/lockspire/commit/453d2d5d5d76cc3a2e7c8209cc97fe1e956d7e4e))
* **02-04:** add token redemption storage helpers ([9427fe7](https://github.com/szTheory/lockspire/commit/9427fe7b96f39cfbede7448d34d4180fdf222ce4))
* **03-01:** publish discovery metadata and jwks ([a1a1177](https://github.com/szTheory/lockspire/commit/a1a1177870d956eb4c409bfa6be3da4ecf5747c9))
* **03-01:** validate issuer and publish durable signing keys ([e41b6eb](https://github.com/szTheory/lockspire/commit/e41b6ebda469656b9faa3cc4b55a6b04b98ad584))
* **03-02:** add oidc id token issuance ([2ec7803](https://github.com/szTheory/lockspire/commit/2ec78032c42c983f2e5e97469b9102c067beb5bc))
* **03-02:** add oidc request validation and userinfo ([f5699eb](https://github.com/szTheory/lockspire/commit/f5699eb0a16820504e7e9711910809f6aa004e9f))
* **03-03:** add durable refresh family rotation ([421bf5a](https://github.com/szTheory/lockspire/commit/421bf5a234ce3de033fa80db2346c8b5fcedd0d7))
* **03-03:** dispatch refresh grants through protocol core ([ea85839](https://github.com/szTheory/lockspire/commit/ea85839aaa290b7170c25603e64baecd4c8171dd))
* **03-03:** extract token endpoint client auth ([32f7e3d](https://github.com/szTheory/lockspire/commit/32f7e3deb03f532e71f3adbdd43abd382409347d))
* **03-04:** add client-bound token revocation ([2d68408](https://github.com/szTheory/lockspire/commit/2d68408255eb74945e2f4d79d4e23d0ce2ebf591))
* **03-04:** add opaque token introspection ([694e5c0](https://github.com/szTheory/lockspire/commit/694e5c0386c81899bcf692f9b9b5e530e8ccdd75))
* **04-01:** add client admin service seam ([36cea60](https://github.com/szTheory/lockspire/commit/36cea6008552bb85b5f5c69344608204c8fbcdd9))
* **05-02:** add transactional audit append helpers ([7f1c7d1](https://github.com/szTheory/lockspire/commit/7f1c7d1d2240814c43e0f1d4c0f5f09343e589e3))
* **05-03:** audit authorization flow transitions ([4622f35](https://github.com/szTheory/lockspire/commit/4622f352c3a495a27337219eea7ad47824f8bc1c))
* **05-03:** audit refresh and revocation outcomes ([98ec1e4](https://github.com/szTheory/lockspire/commit/98ec1e4f4d3f08579b84197568d9a81206206437))
* **05-03:** audit token exchange outcomes ([20530d7](https://github.com/szTheory/lockspire/commit/20530d73d5dda7e160deb4f03cace81a9245851e))
* **05-05:** centralize telemetry and audit redaction ([342978f](https://github.com/szTheory/lockspire/commit/342978f6627fe140a3ee0edfa8fb0f9ee1c8336f))
* **05-06:** mask token and key detail projections ([39d6bef](https://github.com/szTheory/lockspire/commit/39d6bef9014b5fbae07865d7cbfa00ea84a9011e))
* **05-security-and-observability-hardening-04:** audit admin client and consent commands ([052b5c8](https://github.com/szTheory/lockspire/commit/052b5c89b6249ded62778796ff0acf3f32fc22f8))
* **05-security-and-observability-hardening-04:** audit admin token and key commands ([cc01b02](https://github.com/szTheory/lockspire/commit/cc01b02d5814ec2ba4f22ffd64db90a687387f65))


### Bug Fixes

* **02:** WR-01 handle invalid client type input ([f2d0ecf](https://github.com/szTheory/lockspire/commit/f2d0ecf2f40e28f55e07b7330d724486ebe56e37))
* **02:** WR-02 merge authorize redirect params safely ([c74fdb7](https://github.com/szTheory/lockspire/commit/c74fdb7023a69ea645c66379fcdafc43df97c3c8))
* **02:** WR-03 support encoded basic auth credentials ([25a8356](https://github.com/szTheory/lockspire/commit/25a8356f1f5fff33e87296cd97ccb1a7f12fc3e8))
* **05-05:** suppress SQL logging for sensitive repository paths ([bd72152](https://github.com/szTheory/lockspire/commit/bd721524f2511de9da1697b48872b23e10faff30))
* **05-06:** preserve calm confirmation gates on masked admin detail ([0667cf3](https://github.com/szTheory/lockspire/commit/0667cf35cdbb4057e306144c388a1354f1e85f89))
* **07-02:** make mix and dialyzer gates truthful ([10af630](https://github.com/szTheory/lockspire/commit/10af6303c2c474121b0b6228854b9da801224258))
* **07-03:** restore deterministic test transactions ([2f940e6](https://github.com/szTheory/lockspire/commit/2f940e6a30cb231e744f90c1161669fd664218cb))
* **07-04:** align contributor gate contract ([9f1e261](https://github.com/szTheory/lockspire/commit/9f1e261be8600fa83ef4a9e465da2d1dfd08e965))
* **08-01:** harden trusted release lane contract ([ed52b00](https://github.com/szTheory/lockspire/commit/ed52b007eab256067fd5079c95909c2fef033f74))

## [Unreleased]

### Added

- Canonical Phoenix-first install and onboarding documentation.
- Executable onboarding proof for the generated host seam.
- Release-readiness CI, package metadata, changelog, and workflow scaffolding.
