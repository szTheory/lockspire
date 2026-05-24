# Phase 71: JARM Core - Validation Architecture

## Test Framework
- Framework: ExUnit
- Config file: mix.exs / test_helper.exs
- Quick run command: mix test
- Full suite command: mix test

## Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| JARM-01 | Default `jwt` correctly based on `response_type` | unit | `mix test test/lockspire/protocol/authorization_request_test.exs` | ✅ Wave 1 |
| JARM-01 | Encapsulate params in JWS and format output | unit | `mix test test/lockspire/protocol/jarm_test.exs` | ❌ Wave 1 |
| JARM-01 | Inject `?response=...` in redirect | integration | `mix test test/lockspire/web/controllers/authorize_controller_test.exs` | ✅ Wave 1 |
| JARM-01 | Support form_post.jwt auto-submit | integration | `mix test test/lockspire/web/controllers/authorize_controller_test.exs` | ✅ Wave 1 |
| JARM-02 | Advertise `authorization_signing_alg_values_supported` | unit | `mix test test/lockspire/protocol/discovery_test.exs` | ✅ Wave 1 |

## Missing Coverage
- test/lockspire/protocol/jarm_test.exs
