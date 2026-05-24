# Phase 44: API Stabilization & Typespecs - Strategy & Recommendations

Based on the user's directive to prioritize developer ergonomics, idiomatic Elixir/Phoenix ecosystem standards, and strict API boundaries, the following strategy will be executed for Phase 44.

## 1. Host Seam Signatures (`Lockspire.Host.AccountResolver`)

### The Problem
Currently, the callbacks in `AccountResolver` use `term()` for the connection/socket and `map()` for the context. This forces host developers to guess what keys are available in the context (e.g., `%{client_id: ..., return_to: ...}`) and defeats Dialyzer's ability to catch type errors when passing the `conn` or `socket`.

### The Recommendation
**Strictly Type the Connection and Context using a Struct.**
- **Type the Transport**: Replace `conn_or_socket :: term()` with `conn_or_socket :: Plug.Conn.t() | Phoenix.LiveView.Socket.t() | term()`. (We include `term()` as a fallback for testing, but prioritize the explicit types for documentation and Dialyzer).
- **Introduce `%Lockspire.Host.Context{}`**: Replace `context :: map()` with a formal struct.
  ```elixir
  defmodule Lockspire.Host.Context do
    @moduledoc "Context passed from Lockspire to host resolution seams."
    defstruct [:return_to, :client_id, :scopes, :interaction_type]
    @type t :: %__MODULE__{
      return_to: String.t() | nil,
      client_id: String.t() | nil,
      scopes: [String.t()] | nil,
      interaction_type: :login | :consent | :logout | nil
    }
  end
  ```
- **Tradeoffs / DX**: This is a breaking change for existing host implementations that pattern-match on `map()`. However, the DX improvement is massive: developers get autocomplete, explicit documentation on what `context` contains, and Dialyzer safety. This matches the "principle of least surprise" seen in top-tier Elixir libraries like `Ash` or `Oban`.

## 2. Configuration Stability (`Lockspire.Config`)

### The Problem
Lockspire relies on a handful of `config :lockspire, ...` keys. For a 1.0 GA release, these must be finalized.

### The Recommendation
**Audit and Document Existing Keys, No Renames Required.**
- The current keys (`:repo`, `:account_resolver`, `:issuer`, `:mount_path`, `:logout_path`, `:oban`, `:security_profile`) are idiomatic and map 1:1 with their internal concepts.
- **Action**: Add strict `@spec` definitions to all accessor functions in `Lockspire.Config` and ensure `@moduledoc` and `@doc` clearly articulate the required types. This avoids footguns where users pass strings instead of atoms for modules.

## 3. Strict Typespec Coverage & Dialyzer Compliance

### The Problem
There are currently 4 Dialyzer errors in the project, and key public boundary modules (`Lockspire`, `Lockspire.Admin`, `Lockspire.Clients`) either lack `@spec` declarations entirely or have incomplete coverage.

### The Recommendation
**Zero-Warning Dialyzer and 100% Public Spec Coverage.**
- **Dialyzer Fixes**: Address the pattern match errors in `dpop.ex` and `backchannel_logout_delivery_worker.ex`. These are likely dead-code branches or incorrect type assumptions that will fail at runtime if not corrected.
- **Public Facades**: Add `@spec` to every function in `Lockspire` and `Lockspire.Admin`. For `defdelegate` functions, the `@spec` should be explicitly redefined on the facade module so that documentation tools (`ExDoc`) and language servers (ElixirLS) present the signatures correctly to the consumer without forcing them to jump to internal modules.

---

## Conclusion
This strategy represents the "perfect set of recommendations" to achieve a 1.0-ready API contract. It maximizes developer ergonomics, embraces Elixir's type system via structs and explicit union types, and eliminates ambiguity in the host integration seams.
