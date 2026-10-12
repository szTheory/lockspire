# Phase 151 Context: Focused Client Registration & Settings

## Decisions

- **D-01 — Dedicated registration route:** Put client registration at `/admin/clients/new`, register the static `new` path before `/admin/clients/:client_id`, and make the client inventory link to that route instead of an in-page form anchor.
- **D-02 — Preserve the one-time credential handoff:** A successful confidential-client creation stays on the registration route and displays the plaintext client secret only in the existing copy-once result. Acknowledging the secret or leaving the route clears it. Never move a secret into a URL, log, or retained screenshot.
- **D-03 — Keep the inventory return context:** Carry normalized inventory filters into the registration route and use them for the return link. Build the return path from the internal clients route and normalized filters; do not accept an arbitrary return URL.
- **D-04 — Keep client tasks focused:** Client-specific settings and credential tasks lead with the relevant client identity, task, and a direct path back to that client's detail page. Keep unrelated inventory and workspace content out of the task's first view. Preserve the current form, confirmation, and credential-redaction behavior.
- **D-05 — Give action styles a stable meaning:** Primary marks the page's principal safe task; secondary marks supporting navigation, recovery, or alternate actions; danger marks a consequential destructive action and retains its existing consequence text and confirmation. Do not alter action handlers or OAuth behavior to change visual emphasis.
- **D-06 — Prove the complete registration journey:** Cover route resolution and ordering, one title and concise explanation, return navigation with filters, invalid and failed submission states, successful creation with the copy-once secret still on the registration route, and secret clearing on acknowledgement or route departure with existing automated tests. Keep verification redaction-safe.

## Deferred Ideas

- Route-wide overview, queue, support, and general copy/layout changes belong to their mapped v1.42 phases, not Phase 151.
- OAuth/OIDC protocol behavior, security defaults, queue controls, new dependencies, and the separate CR-01 private-key-storage finding are outside Phase 151.

## Agent Discretion

- Reuse the existing `ClientsLive.Index` and `FormComponent` patterns for the new route when that keeps the current create and one-time-secret lifecycle intact; introduce no new UI dependency.
- Use the existing ExUnit and LiveView test harness as blocking regression evidence. A local rendered-browser spot check may supplement it without requiring user UAT or retaining any credential-bearing image.
- Keep changes within existing Admin components, design tokens, and staff-facing language conventions.
