defmodule Mix.Tasks.Lockspire.Clients.Verifier.RewrapOperationContextTest do
  use ExUnit.Case, async: false

  @moduletag :operation_context

  @tag :operation_context_api
  test "bare config resolves signing and endpoint exclusions without starting Lockspire" do
    assert {:module, Lockspire.Security.ClientSecretVerifier.OperationContext} =
             Code.ensure_loaded(Lockspire.Security.ClientSecretVerifier.OperationContext)

    assert function_exported?(Lockspire.Security.ClientSecretVerifier.OperationContext, :resolve, 0)

    verifier_key = :crypto.hash(:sha256, "task-local-verifier-key")
    signing_key = :crypto.hash(:sha256, "task-local-signing-key")
    endpoint_secret = "endpoint secret sentinel"

    script = """
    verifier_key = Base.decode64!(#{inspect(Base.encode64(verifier_key))})
    signing_key = Base.decode64!(#{inspect(Base.encode64(signing_key))})
    endpoint_secret = #{inspect(endpoint_secret)}
    Application.put_env(:lockspire, Lockspire.Security.ClientSecretVerifier,
      keys: [{"verifier", Base.url_encode64(verifier_key, padding: false)}],
      current: "verifier", write_mode: :dedicated, legacy_read: :allow)
    Application.put_env(:lockspire, :key_encryption,
      keys: [{"signing", {:system, "LOCKSPIRE_TASK_SIGNING_KEY"}}], current: "signing")
    Application.put_env(:lockspire, Lockspire.Web.Endpoint, secret_key_base: endpoint_secret)
    before_context = :persistent_term.get(Lockspire.Config.client_secret_verifier_cache_key(), :missing)
    before_signing = :persistent_term.get(Lockspire.Config.key_encryption_cache_key(), :missing)
    result = Lockspire.Security.ClientSecretVerifier.OperationContext.resolve()
    after_context = :persistent_term.get(Lockspire.Config.client_secret_verifier_cache_key(), :missing)
    after_signing = :persistent_term.get(Lockspire.Config.key_encryption_cache_key(), :missing)
    case result do
      {:ok, context} ->
        IO.puts("RESOLVED=\#{context.state == :valid and signing_key in context.forbidden_key_bytes and endpoint_secret in context.forbidden_key_bytes}")
      _ -> IO.puts("RESOLVED=false")
    end
    IO.puts("UNCHANGED=\#{before_context == after_context and before_signing == after_signing}")
    IO.puts("SUPERVISOR=\#{is_pid(Process.whereis(Lockspire.Supervisor))}")
    """

    {output, status} = run_bare(script, "LOCKSPIRE_TASK_SIGNING_KEY", Base.encode64(signing_key))

    assert status == 0, output
    assert output =~ "RESOLVED=true"
    assert output =~ "UNCHANGED=true"
    assert output =~ "SUPERVISOR=false"
  end

  test "bare config rejects signing key reuse without exposing key bytes" do
    reused_key = :crypto.hash(:sha256, "purpose-reuse-sentinel")

    script = """
    key = Base.decode64!(#{inspect(Base.encode64(reused_key))})
    Application.put_env(:lockspire, Lockspire.Security.ClientSecretVerifier,
      keys: [{"verifier", Base.url_encode64(key, padding: false)}],
      current: "verifier", write_mode: :dedicated, legacy_read: :allow)
    Application.put_env(:lockspire, :key_encryption,
      keys: [{"signing", {:system, "LOCKSPIRE_TASK_SIGNING_KEY"}}], current: "signing")
    IO.inspect(Lockspire.Security.ClientSecretVerifier.OperationContext.resolve(), label: "RESULT")
    """

    {output, status} = run_bare(script, "LOCKSPIRE_TASK_SIGNING_KEY", Base.encode64(reused_key))

    assert status == 0, output
    assert output =~ "client_secret_verifier_configuration_invalid"
    refute output =~ Base.encode64(reused_key)
  end

  test "bare config fails closed when a signing system environment entry is invalid" do
    verifier_key = :crypto.hash(:sha256, "valid-verifier-key")
    signing_key = :crypto.hash(:sha256, "signing-invalid-env-sentinel")

    script = """
    verifier_key = Base.decode64!(#{inspect(Base.encode64(verifier_key))})
    Application.put_env(:lockspire, Lockspire.Security.ClientSecretVerifier,
      keys: [{"verifier", Base.url_encode64(verifier_key, padding: false)}],
      current: "verifier", write_mode: :dedicated, legacy_read: :allow)
    Application.put_env(:lockspire, :key_encryption,
      keys: [{"signing", {:system, "LOCKSPIRE_TASK_MISSING_SIGNING_KEY"}}], current: "signing")
    IO.inspect(Lockspire.Security.ClientSecretVerifier.OperationContext.resolve(), label: "RESULT")
    """

    {output, status} = run_bare(script, "LOCKSPIRE_TASK_UNUSED", Base.encode64(signing_key))

    assert status == 0, output
    assert output =~ "client_secret_verifier_configuration_invalid"
    refute output =~ Base.encode64(signing_key)
  end

  defp run_bare(script, variable, value) do
    System.cmd("mix", ["run", "--no-start", "-e", script],
      env: [{variable, value}, {"MIX_ENV", "test"}],
      stderr_to_stdout: true
    )
  end
end
