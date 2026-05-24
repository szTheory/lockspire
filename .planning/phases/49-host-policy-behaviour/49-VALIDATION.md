# Phase 49: Host Policy Behaviour - Validation

## Success Criteria Mapping

| Truth | Verification Strategy | Test File |
|-------|-----------------------|-----------|
| Developers can configure a `Lockspire.Host.TokenExchangeValidator` behaviour module. | ExUnit test verifying behavior callbacks exist and can be configured | `test/lockspire/config_test.exs` |
| Token exchange requests are denied by default. | ExUnit test verifying default fallback returns access_denied | `test/lockspire/host/default_deny_token_exchange_validator_test.exs` |
| Token exchanges invoke the configured host validator. | ExUnit test mocking validator and ensuring it is called during token exchange | `test/lockspire/protocol/rfc8693_exchange_test.exs` |
| Token exchanges failing validation map to an OAuth `access_denied` error while logging the internal reason. | ExUnit test verifying the error struct returned on validation failure | `test/lockspire/protocol/rfc8693_exchange_test.exs` |
| Custom claims returned from the validator are securely merged into the token without overriding protocol keys. | ExUnit test injecting claims and verifying restricted keys are maintained | `test/lockspire/protocol/rfc8693_exchange_test.exs` |
| The server issues a signed JWT access token instead of an opaque token when custom claims are added. | ExUnit test parsing the returned token as a JWT and verifying its signature | `test/lockspire/protocol/rfc8693_exchange_test.exs` |

## Nyquist Compliance
All truths in the must-haves are mapped to automated ExUnit tests, fulfilling the automated verification requirement (Nyquist compliance).