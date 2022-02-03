defmodule AppcuesIncrementWeb.Plugs.RateLimit do
  import Plug.Conn, only: [put_status: 2, halt: 1]
  import Phoenix.Controller, only: [render: 3, put_view: 2]

  def rate_limit(conn, opts \\ []) do
    case check_rate(conn, opts) do
      {:ok, _count} ->
        conn

      _error ->
        :telemetry.execute([:appcues, :api, :rate_limited], %{event: 1}, conn)
        render_error(conn)
    end
  end

  defp check_rate(conn, opts) do
    interval_ms = Keyword.fetch!(opts, :interval_seconds) * 1000
    max_requests = Keyword.fetch!(opts, :max_requests)
    ExRated.check_rate(bucket_name(conn), interval_ms, max_requests)
  end

  # Bucket name should be a combination of IP address and request path.
  defp bucket_name(conn) do
    path = Enum.join(conn.path_info, "/")
    ip = conn.remote_ip |> Tuple.to_list() |> Enum.join(".")

    # E.g., "127.0.0.1:/increment"
    "#{ip}:#{path}"
  end

  defp render_error(conn) do
    conn
    |> put_status(429)
    |> put_view(AppcuesIncrementWeb.ErrorView)
    |> render("error.json", %{message: "Too Many Requests"})
    |> halt()
  end
end
