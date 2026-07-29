# Requirements: Lockspire — Milestone v1.36 Adopter Path Proof

**Defined:** 2026-07-28
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

**Milestone goal:** Prove the documented path from `mix phx.new` to a working third-party OAuth flow end to end in one run, and fix every break found along the way.

## Milestone Requirements

Requirements scoped to v1.36 only. Each maps to exactly one roadmap phase.

### Adopter Path Walk

The path an adopter actually follows, executed as one continuous run rather than as
independently-proven segments.

- [x] **ADOPT-01**: A maintainer can run a single command that walks the whole documented adopter path — generate a Phoenix app, install Lockspire, wire it, migrate, boot it, register a client, complete an authorization-code + PKCE flow — and get one pass/fail verdict.
- [x] **ADOPT-02**: The walk uses a stock `mix phx.new` app with the defaults a real adopter would use, including Ecto and HTML, rather than a stripped-down variant chosen to make the walk easier.
- [x] **ADOPT-03**: When the walk fails, a maintainer can see which documented step failed and the underlying error without re-running the earlier steps by hand.
- [x] **ADOPT-04**: The walk asserts that the flow actually issued a usable token, not merely that each command exited zero.

### Installer Against A Real Host

`mix lockspire.install` currently runs against an empty directory in test. This category
covers proving it against a real generated application.

- [ ] **INSTALL-01**: `mix lockspire.install` is exercised against a freshly generated Phoenix application instead of an empty fixture directory.
- [ ] **INSTALL-02**: A maintainer can confirm the installer's generated files match the host they were generated into — app name, web module, router module, and repo module all resolve against the real host rather than a placeholder.
- [ ] **INSTALL-03**: Installer behavior when the host already contains conflicting files or prior Lockspire output is observable and predictable, so a re-run does not leave the host in an unclear half-installed state.

### Documented Wiring Truth

Section 3 of `docs/install-and-onboard.md` is manual work the adopter performs, and no
test currently proves those instructions produce a working provider.

- [ ] **WIRE-01**: Every manual step in `docs/install-and-onboard.md` is executed by the path walk, so the guide cannot silently drift from what actually works.
- [ ] **WIRE-02**: An adopter following only the guide reaches a booting provider without needing knowledge that is absent from the guide; any such missing knowledge is added to it.
- [ ] **WIRE-03**: Defects found while walking the path are fixed at the real source — library, generator, or guide — rather than worked around inside the walk itself.

### Reference Artifact Alignment

`examples/adoption_demo` contains no reference to `mix lockspire.install`. It is hand-wired,
so the artifact adopters are pointed at bypasses the path they are told to walk.

- [ ] **REF-01**: The relationship between `examples/adoption_demo` and the installer path is explicit and accurate, so an adopter reading the demo knows whether it demonstrates the documented install path or a hand-wired alternative.
- [ ] **REF-02**: Any divergence between the demo's wiring and the installer's generated wiring is either removed or documented with its reason, so the demo cannot quietly teach a different integration than the one Lockspire ships.

### Durable Guardrail

Without automation this surface rots again as soon as attention moves on.

- [ ] **GUARD-01**: The adopter path walk runs automatically — on a schedule, on release, or both — so a break is detected without a maintainer remembering to check.
- [ ] **GUARD-02**: `scripts/publish/verify_install_truth.sh` either proves the adopter path or states plainly what it does not prove, so "Install Truth proven" cannot overstate its coverage again.
- [ ] **GUARD-03**: A failing adopter path walk is visible to a maintainer as a distinct, attributable failure rather than a generic red build.

## Future Requirements

Acknowledged, deliberately deferred out of v1.36.

### Adopter Path Breadth

- **FUTURE-01**: Extend the path walk beyond authorization-code + PKCE to device flow, DCR, and CIBA onboarding.
- **FUTURE-02**: Prove the adopter path against the minimum supported Elixir/OTP pair in addition to the current one.
- **FUTURE-03**: Prove the Sigra companion path end to end alongside the plain Phoenix path.

## Out of Scope

| Item | Reason |
|------|--------|
| Any new protocol surface | This milestone is adoption hardening, not protocol breadth — the ordering rule in `.planning/MILESTONE-ARC.md` says do not widen protocol without adopter evidence. |
| Widening `docs/supported-surface.md` | Findings that would expand the public support contract are logged as future candidates, not built. Widening claims while proving the install path would confuse what was actually verified. |
| Making the installer inject into host router/config/application | A real possibility, but it is a design decision the walk should inform rather than a conclusion assumed before walking. Revisit once the evidence exists. |
| Host-owned seam changes | Accounts, login UX, layouts, branding, and policy stay host-owned. Fixing adopter friction must not absorb host responsibilities into the library. |
| Admin/operator UI work | v1.28–v1.32 covered this. Adopter-path defects in admin UI get logged unless they block the walk. |
| Rewriting the adoption demo as a generated app | Possible outcome of REF-01/REF-02, but forcing it up front presumes the answer. The demo's in-repo path dependency may make full installer parity wrong. |

## Traceability

Populated during roadmap creation on 2026-07-28. See `.planning/ROADMAP.md`.

| Requirement | Phase | Status |
|-------------|-------|--------|
| ADOPT-01 | Phase 126 | Complete |
| ADOPT-02 | Phase 126 | Complete |
| ADOPT-03 | Phase 126 | Complete |
| ADOPT-04 | Phase 126 | Complete |
| INSTALL-01 | Phase 127 | Pending |
| INSTALL-02 | Phase 127 | Pending |
| INSTALL-03 | Phase 127 | Pending |
| WIRE-01 | Phase 128 | Pending |
| WIRE-02 | Phase 128 | Pending |
| WIRE-03 | Phase 128 | Pending |
| REF-01 | Phase 129 | Pending |
| REF-02 | Phase 129 | Pending |
| GUARD-01 | Phase 130 | Pending |
| GUARD-02 | Phase 130 | Pending |
| GUARD-03 | Phase 130 | Pending |

**Coverage:**
- Milestone requirements: 15 total
- Mapped to phases: 15 ✓
- Unmapped: 0

Each requirement maps to exactly one phase. Phase span for v1.36 is 126-130, continuing from
Phase 125 (milestone v1.32).

| Phase | Name | Requirements |
|-------|------|--------------|
| 126 | Adopter Path Walk & Defect Ledger | ADOPT-01, ADOPT-02, ADOPT-03, ADOPT-04 |
| 127 | Installer Against A Real Host | INSTALL-01, INSTALL-02, INSTALL-03 |
| 128 | Documented Wiring Truth | WIRE-01, WIRE-02, WIRE-03 |
| 129 | Reference Artifact Alignment | REF-01, REF-02 |
| 130 | Adopter Path Guardrail | GUARD-01, GUARD-02, GUARD-03 |

## Evidence Behind These Requirements

Repo-local findings gathered on 2026-07-28 that motivated each category. Recorded so a
later reader can tell whether a requirement was grounded or assumed.

- `scripts/publish/verify_install_truth.sh` generates a clean-room host with `--no-assets --no-ecto --no-html --no-mailer`, injects the dependency, runs `deps.get` and `compile`, then reports "Install Truth proven". It never runs the installer, migrates, boots, or completes a flow. → ADOPT-01, ADOPT-02, GUARD-02
- `test/integration/install_generator_test.exs:379` — `reset_fixture!` removes `config`, `lib`, and `test` from the fixture root and writes a bare `.keep`. The installer therefore runs into an empty directory, so generated content is asserted but host-interaction behavior is not. → INSTALL-01, INSTALL-02
- `lib/mix/tasks/lockspire.install.ex` contains no injection, patching, or replacement of host router, config, or application files. Wiring is entirely manual on the adopter's side. → WIRE-01, WIRE-02
- `docs/install-and-onboard.md` section 3, "Wire the generated files", is unexecuted by any test. → WIRE-01, WIRE-02
- `examples/adoption_demo` has zero references to `mix lockspire.install`. → REF-01, REF-02

---
*Requirements defined: 2026-07-28*
*Last updated: 2026-07-28 at v1.36 roadmap creation (phases 126-130)*
