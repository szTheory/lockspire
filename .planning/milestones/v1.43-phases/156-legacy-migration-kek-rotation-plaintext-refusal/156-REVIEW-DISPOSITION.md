---
phase: 156-legacy-migration-kek-rotation-plaintext-refusal
review: 156-REVIEW.md
critical: 1
warning: 3
info: 2
---

# Phase 156 — Code Review Disposition

| Finding | Severity | Disposition | Rationale |
|---------|----------|-------------|-----------|
| CR-01 Ecto query telemetry `result` carries stored key bytes on the locked SELECT and status listing | critical | fixed (`72fd022a`) | `sensitive: true` in `Support.repo_options` now implies `log: false` **and** `telemetry_event: nil`. The engine's locked read and CAS write, `encryption_status/0` and the dry-run listing all use sensitive reads, which covers `--check`, doctor and Verify. **Residual (pre-existing, deferred → Phase 157 RED-01):** protocol signing-path reads (`fetch_active_signing_key`, `fetch_signing_key_by_id`, `list_decryption_keys`) and admin `Keys.list_keys/1` still read the column through non-sensitive queries. After migration that column holds envelope ciphertext; before migration it holds legacy plaintext. |
| WR-01 doctor exits 0 under `:reject` with legacy rows while Verify errors | warning | fixed (`6a8dc1d9`) | Shared `EncryptionStatus.broken_now?/1` predicate used by doctor and Verify (D-19). |
| WR-02 leak test never inspected repo-event `result` nor ran dry-run/status | warning | fixed (`af60f6c6`) | Test now covers dry-run and status in the captured window, checks `result`, and refutes any key-column query reaching log/telemetry. Confirmed it fails with the CR-01 fix reverted. |
| WR-03 stranded retired rows force exit 1 forever | warning | fixed (`33c42355`) | Per D-11a; D-15 clarified in CONTEXT. Stranded failures print but do not fail the run or dry-run. |
| IN-01 test-only options reachable from public API, `page_size` unvalidated | info | fixed (`2bab26c7`) | `page_size` validated (`{:error, :invalid_option}`). `@doc` names `:dry_run`/`:actor` as supported. `after_lock` narrowed to `%{kid: kid}`. |
| IN-02 `Verify.safely/1` MatchError message inspects the unmatched term | info | fixed (`04fab11d`) | Fixed generic message for `MatchError`. |
