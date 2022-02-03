defmodule AppcuesIncrementWeb.KVControllerTest do
  use AppcuesIncrementWeb.ConnCase

  alias AppcuesIncrement.Counter

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "post" do
    setup do
      Application.put_env(:appcues_increment, :strategy, "sync")

      on_exit(fn ->
        Application.put_env(:appcues_increment, :strategy, "dist")
      end)
    end

    test "creates key with assigned value", %{conn: conn} do
      body = %{key: "mykey", value: 1}
      conn = post(conn, Routes.kv_path(conn, :create), body)
      assert response(conn, :no_content) == ""
      assert %{key: "mykey", value: 1} = Counter.get_by_key("mykey")
    end

    test "update key serially", %{conn: conn} do
      body1 = %{key: "mykey", value: 1}
      body2 = %{key: "mykey", value: 1}

      conn
      |> post(Routes.kv_path(conn, :create), body1)
      |> post(Routes.kv_path(conn, :create), body2)

      assert %{key: "mykey", value: 2} = Counter.get_by_key("mykey")
    end

    test "update key parallel", %{conn: conn} do
      body = %{key: "mykey", value: 1}

      tasks =
        for _ <- 0..3 do
          Task.async(fn ->
            post(conn, Routes.kv_path(conn, :create), body)
          end)
        end

      Task.await_many(tasks)

      assert %{key: "mykey", value: 4} = Counter.get_by_key("mykey")
    end

    test "won't create key with negative value", %{conn: conn} do
      body = %{key: "mykey", value: -1}
      conn = post(conn, Routes.kv_path(conn, :create), body)
      assert %{"error" => %{"message" => "Bad Request."}} = json_response(conn, :bad_request)
    end

    test "won't create empty key", %{conn: conn} do
      body = %{key: "", value: 1}
      conn = post(conn, Routes.kv_path(conn, :create), body)
      assert %{"error" => %{"message" => "Bad Request."}} = json_response(conn, :bad_request)
    end
  end

  describe "show" do
    setup do
      Application.put_env(:appcues_increment, :strategy, "sync")

      on_exit(fn ->
        Application.put_env(:appcues_increment, :strategy, "dist")
      end)
    end

    test "get current key value", %{conn: conn} do
      body = %{key: "mykey", value: 1}

      conn =
        conn
        |> post(Routes.kv_path(conn, :create), body)
        |> get(Routes.kv_path(conn, :show, "mykey"))

      assert %{"mykey" => 1} = json_response(conn, :ok)
    end
  end

  describe "distributed post" do
    setup do
      Application.put_env(:appcues_increment, :strategy, "dist")

      on_exit(fn ->
        Application.put_env(:appcues_increment, :strategy, "sync")
      end)
    end

    test "creates key with assigned value", %{conn: conn} do
      body = %{key: "mykey", value: 1}
      conn = post(conn, Routes.kv_path(conn, :create), body)
      assert response(conn, :no_content) == ""
      # wait for sync to DB to happen
      assert :ok =
               wait_for(fn ->
                 case Counter.get_by_key("mykey") do
                   nil -> false
                   record -> record.key == "mykey" && record.value == 1
                 end
               end)
    end

    test "update key serially", %{conn: conn} do
      body1 = %{key: "mykey", value: 1}
      body2 = %{key: "mykey", value: 1}

      conn
      |> post(Routes.kv_path(conn, :create), body1)
      |> post(Routes.kv_path(conn, :create), body2)

      # wait for sync to DB to happen
      assert :ok =
               wait_for(fn ->
                 case Counter.get_by_key("mykey") do
                   nil -> false
                   record -> record.key == "mykey" && record.value == 2
                 end
               end)
    end

    test "update key parallel", %{conn: conn} do
      body = %{key: "mykey", value: 1}

      tasks =
        for _ <- 0..3 do
          Task.async(fn ->
            post(conn, Routes.kv_path(conn, :create), body)
          end)
        end

      Task.await_many(tasks)

      # wait for sync to DB to happen
      assert :ok =
               wait_for(fn ->
                 case Counter.get_by_key("mykey") do
                   nil -> false
                   record -> record.key == "mykey" && record.value == 4
                 end
               end)
    end
  end
end
