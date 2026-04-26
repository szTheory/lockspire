# Phase 27: HTTP Surface — Registration and Management Controllers - Context

**Gathered:** 2026-04-26 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement HTTP routes, controllers, JSON view layer, and error mapping for RFC 7591 intake (`POST /register`) and RFC 7592 management (`GET/PUT/DELETE /register/:client_id`).
</domain>

<decisions>
## Implementation Decisions

### Routing and Controller Topology
- **D-01:** A single `Lockspire.Web.RegistrationController` will handle all four DCR endpoints (`POST`, `GET`, `PUT`, `DELETE` at `/register`), accompanied by a unified `RegistrationJSON` view.

### Token Extraction and Authentication Execution
- **D-02:** The `Authorization: Bearer <token>` properties will be manually parsed via `Plug.Conn.get_req_header/2` in the actions. For management routes, the controller will compute the RAT hash inline and look up the client before triggering the protocol logic.

### HTTP Status Code Mapping
- **D-03:** The controller assumes the explicit duty of mapping domain `Registration.Error.code` atoms into valid RFC 7591/7592 HTTP statuses, attaching a `WWW-Authenticate` header and returning `401 Unauthorized` whenever hitting `:invalid_token`.

### Response Payload Serialization
- **D-04:** The `RegistrationJSON` module will algorithmically reconstruct the flat RFC 7591 payload structure by spreading `%Lockspire.Domain.Client{}` properties and unnesting its internal `:metadata` extension bag back to strings.

### Claude's Discretion
Any assumptions where the user confirmed "you decide" or left as-is with Likely confidence.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `lib/lockspire/web/router.ex`
- `lib/lockspire/web/controllers/pushed_authorization_request_controller.ex`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- PushedAuthorizationRequestController uses `Plug.Conn` to get headers, invokes `Protocol` module, and renders JSON via `PushedAuthorizationRequestJSON`.
- Lockspire.Web.Router routes `/par`, `/token`, `/revoke`, `/introspect`, `/authorize`, `/userinfo`, `/jwks`.

### Established Patterns
- Controllers are thin adapters that extract headers, invoke protocol modules, map status codes, and delegate serialization to JSON views.

### Integration Points
- `Lockspire.Protocol.Registration.register/1`
- `Lockspire.Protocol.RegistrationManagement.{read,update,delete}/2`
- `Lockspire.Web.Router`
</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches
</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within phase scope
</deferred>
