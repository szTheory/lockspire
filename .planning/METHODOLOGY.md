# Methodology

## Assumption-First Recommendation Mode

**Diagnoses:** Excessive user questioning on issues that can be resolved through codebase reading,
spec research, ecosystem comparison, or coherent engineering judgment.

**Recommends:** Default to codebase-first analysis, standards research, and decisive
recommendations. Bring the user a coherent default set, not a menu of low-signal questions. Ask
only when a decision is genuinely product-shaping, materially irreversible, or lacks enough
evidence for a responsible default.

**Apply when:** Discuss, plan, or review work where most ambiguity is technical, architectural, or
ecosystem-shaped rather than brand/product-preference shaped.

## Least-Surprise Host Seam

**Diagnoses:** Designs that push hidden protocol responsibilities onto the host app or infer
security-sensitive behavior from ambient framework state.

**Recommends:** Prefer explicit narrow seams for host-owned responsibilities and keep protocol truth
inside Lockspire. If a behavior affects interoperability, conformance, or security claims, model it
as durable protocol state rather than as implicit Phoenix session behavior.

**Apply when:** OAuth/OIDC correctness depends on authentication freshness, silent auth, logout,
claims emission, durable policy, or any behavior that downstream clients will treat as protocol
truth.

## Research-First Decisive Defaults

**Diagnoses:** Discussion and planning loops that surface too many medium-value choices to the user
before doing enough codebase, standards, and ecosystem research to earn a coherent recommendation.

**Recommends:** For discuss, plan, and review work, push research left: read the repo first,
compare ecosystem precedents second, then present a cohesive recommendation set with clear tradeoffs.
Ask the user only about decisions that are materially product-shaping, hard to reverse, or likely to
reflect taste/strategy rather than engineering judgment. Prefer one-shot recommendation bundles over
piecemeal option menus.

**Apply when:** A phase has multiple connected design decisions whose value comes from internal
coherence, developer ergonomics, protocol truthfulness, operator clarity, or least-surprise
architecture.

## High-Threshold Escalation

**Diagnoses:** Users get dragged into avoidable decision-making on medium-impact implementation
 details that the agent could resolve coherently with stronger codebase, standards, and ecosystem
 synthesis.

**Recommends:** Default to resolving medium-value design and implementation choices inside the
 workflow. Escalate only for changes that materially affect product boundary, public API shape,
 security posture, support/release claims, or hard-to-reverse strategic direction. When escalation
 is necessary, bring one coherent recommendation bundle first instead of an unfiltered menu.

**Apply when:** Adoption-hardening, install DX, documentation truth, generated-host seams, and
 other multi-decision phases where internal coherence and least surprise matter more than user
 taste on each individual choice.

## One-Shot Recommendation Bundles

**Diagnoses:** GSD workflows surface too many medium-value options independently, forcing the user
to assemble the final answer themselves even when the repo, codebase, and ecosystem evidence already
support one coherent direction.

**Recommends:** For already-shipped surfaces and support-truth work, default to producing a single
cohesive recommendation bundle that:
- compares the realistic approaches internally;
- accounts for repo prompts, prior planning artifacts, and ecosystem precedent;
- chooses the least-surprise option aligned with Lockspire's embedded-library boundary, operator UX,
  and developer ergonomics;
- escalates only when a decision changes product boundary, public support claims, operator
  responsibility, security posture, API shape, or runtime guarantees.

**Apply when:** Discuss, plan, and review phases touching docs-as-contract, advanced setup truth,
operator/admin wording, install DX, diagnostics, or other areas where cohesion matters more than
giving the user a menu of medium-value choices.
