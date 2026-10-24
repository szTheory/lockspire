# v1.47 OAuth/OIDC Core Interoperability & Hardening

**Research date:** 2026-10-24
**Scope:** Protocol-facing interoperability and security hardening for the existing embedded Phoenix authorization-server surface. No admin or user-interface scope.
**Confidence:** HIGH for the current repo contract and normative standards; MEDIUM for interpreting historical external-suite failures; LOW for any present-day defect claim until reproduced.

## Recommendation

Treat v1.47 as a focused protocol-conformance correction milestone, not a certification or profile-expansion milestone. Reproduce and classify the saved Phase 37 and FAPI 2.0 failures first, using their exact historical inputs. Fix only issues independently established against a normative requirement and the supported Lockspire path. Put repo-native regression cases at the protocol/controller boundary, then rerun the same pinned suite plans as supplemental evidence. Keep certification and CI/release-gate claims out of scope.

This recommendation follows Lockspire's support contract: the existing code + PKCE and strictness slice are supported, FAPI profiles are configuration-enforced slices, while broad external certification is explicitly not claimed. RFC 9700 requires exact redirect matching (with a native-loopback exception irrelevant to this current web-client profile); OIDC Core defines redirect-safe error return and silent-auth errors; FAPI 2.0 is a composed confidential-client, PAR, sender-constraining, client-authentication, TLS, and cryptographic profile. These are cross-boundary contracts, so the best vertical slices are request validation → response/error serialization → independent HTTP assertion, with the narrowest shared behavior fixed once.

## Evidence and Boundaries

### Repository facts

- `docs/supported-surface.md` is canonical. It claims the embedded Phoenix path, auth code + PKCE, exact redirect URI matching, `prompt=none`/`max_age` strictness, PAR, discovery, and selected FAPI 2.0 profile behavior. It explicitly disclaims external OIDF/FAPI certification.
- `docs/maintainer-conformance.md` classifies `suite_failure` as a run where the external suite ran and found a profile result Lockspire did not satisfy. It requires reproducing at the same suite commit, plan, and image digests and correlating repo-native proof before changing protocol code.
- The immutable suite lock names OIDF `release-v5.1.43`, commit `16ad152b1b2c0baacd3d2519128340d95deb2b8c`, verified archive/helper hashes, and OCI digests. The Phase 37 and FAPI plan checksums bind the exact checked-in plans.
- `phase37-plan.json` selects OIDC `code`, `client_auth_type=none`, `response_mode=default`, dynamic registration, and modules for not-logged-in/logged-in `prompt=none`, registered redirect URI enforcement, query mismatch, valid query, and `max_age=10000`.
- `fapi2-plan.json` selects `fapi2-security-profile-final-test-plan`, variants `plain_fapi`, `openid_connect`, `private_key_jwt`, and DPoP sender constraint. An empty `modules` array delegates module selection to the named upstream plan; it is not a hand-picked list of individual tests.
- Phase 137 verification records both immutable runs as `suite_failure`. It says Phase 37 got past DCR credential-method selection and remaining findings concern authorization error behavior; it summarizes FAPI findings as PAR/TLS/WebRunner interoperability. The retained evidence deliberately excludes raw suite logs/configuration, so those summaries cannot identify an exact failed assertion or prove a current defect.
- Current checked-in repo-native proof includes `test/integration/phase37_protocol_strictness_e2e_test.exs`, authorization request unit tests, PAR tests, and FAPI enforcement tests. Read evidence shows explicit behavior coverage for redirect mismatch staying browser-safe, `prompt=none` returning `login_required` to the registered redirect, invalid/expired/replayed PAR references, and FAPI's PAR/JARM enforcement boundaries.

### Facts, inferences, proposals

| Label | Statement |
|---|---|
| **Fact** | The saved Phase 137 run reported `suite_failure` for both plans; the report describes authorization-error, PAR/TLS, and WebRunner findings. |
| **Fact** | The retained repo evidence does not contain per-module results or raw assertion details. The run happened at the reported historical commit, not the present checkout. |
| **Inference** | The Phase 37 report is most useful as a pointer toward authorization-error disposition and parameter serialization, especially where a request has a known registered redirect URI versus an invalid/missing redirect. It is not enough to select a code change. |
| **Inference** | FAPI PAR/TLS/WebRunner signals span server behavior and the harness's TLS/front-channel simulation. Each needs separation into protocol assertion, transport setup, and WebRunner/browser orchestration before attribution. |
| **Proposal** | Reproduce selected failures locally with exact lock identities; capture only approved bounded module/condition names in ephemeral diagnostics; map each confirmed behavior to the relevant repo-native test and normative citation. |
| **Proposal** | Maintain the historical lock for comparable reruns. Update it only in a separate reviewed input-lock change after checking OIDF release notes, plan/module drift, checksums, image digests, runner dependency lock, and rerunning both profiles against old/new identities where practical. |

## Bounded Decision Matrix

| Decision | Recommendation | Why | Do not infer |
|---|---|---|---|
| First target | Phase 37 authorization error semantics and their HTTP redirect/browser-safe split | Its narrow plan is close to current supported web OIDC surface and existing integration tests. OIDC Core says an error is returned to the registered redirect URI unless that URI is invalid; error includes `state` when sent. | A suite failure does not establish which branch or whether current source still fails. |
| Second target | FAPI PAR boundary only after Phase 37 triage; verify pushed parameters are authoritative, malformed references fail closed, and FAPI `/authorize` requires a valid PAR reference | PAR is already supported and required by the FAPI security tier. RFC 9126 requires PAR's HTTPS form-encoded POST and authorization-request validation when referenced. | Do not equate a PAR/TLS/WebRunner summary with a PAR implementation defect; the observed failure may be TLS termination, host reachability, or browser runner setup. |
| FAPI breadth | Keep the pinned FAPI plan as an optional supplemental probe; don't promise profile certification or tackle all FAPI dimensions under v1.47 | The FAPI 2.0 Security Profile composes protocol, client, resource server, TLS, cryptographic, and deployment requirements. A single server-side embedded library cannot certify the complete ecosystem. | Do not label a selected test-plan run “FAPI certified”; do not expand host responsibilities or declare all profile combinations supported. |
| Suite selection | Preserve the exact Phase 37 and FAPI plan identities already checked in; run the narrow Phase 37 plan first and full named FAPI plan only when the disposable host's edge is known-good | Exact plan and suite input identities make failures comparable; Phase 37 is a smaller diagnostic loop. | Do not silently change plan modules, use `master`/mutable tags, or treat a newer runner as equivalent. |
| Change policy | Fix standard-backed, reproducible behavior with a regression test; document a harness/infrastructure finding if protocol behavior is correct | This protects security defaults and avoids churn against false positives. | Do not loosen redirect validation, weaken PAR/TLS, introduce browser redirects for unsafe requests, or change errors solely to satisfy a suite without spec evidence. |
| Dependencies | Default to no new Elixir/runtime dependency. Reuse current Plug/Phoenix, Ecto, crypto/Jose, and existing conformance tooling. | Scope is behavioral; new crypto/URL code would enlarge attack surface. Existing tooling already pins Python runner dependencies and external suite inputs. | Never copy or implement cryptographic primitives; no new browser testing stack unless an isolated diagnostic proves existing tooling cannot test the requirement. |

## Proposed Atomic Requirement Categories

1. **Authorization error disposition:** For recognized client + exact valid registered redirect URI, assert protocol-defined redirect error response and round-trip `state`; for unknown client, absent/malformed/unregistered redirect URI, assert a local/browser-safe HTTP error with no attacker-controlled `Location`. Enumerate exact combinations before implementation. OIDC Core's “unless the Redirection URI is invalid” is the key boundary.
2. **Silent authentication and freshness:** Preserve `prompt=none` outcomes (`login_required`, `interaction_required`, or `consent_required` as applicable) without invoking a host login redirect, and enforce `max_age` against host-provided authentication time. Include success and failure paths; host account/session resolution stays host-owned.
3. **Redirect URI exactness and query behavior:** Keep simple exact registered URI comparison for the supported web path; test query, trailing slash, encoding, fragment, duplicate-parameter, and mismatch cases at the actual HTTP boundary. Never create an open redirect from an unvalidated URI.
4. **PAR and request intake:** Verify HTTPS deployment assumptions, `application/x-www-form-urlencoded` payload acceptance, stored-request binding to client and one-time/expiry semantics, conflict rejection, and FAPI required-PAR behavior. Discovery must remain truthful to the mounted/configured usable surface.
5. **FAPI transport/harness separation:** Document the disposable provider's external TLS terminator and forwarded endpoint assumptions; prove discovery issuer/endpoint URLs and externally visible scheme/host used by the suite. Maintain separate failure classes for suite assertion vs startup, TLS certificate/hostname, Docker host routing, and WebRunner/browser orchestration.
6. **Regression evidence and claim hygiene:** Each confirmed protocol correction gets a deterministic repo-native unit or HTTP integration case. External receipts remain bounded supplemental evidence. Update public support wording only if shipped behavior changes; do not claim certification.

## Perspectives and Examples

- **Client developer:** A valid configured callback must receive an OIDC `login_required` with its original `state` on `prompt=none`; a callback differing by `/callback` vs `/callback/` must not receive a redirect. Avoid ambiguity by registering the exact callback and treating redirect query strings as part of that registered value.
- **Security reviewer:** Error paths need the same open-redirect scrutiny as success paths. Attackers can deliberately induce invalid scopes or deny consent using their own registered callback; even a valid callback may be untrustworthy, so the standards allow the OP to make trust decisions, but invalid client/redirect pairs must not trigger automatic redirect. Never “fix” a suite by falling back to a supplied URI.
- **Host team:** Host controls login UX, account resolution, authentication timestamp source, TLS termination, and proxy trust. Host `/login` redirects are not valid completion for `prompt=none`; provider must return an OIDC protocol result. Public issuer and endpoint URLs must reflect the externally reachable HTTPS origin under proxy deployment.
- **Maintainer:** The current failure receipts are historical and summary-only. Re-run same SHA-compatible host behavior, suite commit, exact plan checksum, and image digests before deriving a remediation. If OIDF plan or harness itself changes, retain both identities in notes and do not mix comparisons.

### Common footguns to guard against

- Treating any 302 as proof of a correct OAuth redirect; assert origin, path, response mode, `error`, `state`, and absence of a host login location.
- Assuming a browser-safe local error is wrong whenever `redirect_uri` is invalid; this protects against redirect injection.
- Comparing decoded/normalized URIs or ignoring query order/content instead of the supported exact-string contract.
- Trusting proxy headers from arbitrary sources and publishing internal `http` scheme/host metadata; transport failures may be deployment mistakes, but they still need explicit verification.
- Treating `/authorize` reached through TLS-terminating nginx as equivalent to the application directly serving TLS. Suite callback URLs, issuer metadata, cookie/origin behavior, and forwarded headers can diverge.
- Treating an empty checked-in FAPI `modules` list as “no tests”; the upstream named plan supplies the test selection.
- Updating suite source/images/helper files but not the input checksums, runner version lock, plan checksums, and result comparison notes together.

## Phase Dependencies and Gates

Recommended sequencing within v1.47:

1. **Failure reproduction and attribution (gate):** Run the exact Phase 37 profile first on a disposable provider with same suite/plan/images; preserve receipt and inspect raw details only ephemerally. For each failure, record module/condition, spec section, current repo test coverage, and classification. If only infra/WebRunner/TLS fails, stop protocol changes for that item and fix or document harness configuration separately.
2. **Authorization error slice:** Add/update tests for redirect-safe versus local errors, `state`, response mode, and `prompt=none` host-login isolation. Make only evidenced code changes. No dependencies.
3. **PAR/FAPI boundary slice (conditional):** Proceed only if exact FAPI failure is protocol behavior after provider-origin/TLS/WebRunner are verified. Cover PAR reference lifecycle and FAPI required behavior at HTTP boundary; reuse existing protocol/storage implementation and test support.
4. **Regression and claim review:** Run focused repo-native behavior tests, then exact pinned suite plans; record suite result as supplemental only. Update maintainer/support documentation only when a true contract change occurs; do not add release-blocking or certification claims.

### Evidence / stop / escalation gates

- **Proceed with code only when:** exact suite failure has a bounded assertion/module identity; same input set can reproduce it (or a repo-native deterministic case demonstrates it); a normative requirement applies to the supported Lockspire surface; and a regression test captures the corrected boundary.
- **Stop as harness/infrastructure when:** suite does not reach the intended endpoint, external scheme/issuer/redirect host is inconsistent, TLS cert/hostname validation fails before a protocol assertion, WebRunner setup is incomplete, or the result changes with no protocol source changes. Record the condition without changing OAuth behavior.
- **Escalate/spec decision when:** OIDC Core's invalid-redirect boundary, host policy, or current product contract does not uniquely determine behavior; capture the exact standard clause and make the product decision before altering observable errors.
- **No milestone success from:** a container becoming ready, `integration_only`, repo-native tests alone, historical `suite_failure` receipts, or an external-suite run without exact input identities. A pass only supports the tested plan/profile and is not OIDF certification.

## Pin and Update Strategy

Keep `release-v5.1.43` and its commit/hash/digests as the historical baseline for diagnosis. Do not opportunistically bump versions while implementing protocol changes. A suite update is a separate reviewed change: select a concrete OIDF release/commit, inspect upstream release notes and plan changes, pin archive and helper hashes plus every OCI digest, refresh any Python runner dependency closure and plan checksums, validate all immutable inputs before use, and run the same plan against both identities where practical. Do not use OIDF staging/master as retained evidence; staging is useful only for private diagnosis of a suspected upstream suite bug. Preserve bounded receipts for pass and fail, delete raw work, and compare module/condition identities rather than only overall status. If upstream test semantics changed, classify old/new differences explicitly rather than calling them regressions.

## Standards and Primary Sources

Accessed 2026-10-24. Normative sources are preferred; current project plans/receipts supply local evidence.

- OpenID Connect Core 1.0 incorporating errata set 2 — authorization request redirect URI matching and authorization error handling / OIDC error codes: https://www.openid.net/specs/openid-connect-core-1_0.html
- RFC 9700, OAuth 2.0 Security Best Current Practice — exact redirect URI matching, code flow security, open redirects: https://www.rfc-editor.org/rfc/rfc9700.html
- RFC 9126, OAuth 2.0 Pushed Authorization Requests — HTTPS form POST, supported authorization-request parameters, request reference validation: https://www.rfc-editor.org/rfc/rfc9126.html
- OpenID Foundation, FAPI 2.0 Security Profile final — TLS, confidential clients, PAR, PKCE, sender-constrained tokens, `iss`, JWT algorithms, AS requirements: https://openid.net/specs/fapi-security-profile-2_0-final.html
- OpenID Foundation, FAPI 2.0 Message Signing final — current message-signing profile reference: https://openid.net/specs/fapi-message-signing-2_0-final.html
- OpenID Foundation, Conformance Suite overview — suite source, local Docker use, CI runner, release notes, distinction from certification process: https://openid.net/certification/about-conformance-suite/
- OpenID Foundation, OP conformance testing — profile/test-plan selection context: https://openid.net/certification/connect_op_testing/
- OpenID Foundation, certification process — certification requires completing applicable test plans and submitting the certification request: https://openid.net/certification/how-to-submit-your-certification-request/
