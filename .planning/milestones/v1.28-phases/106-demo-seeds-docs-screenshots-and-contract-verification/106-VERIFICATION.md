---
phase: 106
status: complete
verification_mode: automated
manual_uat: not_required
updated: 2026-06-03T22:25:00Z
---

# Phase 106 Verification

## Automated Evidence

| Check | Command / Evidence | Result |
|-------|--------------------|--------|
| Compile with warnings as errors | `MIX_ENV=test mix compile --warnings-as-errors` | pass |
| Design-system contract fence | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs` | pass: 7 tests, 0 failures |
| Admin LiveView regression suite | `mix test test/lockspire/web/live/admin` | pass: 69 tests, 0 failures |
| Demo seed state covers screenshot/click-through needs | Source checks for `northstar-dcr-self-registered`, `provenance: :self_registered`, `active: false`, `demo-refresh-reuse-detected`, and `demo-logout-backchannel-retryable` in `examples/adoption_demo/priv/repo/seeds.exs` | pass |
| Operator guide preserves journey and host boundary | Source checks for `Admin navigation model`, `docs/supported-surface.md`, and `The host app owns` in `docs/operator-admin.md` | pass |
| Screenshot inventory covers full admin route surface | `.planning/phases/106-demo-seeds-docs-screenshots-and-contract-verification/106-SCREENSHOTS.md` contains desktop/mobile screenshot paths for every listed route | pass |
| Screenshot files exist | Every `tmp/admin-ui-polish/*.png` path referenced by `106-SCREENSHOTS.md` exists | pass |
| Screenshots are evidence only | `rg "tmp/admin-ui-polish" lib` returns no runtime source references | pass |

## Browser Evidence

Adoption demo browser capture was run locally:

1. `mix ecto.setup` in `examples/adoption_demo`.
2. `mix phx.server` at `http://127.0.0.1:4100`.
3. `agent-browser` login as seeded `ops` account.
4. Desktop screenshots for previously uncovered support/operations routes.
5. Mobile screenshots at `390x844` for support, operations, DCR, policy, IAT, token, and client list routes.

Evidence is recorded in:

- `.planning/phases/106-demo-seeds-docs-screenshots-and-contract-verification/106-SCREENSHOTS.md`
- `tmp/admin-ui-polish/`

## Residuals

None. Browser capture produced desktop/mobile evidence for every route in the Phase 106 coverage matrix.

## Notes

- The test runs emit an existing startup log line about `Lockspire.TestRepo` not being started during KeyCache refresh; affected commands exited 0.
- During browser capture, the demo server logged existing 404 template errors for browser asset probes. The requested admin routes rendered and screenshots were saved.
