# Changelog

All notable changes to Lockspire will be documented in this file.

The format is based on Keep a Changelog, and versions follow Semantic Versioning.

## [1.1.0](https://github.com/szTheory/lockspire/compare/lockspire-v1.0.0...lockspire-v1.1.0) (2026-05-26)


### Features

* **91-01:** add shared remote jwks diagnostics taxonomy ([13064b7](https://github.com/szTheory/lockspire/commit/13064b70bb69193e8ef4c7a74c43791ca3c86761))
* **91-01:** align jarm remote jwks diagnostics ([0fbd363](https://github.com/szTheory/lockspire/commit/0fbd36359f65a00da6979ccc94eeab7f32dddcf4))
* **91-01:** normalize private_key_jwt remote jwks incidents ([93c71a5](https://github.com/szTheory/lockspire/commit/93c71a586752160a8a8a492a5009674024ff811f))
* **91-02:** add remote jwks doctor surface ([445f511](https://github.com/szTheory/lockspire/commit/445f511d42b666759509af845b5a6111cee374d0))
* **91-02:** surface remote jwks truth in admin client detail ([a26dce5](https://github.com/szTheory/lockspire/commit/a26dce52002b6c9b0b9564d445c61dddb0d9a3d2))


### Bug Fixes

* **phase-91:** wire remote jwks operator diagnostics ([ce8f313](https://github.com/szTheory/lockspire/commit/ce8f31383c60d558091e63bdf00af2371c1aacb2))

## [Unreleased]

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

* **39-04:** start named lockspire oban runtime ([75ff291](https://github.com/szTheory/lockspire/commit/75ff291ffaa2e670268e4b911328ffab5c34163f))
* **39-05:** delegate end session completion to logout propagation ([59ecd99](https://github.com/szTheory/lockspire/commit/59ecd9906aa078e219a15efd28a2ce7d1be3f93f))
* **39-05:** implement transactional logout completion orchestration ([cf06358](https://github.com/szTheory/lockspire/commit/cf0635847c53feec2e880bbb46a387967364efd1))
* **39-06:** publish logout truth across discovery and admin ([41f9ee5](https://github.com/szTheory/lockspire/commit/41f9ee5b3a998b8ebc30bedcd8b4366643f1d89a))
* **39-06:** render truthful frontchannel logout completion ([bd4a0dc](https://github.com/szTheory/lockspire/commit/bd4a0dc61a30bc673caaadfc31914d7c1ab25db8))
* **41-01:** add admin command boundary for security_profile with 7 tests ([a0cc3ac](https://github.com/szTheory/lockspire/commit/a0cc3aca3e436e8e1a2ca99a92b9d6d3b443bd88))
* **41-01:** add security_profile migration, Ecto schemas, and round-trip tests ([f7f867b](https://github.com/szTheory/lockspire/commit/f7f867b57d741f8a71e1f8c5b8638c8cc682107d))
* **41-01:** add SecurityProfile resolver, domain field additions, and unit tests ([4995a8a](https://github.com/szTheory/lockspire/commit/4995a8ad4a88f9a39a477fb260bd12d736cc9fb6))
* **41-02:** implement FAPI20EnforcerPlug boundary enforcer (GREEN phase) ([90a9fb4](https://github.com/szTheory/lockspire/commit/90a9fb40c63c4da32e37400710b6fa3e87cd2d55))
* **41-02:** wire FAPI20EnforcerPlug into Phoenix router via :fapi_boundary pipeline ([30baa00](https://github.com/szTheory/lockspire/commit/30baa0064be1ffa3d1d745f093efb46a34c9455a))
* **42-01:** enforce FAPI signing key lifecycle gates ([2ae38ff](https://github.com/szTheory/lockspire/commit/2ae38fff7c6c2823c8f06695f2743c0ac2ff4bcb))
* **42-01:** narrow canonical FAPI signing policy ([b5f3a9c](https://github.com/szTheory/lockspire/commit/b5f3a9c11e507420454815d9bd476482e4abdbda))
* **42-02:** align JAR verification with canonical FAPI policy ([dc0c4b5](https://github.com/szTheory/lockspire/commit/dc0c4b5bb0f473db20075c56baef6b76972ecaa8))
* **42-02:** enforce canonical FAPI policy for ID token signing ([35ea281](https://github.com/szTheory/lockspire/commit/35ea28199153f32b850841ce1591396c4c3765f9))
* **42-03:** implement FAPI readiness rejection and admin updates ([f9417dc](https://github.com/szTheory/lockspire/commit/f9417dc3ec18f1a8a87903c037754875d1c424ed))
* **42-04:** wire preparatory OIDF maintainer lane and algorithm lockdown ([25fe77e](https://github.com/szTheory/lockspire/commit/25fe77e6ddcbf09857223d16cb082988298a83f3))
* **42-05:** align discovery, JWKS, and DPoP publication with runtime truth ([7abe72a](https://github.com/szTheory/lockspire/commit/7abe72aece2ed706904f569e93127ba9909dd189))
* **42-07:** align DPoP verification with FAPI policy ([b0b76d4](https://github.com/szTheory/lockspire/commit/b0b76d41c89ffc900c2d6123ce242fadfb60a317))
* **42-07:** remove hardcoded RS256 from logout and end-session ([54621c1](https://github.com/szTheory/lockspire/commit/54621c1cec7d2f16bba50a09c2d1e16e9c71f4a4))
* **43-01:** emit iss on authorization flow redirects ([b4b3bed](https://github.com/szTheory/lockspire/commit/b4b3bed8dadf781910e0b17101d30276d5e75b22))
* **43-01:** emit iss on authorize error redirects ([fa470a9](https://github.com/szTheory/lockspire/commit/fa470a99ae12be81a8a29dea3a46cc0528f3778b))
* **43-02:** publish iss discovery metadata ([9255599](https://github.com/szTheory/lockspire/commit/9255599b059ac43f1dfb2d8d567820a5ecf2c637))
* **43-02:** publish par discovery requirement ([36088c5](https://github.com/szTheory/lockspire/commit/36088c5822f02ffcb166515268554b9522561b7b))
* **43-03:** add OIDF conformance preflight task ([a1f1591](https://github.com/szTheory/lockspire/commit/a1f159161f19f25ccd1b9f16faa611e996b16de4))
* **43-03:** pin OIDF FAPI2 plan artifact ([87e7cdd](https://github.com/szTheory/lockspire/commit/87e7cdd9c0f7ca59896c048eda4b60645c2cb608))
* **43-04:** generate host fapi smoke test ([2db7988](https://github.com/szTheory/lockspire/commit/2db798826e70a92adb148c29208cbd8e9f2d23c2))
* **43-06:** add phase 43 FAPI milestone e2e proof ([dce0afc](https://github.com/szTheory/lockspire/commit/dce0afc1a23e31e05da8e96f63c2c2946ff20092))
* **44-01:** create UsedJti domain, schema, migration, and store behaviour ([1690c70](https://github.com/szTheory/lockspire/commit/1690c709c5f48416e93e2d0275c5efd976746080))
* **44-01:** define Lockspire.Host.Context struct ([b424e42](https://github.com/szTheory/lockspire/commit/b424e4285daa835e5aa337cd5544191c334044a1))
* **44-01:** implement used jti storage and pruner ([a0dd850](https://github.com/szTheory/lockspire/commit/a0dd8507598432255065627e260cf7b0c443b72a))
* **44-02:** enforce jwks and jwks_uri coherence for private_key_jwt ([8bc8054](https://github.com/szTheory/lockspire/commit/8bc8054f464321fb3bafe3a64d4edf6639cd226b))
* **44-03:** implement private_key_jwt TTL and replay tracking ([945b68b](https://github.com/szTheory/lockspire/commit/945b68ba7e8a4164fd3cb02f5e44c7f6991d6004))
* **44-api-stabilization:** add strict [@spec](https://github.com/spec) definitions to public facades ([af656c6](https://github.com/szTheory/lockspire/commit/af656c6da61ae4520da3a8334df104fe524ba18c))
* **44-api-stabilization:** complete plan 44-02 and resolve test suite ([61d98d1](https://github.com/szTheory/lockspire/commit/61d98d1c6671840b1dcfc450fc1958b14eadf6b6))
* **44-api-stabilization:** lock AccountResolver signatures ([4ed092e](https://github.com/szTheory/lockspire/commit/4ed092ecf25db58f857b4f99340cd1933cf2412a))
* **45-01:** emit telemetry for device authorization and verification ([1537241](https://github.com/szTheory/lockspire/commit/15372414d799ba3c5e8ef3008d8f3f5983bfe906))
* **45-02:** implement interactions panel ([c40134a](https://github.com/szTheory/lockspire/commit/c40134aca449f82b732bb3dd8605a3ae12bf5c9a))
* **45-02:** implement logout deliveries panel ([515d521](https://github.com/szTheory/lockspire/commit/515d52142c9299981b95a5b8e8392dccd7d7117e))
* **45-03:** implement Device Authorizations LiveView panel ([b45d68b](https://github.com/szTheory/lockspire/commit/b45d68bae7afca9fc09d2901539991a5c3d437d7))
* **48-00:** add token exchange protocol logic and tests ([87e3cf2](https://github.com/szTheory/lockspire/commit/87e3cf2dbdadbc19be559c771d67d63190b72aa8))
* **49-01:** create TokenExchangeValidator behaviour and default-deny implementation ([666e2b7](https://github.com/szTheory/lockspire/commit/666e2b7ca3e7861c72d4b6a8a8a4cf01d9171042))
* **49-01:** define TokenExchangeContext struct ([77f0552](https://github.com/szTheory/lockspire/commit/77f0552ec9b2bb8d351a33a529c08c1f038df693))
* **49-01:** update Config with TokenExchangeValidator accessor ([e7f4990](https://github.com/szTheory/lockspire/commit/e7f499026da38c1a7e9679540151630d0218fb93))
* **49-02:** integrate host validator and JWT minting for token exchange ([b195eaf](https://github.com/szTheory/lockspire/commit/b195eaf589fba5b109819b987aa43747a608385f))
* **50-01:** add max_delegation_depth to server_policies and clients ([16e760d](https://github.com/szTheory/lockspire/commit/16e760de784a4046fed67fa2b74ed360b30d3b8f))
* **50-01:** enforce max_delegation_depth constraints ([b3f11cf](https://github.com/szTheory/lockspire/commit/b3f11cf1e16beb18c2ddc8f15d2493267cb41eda))
* **50-01:** update domain structs and schemas with max_delegation_depth ([3af4c4f](https://github.com/szTheory/lockspire/commit/3af4c4f65aff917e84b3f92b1051b65afb7b8f07))
* **50-02:** implement default delegation validator ([151c6a9](https://github.com/szTheory/lockspire/commit/151c6a9fe178c15fe03022118f6cbb9dda903fd4))
* **50-02:** implement delegation depth enforcement ([67638d5](https://github.com/szTheory/lockspire/commit/67638d55c68d509e187e244bc27d5f499f2ec4b6))
* **54:** add OAuth 2.0 Resource Indicators (RFC 8707) support ([b11109d](https://github.com/szTheory/lockspire/commit/b11109d02f544989d5fea57565a3eb814079a58d))
* **55-01:** add authorization_details to Interaction domain and storage ([1962e36](https://github.com/szTheory/lockspire/commit/1962e364650e40bfbe7e08f266650d1c9e753c19))
* **55-01:** add authorization_details to PAR domain and storage ([a585b23](https://github.com/szTheory/lockspire/commit/a585b23ecdfe55f7a70e273344f158eb5d620b8f))
* **55-01:** add migration for RAR intake state ([61ed749](https://github.com/szTheory/lockspire/commit/61ed749b4bf54a4323508ff9e2f9f15b88b69e50))
* **55-02:** carry authorization_details from validated request into interaction ([5118661](https://github.com/szTheory/lockspire/commit/5118661f2dc55c7c446d1b63c4c6d8a1b0ed32aa))
* **55-02:** parse and validate authorization_details on /authorize ([e56c4ac](https://github.com/szTheory/lockspire/commit/e56c4acf2f73d7ffb96b1a215838cc83a070db27))
* **55-02:** persist authorization_details through PAR issuance ([f151691](https://github.com/szTheory/lockspire/commit/f1516916ae79b7d97aa6619bae6645af00054eae))
* **57-01:** enrich active introspection with granted rar data ([75e7e99](https://github.com/szTheory/lockspire/commit/75e7e999d360c85ee501455dd0554b701e67df81))
* **57-01:** surface structural rar data in consent live ([a6b2bed](https://github.com/szTheory/lockspire/commit/a6b2bed0cef57553d62f33479bf145c4627bdbad))
* **58-01:** publish truthful rar discovery metadata ([f4b5018](https://github.com/szTheory/lockspire/commit/f4b50182b930198a477ede2a9d5396dede800980))
* **59-01:** admit private_key_jwt jwks_uri registration ([7a93cc7](https://github.com/szTheory/lockspire/commit/7a93cc7bfce2b4b9c8d3b2eea7429a0f01323b98))
* **59-01:** preserve jwks_uri on registration management updates ([15732ca](https://github.com/szTheory/lockspire/commit/15732ca6735cbaecfb5c89f8cbb0794019607694))
* **59-02:** derive private_key_jwt policy truth ([429354e](https://github.com/szTheory/lockspire/commit/429354e5ce466f7ec2b3e81a3e834083a036cd92))
* **59-02:** surface private_key_jwt admin posture ([333d14b](https://github.com/szTheory/lockspire/commit/333d14beef1c9515f18395d193bd31d9a25b10e9))
* **59-03:** centralize endpoint auth discovery truth ([da8be5e](https://github.com/szTheory/lockspire/commit/da8be5ec745f36736cef80932c6b9610e40e14d2))
* **67-01:** align release candidate artifacts ([daa706d](https://github.com/szTheory/lockspire/commit/daa706df558ffe1a370b376375bb0b80f022fc67))
* **71-01:** implement JARM core signer ([a8c3daa](https://github.com/szTheory/lockspire/commit/a8c3daa5c9a82c02e71e5132998e3aba5839dbda))
* **71-jarm-core-01:** implement domain structs and migration ([4d7f915](https://github.com/szTheory/lockspire/commit/4d7f915f2ccd8a25ce585dc47177d22eab4e340e))
* **71-jarm-core-02:** implement jarm core utility and discovery updates ([c0db486](https://github.com/szTheory/lockspire/commit/c0db486047216052f53ede391388d124c69fae24))
* **71-jarm-core-03:** support JARM response modes in authorization flow ([82fb468](https://github.com/szTheory/lockspire/commit/82fb4683cffc238386839daacb9e760cc1bdff16))
* **72-01:** persist JARM encryption client metadata ([7ddf64d](https://github.com/szTheory/lockspire/commit/7ddf64d249213faa520fd4c1399a82e24a0a5bcb))
* **72-01:** validate encrypted JARM registration metadata ([e198fe6](https://github.com/szTheory/lockspire/commit/e198fe6bd9ae2493e949a486d45081d5f9824963))
* **72-02:** encode nested JARM responses ([c64c6af](https://github.com/szTheory/lockspire/commit/c64c6af21215c7165cd02f99b0df82a938d741a8))
* **72-02:** resolve JARM recipient keys ([f4013f7](https://github.com/szTheory/lockspire/commit/f4013f763ef8f0f4ee5e002e772538fd5a2623c9))
* **72-03:** share truthful JARM discovery capabilities ([2fb620f](https://github.com/szTheory/lockspire/commit/2fb620fa7a861de3b4c21f4b488c487e1eaa14d0))
* **73-01:** add JWT introspection signer ([766d5e9](https://github.com/szTheory/lockspire/commit/766d5e933f8d26b6886e3a88ce98ea437d95a018))
* **73-01:** return introspection success context ([65ac955](https://github.com/szTheory/lockspire/commit/65ac955e25a7c9cf7f652f64a6ebb36776be8f72))
* **73-02:** negotiate JWT introspection responses ([498d605](https://github.com/szTheory/lockspire/commit/498d60507cdf90d34354f7dfaeaff7d2380f252a))
* implement OIDC CIBA Poll, Ping, and Push delivery modes ([4bb0997](https://github.com/szTheory/lockspire/commit/4bb0997f625618297f5e056228f7cbe390c141e9))
* **jar:** add JWE decryption support for request objects ([4f030af](https://github.com/szTheory/lockspire/commit/4f030aff126539415f7ceddb46564c6f707619be))
* **phase-38:** persist logout protocol and token admin cleanup ([d9bc173](https://github.com/szTheory/lockspire/commit/d9bc1738436de1797a97d676e29e261a689d586d))
* **S01-02:** instrument DPoP failures with telemetry ([048f6e4](https://github.com/szTheory/lockspire/commit/048f6e477bd471a8b285d9cff47959855d0d5b4a))
* **S01-02:** instrument FAPI 2.0 failures with telemetry ([cc79d8e](https://github.com/szTheory/lockspire/commit/cc79d8e35ffea3277088b6dabb3662c746326390))
* **S01-03:** add optional phoenix_live_dashboard dependency ([d8c6f5b](https://github.com/szTheory/lockspire/commit/d8c6f5b3dc065e3ff2fdfb48645eca1f73cc6b16))
* **S01-03:** implement LiveDashboard page ([fb424f7](https://github.com/szTheory/lockspire/commit/fb424f7b9b6102cbe715bc017b1eb07baa6adbbb))
* **S02-01:** add pruner configuration and oban setup ([07ee50a](https://github.com/szTheory/lockspire/commit/07ee50a4e6fca97c3e63dd6bc2396db723b055d2))
* **S02-01:** create pruner worker and emit telemetry ([329eabe](https://github.com/szTheory/lockspire/commit/329eabeed8b61b6ab7c404e36393a0c228260d47))
* **S02-01:** implement chunked recursive deletion ([d69dcb0](https://github.com/szTheory/lockspire/commit/d69dcb035321c50c9e111a0173293dbf5b3eb622))
* ship v1.15 private_key_jwt client auth ([48764b7](https://github.com/szTheory/lockspire/commit/48764b729d8a976a1d79e255ab66b94d3d6d0e4d))
* **v1.16:** complete embedded adoption hardening ([417ae8c](https://github.com/szTheory/lockspire/commit/417ae8c4e79bbf0714bf4360aeced7d6e1df412d))


### Bug Fixes

* **27:** revise plans based on checker feedback ([e9b9a14](https://github.com/szTheory/lockspire/commit/e9b9a14c2998198fbd360fabe5eebfe409351439))
* **30:** correct device authorization mapping and contract tests ([ddf93b4](https://github.com/szTheory/lockspire/commit/ddf93b4238ed7887679d713988f8562622e12c9f))
* **32:** enforce device poll expiry and pacing ([0b8abdf](https://github.com/szTheory/lockspire/commit/0b8abdfa13c04838d61fd0c1da21c9bd7619ddaa))
* **34-03:** preserve device poll errors before dpop resolution ([8607d98](https://github.com/szTheory/lockspire/commit/8607d987a13d66fbc9988a28f2543a9cf6b96b87))
* **35:** preserve dpop challenge and client name ([b20c6de](https://github.com/szTheory/lockspire/commit/b20c6de25d0e734b4d507620ed0a3c62e2829014))
* **37-04:** stabilize generated host conformance harness ([d256da1](https://github.com/szTheory/lockspire/commit/d256da1975d2022e5d06e7dbf5aea9179e53ec51))
* **37:** CR-01 remove decode_term_jwk Erlang deserialization fallback ([a980b8b](https://github.com/szTheory/lockspire/commit/a980b8b8477ad4dc5f1a05a9452cfe535373cf93))
* **37:** CR-02 fix validate_pkce guard inversion ([4cc2d61](https://github.com/szTheory/lockspire/commit/4cc2d61ef0ec4bf292b6de9be4173b66b2273249))
* **37:** CR-03 fix refresh_scope_policy_allows? always returning true ([6492fca](https://github.com/szTheory/lockspire/commit/6492fca40e8175dfc6669404d4ce75586e9cc51f))
* **37:** CR-04 add safe_return_to guard to prevent open redirect in SessionController ([03ac58b](https://github.com/szTheory/lockspire/commit/03ac58b3be863b19b93ab1f7f5f9ab2e8f716d14))
* **37:** merge protocol strictness conformance review fixes ([fbb3729](https://github.com/szTheory/lockspire/commit/fbb37290d5187369fc062df97d5d4ff219a800c8))
* **37:** WR-01 add [@spec](https://github.com/spec) annotation to emit_success/2 in TokenExchange ([ac3f3db](https://github.com/szTheory/lockspire/commit/ac3f3dbdc0d33f6ace69b60ae22f761bc3fc77d0))
* **37:** WR-02 change Interaction code_challenge_method default from :S256 to nil ([533caaf](https://github.com/szTheory/lockspire/commit/533caaf81b23c53d86b79ecec67d3acbb7d3ac69))
* **37:** WR-03 fix indentation in start_authorization/3 cond branch ([3209941](https://github.com/szTheory/lockspire/commit/320994100cd10b3e3934d7353cad83d71cd4e956))
* **37:** WR-04 add else clause to exchange_refresh_token/1 with block ([2e2d3cc](https://github.com/szTheory/lockspire/commit/2e2d3ccdda172c9a39439c36624b8a1c8ce7587a))
* **37:** WR-05 rename migration module from TestRepo to Repo namespace ([9dacccc](https://github.com/szTheory/lockspire/commit/9dacccc430e2c73c91b3ed59a5ee453f473f509b))
* **37:** WR-06 remove map_size==1 guard from ensure_supported_claims_structure ([e7d5dde](https://github.com/szTheory/lockspire/commit/e7d5ddea0939b658dad62a70acfd4e3d323c17a7))
* **42-06:** apply FAPI 2.0 readiness contract and fix FAPI validation order ([919683f](https://github.com/szTheory/lockspire/commit/919683f015720503454745a4cc8c17ff378afcf3))
* **42-06:** pass server_policy to validate_intake_metadata ([ac7f16f](https://github.com/szTheory/lockspire/commit/ac7f16f832646db42b22bef552496b5cf8f46450))
* **44-01:** resolve existing Dialyzer errors ([7b21951](https://github.com/szTheory/lockspire/commit/7b2195101c167dd065cb3ac24ca438aad843eba0))
* **50-verification:** implement actor_token parsing and delegation depth limit ([660c132](https://github.com/szTheory/lockspire/commit/660c132675cfbf66311ae69f521dd559059a9a5b))
* **59-02:** restore verification prerequisites ([7d7d1b0](https://github.com/szTheory/lockspire/commit/7d7d1b0367c2a0ba2c7f204cc87787d8d1822cd0))
* **59-03:** stop publishing unverified private_key_jwt metadata ([d7f9221](https://github.com/szTheory/lockspire/commit/d7f92217412a477a865374a501d6f770b3177bf3))
* **71-jarm-core-01:** restore missing consent grant and token domain fields ([d867c09](https://github.com/szTheory/lockspire/commit/d867c093f3f5e45b06ef541aabd801a7d1b9be81))
* **ci:** satisfy dialyzer in JAR test helpers ([b82ee5f](https://github.com/szTheory/lockspire/commit/b82ee5fdee27538a523a7e84bec86d3d8a1e8ee1))
* **ci:** skip dependency review when graph is unavailable ([164ea12](https://github.com/szTheory/lockspire/commit/164ea1207ece98b5d460a86019152d46ea7deb7a))
* **deps:** restrict oban to ~&gt; 2.21.0 to prevent 2.22 breaking test startup ([bab7552](https://github.com/szTheory/lockspire/commit/bab7552128ef11d545b0075cb1ea6ed54716ae9f))
* **device-flow:** finalize host verification proof surface ([2ba1041](https://github.com/szTheory/lockspire/commit/2ba104114633a48aaa56dc11eea3b1ed9b3d4904))
* **runtime:** add minimal error view ([6b7f6ca](https://github.com/szTheory/lockspire/commit/6b7f6cad099f43dd7c07437b30ddaee5bb62c0ae))
* **test:** align discovery tests with v1.13 CIBA grant type ([909e6aa](https://github.com/szTheory/lockspire/commit/909e6aad3af2b68967fe177be79e5fe454b43518))


### Documentation

* **47-01:** upgrade documentation to GA posture ([5efa4c1](https://github.com/szTheory/lockspire/commit/5efa4c1e8d1ef8e22db2cdfea39b3ea8215e9023))

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
