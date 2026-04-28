# Roadmap

## Phases

- [ ] **Phase 37: Protocol Strictness & Conformance** - Enforce strict OIDC validation and automated conformance testing
- [ ] **Phase 38: Session Tracking & RP-Initiated Logout** - Track user sessions and support relying-party initiated logout
- [ ] **Phase 39: Automated RP Logout Propagation** - Implement Back-Channel and Front-Channel logout mechanisms
- [ ] **Phase 40: JWE Support for Request Objects** - Add encryption key management and nested JWT validation

## Phase Details

### Phase 37: Protocol Strictness & Conformance
**Goal**: The authorization server strictly validates OIDC parameters and passes automated conformance tests
**Depends on**: Nothing
**Requirements**: CONF-01, CONF-02, CONF-03, CONF-04
**Success Criteria** (what must be TRUE):
  1. Token endpoints reject requests with string timestamps where integers are expected.
  2. Authorization endpoint rejects requests where `redirect_uri` does not exactly match the registered client URI.
  3. Requests with invalid `prompt=none`, `max_age`, or `nonce` are rejected with appropriate OIDC errors.
  4. An automated test pipeline successfully runs against the OIDF Conformance Test Suite without failures.
**Plans**: TBD

### Phase 38: Session Tracking & RP-Initiated Logout
**Goal**: The authorization server tracks interactions and supports standard RP-initiated logout workflows
**Depends on**: Phase 37
**Requirements**: SLO-01, SLO-02
**Success Criteria** (what must be TRUE):
  1. Operators can see a session ID (`sid`) associated with user interactions and issued tokens.
  2. Relying parties can redirect to `/end_session` to initiate logout.
  3. Host apps receive the logout intent and clear the user's web session securely.
  4. Users are correctly redirected to the `post_logout_redirect_uri` after logout.
**Plans**: TBD
**UI hint**: yes

### Phase 39: Automated RP Logout Propagation
**Goal**: The authorization server actively propagates logout events to connected relying parties
**Depends on**: Phase 38
**Requirements**: SLO-03, SLO-04
**Success Criteria** (what must be TRUE):
  1. Relying parties registered for Back-Channel Logout receive an automated server-to-server POST when the user's session ends.
  2. Relying parties registered for Front-Channel Logout are rendered in invisible iframes during the host's logout return.
  3. The server tracks and logs the successful dispatch of logout webhooks.
**Plans**: TBD
**UI hint**: yes

### Phase 40: JWE Support for Request Objects
**Goal**: The authorization server supports nested encrypted JWTs for request objects
**Depends on**: Phase 39
**Requirements**: AUTHZ-01, AUTHZ-02
**Success Criteria** (what must be TRUE):
  1. Operators can manage and advertise `enc` keys in the server's JWKS.
  2. Clients can submit JAR request objects that are encrypted (JWE) and then signed (JWS).
  3. The server successfully decrypts and validates nested JWE/JWS request objects.
**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 37. Protocol Strictness & Conformance | 0/0 | Not started | - |
| 38. Session Tracking & RP-Initiated Logout | 0/0 | Not started | - |
| 39. Automated RP Logout Propagation | 0/0 | Not started | - |
| 40. JWE Support for Request Objects | 0/0 | Not started | - |
