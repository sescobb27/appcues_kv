defmodule AppcuesIncrementWeb.KVController do
  use AppcuesIncrementWeb, :controller
  import AppcuesIncrementWeb.Plugs.RateLimit

  action_fallback(AppcuesIncrementWeb.FallbackController)

  plug :rate_limit, max_requests: 1000, interval_seconds: 5

  def create(conn, %{"key" => key, "value" => value})
      when is_binary(key) and key != "" and is_integer(value) and value >= 0 do
    # we can't measure success/error in dist strategy as it is async
    :telemetry.execute([:appcues, :api, :create_key], %{event: 1})
    module = get_sync_module()

    case module.increment(key, value) do
      :ok -> conn |> send_resp(:no_content, "") |> halt()
      {:error, _reason} = error -> error
    end
  end

  def create(_conn, _params) do
    {:error, :bad_request}
  end

  def show(conn, %{"key" => key}) when is_binary(key) and key != "" do
    case AppcuesIncrement.Counter.get_by_key(key) do
      nil ->
        # we need to know if keys are not found means because we are failing to store
        # or because users are sending bad requests
        :telemetry.execute([:appcues, :api, :key_not_found], %{event: 1})
        {:error, :not_found}

      %{key: key, value: value} ->
        conn
        |> put_status(:ok)
        |> render("show.json", key: key, value: value)
    end
  end

  defp get_sync_module do
    AppcuesIncrement.Config.appcues_strategy()
    |> Macro.camelize()
    |> then(fn strategy ->
      Module.concat([AppcuesIncrement.KV, strategy])
    end)
  end
end
