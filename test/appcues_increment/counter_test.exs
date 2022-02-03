defmodule AppcuesIncrement.CounterTest do
  use AppcuesIncrement.DataCase

  alias AppcuesIncrement.Counter

  describe "create" do
    test "creates key with value" do
      key = Ecto.UUID.generate()
      assert {:ok, %{key: ^key, value: 1}} = Counter.create_or_increment(key, 1)
    end

    test "won't create key with negative value" do
      assert {:error, error} = Counter.create_or_increment("mykey", -1)
      assert %{value: ["must be greater than or equal to 0"]} = errors_on(error)
    end
  end

  describe "update" do
    test "updates key with value serially" do
      key = Ecto.UUID.generate()
      assert {:ok, %{key: ^key, value: 1}} = Counter.create_or_increment(key, 1)
      assert {:ok, %{key: ^key, value: 2}} = Counter.create_or_increment(key, 1)
    end

    test "updates key with value parallel" do
      key = Ecto.UUID.generate()

      tasks =
        for _ <- 0..3 do
          Task.async(fn ->
            Counter.create_or_increment(key, 1)
          end)
        end

      Task.await_many(tasks)

      assert %{key: ^key, value: 4} = Counter.get_by_key(key)
    end
  end

  describe "get" do
    test "get by key" do
      key = Ecto.UUID.generate()
      Counter.create_or_increment(key, 1)
      assert %{key: ^key, value: 1} = Counter.get_by_key(key)
    end
  end
end
