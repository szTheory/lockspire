# Changelog

All notable changes to Lockspire will be documented in this file.

The format is based on Keep a Changelog, and versions follow Semantic Versioning.

## [1.5.0](https://github.com/szTheory/lockspire/compare/lockspire-v1.4.0...lockspire-v1.5.0) (2026-08-28)


### Features

* **131-01:** generate executable host routes ([4eae42d](https://github.com/szTheory/lockspire/commit/4eae42dfea43cdf16aa850e42b67daf28814e709))
* **131-02:** preflight packaged migrations ([4dc96b9](https://github.com/szTheory/lockspire/commit/4dc96b9a0a317183db65bd2e3edc6f7812f716dc))
* **131-03:** expose safe consent render context ([896a549](https://github.com/szTheory/lockspire/commit/896a549c3117b3fba70c79e19461ee785fe20a3d))
* **131-03:** generate executable host consent ([fcb08b8](https://github.com/szTheory/lockspire/commit/fcb08b83b15f50637a339bf2677771e9ca247a02))
* **131-04:** atomically preflight install artifacts ([fb16fcd](https://github.com/szTheory/lockspire/commit/fb16fcd20617a33ef5c49be3537406d3d6663cae))
* **131-04:** audit packaged migration inventory ([119a6d4](https://github.com/szTheory/lockspire/commit/119a6d4359d564f49195118886ce99a39c131a24))
* **131-05:** generate default-profile smoke proof ([a1d98c7](https://github.com/szTheory/lockspire/commit/a1d98c7dde5494bfc30156b5f2f4ce4963c86c2e))
* **131-06:** aggregate install verification diagnostics ([de63513](https://github.com/szTheory/lockspire/commit/de635132241003fd3038738f2c8856d3a88bc094))
* **131-07:** defer generated consent context loading\n\n- Render a safe non-interactive consent status before authority resolves\n- Preserve host resolver context and existing approval completion flow\n ([78c750e](https://github.com/szTheory/lockspire/commit/78c750e924017d359d6459117592588a5ccc46b5))
* **132-01:** add shared token semantic readers ([9062934](https://github.com/szTheory/lockspire/commit/9062934a47ea900082f3815853fbd10e895c3dbe))
* **132-01:** expose expiry and confirmation readers ([88d5e05](https://github.com/szTheory/lockspire/commit/88d5e05285200d362929b5d57b51297f8c07094b))
* **132-02:** unify dynamic registration capability checks ([c441dd9](https://github.com/szTheory/lockspire/commit/c441dd9d3e614d665f82ee9a72a368e66eef00df))
* **132-02:** validate direct client registration shapes ([2e4917e](https://github.com/szTheory/lockspire/commit/2e4917ecf9710bb572b51e25ebe06c7690cecde2))
* **132-04:** make generated resource authorization explicit ([a5f6c65](https://github.com/szTheory/lockspire/commit/a5f6c654ac6efa1c5c3ddf620703cdcd67c1ac25))
* **133-01:** lock clean-room package inputs ([70d380e](https://github.com/szTheory/lockspire/commit/70d380e3e196857d19ad316de866b9b3f5521bdc))
* **133-01:** redact clean-room failure evidence ([4f7acc6](https://github.com/szTheory/lockspire/commit/4f7acc6a23c276805debe9550beb7e401fb3ad37))
* **133-01:** supervise clean-room origins safely ([04baf14](https://github.com/szTheory/lockspire/commit/04baf14d290a514a85bc9c537fecb071fb45cad7))
* **133-02:** add package-clean provider builder ([a8d04ba](https://github.com/szTheory/lockspire/commit/a8d04bacbc9f0ca2e279aef6a139831c63993281))
* **133-02:** bootstrap bounded SaaS clients ([0ac5764](https://github.com/szTheory/lockspire/commit/0ac5764fb2afabc4211dbf56b5c7aaec22567586))
* **133-03:** add fixed confidential callback profiles ([d5c0096](https://github.com/szTheory/lockspire/commit/d5c00961f4622682093bbd5719d405bf93349e3a))
* **133-03:** persist clean-room authorization transactions ([95bdcc8](https://github.com/szTheory/lockspire/commit/95bdcc879bb14ccf250903cd4b88fd91b6684cc8))
* **133-03:** validate clean-client OIDC claims ([9a6de07](https://github.com/szTheory/lockspire/commit/9a6de07c81b83b0e72d949033cce01c662ab84c4))
* **133-04:** prove clean-room SaaS bearer journey ([c8ddc2c](https://github.com/szTheory/lockspire/commit/c8ddc2c1453aa846c4f27ca5f3b45d777c33a625))
* **133-05:** prove clean-room negative wire matrix ([2925027](https://github.com/szTheory/lockspire/commit/2925027eb162645995560c0145791042663d7c93))
* **133-05:** prove refresh lifecycle over HTTP ([281ed12](https://github.com/szTheory/lockspire/commit/281ed121ffb4b73e8e168653fb5b98fc282965f7))
* **133-06:** prove durable DPoP resource replay ([2c5e2cf](https://github.com/szTheory/lockspire/commit/2c5e2cf572d9ecb1ec3cb7c1e5fae340189b80ad))
* **134-01:** route client creation through neutral lifecycle ([4d3e59c](https://github.com/szTheory/lockspire/commit/4d3e59c0fd4365039097bd3e1b3f8a8f363dddae))
* **134-02:** route RFC7592 lifecycle through neutral service ([db2c9d2](https://github.com/szTheory/lockspire/commit/db2c9d2b82c6ed533d7b1b1edcea281a6322a65c))
* **134-03:** inject neutral discovery route paths ([ea8a00b](https://github.com/szTheory/lockspire/commit/ea8a00b25dfa4a206ffc9fb496ff4c9a0c71e5ed))
* **134-03:** resolve discovery routes in web delivery ([249f791](https://github.com/szTheory/lockspire/commit/249f791106db109ae7d96c77d12dc0fc9d817951))
* **134-04:** extract pure prefix utility ([14fc287](https://github.com/szTheory/lockspire/commit/14fc287844be1390ba8b68498c3684c8c763500a))
* **134-05:** adapt JAR results at protocol boundaries ([66d79a9](https://github.com/szTheory/lockspire/commit/66d79a9bb5010b119617189b2d68fd411e9f892c))
* **134-05:** add neutral request object results ([9bfba74](https://github.com/szTheory/lockspire/commit/9bfba74c9944553fc67005816c413dd683de3212))
* **134-06:** return neutral protected-resource errors ([cdd295d](https://github.com/szTheory/lockspire/commit/cdd295d2b059e11bc4adf45fa4e0979ee67563a8))
* **134-07:** add neutral token result compatibility ([6d29ae4](https://github.com/szTheory/lockspire/commit/6d29ae4de02556b65c8617e5fd4b5da6f77ce9c8))
* **136-01:** classify Credo directive debt\n\n- scan source paths deterministically from repository root\n- expose exact file-wide and unnamed directive identities ([2c55e0e](https://github.com/szTheory/lockspire/commit/2c55e0e5141be566944bcfd5726be84ea94d3d75))
* **136-01:** classify proof and diagnostic debt\n\n- identify active macro, archaeology, and count contracts\n- parse Dialyzer identities and routine diagnostic categories ([3f59acd](https://github.com/szTheory/lockspire/commit/3f59acd848bade5621c4353787ece97685897637))
* **137-01:** enforce dependency graph truth ([5406f9f](https://github.com/szTheory/lockspire/commit/5406f9f45e6705ecb5fcd4dd4c86ae4102718c0b))
* **137-01:** scan both shipped routers ([05c5bca](https://github.com/szTheory/lockspire/commit/05c5bca5eba4567c487c6294f97c17e76d372809))
* **137-05:** lock immutable OIDF suite inputs ([7d898eb](https://github.com/szTheory/lockspire/commit/7d898ebe6e316272f6180c1a0b561d51aea461da))
* **137-05:** prepare verified OIDF suite inputs ([bc24dce](https://github.com/szTheory/lockspire/commit/bc24dce76a9ba25691879c98ab4e7758e0d74444))
* **137-06:** align FAPI conformance evidence ([e33190d](https://github.com/szTheory/lockspire/commit/e33190d7483a1f16a5fb552622984f6c8eb84140))
* **137-06:** retain redacted OIDF receipts ([c4a2e49](https://github.com/szTheory/lockspire/commit/c4a2e49d0f5e6a12c30a15a7d4f8f47942eaa2d4))
* **ci:** aggregate same-sha native coverage ([70534a3](https://github.com/szTheory/lockspire/commit/70534a3fda56c2cf05fe875cbdf937d2b03442fe))
* **ci:** manage dependency graph gate prerequisites ([18518ff](https://github.com/szTheory/lockspire/commit/18518ff6abf9358b53113e2c88e1afe23bdb6395))
* deliver v1.37 prime-time readiness ratchet ([75743cf](https://github.com/szTheory/lockspire/commit/75743cfc49d2b0340d4479cafedc17f528e1d2c5))
* **release:** bind publication to one verified artifact ([44a380c](https://github.com/szTheory/lockspire/commit/44a380c5ec0c35aadd14f1a1abae278e26489b1f))
* **release:** prove exact clean-room package sources ([5d83fdb](https://github.com/szTheory/lockspire/commit/5d83fdb6e0f620a6d6029ebf4ca03890526457aa))


### Bug Fixes

* **126:** bind releases to canonical CI ([b3b1326](https://github.com/szTheory/lockspire/commit/b3b132666772ce0a08358fb4437502b8d5c5da76))
* **126:** make release publication retry-safe ([536eb1c](https://github.com/szTheory/lockspire/commit/536eb1cb34742f515a660413735e5c474ad2385d))
* **128-01:** use adapter for access-token signing ([e9b098a](https://github.com/szTheory/lockspire/commit/e9b098a022350565f7968b7f768611eaef1c4b46))
* **128-02:** default protocol stores to adapter ([5403afa](https://github.com/szTheory/lockspire/commit/5403afac95196af6f2aaf6acbea2275850c5d821))
* **128-03:** use adapter in secure protocol paths ([b355c81](https://github.com/szTheory/lockspire/commit/b355c811a611c2122bc7135aaebe52d8eaf08158))
* **129:** make token issuance types truthful ([c62fc83](https://github.com/szTheory/lockspire/commit/c62fc833b22be7907437f00c24933b9d0c56f242))
* **129:** preserve decoder failure boundary ([a9ff0df](https://github.com/szTheory/lockspire/commit/a9ff0df6a6581d070707e98bc2a97f7c2f65b19d))
* **130:** close release and proof gaps ([a52c30d](https://github.com/szTheory/lockspire/commit/a52c30dd7b130c872502b90a5ee45c424de9c2da))
* **131-01:** make generated config truthful ([e70d521](https://github.com/szTheory/lockspire/commit/e70d5218cd17addbcf9095ff8e826f7bd0966464))
* **131-01:** preserve upgrade route proof ([850524c](https://github.com/szTheory/lockspire/commit/850524cdd767a4fbd134a933d93ee316b2c48471))
* **131:** close transaction recovery gaps ([ce35107](https://github.com/szTheory/lockspire/commit/ce35107821ca1d91f970c058d51921d17c94ab54))
* **131:** CR-01 verify operator guard metadata ([393afa1](https://github.com/szTheory/lockspire/commit/393afa18637cf596a07151460b2790dbd18662b5))
* **131:** CR-02 retain opted-in FAPI smoke on upgrade ([8ea3fb7](https://github.com/szTheory/lockspire/commit/8ea3fb765d9174b4685116c623d82a7e5d7a40bf))
* **131:** CR-03 honor configured logout path ([1d2da95](https://github.com/szTheory/lockspire/commit/1d2da95380cf1d331689c119a24610e770311eac))
* **131:** journal installer filesystem transaction ([445e0ce](https://github.com/szTheory/lockspire/commit/445e0ce8126a56bc923b0e206a3aeec6ce767e32))
* **131:** narrow operator mount verification claim ([eef15ea](https://github.com/szTheory/lockspire/commit/eef15eaf4b0426d066ae1c9cafd35c26548f4341))
* **131:** polish generated consent semantics ([85b79ee](https://github.com/szTheory/lockspire/commit/85b79ee142240809e5ea56b3b8b89f8be6b35024))
* **131:** randomize generated OAuth smoke requests ([03e7b6f](https://github.com/szTheory/lockspire/commit/03e7b6fa22d4ea84cc64d2acd013fb223d76196f))
* **131:** report manifest transaction status ([af8545f](https://github.com/szTheory/lockspire/commit/af8545fb4a9ec08bba2709a22f97937870c62818))
* **131:** satisfy transaction static checks ([4a65cfe](https://github.com/szTheory/lockspire/commit/4a65cfefa07bc07d6b39c09c6e0e8028d0664aab))
* **131:** WR-03 randomize generated FAPI request values ([2896b88](https://github.com/szTheory/lockspire/commit/2896b8853841a9dc067ef446f2aed4d60e72d4ae))
* **132-03:** default protected DPoP replay to configured repo ([894813f](https://github.com/szTheory/lockspire/commit/894813fee766d578323d9e663999cba5ef7bc43a))
* **132:** CR-01 preserve exact audience bytes ([6924204](https://github.com/szTheory/lockspire/commit/6924204744b8b112546129a92ee65f19d2e185ef))
* **132:** reject partially malformed audiences ([e48bcb8](https://github.com/szTheory/lockspire/commit/e48bcb8e7514199dad81e2533d48d56bbd759a28))
* **132:** simplify scope validation ([390b714](https://github.com/szTheory/lockspire/commit/390b714458d802a678f7e09e3ee454f2b45e0663))
* **132:** WR-01 simplify JWKS parser rescue ([563ea28](https://github.com/szTheory/lockspire/commit/563ea280fd302176238cd5dcbc56383200c58f2f))
* **132:** WR-01 validate public inline JWKS ([574061b](https://github.com/szTheory/lockspire/commit/574061b86301c18aeeae1bca8083f49dca0c811a))
* **132:** WR-02 exercise semantic resource server seam ([5597d9a](https://github.com/szTheory/lockspire/commit/5597d9a629c8c8c1e84b02f252f6e2dec4631c24))
* **133-01:** preflight clean-room dependencies ([bd5f303](https://github.com/szTheory/lockspire/commit/bd5f303672ef430e89654f76a02cc169742aa351))
* **133-02:** compile provider host overlays ([1b2f744](https://github.com/szTheory/lockspire/commit/1b2f744a6a2d2de13469f3b6990c3b648575e528))
* **133-06:** complete durable DPoP replay proof ([e4558ad](https://github.com/szTheory/lockspire/commit/e4558ad58d24af924eff9c722ed32930e8092c97))
* **133-06:** isolate nested clean-room tests ([12a3b24](https://github.com/szTheory/lockspire/commit/12a3b24d83e7339d0f2404bb2fcc273e16ff98ff))
* **133:** await protected resource after provider restart ([7359d36](https://github.com/szTheory/lockspire/commit/7359d368e115600269d0db46a09aeee00a2ce589))
* **133:** bind lifecycle resources at journey runtime ([9368cde](https://github.com/szTheory/lockspire/commit/9368cde28dcd0f0cfdc66c2a02de08b41e41a0cc))
* **133:** CR-01 use configured clean-room database credentials ([63246c5](https://github.com/szTheory/lockspire/commit/63246c556e6305ee9dd28a8c2bd59352f8067a96))
* **133:** CR-02 isolate real clean-room journeys ([df8370b](https://github.com/szTheory/lockspire/commit/df8370bbc6872b1a1ead74dccfba8a63ffa1df27))
* **133:** CR-04 prevent login reflection and redirects ([bb91670](https://github.com/szTheory/lockspire/commit/bb91670d0120bd4d7f0b8d3bcdb8c5fc6d192933))
* **133:** isolate clean-room temporary ownership ([63a366b](https://github.com/szTheory/lockspire/commit/63a366b4d757abd90f337f1d0422fb21ed7de2b4))
* **133:** retain restarted provider for teardown ([6274959](https://github.com/szTheory/lockspire/commit/62749599759cab5943140bd577d6deededcdb71b))
* **133:** WR-01 protect client acceptance mutations ([26d5e0c](https://github.com/szTheory/lockspire/commit/26d5e0c0eee9c016bdc734287e54315aa7702623))
* **133:** WR-02 redact retained real journey evidence ([d807c36](https://github.com/szTheory/lockspire/commit/d807c36b94c8caa9eb4db8c6d7c78987cdd4e870))
* **133:** WR-03 exclude full journey from default suites ([a93e42a](https://github.com/szTheory/lockspire/commit/a93e42a9787247e6a1da45b425bade1bae62d420))
* **133:** WR-03 make one clean-room proof authoritative ([832de94](https://github.com/szTheory/lockspire/commit/832de9457b02fec02cf84cd9c59a4eeba3e237f5))
* **134:** centralize client lifecycle writes ([7143924](https://github.com/szTheory/lockspire/commit/7143924ec940d7ee9a320aa822993d704100cfbc))
* **134:** make architecture QA environment-stable ([dbea66c](https://github.com/szTheory/lockspire/commit/dbea66c99045dd8df8cbfd945f6bbe5a893c7c04))
* **134:** restore public boundaries and topology fitness ([ea91cdd](https://github.com/szTheory/lockspire/commit/ea91cdd2b50b5dceef86b73a4a7c9e265845e17b))
* **135-08:** preserve authorization-code error precedence ([d97f857](https://github.com/szTheory/lockspire/commit/d97f857ef0981c675aa65e92fba79402c5b871cd))
* **135-09:** keep internal dependency types out of docs ([3727171](https://github.com/szTheory/lockspire/commit/37271718d9e69e5c6db6d971a7615463dc6824a3))
* **135-09:** preserve atomic lifecycle behavior\n\n- compare lifecycle expiry timestamps chronologically\n- make family revocation idempotent and characterization deterministic\n ([1bcbac8](https://github.com/szTheory/lockspire/commit/1bcbac86b1ed8d0457ddd056f5b403bd895ffdff))
* **135-09:** retain reuse-family revocation semantics\n\n- keep reuse containment authoritative\n- limit idempotency filtering to operator family revoke\n ([90237de](https://github.com/szTheory/lockspire/commit/90237deb38af97169f1e1bd08f46c1b69b1275f5))
* **136-10:** focus runtime noise contract ([2a04436](https://github.com/szTheory/lockspire/commit/2a044366041613cc6d0542cc7f49c185a7713f66))
* **136-10:** make key cache startup quiet ([002e09b](https://github.com/szTheory/lockspire/commit/002e09b0a0a862e9e1f50a1cf77a7d45b1c0db63))
* **137:** execute pinned OIDF conformance plans ([9cbecdf](https://github.com/szTheory/lockspire/commit/9cbecdfa7a4b3078bbfd72521c521bc96b50cdb0))
* **137:** provision OIDF workflow inputs ([01695e1](https://github.com/szTheory/lockspire/commit/01695e1ef001a054b8215e3ec84e0be50f9e46dc))
* **acceptance:** make clean-room migrations cold-start safe ([835026b](https://github.com/szTheory/lockspire/commit/835026b7dba86d4abdeca5655d02014ca8981449))
* **ci:** isolate compatibility and conformance tests ([fc87833](https://github.com/szTheory/lockspire/commit/fc878332a03c1968142f170d4b201d3178044729))
* **ci:** make external acceptance failures actionable ([7b446da](https://github.com/szTheory/lockspire/commit/7b446da7c191824290b7e8adfc66658d57d4df7d))
* **ci:** make JOSE cache patch idempotent ([5686853](https://github.com/szTheory/lockspire/commit/5686853226794e9e84c58a7da8531c42997d0890))
* **ci:** preserve guarded milestone release automation ([cd18f9a](https://github.com/szTheory/lockspire/commit/cd18f9a220e828dffe96a8b098c8657d7cbc1346))
* **conformance:** align pinned suite variants ([e4c2ec2](https://github.com/szTheory/lockspire/commit/e4c2ec2196823f0c8718428bd61735cc747b9e87))
* **conformance:** retain safe failure classifications ([7e2fa3b](https://github.com/szTheory/lockspire/commit/7e2fa3bcf3df78bffe0482a66a0149668a9df22e))
* **conformance:** terminate ephemeral provider traffic with tls ([2685e40](https://github.com/szTheory/lockspire/commit/2685e40c9a2eedba93ed338b70a7be2022bc5283))
* **conformance:** wait for complete ephemeral host setup ([c1f8285](https://github.com/szTheory/lockspire/commit/c1f82857d638d0669b54dd79b80653a6c323f2c6))
* **dcr:** issue credentials by client auth method ([612a7b0](https://github.com/szTheory/lockspire/commit/612a7b07e1198ad1c8bc0cbe16d694ede3befcab))
* **dcr:** preserve optional scope metadata ([3938a4a](https://github.com/szTheory/lockspire/commit/3938a4a6c55acdb00071b4a40cd680ff7cccb6b5))
* **docs:** keep internal types out of public references ([e2658ce](https://github.com/szTheory/lockspire/commit/e2658ce0ca4703622ff335d7409eb541086ad8c3))
* **install:** avoid shadow migration status tables ([da2dabb](https://github.com/szTheory/lockspire/commit/da2dabb1e59b14438109f9bde46fc69c34a719d5))
* prove clean-room package install on Elixir 1.19 ([d3ca3ca](https://github.com/szTheory/lockspire/commit/d3ca3ca2f1a12a86ffb8a1ed3fe599e8ffc34d8a))
* **release:** load pinned runtime as ESM ([249adf1](https://github.com/szTheory/lockspire/commit/249adf18073a5ee021480954587e9e1df8467737))
* **release:** load pinned runtime as ESM ([1022e8a](https://github.com/szTheory/lockspire/commit/1022e8a4f059daab7baa7e5e70685140885d9f37))
* **release:** upload the exact verified Hex artifact ([4f73ec8](https://github.com/szTheory/lockspire/commit/4f73ec84ab04e6722304707e91b16afd645a72ce))

## [1.4.0](https://github.com/szTheory/lockspire/compare/lockspire-v1.3.0...lockspire-v1.4.0) (2026-07-28)


### Features

* **demo:** host-owned 404 page and working Disconnect for authorized apps ([#75](https://github.com/szTheory/lockspire/issues/75)) ([d5532d5](https://github.com/szTheory/lockspire/commit/d5532d540e44efe0b078a9a9a24a1c69a09d12de))


### Bug Fixes

* **ci:** keep Release Please unblocked after a publish ([#78](https://github.com/szTheory/lockspire/issues/78)) ([ddf1b1b](https://github.com/szTheory/lockspire/commit/ddf1b1b1485a324c7416e9eee1e21a26bf42465b))
* **consent:** reuse a remembered grant instead of duplicating it on re-approval ([#77](https://github.com/szTheory/lockspire/issues/77)) ([2e597ad](https://github.com/szTheory/lockspire/commit/2e597ad957e9c308efa60428deb79db960fd3a48))
* **deps:** allow phoenix_live_view 1.2.x without forcing adopters onto it ([#76](https://github.com/szTheory/lockspire/issues/76)) ([6ecc37a](https://github.com/szTheory/lockspire/commit/6ecc37aa78fbb10b3a8263ca7313e6f8aabb0256))

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
