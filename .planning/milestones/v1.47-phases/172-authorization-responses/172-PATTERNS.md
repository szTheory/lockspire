# Phase 172: Authorization Responses - Pattern Map

**Mapped:** 2026-10-24
**Files analyzed:** 6 implementation/evidence owners
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/protocol/authorization_request.ex` | service/protocol validator | request-response | same file, `validate_response_mode/1` and strict mode validator | exact |
| `test/lockspire/web/authorize_controller_test.exs` | test | request-response | same file, `call_authorize/1` and first-party browser error tests | exact |
| `test/lockspire/protocol/authorization_request_test.exs` | test | request-response | same file, response-mode and strict-signing tests | exact |
| `test/lockspire/protocol/pushed_authorization_request_test.exs` | test | request-response | same file, PAR response validation tests | exact |
| `.planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json` | evidence/config manifest | transform | same ledger's `input_manifest_audits` | exact |
| `.planning/phases/172-authorization-responses/172-VERIFICATION.md` / phase summary | evidence document | transform | `.planning/phases/171-accepted-baseline-finding-qualification/171-04-SUMMARY.md` | role-match |

The only selected runtime correction is A171-003. The regression belongs in the existing controller test and runs through `Lockspire.Web.Router`. Treat roadmap-selector and frozen-manifest changes as narrowly audited evidence metadata. A171-001/002 and A171-004/005/006 remain owned by their existing tests; do not duplicate or alter those cases.

## Pattern Assignments

### `lib/lockspire/protocol/authorization_request.ex` (protocol validator, request-response)

**Analog:** same file, tracked source.

**Validation order** (`validate_with_client/3`, lines 389-408):

```elixir
with :ok <- maybe_validate_pushed_client_id(params, client, pushed?),
     :ok <- maybe_reject_inbound_request_uri(params, pushed?),
     {:ok, redirect_uri} <- validate_redirect_uri(client, params),
     {:ok, scopes} <- validate_scopes(client, params),
     {:ok, prompt} <- validate_prompt(params),
     {:ok, max_age} <- validate_max_age(params),
     :ok <- validate_response_type(params),
     {:ok, response_mode} <- validate_response_mode(params),
     :ok <-
       validate_strict_message_signing_response_mode(params, response_mode, security_profile),
     :ok <- validate_nonce(params, scopes),
     :ok <- validate_pkce(client, params, security_profile: security_profile),
     {:ok, auth_time_requested?} <- validate_claims_parameter(params),
     {:ok, resources} <- validate_resources(params),
     {:ok, authorization_details} <- validate_authorization_details(params, client, pushed?),
     :ok <- reject_unsupported_params(params) do
  ...
end
```

**Current unsupported-mode branch** (lines 582-593):

```elixir
defp validate_response_mode(%{"response_mode" => mode} = params) when is_binary(mode) do
  if MapSet.member?(@allowed_response_modes, mode) do
    {:ok, resolve_default_delivery_mode(mode, params["response_type"])}
  else
    {:redirect_error,
     redirect_error(
       params,
       :invalid_request,
       "response_mode is invalid or unsupported",
       :invalid_response_mode
     )}
  end
end

defp validate_response_mode(params) do
  {:ok, resolve_default_delivery_mode(nil, params["response_type"])}
end
```

The phase decision is to change only the disposition of the unsupported binary value to the existing browser error helper, retaining `:invalid_request`, description, and `:invalid_response_mode`. Preserve the supported allow-set, defaults (`nil` -> `query`, `jwt` -> `query.jwt`), and separate strict-signing branch (`:strict_message_signing_requires_jarm`, lines 604-623).

**Shared PAR normalization** (lines 133-157) maps both validation dispositions to `{:error, error}` from `validate_pushed/3`; keep it untouched so PAR remains a backchannel HTTP 400 OAuth JSON response.

### `lib/lockspire/web/controllers/authorize_controller.ex` (controller, request-response)

**Analog:** same tracked controller, lines 18-39 and 164-169.

**Disposition delivery pattern** (lines 34-39):

```elixir
{:browser_error, %Error{} = error} ->
  render_browser_error(conn, error, :bad_request)

{:redirect_error, %Error{} = error} ->
  redirect(conn, external: redirect_location(error))
```

**Browser rendering pattern** (lines 164-169):

```elixir
defp render_browser_error(conn, %Error{} = error, status) do
  conn
  |> put_status(status)
  |> put_resp_content_type("text/html")
  |> send_resp(status, AuthorizeHTML.error_page(error))
end
```

Keep this controller thin. The new classification should naturally route into this existing 400 path; do not add a controller reason-code exception, callback redirect, JSON/form response, or new renderer.

### `lib/lockspire/web/controllers/authorize_html.ex` (renderer, transform)

**Analog:** same tracked renderer, lines 8-24.

```elixir
def error_page(%Error{} = error) do
  description = Plug.HTML.html_escape_to_iodata(error.error_description)
  reason = Plug.HTML.html_escape_to_iodata(to_string(error.reason_code))

  [
    "<!doctype html><html><head><meta charset=\"utf-8\"><title>Authorization Error</title></head><body>",
    "<main><h1>Authorization request rejected</h1>",
    "<p>", description, "</p>",
    "<p>Reason: <code>", reason, "</code></p>",
    "</main></body></html>"
  ]
  |> IO.iodata_to_binary()
end
```

No renderer change is indicated. The existing escaped human-readable text is allowed, while OAuth response parameters must not be emitted in the browser error body.

### `test/lockspire/web/authorize_controller_test.exs` (test, request-response)

**Analog:** same tracked test file.

**Real router helper** (lines 674-679):

```elixir
defp call_authorize(params) do
  conn = build_conn(:get, "/authorize", params)
  Lockspire.Web.Router.call(conn, Lockspire.Web.Router.init([]))
end

defp redirected?(conn), do: Plug.Conn.get_resp_header(conn, "location") != []
```

**Fixture defaults** (lines 683-693):

```elixir
defp valid_params(client_id) do
  %{
    "client_id" => client_id,
    "response_type" => "code",
    "redirect_uri" => "https://client.example.com/callback",
    "scope" => "profile email",
    "state" => "state-123",
    "prompt" => "consent",
    "code_challenge" => String.duplicate("a", 43),
    "code_challenge_method" => "S256"
  }
end
```

For the new regression, explicitly override scope to `openid email` and provide a nonce; preserve the registered callback, authorization-code type, state, and S256 values. The helper's normal login resolver owns the query-mode control handoff. Assert the candidate is HTTP 400, has no `Location`, and contains no structured OAuth response parameters; do not assert the historical 302 as expected behavior. Existing first-party error assertions at lines 533-538 demonstrate checks for status, absence of redirect, and human-readable page content.

### `test/lockspire/protocol/authorization_request_test.exs` (test, request-response)

**Analog:** same tracked test file, lines 288-364.

```elixir
for params <- [
      valid_params(client.client_id),
      Map.put(valid_params(client.client_id), "response_mode", "query"),
      Map.put(valid_params(client.client_id), "response_mode", "fragment"),
      Map.put(valid_params(client.client_id), "response_mode", "form_post")
    ] do
  assert {:error, %Error{} = error} = AuthorizationRequest.validate_pushed(params, client)
  assert error.reason_code == :strict_message_signing_requires_jarm
end
```

Nearby tests establish accepted JWT modes and normalization. Preserve these owner tests and add a protocol assertion only if the controller regression/shared tests leave a material uncovered contract. In particular, do not conflate an unsupported mode with a supported raw mode rejected by strict signing.

### `test/lockspire/protocol/pushed_authorization_request_test.exs` (test, request-response)

**Analog:** same tracked PAR test suite. Research identifies the existing PAR controller/validation path as the owner for backchannel HTTP 400 OAuth JSON representation. Reuse its focused existing coverage; change neither delivery format nor the shared normalization in `validate_pushed/3`. Only add a targeted assertion if an uncovered consequence of changing the shared disposition is found.

### `.planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json` (evidence manifest, transform)

**Analog:** same tracked frozen qualification ledger and `test/lockspire/qualification_ledger_contract_test.exs`.

The ledger's `input_manifest_audits` records dated entries with `path`, `previous_sha256`, new `sha256`, and a reason (see ledger lines 1696 onward). For intentional edits to the controller regression file and Phase 172/173 roadmap selector, update only affected manifest identities and the ordered aggregate `input_digest`, with matching old/new/source/reason audit entries. Preserve case definitions, original source identities, receipt and probe bytes, frozen timestamp, and `qualification_sha`; do not blanket-refresh hashes. The ledger contract has a selector-specific hash path for `.planning/ROADMAP.md` (`test/lockspire/qualification_ledger_contract_test.exs:1296-1305`) and a whole-file hash path for ordinary inputs (`1307-1315`).

### Phase verification / summary evidence (evidence document, transform)

**Analog:** `.planning/phases/171-accepted-baseline-finding-qualification/171-04-SUMMARY.md` and `171-VERIFICATION.md`.

Record actual RED and GREEN commands, code revision, regression-file identity, and observed results. Keep Phase 171's probe as historical qualification evidence; do not describe it as a run at Phase 172 source. Include relevant focused controller, protocol mode, PAR, ledger-contract, formatter, and strict Credo outcomes only when actually executed.

## Shared Patterns

### Protocol disposition and browser response

**Sources:** `lib/lockspire/protocol/authorization_request.ex:582-623`; `lib/lockspire/web/controllers/authorize_controller.ex:34-39,164-169`.
**Apply to:** unsupported binary `response_mode` only.

Use the established browser error tuple to reach the existing HTTP 400 escaped HTML response. Preserve the protocol error name, description, and reason code. Supported modes and strict-signing errors remain on their existing paths.

### PAR backchannel normalization

**Source:** `lib/lockspire/protocol/authorization_request.ex:133-157`.
**Apply to:** existing PAR validation only.

Both browser and redirect classifications normalize to `{:error, error}` from `validate_pushed/3`; preserve the PAR endpoint's OAuth JSON HTTP 400 behavior.

### Source-bound qualification evidence

**Sources:** `.planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json`; `test/lockspire/qualification_ledger_contract_test.exs:1296-1315`.
**Apply to:** the regression-file and Phase 172 roadmap-selector ledger inputs.

Use selective audit records with previous and current hashes plus a concrete reason. Preserve immutable historical receipts and case observations.

## No Analog Found

None. The requested runtime and evidence changes have direct repository owners.

## Metadata

**Analog search scope:** `lib/lockspire/protocol`, `lib/lockspire/web/controllers`, `test/lockspire/web`, `test/lockspire/protocol`, qualification ledger tests and Phase 171 evidence.
**Files scanned:** 9 focused analog/source files.
**Pattern extraction date:** 2026-10-24
