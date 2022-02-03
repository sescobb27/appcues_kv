defmodule AppcuesIncrementWeb.Plugs.RateLimitTest do
  use AppcuesIncrementWeb.ConnCase

  @rate_limit_options [max_requests: 1, interval_seconds: 60]

  setup do
    bucket_name = "127.0.0.1:/api/increment"

    on_exit(fn ->
      ExRated.delete_bucket(bucket_name)
    end)
  end

  describe "rate_limit" do
    test "rate limit", %{conn: conn} do
      body = %{key: "something", value: 1}

      conn1 =
        conn
        |> bypass_through(AppcuesIncrementWeb.Router, :api)
        |> post(Routes.kv_path(conn, :create), body)
        |> AppcuesIncrementWeb.Plugs.RateLimit.rate_limit(@rate_limit_options)

      refute conn1.halted

      conn2 =
        conn
        |> bypass_through(AppcuesIncrementWeb.Router, :api)
        |> post(Routes.kv_path(conn, :create), body)
        |> AppcuesIncrementWeb.Plugs.RateLimit.rate_limit(@rate_limit_options)

      assert conn2.halted
      assert %{"error" => %{"message" => "Too Many Requests"}} == json_response(conn2, 429)
    end
  end
end
