defmodule Mix.Tasks.Lockspire.Client.Create do
  @moduledoc """
  Register a durable OAuth client from the command line.
  """

  @shortdoc "Registers a durable OAuth client"

  use Mix.Task

  @requirements ["app.config"]

  alias Lockspire.Clients

  @switches [
    client_id: :string,
    name: :string,
    redirect_uri: :keep,
    scope: :keep,
    grant_type: :keep,
    client_type: :string,
    token_endpoint_auth_method: :string,
    created_by: :string,
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
      opts
      |> build_attrs()
      |> Clients.register_client()
      |> print_result()
    end
  end

  def help do
    """
    mix lockspire.client.create --client-type public|confidential --redirect-uri URI --scope SCOPE --grant-type authorization_code [options]

    Required:
      --client-type TYPE
      --redirect-uri URI
      --scope SCOPE
      --grant-type TYPE

    Optional:
      --client-id ID
      --name NAME
      --token-endpoint-auth-method METHOD
      --created-by SUBJECT
    """
  end

  defp build_attrs(opts) do
    %{
      client_id: Keyword.get(opts, :client_id),
      name: Keyword.get(opts, :name),
      client_type: Keyword.get(opts, :client_type),
      redirect_uris: Keyword.get_values(opts, :redirect_uri),
      allowed_scopes: Keyword.get_values(opts, :scope),
      allowed_grant_types: Keyword.get_values(opts, :grant_type),
      token_endpoint_auth_method:
        Keyword.get(opts, :token_endpoint_auth_method) ||
          default_auth_method(Keyword.get(opts, :client_type)),
      created_by: Keyword.get(opts, :created_by)
    }
  end

  defp default_auth_method("public"), do: "none"
  defp default_auth_method("confidential"), do: "client_secret_basic"
  defp default_auth_method(_other), do: nil

  defp print_result({:ok, result}) do
    Mix.shell().info("client_id=#{result.client.client_id}")
    Mix.shell().info("client_type=#{result.client.client_type}")
    Mix.shell().info("redirect_uris=#{Enum.join(result.client.redirect_uris, ",")}")
    Mix.shell().info("allowed_scopes=#{Enum.join(result.client.allowed_scopes, ",")}")
    Mix.shell().info("allowed_grant_types=#{Enum.join(result.client.allowed_grant_types, ",")}")

    if result.client_secret do
      Mix.shell().info("client_secret=#{result.client_secret}")
    end
  end

  defp print_result({:error, errors}) do
    details =
      Enum.map_join(errors, "; ", fn error ->
        "#{error.field}:#{error.reason}(#{error.detail})"
      end)

    Mix.raise("client registration failed: #{details}")
  end
end
