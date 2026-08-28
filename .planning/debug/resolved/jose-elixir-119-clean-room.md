---
status: resolved
trigger: "Phase 133 clean-room provider child cannot compile pinned JOSE 1.11.12 under local Elixir 1.19.5"
created: 2026-08-27
updated: 2026-08-27
---

# Debug Session: JOSE Elixir 1.19 Clean Room

## Symptoms

### Expected behavior

A fresh package-clean Phoenix/Ecto child resolves the checked-in locked dependencies, runs `mix lockspire.install`, compiles, migrates, verifies, boots, and exposes live discovery.

### Actual behavior

The copied clean child reaches dependency compilation but JOSE 1.11.12 fails before the provider can compile or run the installer-to-listener proof. Root tests pass because the root dependency tree was previously compiled under a compatible environment.

### Error messages

The executor reports that Elixir `Record.extract` cannot find `jose_jwt.hrl` while compiling pinned `jose 1.11.12` under Elixir 1.19.5.

### Timeline

First exposed by Phase 133 Plan 02 on 2026-08-27 when the new clean-room harness forced a fresh dependency compile. The repository's existing compiled dependency tree did not expose it.

### Reproduction

Run the real clean provider builder/fresh-child path from `scripts/acceptance/clean_room/build_provider.py` so it prepares the vendored Lockspire package and compiles the child dependencies from the pinned `test/clean_room/provider_host/mix.lock`.

## Current Focus

hypothesis: Confirmed: JOSE 1.11.12 uses Record.extract(from_lib:) while Elixir 1.19 resolves the application through a partially-built Mix path that lacks JOSE's package headers.
test: Complete one fresh child run after the embedded-host startup fixture repair, then fold the install/compile/migrate/verify/discovery proof into the builder test.
expecting: The public installer and live discovery proof pass without accessing the checkout or unpinned dependency input.
next_action: none
reasoning_checkpoint:
tdd_checkpoint:

## Evidence

- timestamp: 2026-08-27; fresh `MIX_BUILD_PATH` compilation of JOSE 1.11.12 consistently failed because `Record.extract` sought `build/lib/jose/include/*.hrl`, while the immutable headers existed only in `deps/jose/include`.
- timestamp: 2026-08-27; a narrow replacement of JOSE's four locked `from_lib` calls with source-relative `from:` paths allowed a blank child to compile and run the public installer. The helper fails closed if the locked source shape changes.
- timestamp: 2026-08-27; the clean proof exposed and corrected package-asset fallback, pre-installer router bootstrap, template/overlay compile defects, and host application ordering. A fresh child completed installer, migration, warnings-as-errors compile, and `mix lockspire.verify`; live boot remains to be rerun after adding the child application's missing `mod:` entry.
- timestamp: 2026-08-27; an entirely fresh child completed public install, migration, warnings-as-errors compile, verification, Bandit boot, and a live mounted discovery request whose issuer exactly matched the configured origin.

## Eliminated

## Resolution

root_cause: JOSE 1.11.12 resolves Record.extract(from_lib:) through Elixir 1.19's partially-built Mix application path, where package headers are unavailable; the new clean proof also revealed unexercised package asset and host-bootstrap defects.
fix: A fail-closed child-local JOSE source compatibility adapter, runtime package-asset fallback, and a complete package-clean provider bootstrap/proof.
verification: `python3 scripts/acceptance/clean_room/build_provider.py --self-test`; focused package-clean integration test; independently repeated fresh child install, migration, warnings-as-errors compile, verification, boot, and discovery.
files_changed: scripts/acceptance/clean_room/build_provider.py; lib/lockspire/install/assets.ex; generator and migration asset lookup; provider fixture and generated HEEx template.
