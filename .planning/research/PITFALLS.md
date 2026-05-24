# v1.23 Research: Pitfalls

## Pitfall 1: Shipping partial support

If `POST /register` accepts the new fields but RFC 7592 read/update responses omit them, self-service clients will see inconsistent state.

Prevention:

- treat create, read, and update as one requirement family
- add full lifecycle integration coverage

## Pitfall 2: Blurring redirect-vs-propagation semantics

`post_logout_redirect_uris` and logout propagation URIs are already separate concepts in Lockspire. Mixing them would create operator and partner confusion.

Prevention:

- keep requirement language explicit
- keep docs and response examples separate

## Pitfall 3: Over-claiming front-channel reliability

Front-channel logout specs permit registration metadata, but Lockspire's shipped truth is still best-effort browser choreography.

Prevention:

- keep `docs/supported-surface.md` explicit
- avoid wording that implies remote success verification

## Pitfall 4: Under-validating RP logout URIs

The OpenID specs require absolute URIs, forbid fragments for back-channel logout URIs, and define session-required flags with boolean defaults.

Prevention:

- validate URI shape explicitly
- reject invalid booleans or malformed strings
- preserve optional-field semantics without inventing silent coercions

## Pitfall 5: Breaking admin provenance truth

Operators already manage logout propagation in admin. DCR support must not erase the distinction between operator-edited and self-service-managed clients.

Prevention:

- preserve provenance and audit behavior
- keep admin docs explicit that both surfaces can exist without changing runtime semantics
