---
phase: 83-lockspire-owned-dpop-endpoint-adoption
plan: 03
subsystem: testing
tags: [dpop, regression, token, userinfo]
requirements-completed: [NONCE-AS-03, NONCE-RS-03]
completed: 2026-05-24
---

# 83-03 Summary

- Preserved valid-nonce regression coverage so nonce support does not mask replay, binding, `ath`, `iat`, or other pre-existing failure modes.
- Trimmed the `/userinfo` controller proof boundary back to one replay challenge plus one explicit retry-success contract, leaving the broader negative matrix in protocol tests.
- Re-ran the full Phase 83 token and userinfo subset with all new retry and regression coverage passing.
