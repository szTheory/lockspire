# Phase 27: HTTP Surface — Registration and Management Controllers - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-04-26
**Phase:** 27-HTTP Surface — Registration and Management Controllers
**Mode:** assumptions
**Areas analyzed:** Routing and Controller Topology, Token Extraction and Authentication Execution, HTTP Status Code Mapping, Response Payload Serialization

## Assumptions Presented

### Routing and Controller Topology
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| A single `Lockspire.Web.RegistrationController` will handle all four DCR endpoints (`POST`, `GET`, `PUT`, `DELETE` at `/register`), accompanied by a unified `RegistrationJSON` view. | Likely | `lib/lockspire/web/router.ex` |

### Token Extraction and Authentication Execution
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The `Authorization: Bearer <token>` properties will be manually parsed via `Plug.Conn.get_req_header/2` in the actions. For management routes, the controller will compute the RAT hash inline and look up the client before triggering the protocol logic. | Confident | `lib/lockspire/protocol/registration_management.ex` |

### HTTP Status Code Mapping
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The controller assumes the explicit duty of mapping domain `Registration.Error.code` atoms into valid RFC 7591/7592 HTTP statuses, attaching a `WWW-Authenticate` header and returning `401 Unauthorized` whenever hitting `:invalid_token`. | Confident | Phase 26 design |

### Response Payload Serialization
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The `RegistrationJSON` module will algorithmically reconstruct the flat RFC 7591 payload structure by spreading `%Lockspire.Domain.Client{}` properties and unnesting its internal `:metadata` extension bag back to strings. | Confident | `lib/lockspire/protocol/registration.ex` |

## Corrections Made

No corrections — all assumptions confirmed.
