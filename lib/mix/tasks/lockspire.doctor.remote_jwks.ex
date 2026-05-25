defmodule Mix.Tasks.Lockspire.Doctor.RemoteJwks do
  @moduledoc """
  Diagnose runtime remote-JWKS incidents for a single client.
  """

  use Mix.Task

  alias Lockspire.Admin.Clients
  alias Lockspire.Diagnostics.RemoteJwks

  @shortdoc "Diagnoses remote jwks_uri runtime incidents for one client"
  @requirements ["app.config"]

  @switches [
    client: :string,
    help: :boolean
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("Unknown options: #{Enum.map_join(invalid, ", ", &elem(&1, 0))}")
    end

    cond do
      Keyword.get(opts, :help, false) ->
        Mix.shell().info(help())

      is_nil(Keyword.get(opts, :client)) ->
        Mix.raise("`--client` is required. See `mix lockspire.doctor remote-jwks --help`.")

      true ->
        opts
        |> Keyword.fetch!(:client)
        |> Clients.get_client()
        |> print_result()
    end
  end

  def help do
    """
    mix lockspire.doctor remote-jwks --client CLIENT_ID

    Runtime remote-JWKS incident diagnosis for one client:
      1. Render the shared remote-JWKS support truth for a jwks_uri-backed client
      2. Show the normalized incident class and safe runtime facts when incident metadata is present
      3. Print one calm remediation step plus the Lockspire/operator/client-integrator ownership split

    Boundary:
      - `mix lockspire.verify` remains the install and onboarding diagnostic
      - `mix lockspire.doctor remote-jwks` is for runtime remote key-distribution incidents
    """
  end

  defp print_result({:ok, client}) do
    summary = Clients.remote_jwks_summary(client)

    lines =
      [
        "Client: #{client.client_id}",
        "Status: #{summary.status}",
        summary.headline,
        summary.detail,
        "Next step: #{summary.next_step}",
        "Ownership: #{summary.ownership}",
        "Boundary: #{RemoteJwks.install_boundary_note()}"
      ] ++ incident_lines(summary) ++ command_hint(summary)

    Enum.each(lines, fn line -> Mix.shell().info(line) end)
  end

  defp print_result({:error, :not_found}) do
    Mix.raise("Client not found.")
  end

  defp print_result({:error, reason}) do
    Mix.raise("Could not inspect client: #{inspect(reason)}")
  end

  defp incident_lines(%{incident: nil}), do: []

  defp incident_lines(%{incident: incident}) do
    [
      "Incident class: #{incident.class}",
      "Stage: #{incident.stage}",
      "Subreason: #{incident.subreason || "n/a"}"
    ] ++ fetch_status_line(incident)
  end

  defp fetch_status_line(%{fetch_status: status}) when is_integer(status),
    do: ["HTTP status: #{status}"]

  defp fetch_status_line(_incident), do: []

  defp command_hint(%{command_hint: nil}), do: []
  defp command_hint(%{command_hint: hint}), do: ["Command: #{hint}"]
end
