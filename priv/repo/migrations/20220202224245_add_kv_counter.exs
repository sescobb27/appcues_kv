defmodule AppcuesIncrement.Repo.Migrations.AddKvCounter do
  use Ecto.Migration

  def change do
    create table(:key_counters, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :key, :string, null: false
      add :value, :bigint, null: false, default: 0
      timestamps(type: :utc_datetime)
    end

    create unique_index(:key_counters, [:key])
  end
end
