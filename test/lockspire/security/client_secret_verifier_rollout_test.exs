defmodule Lockspire.Security.ClientSecretVerifierRolloutTest do
  use ExUnit.Case, async: true

  alias Lockspire.Clients.SecretMaterial
  alias Lockspire.Config
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Security.Policy

  @legacy_key "rollout-test-endpoint-secret-key-base"

  test "absent and staged configurations keep legacy writes readable by old code" do
    client_id = "rollout-legacy-client"

    for staged_config <- [
          nil,
          [keys: key_entries(), write_mode: :legacy, legacy_read: :allow],
          [keys: key_entries(), current: nil, write_mode: :legacy, legacy_read: :allow],
          [keys: key_entries(), current: "next", write_mode: :legacy, legacy_read: :allow]
        ] do
      context_override =
        case staged_config do
          nil -> %Context{state: :absent}
          config -> resolve(config)
        end

      material = generate(client_id, context_override)

      assert legacy_reader_matches?(client_id, material)

      assert ClientSecretVerifier.open(
               context_override,
               client_id,
               material.client_secret_jwt_verifier_encrypted,
               legacy_secret_key_base: @legacy_key
             )
             |> matches_material?(material)
    end
  end

  test "reader-first activation reads retained keys and applies explicit legacy policy" do
    client_id = "rollout-dedicated-client"
    old_key = random_key()
    current_key = random_key()

    legacy_context =
      resolve(config([{"old", old_key}, {"current", current_key}], "current", :legacy, :allow))

    legacy_material = generate(client_id, legacy_context)
    assert legacy_reader_matches?(client_id, legacy_material)

    dedicated_context =
      resolve(config([{"old", old_key}, {"current", current_key}], "current", :dedicated, :allow))

    dedicated_material = generate(client_id, dedicated_context)
    refute legacy_reader_matches?(client_id, dedicated_material)
    assert compatible_reader_matches?(dedicated_context, client_id, dedicated_material)
    assert compatible_reader_matches?(dedicated_context, client_id, legacy_material)

    reject_legacy_context =
      resolve(
        config([{"old", old_key}, {"current", current_key}], "current", :dedicated, :reject)
      )

    reject_material = generate(client_id, reject_legacy_context)
    assert compatible_reader_matches?(reject_legacy_context, client_id, reject_material)
    refute compatible_reader_matches?(reject_legacy_context, client_id, legacy_material)

    old_writer_context =
      resolve(config([{"old", old_key}], "old", :dedicated, :allow))

    old_key_material = generate(client_id, old_writer_context)

    rotated_reader_context =
      resolve(config([{"old", old_key}, {"current", current_key}], "current", :dedicated, :allow))

    assert compatible_reader_matches?(rotated_reader_context, client_id, old_key_material)

    current_only_context =
      resolve(config([{"current", current_key}], "current", :dedicated, :allow))

    refute compatible_reader_matches?(current_only_context, client_id, old_key_material)

    assert ClientSecretVerifier.open(
             current_only_context,
             client_id,
             old_key_material.client_secret_jwt_verifier_encrypted,
             legacy_secret_key_base: @legacy_key
           ) == {:error, :client_secret_verifier_key_unknown}
  end

  test "switching writes back to legacy does not make dedicated rows readable by old code" do
    client_id = "rollout-switchback-client"
    key = random_key()

    dedicated_context = resolve(config([{"current", key}], "current", :dedicated, :allow))
    dedicated_material = generate(client_id, dedicated_context)

    legacy_write_context = resolve(config([{"current", key}], "current", :legacy, :allow))
    legacy_material = generate(client_id, legacy_write_context)

    assert legacy_reader_matches?(client_id, legacy_material)
    refute legacy_reader_matches?(client_id, dedicated_material)
    assert compatible_reader_matches?(legacy_write_context, client_id, dedicated_material)
  end

  defp config(keys, current, write_mode, legacy_read) do
    [
      keys: Enum.map(keys, fn {id, key} -> {id, Base.url_encode64(key, padding: false)} end),
      current: current,
      write_mode: write_mode,
      legacy_read: legacy_read
    ]
  end

  defp key_entries do
    [
      {"staged", Base.url_encode64(random_key(), padding: false)},
      {"next", Base.url_encode64(random_key(), padding: false)}
    ]
  end

  defp random_key, do: :crypto.strong_rand_bytes(32)

  defp resolve(config) do
    {:ok, context} =
      Context.resolve({:present, config}, Config.client_secret_verifier_forbidden_key_bytes())

    context
  end

  defp generate(client_id, context) do
    {:ok, material} =
      SecretMaterial.generate(client_id,
        client_secret_verifier_context: context,
        secret_key_base: @legacy_key
      )

    material
  end

  defp legacy_reader_matches?(_client_id, material) do
    case Policy.unseal_client_secret_jwt_verifier(
           material.client_secret_jwt_verifier_encrypted,
           @legacy_key
         ) do
      {:ok, secret} -> secret == material.client_secret
      {:error, :invalid_client_secret_jwt_verifier} -> false
    end
  end

  defp compatible_reader_matches?(context, client_id, material) do
    ClientSecretVerifier.open(context, client_id, material.client_secret_jwt_verifier_encrypted,
      legacy_secret_key_base: @legacy_key
    )
    |> matches_material?(material)
  end

  defp matches_material?({:ok, secret}, material), do: secret == material.client_secret
  defp matches_material?({:error, _reason}, _material), do: false
end
