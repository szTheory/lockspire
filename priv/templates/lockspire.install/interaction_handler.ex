defmodule <%= @interaction_handler_module %> do
  @moduledoc """
  Host-owned login handoff helper for Lockspire interaction routes.
  """

  alias Lockspire.Host.InteractionResult

  @spec consent_path(String.t()) :: String.t()
  def consent_path(interaction_id) do
    "<%= @mount_path %>/consent/#{interaction_id}"
  end

  @spec finalize_path(String.t()) :: String.t()
  def finalize_path(interaction_id) do
    "<%= @mount_path %>/interactions/#{interaction_id}/complete"
  end

  @spec finish_interaction(String.t(), map()) :: {:ok, map()}
  def finish_interaction(interaction_id, params \\ %{}) do
    next_path = consent_path(interaction_id)

    {:ok,
     %{
       interaction_id: interaction_id,
       consent_path: next_path,
       finalize_path: finalize_path(interaction_id),
       next: %InteractionResult{
         login_path: next_path,
         return_to: next_path,
         params:
           params
           |> Map.take(["source"])
           |> Map.put("interaction_id", interaction_id)
       }
     }}
  end
end
