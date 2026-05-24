# Phase 68: Publish Verification & Install Truth - Validation

This document describes how the Phase 68 plans validate the phase requirements and success criteria outlined in the ROADMAP.

## Requirement Coverage

- **PUB-01 (Automated Verification):** Addressed by `68-01-PLAN.md`, which introduces `scripts/verify_install_truth.sh` to automatically verify the published package via the Hex API, ensuring version metadata matches expectations.
- **PUB-02 (Install Path Confidence):** Addressed by `68-01-PLAN.md` by generating an isolated Phoenix host application in a temporary directory, forcefully downloading the package from Hex, and running `mix compile` to prove install truth cleanly without referencing local directory sources. It is also covered by `68-02-PLAN.md` (Maintainer Contract and Test) verifying explicit instructions.

## Success Criteria Validation

1. **Post-publish checks confirm Hex metadata, docs pointers, and release artifacts match the canonical support contract.**
   - *Validated by:* The bash script in `68-01-PLAN.md` explicitly fetches metadata from `https://hex.pm/api/packages/lockspire` using a retry loop and checks the response code of `hexdocs.pm` URLs.

2. **The documented install path still works for the released package without contradictory version or support signals.**
   - *Validated by:* `68-01-PLAN.md` executing an end-to-end `mix phx.new` and dependency addition using only published artifacts.

3. **Any release-lane evidence that cannot be fully automated in repo is captured as explicit maintainer verification rather than implied proof.**
   - *Validated by:* `68-02-PLAN.md` (Maintainer Contract and Test), explicitly capturing manual evidence requirements and test assertions around the maintainer workflow.

## Plan Breakdown

- **Plan 68-01:** Scaffold and build the automated publish truth script (`scripts/verify_install_truth.sh`) which serves as the executable verification.
- **Plan 68-02:** Establish the test assertions around the maintainer guidelines and processes to ensure the workflow is documented and enforceable.