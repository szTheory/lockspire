# Phase 40: JWE Support for Request Objects - Pattern Map

**Mapped:** 2024-05-18
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/domain/signing_key.ex` | model | CRUD | `lib/lockspire/domain/signing_key.ex` | exact |
| `lib/lockspire/storage/key_store.ex` | store | CRUD | `lib/lockspire/storage/key_store.ex` | exact |
| `lib/lockspire/protocol/jwks.ex` | protocol | transform | `lib/lockspire/protocol/jwks.ex` | exact |
| `lib/lockspire/protocol/jar.ex` | protocol | transform | `lib/lockspire/protocol/jar.ex` | exact |
| `lib/lockspire/admin/keys.ex` | service | CRUD | `lib/lockspire/admin/keys.ex` | exact |

## Pattern Assignments

### `lib/lockspire/domain/signing_key.ex` (model, CRUD)

**Analog:** `lib/lockspire/domain/signing_key.ex`

**Key Use Type Pattern** (lines 7-8):
```elixir
  @type key_type :: :RSA | :EC | :OKP
  @type use_type :: :sig
```
*(Note: Planners should modify `use_type` to allow `:enc`, and ensure renaming/generalizing of `SigningKey` logic to `EncryptionKey` or `Key` where applicable.)*

### `lib/lockspire/storage/key_store.ex` (store, CRUD)

**Analog:** `lib/lockspire/storage/key_store.ex`

**Callback Pattern** (lines 10-14):
```elixir
  @callback publish_key(SigningKey.t()) :: {:ok, SigningKey.t()} | {:error, store_error()}
  @callback list_active_keys() :: {:ok, [SigningKey.t()]} | {:error, store_error()}
  @callback list_signing_keys(keyword()) :: {:ok, [SigningKey.t()]} | {:error, store_error()}
  @callback list_publishable_keys() :: {:ok, [SigningKey.t()]} | {:error, store_error()}
```
*(Note: We will need new callbacks for encryption keys or updated args, such as `list_publishable_keys(use: :enc)`)*

### `lib/lockspire/protocol/jwks.ex` (protocol, transform)

**Analog:** `lib/lockspire/protocol/jwks.ex`

**JWK mapping pattern** (lines 20-27):
```elixir
  defp to_public_jwk(%SigningKey{} = key) do
    key.public_jwk
    |> Map.take(@public_jwk_members)
    |> Map.put_new("kid", key.kid)
    |> Map.put_new("kty", Atom.to_string(key.kty))
    |> Map.put_new("alg", key.alg)
    |> Map.put_new("use", Atom.to_string(key.use))
  end
```
*(Note: Because `key.use` is mapped directly to the `use` claim, `enc` will correctly populate if we expose encryption keys.)*

### `lib/lockspire/protocol/jar.ex` (protocol, transform)

**Analog:** `lib/lockspire/protocol/jar.ex`

**JWT Decoding Pattern** (lines 34-41):
```elixir
      # JOSE.JWT.peek_payload and peek_protected raise ArgumentError if malformed
      payload_struct = JOSE.JWT.peek_payload(jwt)
      protected_struct = JOSE.JWT.peek_protected(jwt)

      # to_map returns {modules_map, fields_map}
      {_modules, claims} = JOSE.JWT.to_map(payload_struct)
      {_modules, header} = JOSE.JWS.to_map(protected_struct)
```
*(Note: JWE support will require conditional branching to `JOSE.JWE.block_decrypt` if `header` contains an `enc` claim, prior to payload evaluation.)*

**Strict Verification Pattern** (lines 122-127):
```elixir
      case JOSE.JWT.verify_strict(public_jwk, @allowed_algorithms, jwt) do
        {true, %JOSE.JWT{} = jwt_struct, %JOSE.JWS{} = jws_struct} ->
          {_modules, claims} = JOSE.JWT.to_map(jwt_struct)
          {_modules, header} = JOSE.JWS.to_map(jws_struct)
```

### `lib/lockspire/admin/keys.ex` (service, CRUD)

**Analog:** `lib/lockspire/admin/keys.ex`

**Listing & View Pattern** (lines 18-23):
```elixir
  @spec list_keys(keyword()) :: {:ok, [key_view()]} | {:error, term()}
  def list_keys(opts \\ []) when is_list(opts) do
    with {:ok, keys} <- Repository.list_signing_keys(opts) do
      {:ok, keys |> Enum.map(&to_view/1) |> Enum.sort_by(&sort_key/1)}
    end
  end
```
*(Note: Admin UI patterns use a key view structure. Planners will need to adjust `list_keys` / `list_signing_keys` to also manage `enc` lifecycle states.)*

## Shared Patterns

### Error Handling
**Source:** `lib/lockspire/protocol/jar.ex`
**Apply to:** JWE processing in `lib/lockspire/protocol/jar.ex`
```elixir
  @type validate_claims_reason ::
          :invalid_claims_options
          | :missing_issuer
          # ...
```
*(Note: Expected to be expanded with `:decryption_failed` or `:invalid_encryption`)*

## No Analog Found

None.

## Metadata

**Analog search scope:** `**/storage/key_store.ex`, `**/protocol/jwks.ex`, `**/protocol/jar.ex`, `**/admin/keys.ex`, `**/domain/signing_key.ex`
**Files scanned:** 5
**Pattern extraction date:** 2024-05-18
