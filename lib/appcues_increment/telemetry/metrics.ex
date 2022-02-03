defmodule AppcuesIncrement.Telemetry.Metrics do
  require Logger

  alias AppcuesIncrement.Telemetry.StatsdReporter

  # TODO: send info to DataDog, StatsD, whatever
  def handle_event([:appcues, :kv, :dist, :increment], %{event: event}, _metadata, _config) do
    StatsdReporter.increment("appcues.kv.dist.increment", 1)
    Logger.info("[TELEMETRY] received [:appcues, :kv, :dist, :increment] count: #{event}")
  end

  def handle_event([:appcues, :kv, :dist, :sync_to_db], %{duration: duration}, _metadata, _config) do
    StatsdReporter.timing("appcues.kv.dist.sync_to_db", duration)
    Logger.info("[TELEMETRY] appcues dist strategy sync to db duration: #{duration}")
  end

  def handle_event([:appcues, :kv, :sync, :increment], %{event: event}, _metadata, _config) do
    StatsdReporter.increment("appcues.kv.sync.increment", 1)
    Logger.info("[TELEMETRY] received [:appcues, :kv, :sync, :increment] count: #{event}")
  end

  def handle_event([:appcues, :api, :create_key], %{event: event}, _metadata, _config) do
    StatsdReporter.increment("appcues.api.create_key", 1)
    Logger.info("[TELEMETRY] received [:appcues, :api, :create_key] count: #{event}")
  end

  def handle_event([:appcues, :api, :key_not_found], %{event: event}, _metadata, _config) do
    StatsdReporter.increment("appcues.api.key_not_found", 1)
    Logger.info("[TELEMETRY] received [:appcues, :api, :key_not_found] count: #{event}")
  end

  def handle_event([:appcues, :api, :rate_limited], %{event: event}, metadata, _config) do
    StatsdReporter.increment("appcues.api.rate_limited", 1)

    Logger.info(
      "[TELEMETRY] received [:appcues, :api, :rate_limited] count: #{event} metadata: #{inspect(metadata)}"
    )
  end
end
