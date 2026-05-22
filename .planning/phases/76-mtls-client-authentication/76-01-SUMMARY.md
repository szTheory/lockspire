# Phase 76 Plan 01: MTLS Client Domain and Schema Extension

**Objective:**
Update the Client domain model and Ecto schema to include the five RFC 8705 MTLS PKI attributes and extend the supported client authentication methods list.

**Changes made:**
- Extended `Lockspire.Domain.Client.token_endpoint_auth_method` type to include `:tls_client_auth` and `:self_signed_tls_client_auth`.
- Extended `Lockspire.Storage.Ecto.ClientRecord` to support the five MTLS properties (`tls_client_auth_subject_dn`, `tls_client_auth_san_dns`, `tls_client_auth_san_uri`, `tls_client_auth_san_ip`, `tls_client_auth_san_email`).
- Included the new attributes in `ClientRecord.changeset/2` casts and Ecto fields.
- Added migration to update the `lockspire_clients` database table.
- Added tests asserting correct behavior.

**Validation:**
- `mix test --stale` passes (787 tests, 0 failures).

**Commit:**
- `feat(76-01): extend Client domain and schema with MTLS attributes`
