# API Coverage — Phase 143 release operations

> Full coverage by default for the existing GitHub Actions and Hex release surfaces used to publish and verify Lockspire 1.5.1. This phase extends the repository's existing release integrations; it does not introduce a new external service or Lockspire product API.

| capability | decision | reason |
|---|---|---|
| Read current GitHub main, matching CI, hygiene, and active release runs | INTEGRATE | Required to authorize only the exact current source and detect stale or replaced runs (D-01, D-02). |
| Read GitHub branch protection, hex-publish reviewers, and auto-merge state | INTEGRATE | Revalidate the live controls before dispatch and publication; auto-merge remains closed for this cut (D-03, D-04). |
| Set and clear the single exact-SHA Phase 143 authorization repository variable | INTEGRATE | The existing workflow consumes this one-SHA authorization; set it only after fresh candidate checks and clear it after the attempt (D-03). |
| Dispatch release workflow on main with exact SHA, CI run ID, and reason | INTEGRATE | This is the selected publication authority; dispatch once and stop if the candidate or evidence changes (D-01, D-03, D-04). |
| Transfer tar, manifest, and prepublish proof as one run artifact | INTEGRATE | The protected publisher must verify and publish the same bytes that passed prepublish proof (D-05). |
| Approve deployment in the protected hex-publish environment | INTEGRATE | Preserve the final human gate before the scoped Hex credential is available (D-03). |
| Publish exact tar through the protected Hex publisher credential | INTEGRATE | The established exact-tar publishing path is required; a publisher compatibility failure blocks the release (D-05, D-07). |
| Read public Hex 1.5.1 checksum and versioned docs | INTEGRATE | Public registry facts must match the manifest-bound artifact before the release can be called verified (D-06). |
| Read or create GitHub release and resolve actual tag ref to source commit | INTEGRATE | Existing release metadata alone does not prove an existing tag target (D-06). |
| Run and retain public clean-room install proof | INTEGRATE | This proves the adopter-facing Hex package works independently of the source checkout (D-06). |
| Trigger publication from a tag or run an unattended publisher | OPT-OUT | Tags may identify stale or non-current commits; publication requires exact-SHA workflow dispatch and protected review (D-03, D-04). |
| Allow Release Please auto-merge during this exceptional release | OPT-OUT | Keep the sustaining merge lane closed until the 1.5.1 outcome and repository controls are reconciled (D-03, D-04). |
| Rebuild in the credentialed job or use a package-building upload API | OPT-OUT | A rebuild would sever the manifest and prepublish proof from published bytes (D-05, D-07). |
| Add OIDC, build attestations, or new supply-chain service | OPT-OUT | These are explicitly deferred and are not prerequisites for this release (D-07, Deferred Ideas). |
| Add runtime/API/OAuth behavior, admin UI, or visual design | OPT-OUT | These are outside the release-only phase boundary. |
