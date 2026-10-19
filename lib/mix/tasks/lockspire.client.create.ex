defmodule Mix.Tasks.Lockspire.Client.Create do
  @moduledoc """
  Register a durable OAuth client from the command line.
  """

  @shortdoc "Registers a durable OAuth client"

  use Mix.Task

  @requirements ["app.config"]

  alias Lockspire.Clients
  alias Lockspire.Install.TaskError

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
      # app.config loads config but starts no applications; sealing client secret material
      # needs the plug_crypto key cache.
      {:ok, _apps} = Application.ensure_all_started(:plug_crypto)

      repo = Lockspire.Config.repo!()

      # The fun only computes. Printing and raising happen after the runner returns, because the
      # runner turns anything raised inside the fun into a repo failure.
      outcome =
        TaskError.run(repo, fn _repo -> opts |> build_attrs() |> Clients.register_client() end)

      case outcome do
        {:ok, {:ok, result}} -> print_result({:ok, result})
        {:ok, {:error, errors}} when is_list(errors) -> print_result({:error, errors})
        {:error, phrase} -> Mix.raise("client registration failed: " <> phrase)
      end
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

    The client secret is printed once, after the app is saved. If the task stops after saving
    but before printing, the app exists: rotate its secret from the admin Apps page instead of
    running the task again, because running it again creates a second app.

    Lockspire audit events are not delivered from this command. The client's created_by value
    records who registered it from the command line.
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
    Mix.shell().info("token_endpoint_auth_method=#{result.client.token_endpoint_auth_method}")

    if result.client_secret do
      Mix.shell().info("client_secret=#{result.client_secret}")
    end

    Mix.shell().info("")
    Mix.shell().info("Next steps:")
    Mix.shell().info("* Store any printed client_secret now; Lockspire will not show it again.")
    Mix.shell().info("* Add this redirect URI to your partner app exactly as printed.")

    Mix.shell().info(
      "* Prove discovery, JWKS, and an authorization-code + PKCE flow before sharing it."
    )

    Mix.shell().info("* Keep product authorization and tenant policy in the host app.")
  end

  defp print_result({:error, errors}) do
    Mix.raise(format_domain_errors(errors))
  end

  defp format_domain_errors(errors) do
    lines = Enum.map(errors, &error_line/1)
    Enum.join(["client registration failed; nothing was saved:" | lines], "\n")
  end

  # A :base error carries an inspected store error as its detail; it is never shown.
  defp error_line(%{field: :base}) do
    "  - base: the client could not be saved; check database connectivity and that mix ecto.migrate has run"
  end

  defp error_line(%{field: field, reason: :persistence_failed, detail: detail}) do
    "  - #{field}: #{detail_text(detail)}"
  end

  defp error_line(%{field: field, reason: reason, detail: detail}) do
    "  - #{field}: #{reason} (#{detail_text(detail)})"
  end

  defp detail_text(detail) when is_binary(detail), do: detail
  defp detail_text(nil), do: "invalid value"
  defp detail_text(detail) when is_atom(detail) or is_number(detail), do: to_string(detail)
  defp detail_text(_detail), do: "invalid value"
end
