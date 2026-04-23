defmodule Lockspire.Storage.InteractionStore do
  @moduledoc """
  Domain-level persistence contract for authorization interactions.
  """

  alias Lockspire.Domain.Interaction

  @type store_error :: term()

  # Acceptance marker: @callback put_interaction/1
  @callback put_interaction(Interaction.t()) :: {:ok, Interaction.t()} | {:error, store_error()}
  @callback fetch_interaction(String.t()) ::
              {:ok, Interaction.t() | nil} | {:error, store_error()}
  @callback fetch_active_interaction(String.t()) ::
              {:ok, Interaction.t() | nil} | {:error, store_error()}
  @callback transition_interaction(String.t(), [Interaction.status()], map()) ::
              {:ok, Interaction.t()} | {:error, store_error()}
  @callback transact((-> term())) :: {:ok, term()} | {:error, store_error()}
end
