# PAR Milestone Research: Pitfalls

**Project:** Lockspire  
**Milestone:** v1.2 PAR Foundation  
**Researched:** 2026-04-24  
**Confidence:** HIGH

## Critical Pitfalls

### 1. Treating PAR as "just another endpoint"

Risk:
PAR is not complete when the server only returns a `request_uri`. The value must be durable, client-bound, expiring, and replay-resistant at `/authorize`.

Prevention:
- Model `request_uri` as a first-class stored artifact with lifecycle rules.
- Test replay, expiry, and wrong-client usage explicitly.

### 2. Accepting conflicting authorization parameters

Risk:
If `/authorize` accepts a PAR-issued `request_uri` and also keeps honoring conflicting raw parameters, Lockspire can blur request truth and undercut the security gain of PAR.

Prevention:
- Define one canonical merge policy before implementation.
- Prefer resolving request truth from the pushed object, not from later browser parameters.

### 3. Leaking into JAR or broader OIDC request-object scope

Risk:
Supporting PAR can tempt the implementation into partial JAR support or ad hoc `request` / external `request_uri` behavior that the project has not scoped or documented.

Prevention:
- Keep `request` and non-PAR `request_uri` support explicitly out of scope.
- Update validation, docs, and tests together so unsupported request-object features stay rejected.

### 4. In-memory-only storage

Risk:
Transient process storage would make PAR correctness fragile under restarts, clustering, or race conditions.

Prevention:
- Keep pushed request truth in the storage boundary used elsewhere for protocol-critical state.

### 5. Discovery/docs claiming too much

Risk:
Adding a PAR endpoint can lead docs to imply broader request-object, DCR, or certification posture than the repo actually proves.

Prevention:
- Couple metadata changes with support-surface docs and contract tests.

### 6. Treating release warning cleanup as optional drift

Risk:
Shipping a new protocol wedge while a known GitHub Actions runtime deprecation remains unresolved weakens the preview trust posture the last milestone established.

Prevention:
- Keep a milestone requirement that closes only when the release path is warning-free and still matches checked-in maintainer guidance.

## Primary Sources

- RFC 9126: OAuth 2.0 Pushed Authorization Requests — https://www.rfc-editor.org/rfc/rfc9126
- GitHub changelog: Node 20 deprecation on Actions runners — https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/

---
*Research completed: 2026-04-24*
