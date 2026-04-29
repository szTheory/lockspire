# Roadmap

## Phases

- [ ] **Phase 40: JWE Support for Request Objects** - Add encryption key management and nested JWT validation

## Phase Details

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
| 40. JWE Support for Request Objects | 0/0 | Executing | - |
