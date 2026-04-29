

# Generate an RSA key for encryption
enc_jwk = JOSE.JWK.generate_key({:rsa, 2048})
# Generate an EC key for signing
sig_jwk = JOSE.JWK.generate_key({:ec, "P-256"})

# Payload
claims = %{"iss" => "client_1", "aud" => "https://server.example.com", "exp" => System.os_time(:second) + 3600}
jwk_sig_public = JOSE.JWK.to_public(sig_jwk)

# Sign
jws = JOSE.JWT.sign(sig_jwk, %{"alg" => "ES256"}, claims)
{_modules, jws_compact} = JOSE.JWS.compact(jws)

# Encrypt
jwe = JOSE.JWE.block_encrypt(enc_jwk, jws_compact, %{"alg" => "RSA-OAEP", "enc" => "A256GCM"})
{_modules, jwe_compact} = JOSE.JWE.compact(jwe)

IO.puts("JWE compact: #{jwe_compact}")

# Decrypt
decrypted = JOSE.JWK.block_decrypt(jwe_compact, enc_jwk)
IO.inspect(decrypted, label: "Decrypted")

case decrypted do
  {plain_text, jwe_struct} ->
    IO.puts("Decrypted text: #{plain_text}")
    # Verify the inner JWS
    verified = JOSE.JWT.verify_strict(jwk_sig_public, ["ES256"], plain_text)
    IO.inspect(verified, label: "Verified inner JWS")
end
