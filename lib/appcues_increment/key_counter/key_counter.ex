defmodule AppcuesIncrement.KeyCounter do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "key_counters" do
    field :key, :string
    field :value, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(schema \\ %__MODULE__{}, attrs) do
    schema
    |> cast(attrs, [:key, :value])
    |> validate_required([:key, :value])
    |> validate_number(:value, greater_than_or_equal_to: 0)
  end

  @doc false
  def update_changeset(schema \\ %__MODULE__{}, attrs) do
    schema
    |> cast(attrs, [:value])
    |> validate_number(:value, greater_than_or_equal_to: 0)
  end
end
