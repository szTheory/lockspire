defmodule Lockspire.RAR.Dispatcher do
  @moduledoc false

  require Logger

  alias Ecto.Changeset
  alias Lockspire.Config
  alias Lockspire.Observability
  alias Lockspire.RAR

  @type dispatch_error :: {String.t(), atom()}

  @spec dispatch_each([map()], map()) :: {:ok, [map()]} | {:error, dispatch_error()}
  def dispatch_each(details, %{pre_validated?: true}) when is_list(details), do: {:ok, details}

  def dispatch_each(details, ctx) when is_list(details) and is_map(ctx) do
    Enum.reduce_while(details, {:ok, []}, fn detail, {:ok, acc} ->
      with {:ok, type} <- fetch_type(detail),
           {:ok, validator} <- fetch_validator(type, ctx),
           {:ok, normalized} <- validate_detail(validator, detail, Map.put(ctx, :type, type)) do
        {:cont, {:ok, [normalized | acc]}}
      else
        {:error, _reason} = error ->
          {:halt, error}
      end
    end)
    |> then(fn
      {:ok, normalized} -> {:ok, Enum.reverse(normalized)}
      error -> error
    end)
  end

  defp fetch_type(%{"type" => type}) when is_binary(type) and type != "", do: {:ok, type}

  defp fetch_type(_detail) do
    {:error,
     {"authorization_details entries must include a non-empty string type",
      :invalid_authorization_details}}
  end

  defp fetch_validator(type, ctx) do
    case Map.get(Config.rar_validators(), type) do
      validator when is_atom(validator) and not is_nil(validator) ->
        {:ok, validator}

      nil ->
        Logger.warning("Unknown RAR type rejected for client #{inspect(ctx[:client_id])}")

        Observability.emit(:rar, :unknown_type, %{count: 1}, %{
          type: type,
          client_id: ctx[:client_id]
        })

        {:error,
         {"authorization_details contains an unsupported type",
          :unknown_authorization_details_type}}
    end
  end

  defp validate_detail(validator, detail, ctx) do
    metadata = %{type: ctx.type, client_id: ctx[:client_id]}

    :telemetry.span([:lockspire, :rar, :validation], metadata, fn ->
      case validator.validate(detail, ctx) do
        {:ok, normalized} when is_map(normalized) ->
          {{:ok, normalized}, Map.put(metadata, :outcome, :ok)}

        {:error, %Changeset{} = changeset} ->
          {{:error, {RAR.error_description(changeset), :invalid_authorization_details}},
           Map.put(metadata, :outcome, :error)}

        {:error, description} when is_binary(description) ->
          {{:error, {description, :invalid_authorization_details}},
           Map.put(metadata, :outcome, :error)}

        _other ->
          {{:error,
            {"authorization_details validator returned an invalid result",
             :invalid_authorization_details}}, Map.put(metadata, :outcome, :error)}
      end
    end)
  end
end
