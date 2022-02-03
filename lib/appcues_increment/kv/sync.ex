defmodule AppcuesIncrement.KV.Sync do
  @behaviour AppcuesIncrement.KV.Strategy

  @impl AppcuesIncrement.KV.Strategy
  def increment(key, value) do
    case AppcuesIncrement.Counter.create_or_increment(key, value) do
      {:ok, _} ->
        :telemetry.execute([:appcues, :kv, :sync, :increment], %{event: 1})
        :ok

      {:error, _} = error ->
        error
    end
  end
end
