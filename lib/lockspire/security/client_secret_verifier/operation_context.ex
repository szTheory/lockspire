defmodule Lockspire.Security.ClientSecretVerifier.OperationContext do
  @moduledoc false

  alias Lockspire.Config
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context

  @safe_failure :client_secret_verifier_configuration_invalid

  @doc false
  @spec resolve_for_secret_generation(keyword()) :: {:ok, Context.t()} | {:error, atom()}
  def resolve_for_secret_generation(opts) when is_list(opts) do
    missing = make_ref()

    case :persistent_term.get(Config.client_secret_verifier_cache_key(), missing) do
      %Context{} ->
        opts
        |> Config.client_secret_verifier_context()
        |> validate_generation_context(opts)

      ^missing ->
        if Keyword.has_key?(opts, :client_secret_verifier_context) do
          {:error, @safe_failure}
        else
          resolve_generation_context(opts)
        end

      _unavailable ->
        {:error, @safe_failure}
    end
  rescue
    _ -> {:error, @safe_failure}
  catch
    _, _ -> {:error, @safe_failure}
  end

  def resolve_for_secret_generation(_opts), do: {:error, @safe_failure}

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

  defp resolve_generation_context(opts) do
    alias Lockspire.Security.ClientSecretVerifier

    with signing_keyset <- Config.key_encryption!(),
         forbidden <-
           Config.client_secret_verifier_operation_forbidden_key_bytes(signing_keyset)
           |> add_operation_key_bytes(opts),
         presence <- verifier_presence(ClientSecretVerifier),
         {:ok, %Context{state: state} = context} <- Context.resolve(presence, forbidden),
         true <- state in [:absent, :valid] do
      {:ok, context}
    else
      _ -> {:error, @safe_failure}
    end
  rescue
    _ -> {:error, @safe_failure}
  catch
    _, _ -> {:error, @safe_failure}
  end

  defp verifier_presence(verifier_module) do
    case Application.fetch_env(:lockspire, verifier_module) do
      {:ok, config} -> {:present, config}
      :error -> :absent
    end
  end

  defp validate_generation_context(%Context{} = context, opts) do
    forbidden = add_operation_key_bytes(context.forbidden_key_bytes, opts)

    case Context.validate(context, forbidden) do
      {:ok, context} ->
        {:ok, %{context | forbidden_key_bytes: forbidden}}

      {:error, _reason} ->
        {:error, @safe_failure}
    end
  end

  defp validate_generation_context(_context, _opts), do: {:error, @safe_failure}

  defp add_operation_key_bytes(forbidden, opts) do
    option_keys =
      [:secret_key_base, :legacy_secret_key_base]
      |> Enum.flat_map(&Keyword.get_values(opts, &1))
      |> Enum.filter(&(is_binary(&1) and &1 != ""))

    (forbidden ++ option_keys) |> Enum.uniq()
  end
end
