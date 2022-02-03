defmodule AppcuesIncrement.KV.Dist do
  @moduledoc """
  Dist strategy to use append only logs and aggregation to scale up key counters
  """
  @behaviour AppcuesIncrement.KV.Strategy
  use GenServer

  require Logger

  def start_link(index: index) do
    GenServer.start_link(__MODULE__, nil, name: via_tuple(index))
  end

  @impl GenServer
  def init(_) do
    # trap exits to try to sync DB on terminate
    Process.flag(:trap_exit, true)
    # TODO: use ets instead of a map with write concurrency for improving performance
    state = %{}
    send(self(), :sync)
    {:ok, state}
  end

  @impl AppcuesIncrement.KV.Strategy
  def increment(key, value) do
    index = :erlang.phash2(key, AppcuesIncrement.Config.kvs_processes()) + 1
    GenServer.cast(via_tuple(index), {:increment, key, value})
  end

  @impl GenServer
  def handle_cast({:increment, key, value}, state) do
    new_state =
      if Map.has_key?(state, key) do
        update_state(state, key, value)
      else
        Map.put(state, key, %{value: 0, logs: [value]})
      end

    # state %{key: %{value: X}} value is used as counter cache and can be used
    # from the api /increment/:key instead of calling the DB TODO

    :telemetry.execute([:appcues, :kv, :dist, :increment], %{event: 1})
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_info(:sync, state) do
    start = System.monotonic_time(:millisecond)
    new_state = sync_state_to_db(state)
    now = System.monotonic_time(:millisecond)
    :telemetry.execute([:appcues, :kv, :dist, :sync_to_db], %{duration: now - start})
    # we need to wait for the sync to happen before scheduling the next sync
    Process.send_after(self(), :sync, AppcuesIncrement.Config.sync_interval())
    {:noreply, new_state}
  end

  @impl GenServer
  def terminate(_reason, state) do
    # sync state to DB on terminate
    sync_state_to_db(state)
    :ok
  end

  defp via_tuple(index) do
    {:via, Registry, {AppcuesIncrement.Registry, index}}
  end

  # append only log with aggregation on sync
  defp update_state(state, key, value) do
    %{logs: logs} = state[key]
    new_logs = [value | logs]
    put_in(state, [key, :logs], new_logs)
  end

  defp sync_state_to_db(state) do
    # This approach will work until thousands of keys, when reaching out couple
    # of hundreds of thousands of keys, it will be better to conver it to a batch
    # update
    Enum.reduce(state, %{}, fn
      {_key, %{logs: []}}, acc ->
        # do nothing if no new logs
        acc

      {key, record}, acc ->
        # aggregate logs before sync
        new_value = aggregate_logs(record.logs)

        # use DB record for keeping the value up to date as we can use it as a
        # counter cache and as other nodes may be updating it we should be aware of
        # those changes and also clear logs so we don't aggregate them again.
        # NOTE: each node in the cluster may have its own processe holding the same
        # key, but that's ok, as its an append only log and we are incrementing at DB
        # level atomically it will scale and won't block other operations, also,
        # it will sync after being updated with the value that holds the DB
        # Eventual Consistency
        case AppcuesIncrement.Counter.create_or_increment(key, new_value) do
          {:ok, db_record} ->
            # use the last updated value from DB so we are up to date to our
            # source of truth
            Map.put(acc, key, %{record | logs: [], value: db_record.value})

          {:error, reason} ->
            Logger.error("error syncing to db key:#{key} reason #{inspect(reason)}")
            # do nothing, log error and keep retrying in the next sync
            acc
        end
    end)
  end

  defp aggregate_logs(logs) do
    Enum.sum(logs)
  end
end
