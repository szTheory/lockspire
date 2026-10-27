# Phase 178 — Fourth Security Re-review

Reviewer: gsd-security-auditor; configured gpt-6.1-sol/xhigh; `/root/phase178_execution_workflow/review178_security`
Reviewed commit: 7ba6b5b0979d115db2455f8e74963f6b600b82dc
Date: 2026-10-27
Scope: Scoped SEC-178-05 correction review. Earlier reports and the other 35 implementation mitigation dispositions remain unchanged.
Disposition: rejected
Active blocking findings: 1

## OPEN_THREATS

**ASVS Level:** 1
**block_on:** high
**Declared threats:** 37
**Implementation mitigations closed:** 35/37
**Blocking open threats:** T-178-21, T-178-25
**Non-blocking open threats:** 0
**threats_open:** 2

## Findings

### SEC-178-05 — HIGH — Version grammars still admit private strings without independent ownership

The three fixed invocation descriptions are corrected. Independent probes confirmed rejection of all twelve opaque/base64/hex/percent substitutions across those fields.

The broader finding remains.

**Locations:**

- `scripts/acceptance/clean_room/verifier_receipts.py:383–386`: package and runtime version grammars.
- `scripts/acceptance/clean_room/verifier_receipts.py:1004–1005`: beam path derives from the receipt’s own candidate version.
- `scripts/acceptance/clean_room/verifier_delivery.py:1143–1174`: uploaded archive ownership verification.
- `scripts/acceptance/clean_room/verifier_delivery.py:1279–1284`: raw receipt ownership comparison.
- `scripts/acceptance/clean_room/package_input.py:736–743`: producer-side package version verification.

**Independent observations:** Four memory-only substitutions were accepted:

1. Release RPC `candidate.version` containing a generated private suffix, with its beam path changed consistently.
2. Rollout `candidate.version` containing a generated private suffix.
3. Release RPC `runtime.elixir` containing a generated private suffix.
4. Rollout `runtime.elixir` containing a generated private suffix.

These values conformed to the new bounded grammars. No generated value was printed or persisted.

**Authority boundary:** `verify_candidate_input()` checks the producer’s `PackageIdentity.version` against the actual extracted package. That does not authenticate the subsequently supplied receipt version.

The downloaded archive consumer authenticates archive/tree/files and owner proof. Its raw receipt comparison checks source/archive/tree/proof, runner, host lock and compiled identity, but excludes candidate version and runtime. Consequently, an authentic package archive does not reject these altered receipt fields. Deriving a beam path from the same altered version establishes consistency between two claims, not ownership by the package.

**Impact:** Grammar-conforming private strings can survive receipt validation before verbatim copying/upload. The new string-leaf tests replace whole values with opaque encodings; they miss private material embedded inside an otherwise accepted version grammar.

**Remediation:** Bind receipt candidate version to the version read from the authenticated package/source owner, including release RPC’s module path. Validate runtime fields against independently obtained, safely normalized runtime observations and applicable expected runtime identities. Avoid accepting arbitrary suffix text merely because it resembles a version.

Extend the finite string tests with grammar-preserving substitutions and coordinated related-field mutations. Exercise them through the actual package-owner/receipt/upload consumer boundary. Keep generated material in memory and diagnostics fixed-message only.

**Disposition:** Open; fix before freeze.

## Evidence

Independently executed at the reviewed commit:

- Receipt suite, endpoint suite and actual source-to-handoff chain: **29 tests, zero failures, errors, skips, expected failures or unexpected successes**.
- Original invocation-field probe: **12 substitutions, zero accepted**.
- Grammar-conforming version/runtime probe: **4 substitutions, all accepted**.
- All thirteen immutable Phase 175 inputs matched.
- Scoped diff whitespace check passed.

The passing chain confirms that ordinary producer output remains consumable. It does not negate the four accepted substitutions.

The selected tracked scope contains **1,069 files**. Canonical sorted rows of `{"path": ..., "sha256": ...}`, serialized with `sort_keys=True` and `separators=(',', ':')`, contain **147,720 bytes** with SHA-256:

```text
7f2900df7a1b1797514ba89196a39ee6a1214a7b1037abfe6b7b3035cb7f5069
```

Working bytes matched those committed bindings. This scope digest is not an accepting review judgment.

## Disposition and limits

The literal-command, release-node, exact module-name and endpoint-audience corrections are present. SEC-178-05 remains active because candidate/runtime version authority is incomplete.

T-178-21 remains blocking for the private-value channel before durable output. T-178-25 remains blocking because receipt safety validation admits that channel. The other 35 mitigation dispositions from the third review are retained at implementation scope.

The actual affected test process, PID/PGID **79154**, completed. Its owned fixture subprocesses and temporary roots completed cleanup. No unresolved auditor process or custody remains. All child diagnostics and generated mutation values remained in memory.

No database, freeze, canonical source CI, genuine package producer, hosted observation, remote mutation or accepted-main execution occurred. The earlier full 227-test result belongs to its recorded source revision and was not restamped onto this commit. Linux process-authority execution remains unobserved here.

The narrow native pre-edit string RED record and subsequent counterfactual are retained. They do not erase the original delivery RED gap, historical secret/database incidents, custody history, diagnostic-handling deviations or unresolved Phase 177 E09/E10.

Freeze remains blocked. No accepting lane judgment, runtime approval, human waiver or phase-completion claim is supplied.
