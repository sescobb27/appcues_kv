defmodule AppcuesIncrement.Counter do
  import Ecto.Query

  alias AppcuesIncrement.KeyCounter
  alias AppcuesIncrement.Repo
  alias Ecto.Multi

  def create_or_increment(key, value) do
    Multi.new()
    |> Multi.run(:get_by_key, fn _, _ ->
      query = from(kc in KeyCounter, where: kc.key == ^key, lock: "FOR UPDATE")
      {:ok, Repo.one(query)}
    end)
    |> Multi.run(:create_or_update, fn
      _, %{get_by_key: nil} ->
        %{key: key, value: value}
        |> KeyCounter.changeset()
        |> Repo.insert()

      _, %{get_by_key: record} ->
        record
        |> KeyCounter.update_changeset(%{value: record.value + value})
        |> Repo.update()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{create_or_update: record}} -> {:ok, record}
      {:error, _, error, _} -> {:error, error}
    end
  end

  def get_by_key(key) do
    query = from(kc in KeyCounter, where: kc.key == ^key)
    Repo.one(query)
  end
end
