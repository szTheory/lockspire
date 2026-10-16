---
phase: "151"
audited: "2026-10-15"
baseline: "abstract 6-pillar + AGENTS.md/PRODUCT.md copy rules (no UI-SPEC)"
overall_score: 17
max_score: 24
screenshots: none (code-only audit)
---

# Phase 151 — UI Review: Focused Client Registration & Settings

Code-only audit of the current HEAD state of the phase-151 surfaces. Phases 152–153 have since modified the same files. Advisory: this review does not block phase completion.

## Pillar Scores

| Pillar | Score | Key Finding |
|---|---|---|
| 1. Copywriting | 2/4 | "client" still appears in UI copy (headings, empty states, error titles) despite the PRODUCT.md vocabulary rule (client → app) |
| 2. Visuals | 3/4 | Route hierarchy is clear; the copy-once secret panel renders below a long, reset form on the registration route |
| 3. Color | 3/4 | Variants mostly follow the rule; "Edit app details" uses the secondary class in the primary slot; danger differs from secondary only by text color at rest |
| 4. Typography | 3/4 | No arbitrary type classes; button font size is hardcoded (0.875rem) rather than tokenized |
| 5. Spacing | 3/4 | No arbitrary spacing; `lockspire-admin-client-create` wrapper has no CSS rule |
| 6. Experience Design | 3/4 | Strong loading, error, empty, validation, confirmation and copy-once states; the main gap is where the secret panel appears after creation |

**Overall: 17/24**

## Top 3 Priority Fixes

1. **"client" in UI copy contradicts the vocabulary map (pillar 1).** Replace these and add the old phrases to the retired-wording table:
   - `index.ex:250` "No clients yet" → "No apps yet" (tests at `clients_live_test.exs:447, 453, 522` lock in the old string)
   - `index.ex:255` "Create a client to begin connecting applications."
   - `index.ex:235` "No matching-client result is available"
   - `show.ex:284` "Client not found"; `show.ex:109` "Client changes saved."; `show.ex:1247` "Check the client before retrying."
   - `form_component.ex:573, 601` "The client could not be saved."; `:608–626` "Client was not created" / "Client changes were not saved" / "Client security profile was not saved"
   - `form_component.ex:732, 737` "Edit client settings", "Update client security profile"
   - `form_component.ex:74` "Client type" → "App type" (the detail page already says "App type" at `show.ex:364`)
   - `show.ex:501` "Client assertion keys" → align with "Signing keys"
   - Keep "Client ID" and "client secret" (allowed by the map).
2. **The copy-once secret panel is hidden below a reset form after a successful create (pillars 2 and 6).** In `index.ex` `:new`, `FormComponent.client_form` renders before the `:if={@created_result}` block, and the form clears on success. Render the result panel above the form (or replace the form and offer "Add another app"), and add a test that asserts the order.
3. **Action hierarchy and danger styling (pillar 3).** `show.ex:336-342` puts "Edit app details" in the `:primary` slot but styles it `lockspire-admin-btn-secondary`; slot and style should agree (`operator-admin.md:129`). `.lockspire-admin-btn-danger` shares the secondary background and border, so give it a visible danger border at rest (`--ls-status-danger-border`).

## Detailed Findings

### Pillar 1: Copywriting (2/4)
- Passing: "Add app" / "Creating app…", "Back to apps", "Server-side app" / "Browser or mobile app", "Allowed permissions (OAuth scopes)", "Sign-in return URLs", and the help text "Add an app that will use this service."
- Accuracy: `show.ex:805` (rotate-secret subtitle) says Lockspire "does not store or show it again", but `index.ex:143-146` correctly says "Lockspire stores only a hash." Suggested wording: "Lockspire stores only a hash, so it cannot show the secret again."
- Minor: `show.ex:30` default `task_body` ("this client's identity") is dead copy that `handle_params` overwrites.
- `vocabulary_contract_test.exs` checks only the retired-wording table, so these strings currently pass CI.

### Pillar 2: Visuals (3/4)
- `:new` has one title, one explanation and one form (`show_heading={false}`, `index.ex:118-122`). Task routes lead with `entity_header` identity and a "Back to app" link (`show.ex:306-321`), and the full workspace is hidden.

### Pillar 3: Color (3/4)
- Primary: inventory "Add app" (`index.ex:170`), empty-state link (`index.ex:262`), form submit (`form_component.ex:429`). Secondary: navigation, filters, recovery. Danger: rotate (`show.ex:792`, `rotate_secret_component.ex:47`) and disable/enable (`show.ex:716`). No hardcoded hex or rgb values.

### Pillar 4: Typography (3/4)
- Semantic headings with shared components. Button `font-size: 0.875rem` is hardcoded in `admin_css.ex` (~884); this is out of phase scope.

### Pillar 5: Spacing (3/4)
- `lockspire-admin-client-create` (`index.ex:109`) has no CSS definition, so the `:new` layout relies on default block spacing.

### Pillar 6: Experience Design (3/4)
- Present: `role="status"` loading, error alert with reload and return recovery, separate first-use and filtered empty states, `aria-invalid`/`aria-describedby` with an error summary, disable-confirmation checkbox, and a copy-once secret with "Hide credential".
- Gaps: secret panel placement (Fix 2) and weak danger styling at rest (Fix 3).

## Files Audited
- `lib/lockspire/web/live/admin/clients_live/index.ex`, `form_component.ex`, `show.ex`, `rotate_secret_component.ex`
- `lib/lockspire/web/components/admin_components.ex`, `lib/lockspire/web/admin_css.ex`
- `docs/operator-admin.md`, `PRODUCT.md`
- `test/lockspire/web/live/admin/clients_live_test.exs`
