# Phase 47 Strategy: 1.0 GA Release Readiness

## Strategic Decisions

Based on the research and the project's vision of maintaining a reliable, developer-friendly automation state, we have finalized the following strategy for transitioning Lockspire to its 1.0 GA release posture.

### 1. Release Automation State (Option A)
We will maintain the integrity of our automated release pipeline (Release Please) rather than bypassing it with manual file edits. 

**Decision:**
- Update `release-please-config.json` by setting `"bump-minor-pre-major": false`.
- Include a specific commit with the footer `Release-As: 1.0.0` to signal the bot to generate the 1.0.0 release PR after this phase is merged.
- **Rationale:** This preserves the single source of truth in the `.release-please-manifest.json` and allows the bot to natively handle the changelog generation and manifest sync. It avoids the high risk of desynchronization that comes with manually editing the manifest and changelog.

### 2. Documentation Posture Update
We will scrub the documentation of "preview" terminology and establish the 1.0.0 GA posture.

**Decision:**
- `docs/supported-surface.md`: Rewrite to remove "v0.2.0 preview" limitations, upgrade the posture to `v1.0.0` GA, and reflect the full feature set as stable.
- `docs/install-and-onboard.md`: Remove the "v0.1 preview support contract" language and reference the stable 1.0 contract.
- `docs/maintainer-release.md`: Update maintainer policies to reference the 1.0.0 GA posture instead of preview limitations.
- `README.md`: Update link titles and phrasing to remove "preview contract" wording.

## Next Steps

With these decisions finalized, the ambiguity around the Release Please transition and the documentation targets is resolved. We are ready to proceed to the planning or execution phase.
