# Requirements: Lockspire Milestone v1.4

This milestone adds support for JWT Secured Authorization Requests (JAR).

| ID | Requirement | Status | Verification |
|----|-------------|--------|--------------|
| JAR-01 | Support JAR-by-value in `/authorize` and `/par` | [x] done | `.planning/phases/22-request-object-integration/22-04-SUMMARY.md` |
| JAR-02 | Validate request object signatures using client keys | [x] done | `.planning/phases/24-verification-and-milestone-closure/24-VERIFICATION.md`, `.planning/phases/24-verification-and-milestone-closure/24-VALIDATION.md` |
| JAR-03 | Enforce mandatory claims (iss, aud, exp) in request objects | [x] done | `.planning/phases/24-verification-and-milestone-closure/24-VERIFICATION.md`, `.planning/phases/24-verification-and-milestone-closure/24-VALIDATION.md` |
| JAR-04 | Support JAR decryption (optional/future) | [ ] deferred | - |
| JAR-05 | Expose JAR support in OIDC discovery metadata | [x] done | `.planning/phases/24-verification-and-milestone-closure/24-VERIFICATION.md`, `.planning/phases/24-verification-and-milestone-closure/24-VALIDATION.md` |
| JAR-06 | Provide operator controls for JAR enforcement policies | [x] done | `.planning/phases/24-verification-and-milestone-closure/24-VERIFICATION.md`, `.planning/phases/24-verification-and-milestone-closure/24-VALIDATION.md` |
