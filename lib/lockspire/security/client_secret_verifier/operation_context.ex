defmodule Lockspire.Security.ClientSecretVerifier.OperationContext do
  @moduledoc false

  alias Lockspire.Config
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context

  @safe_failure :client_secret_verifier_configuration_invalid

  @spec resolve() :: {:ok, Context.t()} | {:error, atom()}
  def resolve do
    with signing_keyset <- Config.key_encryption!(),
         forbidden <- Config.client_secret_verifier_operation_forbidden_key_bytes(signing_keyset),
         {:ok, config} <- Application.fetch_env(:lockspire, ClientSecretVerifier),
         {:ok, %Context{state: :valid, write_mode: :dedicated} = context} <-
           Context.resolve({:present, config}, forbidden) do
      {:ok, context}
    else
      _ -> {:error, @safe_failure}
    end
  rescue
    _ -> {:error, @safe_failure}
  catch
    _, _ -> {:error, @safe_failure}
  end
end
