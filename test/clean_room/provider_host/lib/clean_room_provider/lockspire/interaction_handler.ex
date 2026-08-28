defmodule CleanRoomProvider.Lockspire.InteractionHandler do
  @moduledoc false

  alias Lockspire.Host.InteractionResult

  def consent_path(interaction_id), do: "/lockspire/consent/#{interaction_id}"
  def finalize_path(interaction_id), do: "/lockspire/interactions/#{interaction_id}/complete"

  def finish_interaction(interaction_id, params \\ %{}) do
    path = consent_path(interaction_id)

    {:ok,
     %{
       interaction_id: interaction_id,
       consent_path: path,
       finalize_path: finalize_path(interaction_id),
       next: %InteractionResult{
         login_path: path,
         return_to: path,
         params: Map.put(Map.take(params, ["source"]), "interaction_id", interaction_id)
       }
     }}
  end
end
