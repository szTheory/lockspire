# Phase 44: API Stabilization & Typespecs - Context

## Goal
The public API contract must be finalized and strictly typed (STAB-01).

## Scope
1. **Typespecs**: Add complete and accurate `@spec` definitions to all public modules (e.g., `Lockspire`, `Lockspire.Admin`, `Lockspire.Clients`, `Lockspire.Config`).
2. **Configuration Options**: Review and finalize all options loaded by `Lockspire.Config`. Resolve any backwards-incompatible changes before the 1.0 GA release.
3. **Host Callbacks**: Lock the signatures for `Lockspire.Host.AccountResolver` and other integration seams.

## Current State Analysis
- **Missing Typespecs**: Modules such as `Lockspire.Admin` are missing `@spec` attributes. While its delegates (`Lockspire.Admin.Clients`, etc.) have specs, the top-level facade module should be strictly typed.
- **Dialyzer**: A baseline run of `mix dialyzer` yields 4 errors (1 in `dpop.ex` and 3 in `backchannel_logout_delivery_worker.ex`). These must be resolved to ensure the typespecs reflect reality.
- **Host Seams**: `Lockspire.Host.AccountResolver` callbacks heavily rely on `term()` for `conn_or_socket` and `map()` for `context`. To guarantee stability, these might need tighter explicit typing, such as a `%Lockspire.Host.Context{}` struct and `Plug.Conn.t() | Phoenix.LiveView.Socket.t()`.
- **Config**: `Lockspire.Config` exposes several options (`:repo`, `:account_resolver`, `:issuer`, `:mount_path`, `:logout_path`, `:oban`, `:security_profile`, etc.). These need to be validated as final.

## Next Steps
We need user input to resolve gray areas regarding the strictness of the callback types and the stability of the configuration keys.
