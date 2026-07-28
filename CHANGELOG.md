# Changelog

All notable changes to Lockspire will be documented in this file.

The format is based on Keep a Changelog, and versions follow Semantic Versioning.

## [1.3.0](https://github.com/szTheory/lockspire/compare/lockspire-v1.2.0...lockspire-v1.3.0) (2026-07-28)


### Features

* **108-01:** add semantic admin design tokens ([a08c2ca](https://github.com/szTheory/lockspire/commit/a08c2ca68286d8eb5e9bc4ed9f0c539e0be39559))
* **108-01:** tokenize admin CSS interaction styles ([44539d4](https://github.com/szTheory/lockspire/commit/44539d44a02ea446122ea5cc00584a7e5aee903a))
* **108-02:** add safe admin row and action primitives ([b68d7b5](https://github.com/szTheory/lockspire/commit/b68d7b5aaa4ce3cf9954065f8ac5c6ccb48fd282))
* **108-02:** add structural admin primitives ([8be147b](https://github.com/szTheory/lockspire/commit/8be147b290d5ef3f5086cade2b38ec104db46cea))
* **108-03:** migrate admin filter bars ([2c83e64](https://github.com/szTheory/lockspire/commit/2c83e643a3920dab26d25e9b457d4c18d8635265))
* **108-03:** migrate admin hero and metric primitives ([ba86255](https://github.com/szTheory/lockspire/commit/ba862552eb0f2151eb84740436fb71266fff6aaa))
* **108-03:** migrate copy-once secret panels ([219d380](https://github.com/szTheory/lockspire/commit/219d380859a2f8f222d4b88a5811cb0b937babc8))
* **109-01:** polish token support investigation ([bcb7853](https://github.com/szTheory/lockspire/commit/bcb78535129064f2fa542202fc56d1381854f146))
* **109-02:** polish consent support investigation ([a72ed2f](https://github.com/szTheory/lockspire/commit/a72ed2f7be573a04b735e1a3e8a3da783cd39595))
* **109-03:** recompose operations queues ([86c2dd9](https://github.com/szTheory/lockspire/commit/86c2dd9823294cc7b09e06f28414d10a2ccd2a21))
* **109-04:** polish DCR onboarding and IAT flows ([b1a29b2](https://github.com/szTheory/lockspire/commit/b1a29b2abcacd6e5c295412468e51bb894fa43f5))
* **109-05:** polish keys and client actions ([173b7d6](https://github.com/szTheory/lockspire/commit/173b7d62bc9ca00b0f7a224ecd9be9c334a85f74))
* **110-01:** expand admin proof demo state ([2db3e18](https://github.com/szTheory/lockspire/commit/2db3e18ffee54431ab705fa5c5900e1a0ffaf783))
* **111-01:** add explicit adoption demo bind IP option ([f7adec3](https://github.com/szTheory/lockspire/commit/f7adec3a05489d50dab21f2d356f2e458fc73fcb))
* **111-01:** derive demo endpoint URL and issuer from base URL ([167a742](https://github.com/szTheory/lockspire/commit/167a7422ac0d8fce1f9c03524973a97e66027563))
* **111-02:** derive developer callback URL from demo base URL ([b69b557](https://github.com/szTheory/lockspire/commit/b69b55761352ea374fe8a6b00e31cab1fcd78331))
* **111-02:** derive seeded demo URLs from base URL ([4bf58d9](https://github.com/szTheory/lockspire/commit/4bf58d97e362d62eaf66f9845a3f9268540e94a3))
* **111-02:** label adoption smoke URL drift assertions ([3a58a61](https://github.com/szTheory/lockspire/commit/3a58a6108ddcac0e8d5ce6e1692e52e273fbbb0b))
* **112-01:** add default demo compose stack ([0bf5183](https://github.com/szTheory/lockspire/commit/0bf5183a9eca3ef4a244a7919eb553aa37189a3a))
* **112-02:** add docker startup readiness wrapper ([420afc6](https://github.com/szTheory/lockspire/commit/420afc6f271eaad6d303b4613e10ef5ae3e98382))
* **113-01:** add direct compose conflict controls ([c7f38c5](https://github.com/szTheory/lockspire/commit/c7f38c578c8a8a1eba73fa6e89c65b6fcd5ea6d8))
* **113-01:** add scoped demo reset docs ([3afdf61](https://github.com/szTheory/lockspire/commit/3afdf61510491043cc3ec8e06b24866c1eddd023))
* **113-02:** add optional Traefik adoption demo routing ([8b0b1ae](https://github.com/szTheory/lockspire/commit/8b0b1ae5ceb7068a1cf25b4faaed44445424bbc7))
* **114-01:** print redacted adoption demo startup info ([3e09e4e](https://github.com/szTheory/lockspire/commit/3e09e4e5d143f4b418716b0e420b8492fcd68a97))
* **114-02:** add adoption smoke wrapper ([34a8398](https://github.com/szTheory/lockspire/commit/34a83988958b5dc65dcbc2f5b3eb61ad057eb98e))
* **115-01:** add scoped adoption demo cleanup helper ([19f07b9](https://github.com/szTheory/lockspire/commit/19f07b91442854ee8db05048b584d122748a458b))
* **115-01:** add volume-preserving demo stop helper ([5ecae2e](https://github.com/szTheory/lockspire/commit/5ecae2ee143f372cc683a276962817d3e321bc6b))
* **115-02:** add deterministic CI hygiene contracts ([0653eca](https://github.com/szTheory/lockspire/commit/0653ecaf604083e6fa8a0be282719cbf02e654b6))
* **115-02:** add local demo hygiene checks ([41fb3fd](https://github.com/szTheory/lockspire/commit/41fb3fd5f80070bed56273775d8918bf3a3b46af))
* **115-03:** align adoption demo lifecycle docs ([8794089](https://github.com/szTheory/lockspire/commit/8794089f9e81632758360e5dae042977a24b49ef))
* **119-01:** recompose client detail panes ([adcc7b2](https://github.com/szTheory/lockspire/commit/adcc7b24513d6606c813bb68fba68784a9b5af2e))
* **119-02:** group DCR policy workflow ([688e085](https://github.com/szTheory/lockspire/commit/688e085d3f350b59f8921dcb52ea1846331b2a76))
* **119-03:** align IAT onboarding workflow ([671cb20](https://github.com/szTheory/lockspire/commit/671cb201525a2ef2cb4ec22449eece5928e23fc7))
* **119-03:** align support detail hierarchy ([d114204](https://github.com/szTheory/lockspire/commit/d11420487328f2e0b1ead96c42f2a703a2d2239b))
* **119-04:** render device and interaction queues as read-only lists ([0759773](https://github.com/szTheory/lockspire/commit/0759773c97a845578c1caa38897f9abba7ce5d0b))
* **119-04:** render logout deliveries as read-only list ([df8c544](https://github.com/szTheory/lockspire/commit/df8c5446f3614a1755acba43fade927d08b312f7))
* **120-02:** add rendered HTML assertion helper ([86260f9](https://github.com/szTheory/lockspire/commit/86260f9ee00efc44339686cc99a8165baa2996df))
* **120-02:** support read-only route control assertions ([9969717](https://github.com/szTheory/lockspire/commit/9969717f7b952db99b3bf81d00a9e1d8f86e2f1f))
* **120-03:** satisfy docs boundary contract ([5d5343c](https://github.com/szTheory/lockspire/commit/5d5343c144b46773f580d2d59d2aea0ab6a06680))
* **121-02:** add route scorecard parser helper ([75a8856](https://github.com/szTheory/lockspire/commit/75a8856ee423376b188892b32b172c825a963f45))
* **122-01:** convert consent index to dense support flow ([13149b1](https://github.com/szTheory/lockspire/commit/13149b13b8c139e9a2ba4fead82c19ae42586059))
* **122-01:** convert token index to dense support flow ([7f15950](https://github.com/szTheory/lockspire/commit/7f1595029db4bb0df8e0ae71af01af8a5f847c67))
* **122-02:** polish token detail investigation actions ([977281d](https://github.com/szTheory/lockspire/commit/977281db94a052a442ce51065453fca646dd4afc))
* **122-03:** polish consent detail investigation actions ([ce8fcf0](https://github.com/szTheory/lockspire/commit/ce8fcf0c808a18ef697bfa8b24d90c8e863d1e60))
* **123-01:** implement pressure-first interaction rows ([eca93f2](https://github.com/szTheory/lockspire/commit/eca93f2a93debb21dfbb01cbc332b62a6a40e76f))
* **123-02:** implement pressure-first device authorization rows ([9599882](https://github.com/szTheory/lockspire/commit/9599882f41ddcd8bc0cbc29868ae787d943b088f))
* **123-03:** implement logout delivery support truth ([e90efb9](https://github.com/szTheory/lockspire/commit/e90efb94479c8c66fd887310bfae36d2052cfafe))
* **124-01:** implement client configure hierarchy ([a90336e](https://github.com/szTheory/lockspire/commit/a90336e8630f8788997c73e4b199a1589e87c77d))
* **124-02:** implement DCR IAT onboarding confirmation ([b4d0a12](https://github.com/szTheory/lockspire/commit/b4d0a123f256c6be577b4de10cd2102835f4c742))
* **124-03:** implement key lifecycle hierarchy ([42a314d](https://github.com/szTheory/lockspire/commit/42a314d680acd74394bd08ff17683e4cb9f3b34a))
* **124-04:** implement policy posture review flow ([e03a03f](https://github.com/szTheory/lockspire/commit/e03a03f7b452ee7d33245ac13870dff1a4d7a048))
* **124-05:** add non-DCR policy posture summaries ([3d3d8d9](https://github.com/szTheory/lockspire/commit/3d3d8d9dbd6ba20ad1a6a43cf7be639f059a0737))
* **125-01:** implement shared fixture matrix ([189c394](https://github.com/szTheory/lockspire/commit/189c394bb8006250a51d4340d84fe731c723e8ab))
* **125-01:** render internal stress matrix proof ([4c2f357](https://github.com/szTheory/lockspire/commit/4c2f357f7c67f6e70c0ccc782e5f3ae7b119c77a))
* **125-02:** implement global proof guardrail contracts ([ba3264b](https://github.com/szTheory/lockspire/commit/ba3264bc1c3f49273c59fe8f3c0c5a3a1f4e4d3a))
* **125-02:** implement rendered html assertion helpers ([de6eb5d](https://github.com/szTheory/lockspire/commit/de6eb5df9abb2e16779dc3040d6a1855f9822186))
* **125-06:** implement browser evidence parser ([8f8e35c](https://github.com/szTheory/lockspire/commit/8f8e35cf664e14799c8dbf332899696768c0e56c))
* **admin:** polish v1.28 operator experience ([4558388](https://github.com/szTheory/lockspire/commit/4558388cacea7e1c1b45d824e89fb99879f0b96c))
* **admin:** Upgrade UI/UX with BEM design system and components ([f2b573b](https://github.com/szTheory/lockspire/commit/f2b573bb18cc573dbd455d600d7f710cf5ab17eb))
* **brand:** add brand book and re-skin admin UI to Signal Cyan identity ([3a23a49](https://github.com/szTheory/lockspire/commit/3a23a497eadda00295aed66f6edf2f3dd837c857))
* harden adoption, prefix storage, and CI ([f3ace6d](https://github.com/szTheory/lockspire/commit/f3ace6decdae101f47e89de3f17bacae62f56f20))


### Bug Fixes

* **109:** correct logout delivery metrics ([1534496](https://github.com/szTheory/lockspire/commit/1534496b06ae0ed58f3a897f96d03363fbde4c4e))
* **109:** revise plans based on checker feedback ([2f639eb](https://github.com/szTheory/lockspire/commit/2f639ebc618384ecc80aeffa4fd780b1b7d150f3))
* **109:** revise plans based on checker feedback ([4f8945a](https://github.com/szTheory/lockspire/commit/4f8945ac8c8fd4f35f4acf9b3bdd75fbf020c617))
* **110-05:** prevent client route mobile overflow ([a55bac7](https://github.com/szTheory/lockspire/commit/a55bac7064c33174432296d254e2fb300d48070b))
* **110-05:** wrap inline admin code values ([6db0c0c](https://github.com/szTheory/lockspire/commit/6db0c0c1decd958baacc3728a215b325f0fec002))
* **112-01:** run demo image from repo mount ([a4d5d1b](https://github.com/szTheory/lockspire/commit/a4d5d1b4b3555696427629f3700fe635d99561e0))
* **112-02:** keep docker startup output minimal ([67cd5e6](https://github.com/szTheory/lockspire/commit/67cd5e6680c3c5b6aa91f1457b83098463c2ef0e))
* **112-02:** make demo image install noninteractive ([d7c97ac](https://github.com/szTheory/lockspire/commit/d7c97ac692b567a9a9ac4bb79e94b2b38ff4d4fa))
* **112-02:** run demo compose through startup wrapper ([01c061d](https://github.com/szTheory/lockspire/commit/01c061d4595909eb6223646be8112265cc45c179))
* **112-02:** use available demo base image ([01bfe4a](https://github.com/szTheory/lockspire/commit/01bfe4ac7bf717221e00ce75a077054e4edca4b4))
* **113:** bind demo database override to loopback ([a6a4749](https://github.com/szTheory/lockspire/commit/a6a474957aafbb4fdbc44247102b0bb198e383c9))
* **113:** revise conflict-control plan feedback ([b3d1015](https://github.com/szTheory/lockspire/commit/b3d10159e4cf2ccb30ac7644035d41893c6dd7b7))
* **113:** tighten validation feedback latency ([d0417ec](https://github.com/szTheory/lockspire/commit/d0417ece0a242261c2c35a394117f979c10f32fb))
* **114:** close adoption demo startup review findings ([22cf8c7](https://github.com/szTheory/lockspire/commit/22cf8c74b35ae491fc5eee6404664aa308c56d07))
* **116:** revise inventory lab plans ([36da81a](https://github.com/szTheory/lockspire/commit/36da81aca97b76181a1be7482f0d2971370560b4))
* **117-01:** render component lab empty fixtures ([db6b9d7](https://github.com/szTheory/lockspire/commit/db6b9d729a8067f3eeb3392634272205a1a8ede9))
* **119:** resolve plan checker artifacts ([221ad36](https://github.com/szTheory/lockspire/commit/221ad36c05f157227246293b0ea874fb22b94f04))
* **120-01:** point logout support pivot at supported route ([be9a328](https://github.com/szTheory/lockspire/commit/be9a328764513bfad9b5a449b5e5b81a1ff70c1b))
* **120:** resolve code review proof warnings ([d3beec5](https://github.com/szTheory/lockspire/commit/d3beec57997960b88532976d094d4252d8d7b18e))
* **121:** WR-01 reject invalid admin follow-up exceptions ([07b4627](https://github.com/szTheory/lockspire/commit/07b46272c9bf6db71d17f2124661a5e99dbefe8d))
* **121:** WR-02 reject duplicate scorecard fields ([da03bd1](https://github.com/szTheory/lockspire/commit/da03bd1f77ca940905e409f457b4ae6a870cc8f4))
* **121:** WR-03 broaden secret evidence guard ([a5eff43](https://github.com/szTheory/lockspire/commit/a5eff43393f96accb5fa099dfb9c5b50bfc45e8b))
* **122:** correct token family reuse action states ([00e379e](https://github.com/szTheory/lockspire/commit/00e379ec7fa631fa29cede0cdb99872c88bad619))
* **122:** revise plans based on checker feedback ([d4b55e5](https://github.com/szTheory/lockspire/commit/d4b55e524a32803e8b6879ce849b60911478c381))
* **123:** revise plans based on checker feedback ([26df814](https://github.com/szTheory/lockspire/commit/26df8146513bac7016e602afe921d082ce3b4c75))
* **125-06:** make browser evidence patterns portable ([4e5abb4](https://github.com/szTheory/lockspire/commit/4e5abb4a7f361ac2882da486312d98ed7b75bae0))
* close v1.30 demo reprint audit gap ([ea516df](https://github.com/szTheory/lockspire/commit/ea516df751b3d95baba2b2d03f11c582732cb47c))
* **deps:** resolve 13 security advisories blocking CI ([#70](https://github.com/szTheory/lockspire/issues/70)) ([f805e6e](https://github.com/szTheory/lockspire/commit/f805e6efde422a4c81f2b0a96e55ce8171c99a42))
* resolve post-merge conflicts from wave 3 ([31f58f6](https://github.com/szTheory/lockspire/commit/31f58f6c2657df9f34b1e59e683d9f0d708e5fd9))
* **test:** Fix integration test regressions and add seeding helpers ([41667e1](https://github.com/szTheory/lockspire/commit/41667e14333603514c8f6ea0414d461361fb7c4c))
* **types:** Fix Dialyzer warnings around token formatting and signing keys ([6a5f880](https://github.com/szTheory/lockspire/commit/6a5f880733d9acc2a5f3f8fcc721560def38cdb1))

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
