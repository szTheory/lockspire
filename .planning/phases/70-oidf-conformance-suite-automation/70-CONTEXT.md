# Phase 70: OIDF Conformance Suite Automation (CONF-04)

## Context
During the start of Milestone v1.18, Mutual TLS (mTLS, RFC 8705) was initially considered as the next major security pillar. However, a deep architectural review concluded that mTLS creates massive infrastructural friction. Lockspire is an embedded library in Phoenix applications, which are almost exclusively deployed behind TLS-terminating reverse proxies (AWS ALB, Nginx, Envoy). mTLS requires the proxy to terminate the connection, validate the client certificate, and pass it to Phoenix via an HTTP header (e.g., `X-Forwarded-Client-Cert`). This is notoriously difficult to configure securely across diverse environments and compromises security if the proxy strips or spoofs the header.

Since Lockspire already robustly supports DPoP—which provides identical sender-constraining security guarantees at the pure HTTP application layer requiring zero proxy configuration—mTLS remains *permanently out of scope*, upholding the locked decision from the v1.10 milestone. This explicit reasoning is documented here to prevent spinning wheels on mTLS in future milestones.

Instead, we pivoted to resolving **CONF-04 (OIDF Conformance Suite Automation)**. While Lockspire has FAPI 2.0 preflight tooling, it lacks an automated CI run against the official OpenID Foundation test suite. Automating this suite provides undeniable proof of correctness and completeness of implementation without burdening developers with proxy-level TLS configuration.

## Objectives
- Integrate the official OpenID Foundation Conformance Suite into the automated CI pipeline.
- Execute and prove Lockspire's FAPI 2.0 compliance automatically.
- Provide a reproducible local testing lane for developers.
- Close the historically deferred `CONF-04` requirement.
