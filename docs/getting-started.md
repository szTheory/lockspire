# Getting Started

Lockspire is for Phoenix teams that need to become an OAuth/OIDC provider inside an existing product.

Use it when:

- Your product already owns accounts and login UX.
- You need OAuth/OIDC for third-party clients.
- You want protocol correctness and operator workflows without standing up a separate auth service.

Do not use Lockspire as:

- A hosted identity platform
- A replacement for your account system
- A SAML, LDAP, or generic federation suite

## Install shape

1. Add the dependency.
2. Run `mix lockspire.install`.
3. Review and wire the generated host-owned files.
4. Run migrations.
5. Register a client and prove the flow with discovery, JWKS, and an authorization-code + PKCE exchange.

The generated files stay host-owned by design. Lockspire provides the protocol core; your app keeps ownership of login UX, branding, policy, and account data.
