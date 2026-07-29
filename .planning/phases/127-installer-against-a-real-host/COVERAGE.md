# API Coverage — Phase 127 (Installer Against A Real Host)

No external API integration: Phase 127 integrates no third-party API or SDK. Every plan in this
phase fixes installer/template/library defects the Phase 126 walk found (router macro shape,
config completeness, dependency range, resolver login path, HEEx compile, Mix task repo access,
installer instructions, plan-then-apply conflict semantics), and reconciles the Phase 126 defect
ledger against the walk harness's own workaround markers. The only external service touched
anywhere in the phase is the Hex registry, for a version-range resolution on `ecto_sql` (plan
127-02) -- a build-time dependency operation, not a runtime integration, and it introduces no new
network call, endpoint, or protocol surface at runtime.

Unlike Phase 126, this phase does not run `mix adopter.walk` end to end as its own verification
method for most of its plans (it is this plan's own blocking checkpoint, not a per-task
verification loop), and none of its plans call any of Lockspire's own protocol endpoints, mint
tokens, or drive an authorization flow directly. Phase 126's `COVERAGE.md` authored a full
HTTP-surface matrix because that phase genuinely exercised Lockspire's own protocol surface end to
end; this phase does not, so no matrix is fabricated here for capabilities that do not exist in
this phase's own scope.
