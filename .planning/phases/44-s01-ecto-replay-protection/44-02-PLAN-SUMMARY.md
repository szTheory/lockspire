# 44-02 Plan Summary

- Removed the unsupported restriction for `jwks_uri`.
- Updated DCR intake to strictly mandate one of `jwks` or `jwks_uri` when `token_endpoint_auth_method` is `private_key_jwt`.
- Enforced mutual exclusion between `jwks` and `jwks_uri` with exact errors.
