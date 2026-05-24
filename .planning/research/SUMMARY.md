# v1.23 Research Summary

## Milestone

`v1.23 DCR Logout Metadata`

## Stack Additions

- No new dependency is needed.
- Extend the existing RFC 7591 / RFC 7592 pipeline to support the four existing logout propagation metadata fields.

## Feature Table Stakes

- Register, read, and update:
  - `backchannel_logout_uri`
  - `backchannel_logout_session_required`
  - `frontchannel_logout_uri`
  - `frontchannel_logout_session_required`
- Validate those fields narrowly and return standard DCR errors on malformed input.

## Why This Milestone Fits

- The fields already exist in Lockspire's domain model and storage schema.
- The current gap is self-service management, not protocol runtime capability.
- This closes a real partner onboarding friction point without widening Lockspire beyond its existing logout truth model.

## Watch Out For

- Do not separate create from read/update support.
- Do not blur logout propagation metadata with `post_logout_redirect_uris`.
- Do not overstate front-channel reliability.
- Do not widen scope into federation or extra logout features.

## Recommended Scope

This milestone should stay core-only and narrow:

1. DCR validator and persistence support.
2. RFC 7592 read/update response truth.
3. Repo-native proof across positive and negative paths.
4. Support-surface and operator docs aligned to the shipped behavior.
