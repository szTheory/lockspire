# v1.24 Research: Pitfalls

## Pitfall 1: Treating all JWT assertions as `private_key_jwt`

The current shared auth parser resolves any JWT client assertion into the asymmetric verifier path. If `client_secret_jwt` is added without changing that split, runtime truth and registration truth will diverge immediately.

Prevention:

- make method resolution explicit before verification
- add tests that prove both auth methods route to their intended verifier

## Pitfall 2: Weakening secret-handling posture

`client_secret_jwt` is easy to implement incorrectly by introducing recoverable secret storage, ad hoc secret copies, or verbose audit logging of assertion contents.

Prevention:

- verify signatures from the existing client secret input only
- preserve hashed-at-rest storage posture
- redact assertions and raw secret-derived material from logs and operator surfaces

## Pitfall 3: Over-claiming FAPI or high-trust equivalence

Lockspire already ships `private_key_jwt` and mTLS for higher-trust deployments. Advertising `client_secret_jwt` as equivalent would create support-truth drift.

Prevention:

- keep `docs/supported-surface.md` explicit about the narrower posture
- ensure discovery/admin wording does not imply stronger-trust parity

## Pitfall 4: Audience and replay drift

The standards history around JWT client-auth audiences has enough ambiguity that permissive matching becomes a long-term interop and security drag. Replay rules can also drift if some endpoints record `jti` and others do not.

Prevention:

- keep the issuer-string `aud` rule explicit and tested
- reuse the same used-`jti` recording path across all shipped direct-client surfaces

## Pitfall 5: Publishing incomplete metadata truth

If DCR or discovery accepts `client_secret_jwt` without exposing the corresponding signing-alg requirements, clients will guess and support burden will rise.

Prevention:

- publish method and algorithm metadata together
- add release-contract and discovery tests that pin the supported values
