defmodule Mix.Tasks.Lockspire.Doctor.TokenFormat do
  @moduledoc """
  Report each client's effective access-token format and flag every client that
  inherits the server default.

  Read-only and diagnostic-only: this task never mutates state, never raises on a
  flagged client, and never exits non-zero (so it is safe to run in operator CI).
  """

  use Mix.Task

  alias Lockspire.Admin.Clients
  alias Lockspire.Admin.ServerPolicy
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy, as: ServerPolicyStruct

  @shortdoc "Reports each client's effective access-token format (read-only)"
  @requirements ["app.config"]

  @switches [
    help: :boolean
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("Unknown options: #{Enum.map_join(invalid, ", ", &elem(&1, 0))}")
    end

    if Keyword.get(opts, :help, false) do
      Mix.shell().info(help())
    else
      report()
    end
  end

  def help do
    """
    mix lockspire.doctor token_format

    Read-only per-client effective access-token-format diagnosis:
      1. Resolve every client's effective access-token format using the same
         precedence the signer uses (per-client override -> server default -> :jwt)
      2. Flag every client with `access_token_format: nil`, whose inherited default
         now resolves to :jwt after the v1.27 issuance flip (changed semantics)
      3. Leave explicit-:opaque clients unflagged

    Boundary:
      - This task is diagnostic-only: it never mutates state, never raises on a
        flagged client, and never exits non-zero.
    """
  end

  # The report path must never crash: both admin reads return {:ok, _} | {:error, _}
  # tuples, and an {:error, _} from either is surfaced calmly via Mix.shell().info.
  defp report do
    with {:ok, policy} <- ServerPolicy.get_server_policy(),
         {:ok, clients} <- Clients.list_clients() do
      print_report(policy, clients)
    else
      {:error, reason} ->
        Mix.shell().info("Could not inspect token formats: #{inspect(reason)}")
    end
  end

  defp print_report(policy, clients) do
    server_default = effective_format(%Client{access_token_format: nil}, policy)

    header = [
      "Effective access-token format per client",
      "Server default: #{server_default}",
      ""
    ]

    lines =
      if clients == [] do
        ["(no clients registered)"]
      else
        Enum.map(clients, &client_line(&1, policy))
      end

    Enum.each(header ++ lines, fn line -> Mix.shell().info(line) end)
  end

  defp client_line(%Client{access_token_format: nil} = client, policy) do
    fmt = effective_format(client, policy)
    "#{client.client_id}: #{fmt} [CHANGED: inherits server default (#{fmt}); was no per-client format]"
  end

  defp client_line(%Client{} = client, policy) do
    "#{client.client_id}: #{effective_format(client, policy)}"
  end

  # Reproduces the precedence of the PRIVATE
  # `Lockspire.Protocol.AccessTokenSigner.resolve_format/2`
  # (lib/lockspire/protocol/access_token_signer.ex:88-98). resolve_format/2 is a
  # `defp` and cannot be called from here; these three clauses MUST stay
  # byte-equivalent to that authority:
  #   1. per-client :jwt|:opaque wins
  #   2. nil + ServerPolicy -> server_fmt || :jwt
  #   3. nil + no policy    -> :jwt
  defp effective_format(%Client{access_token_format: fmt}, _server_policy)
       when fmt in [:jwt, :opaque],
       do: fmt

  defp effective_format(%Client{access_token_format: nil}, %ServerPolicyStruct{
         access_token_format: server_fmt
       }),
       do: server_fmt || :jwt

  defp effective_format(%Client{access_token_format: nil}, _server_policy), do: :jwt
end
