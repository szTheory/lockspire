# Deferred Items

- `test/lockspire/release_readiness_contract_test.exs` still expects the older `PROJECT.md` milestone wording (`Current Milestone: v1.3 PAR Policy Controls`).
- `test/lockspire/protocol/pushed_authorization_request_test.exs` has two existing JAR-by-value cases that fail in the full suite with `Config.issuer!/0` mount-path validation (`/lockspire` vs `""`).
- `mix test --include integration` and `mix test` both still fail on the pre-existing `release_readiness_contract_test` wording mismatch during this plan run.

These were observed during full-suite verification and are out of scope for this controller-seam plan.
