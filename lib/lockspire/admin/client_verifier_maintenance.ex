defmodule Lockspire.Admin.ClientVerifierMaintenance do
  @moduledoc """
  Exhaustive, redacted verifier-custody status and maintenance over the selected client store.

  The operation deliberately separates scan completion, committed changes and a fresh
  current-custody check. It never returns a client struct or verifier material.
  """

  alias Lockspire.Config
  alias Lockspire.Domain.Client
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Storage.ClientVerifierMaintenance, as: Maintenance

  @default_limit 100
  @min_limit 1
  @max_limit 500
  @max_details 100
  @max_identity_bytes 512
  @key_id_pattern ~r/\A[A-Za-z0-9._-]{1,32}\z/

  @type mode :: :apply | :dry_run | :check

  @spec run(keyword()) :: {:ok, map()} | {:error, map() | atom()}
  def run(opts \\ [])

  def run(opts) when is_list(opts) do
    with {:ok, mode, limit, cursor} <- validate_options(opts),
         {:ok, context, context_source} <- resolve_context(opts),
         {:ok, config} <- Maintenance.configured(),
         {:ok, %Context{state: :valid, write_mode: :dedicated} = context} <-
           validate_context(context) do
      report = new_report(mode, cursor, context_source)

      report =
        walk_pages(report, context, config, cursor, limit)
        |> finalize(context, cursor)

      if successful?(report),
        do: {:ok, public_report(report)},
        else: {:error, public_report(report)}
    else
      {:error, reason} when is_atom(reason) -> {:error, safe_reason(reason)}
      _ -> {:error, :client_secret_verifier_maintenance_failed}
    end
  rescue
    _ -> {:error, :client_secret_verifier_maintenance_failed}
  catch
    _, _ -> {:error, :client_secret_verifier_maintenance_failed}
  end

  def run(_opts), do: {:error, :client_secret_verifier_maintenance_invalid_options}

  defp validate_options(opts) do
    allowed = [
      :mode,
      :limit,
      :after_client_id,
      :context_source,
      :client_secret_verifier_context
    ]

    if not Keyword.keyword?(opts) or duplicate_keys?(opts) or Keyword.keys(opts) -- allowed != [] do
      {:error, :client_secret_verifier_maintenance_invalid_options}
    else
      mode = Keyword.get(opts, :mode, :apply)
      limit = Keyword.get(opts, :limit, @default_limit)
      cursor = Keyword.get(opts, :after_client_id)

      cond do
        mode not in [:apply, :dry_run, :check] ->
          {:error, :client_secret_verifier_maintenance_invalid_options}

        not is_integer(limit) or limit < @min_limit or limit > @max_limit ->
          {:error, :client_secret_verifier_maintenance_invalid_limit}

        not is_nil(cursor) and
            (not is_binary(cursor) or cursor == "" or not String.valid?(cursor)) ->
          {:error, :client_secret_verifier_inventory_invalid_cursor}

        mode == :check and not is_nil(cursor) ->
          {:error, :client_secret_verifier_maintenance_check_requires_fresh_scan}

        true ->
          {:ok, mode, limit, cursor}
      end
    end
  end

  defp duplicate_keys?(opts) do
    keys = Keyword.keys(opts)
    length(keys) != length(Enum.uniq(keys))
  end

  defp validate_context(context) do
    case Context.validate(context) do
      {:ok, %Context{state: :valid, write_mode: :dedicated} = valid} -> {:ok, valid}
      _ -> {:error, :client_secret_verifier_configuration_invalid}
    end
  end

  defp resolve_context(opts) do
    case {Keyword.get(opts, :context_source, :startup),
          Keyword.fetch(opts, :client_secret_verifier_context)} do
      {:startup, :error} ->
        {:ok, Config.client_secret_verifier_context(), :startup}

      {:task_local, {:ok, %Context{} = context}} ->
        {:ok, context, :task_local}

      _ ->
        {:error, :client_secret_verifier_configuration_invalid}
    end
  end

  defp new_report(mode, cursor, context_source) do
    %{
      mode: mode,
      context_source: context_source,
      initial_cursor: cursor,
      scan_complete?: false,
      scanned: 0,
      committed_changed: 0,
      already_current: 0,
      no_material: 0,
      pending: 0,
      conflicts: 0,
      failed: 0,
      uninspected: 0,
      custody_condition_met?: false,
      detail_counts: %{},
      details: [],
      details_truncated?: false,
      all_current?: true
    }
  end

  defp walk_pages(report, context, config, cursor, limit) do
    case config.client_store.verifier_inventory_page(cursor, limit) do
      {:ok, page} ->
        case validate_page(page, cursor, limit) do
          :ok ->
            report = Enum.reduce(page.clients, report, &inspect_client(&1, &2, context))

            if page.complete? do
              %{report | scan_complete?: true}
            else
              walk_pages(report, context, config, page.next_cursor, limit)
            end

          {:error, _safe_reason} ->
            report
            |> Map.update!(:uninspected, &(&1 + max(length(page_clients(page)), 1)))
            |> Map.put(:all_current?, false)
            |> add_detail(nil, :uninspected, :invalid_inventory_page, :rerun_fresh_check)
        end

      {:error, _reason} ->
        report
        |> Map.update!(:uninspected, &(&1 + 1))
        |> Map.put(:all_current?, false)
        |> add_detail(nil, :uninspected, :inventory_unreadable, :repair_storage_or_retry)

      _other ->
        report
        |> Map.update!(:uninspected, &(&1 + 1))
        |> Map.put(:all_current?, false)
        |> add_detail(nil, :uninspected, :inventory_unreadable, :repair_storage_or_retry)
    end
  rescue
    _ ->
      report
      |> Map.update!(:uninspected, &(&1 + 1))
      |> Map.put(:all_current?, false)
      |> add_detail(nil, :uninspected, :inventory_unreadable, :repair_storage_or_retry)
  catch
    _, _ ->
      report
      |> Map.update!(:uninspected, &(&1 + 1))
      |> Map.put(:all_current?, false)
      |> add_detail(nil, :uninspected, :inventory_unreadable, :repair_storage_or_retry)
  end

  defp validate_page(
         %{clients: clients, next_cursor: next, complete?: complete?} = page,
         cursor,
         limit
       )
       when is_list(clients) and is_boolean(complete?) and map_size(page) == 3 do
    ids = Enum.map(clients, &client_id/1)

    cond do
      length(clients) > limit -> {:error, :oversized_page}
      Enum.any?(ids, &is_nil/1) -> {:error, :invalid_client}
      not strictly_after?(ids, cursor) -> {:error, :unordered_or_duplicate}
      complete? and not is_nil(next) -> {:error, :terminal_cursor}
      not complete? and (clients == [] or next != List.last(ids)) -> {:error, :nonterminal_cursor}
      not complete? and not strictly_after?([next], cursor) -> {:error, :nonprogressing_cursor}
      true -> :ok
    end
  end

  defp validate_page(_page, _cursor, _limit), do: {:error, :invalid_page}

  defp client_id(%Client{client_id: id}) when is_binary(id) and id != "" do
    if String.valid?(id), do: id, else: nil
  end

  defp client_id(_), do: nil

  defp strictly_after?(ids, cursor) do
    Enum.reduce_while(ids, cursor, fn id, previous ->
      cond do
        not is_binary(id) -> {:halt, :invalid}
        is_nil(previous) -> {:cont, id}
        id > previous -> {:cont, id}
        true -> {:halt, :invalid}
      end
    end) != :invalid
  end

  defp page_clients(%{clients: clients}) when is_list(clients), do: clients
  defp page_clients(_), do: []

  defp inspect_client(%Client{} = client, report, context) do
    report = Map.update!(report, :scanned, &(&1 + 1))

    case classify(client, context) do
      {:ok, :no_material, _metadata} ->
        report
        |> Map.update!(:no_material, &(&1 + 1))
        |> count_class(:no_material)
        |> add_detail(client.client_id, :no_material, nil, :none)

      {:ok, :current_key, metadata} ->
        report
        |> Map.update!(:already_current, &(&1 + 1))
        |> count_class(:current_key)
        |> add_detail(client.client_id, :current_key, nil, :none, metadata)

      {:ok, :expired_migrated, metadata} ->
        if metadata.custody_class == :current_key do
          report
          |> Map.update!(:already_current, &(&1 + 1))
          |> count_class(:expired_migrated)
          |> add_detail(
            client.client_id,
            :expired_migrated,
            nil,
            :review_client_lifetime,
            metadata
          )
        else
          process_pending(client, report, :expired_migrated, metadata, context)
        end

      {:ok, classification, metadata} when classification in [:legacy, :old_key] ->
        process_pending(client, report, classification, metadata, context)

      {:attention, classification, reason, action, metadata} ->
        report
        |> Map.update!(:failed, &(&1 + 1))
        |> Map.put(:all_current?, false)
        |> count_class(classification)
        |> add_detail(client.client_id, classification, reason, action, metadata)
    end
  rescue
    _ ->
      report
      |> Map.update!(:failed, &(&1 + 1))
      |> Map.put(:all_current?, false)
      |> count_class(:unreadable)
      |> add_detail(
        client.client_id,
        :unreadable,
        :custody_unreadable,
        :repair_storage_or_recover
      )
  end

  defp inspect_client(_client, report, _context) do
    report
    |> Map.update!(:uninspected, &(&1 + 1))
    |> Map.put(:all_current?, false)
    |> add_detail(nil, :uninspected, :invalid_client_record, :repair_storage_or_retry)
  end

  defp classify(%Client{} = client, context) do
    hash = client.client_secret_hash
    verifier = client.client_secret_jwt_verifier_encrypted

    cond do
      is_nil(hash) and is_nil(verifier) and client.client_type == :public and
          client.token_endpoint_auth_method == :none ->
        {:ok, :no_material, %{authenticated?: true}}

      is_nil(hash) and is_binary(verifier) ->
        {:attention, :orphan_verifier, :orphan_verifier, :repair_client_record,
         %{authenticated?: false}}

      is_binary(hash) and is_nil(verifier) ->
        {:attention, :missing_material, :missing_expected_material, :rotate_client_secret,
         %{authenticated?: false}}

      not is_binary(hash) or not is_binary(verifier) ->
        {:attention, :missing_material, :missing_expected_material, :rotate_client_secret,
         %{authenticated?: false}}

      true ->
        classify_authenticated_inspection(client, context, hash, verifier)
    end
  end

  defp classify_authenticated_inspection(client, context, hash, verifier) do
    custody_opts = legacy_key_opts()

    case ClientSecretVerifier.inspect_custody(
           context,
           client.client_id,
           verifier,
           hash,
           custody_opts
         ) do
      {:ok, %{authenticated?: true, classification: classification} = metadata} ->
        key_id = safe_key_id(metadata.key_id)

        if classification == :legacy do
          {:ok, :legacy, %{authenticated?: true, key_id: nil}}
        else
          if metadata.age_kind == :migrated and not metadata.authentication_eligible? do
            {:ok, :expired_migrated,
             %{authenticated?: true, key_id: key_id, custody_class: classification}}
          else
            safe_classification =
              if key_id == context.current_id, do: :current_key, else: :old_key

            {:ok, safe_classification, %{authenticated?: true, key_id: key_id}}
          end
        end

      {:ok, _untrusted_metadata} ->
        {:attention, :unreadable, :custody_unreadable, :repair_storage_or_recover,
         %{authenticated?: false}}

      {:error, reason} ->
        {classification, safe_reason, action} = inspection_error(reason)
        {:attention, classification, safe_reason, action, %{authenticated?: false}}

      _other ->
        {:attention, :unreadable, :custody_unreadable, :repair_storage_or_recover,
         %{authenticated?: false}}
    end
  rescue
    _ ->
      {:attention, :unreadable, :custody_unreadable, :repair_storage_or_recover,
       %{authenticated?: false}}
  end

  defp inspection_error(:client_secret_verifier_key_unknown),
    do: {:unknown_key, :unknown_key, :restore_verifier_key}

  defp inspection_error(:client_secret_verifier_unsupported_format),
    do: {:malformed, :malformed_verifier, :replace_client_secret}

  defp inspection_error(:client_secret_verifier_configuration_invalid),
    do: {:unreadable, :inspection_unavailable, :repair_configuration}

  defp inspection_error(_), do: {:unreadable, :custody_unreadable, :repair_storage_or_recover}

  defp process_pending(client, report, classification, metadata, context) do
    case report.mode do
      :apply ->
        maintenance_opts =
          Keyword.put(legacy_key_opts(), :operation_context, context)

        case Maintenance.rewrap_client(client.client_id, maintenance_opts) do
          {:ok, :changed} ->
            report
            |> Map.update!(:committed_changed, &(&1 + 1))
            |> Map.put(:all_current?, false)
            |> count_class(classification)
            |> add_detail(
              client.client_id,
              classification,
              nil,
              :run_fresh_check,
              Map.put(metadata, :outcome, :changed)
            )

          {:ok, :already_current} ->
            report
            |> Map.update!(:already_current, &(&1 + 1))
            |> Map.put(:all_current?, false)
            |> count_class(classification)
            |> add_detail(
              client.client_id,
              classification,
              nil,
              :run_fresh_check,
              Map.put(metadata, :outcome, :already_current)
            )

          {:ok, :material_conflict} ->
            report
            |> Map.update!(:conflicts, &(&1 + 1))
            |> Map.put(:all_current?, false)
            |> count_class(classification)
            |> add_detail(
              client.client_id,
              classification,
              :material_changed_during_run,
              :run_fresh_check,
              Map.put(metadata, :outcome, :material_conflict)
            )

          {:error, _safe_reason} ->
            failed_row(report, client.client_id, :maintenance_failed)

          _other ->
            failed_row(report, client.client_id, :maintenance_failed)
        end

      _preview ->
        report
        |> Map.update!(:pending, &(&1 + 1))
        |> Map.put(:all_current?, false)
        |> count_class(classification)
        |> add_detail(client.client_id, classification, nil, :rewrap_or_recover, metadata)
    end
  rescue
    _ -> failed_row(report, client.client_id, :maintenance_failed)
  end

  defp failed_row(report, client_id, reason) do
    report
    |> Map.update!(:failed, &(&1 + 1))
    |> Map.put(:all_current?, false)
    |> count_class(:failed)
    |> add_detail(client_id, :failed, reason, :repair_storage_or_retry)
  end

  defp count_class(report, classification) do
    update_in(report, [:detail_counts, classification], fn
      nil -> 1
      count -> count + 1
    end)
  end

  defp add_detail(report, client_id, classification, reason, action, metadata \\ %{}) do
    if length(report.details) >= @max_details do
      %{report | details_truncated?: true}
    else
      entry = %{
        client_id: safe_identity(client_id),
        classification: classification,
        reason: reason,
        next_action: action,
        key_id: if(metadata[:authenticated?], do: safe_key_id(metadata[:key_id])),
        outcome: safe_outcome(metadata[:outcome])
      }

      %{report | details: [entry | report.details]}
    end
  end

  defp safe_identity(id) when is_binary(id) and byte_size(id) <= @max_identity_bytes do
    %{value: Base.url_encode64(id, padding: false), encoding: :base64url_utf8_bytes}
  end

  defp safe_identity(id) when is_binary(id) do
    fingerprint = :crypto.hash(:sha256, id) |> Base.encode16(case: :lower) |> binary_part(0, 16)
    %{value: "sha256:" <> fingerprint, encoding: :sha256_prefix, truncated?: true}
  end

  defp safe_identity(_), do: %{value: nil, encoding: :unavailable}

  defp safe_key_id(id) when is_binary(id) do
    if Regex.match?(@key_id_pattern, id), do: id, else: nil
  end

  defp safe_key_id(_), do: nil

  defp safe_outcome(outcome) when outcome in [:changed, :already_current, :material_conflict],
    do: outcome

  defp safe_outcome(_), do: nil

  defp legacy_key_opts do
    case Config.secret_key_base() do
      key when is_binary(key) and key != "" -> [legacy_secret_key_base: key]
      _ -> []
    end
  rescue
    _ -> []
  end

  defp finalize(report, _context, cursor) do
    ready? =
      report.mode == :check and is_nil(cursor) and report.scan_complete? and report.all_current? and
        report.pending == 0 and report.failed == 0 and report.conflicts == 0 and
        report.uninspected == 0

    %{report | custody_condition_met?: ready?, details: Enum.reverse(report.details)}
  end

  defp successful?(%{mode: :dry_run} = report),
    do:
      report.scan_complete? and report.failed == 0 and report.conflicts == 0 and
        report.uninspected == 0

  defp successful?(%{mode: :check} = report), do: report.custody_condition_met?

  defp successful?(report),
    do:
      report.scan_complete? and report.failed == 0 and report.conflicts == 0 and
        report.uninspected == 0

  defp public_report(report), do: Map.drop(report, [:initial_cursor, :all_current?])

  defp safe_reason(reason)
       when reason in [
              :client_secret_verifier_maintenance_unsupported,
              :client_secret_verifier_maintenance_authority_mismatch,
              :client_secret_verifier_configuration_invalid,
              :client_secret_verifier_maintenance_invalid_options,
              :client_secret_verifier_maintenance_invalid_limit,
              :client_secret_verifier_inventory_invalid_cursor,
              :client_secret_verifier_maintenance_check_requires_fresh_scan
            ],
       do: reason

  defp safe_reason(_), do: :client_secret_verifier_maintenance_failed
end
