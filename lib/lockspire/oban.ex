defmodule Lockspire.Oban do
  @moduledoc """
  Named Oban instance owned by Lockspire for durable protocol work.
  """

  use Oban, otp_app: :lockspire

  @default_queues [logout_backchannel: 10]

  @spec runtime_config!() :: keyword()
  def runtime_config! do
    config =
      :lockspire
      |> Application.get_env(:oban, [])
      |> Keyword.merge(name: __MODULE__)
      |> Keyword.put_new(:repo, repo!())
      |> apply_plugins()
      |> Keyword.put_new(:queues, @default_queues)
      |> maybe_put_testing_mode()

    case Oban.Config.validate(config) do
      :ok ->
        config

      {:error, reason} ->
        raise RuntimeError, "invalid :lockspire, :oban config: #{reason}"
    end
  end

  @spec config!() :: Oban.Config.t()
  def config! do
    Oban.config(__MODULE__)
  end

  defp repo! do
    case Application.get_env(:lockspire, :repo) do
      nil ->
        raise RuntimeError,
              "Lockspire.Oban requires :lockspire repo config before startup."

      repo ->
        repo
    end
  end

  defp maybe_put_testing_mode(config) do
    if Mix.env() == :test do
      Keyword.put_new(config, :testing, :manual)
    else
      config
    end
  end

  defp apply_plugins(config) do
    base_plugins = Keyword.get(config, :plugins, false)

    plugins =
      case Lockspire.Config.pruner_schedule() do
        schedule when is_binary(schedule) and schedule != "" ->
          base_list = if base_plugins == false, do: [], else: List.wrap(base_plugins)
          base_list ++ [{Oban.Plugins.Cron, crontab: [{schedule, Lockspire.Workers.Pruner}]}]

        _ ->
          base_plugins
      end

    Keyword.put(config, :plugins, plugins)
  end
end
