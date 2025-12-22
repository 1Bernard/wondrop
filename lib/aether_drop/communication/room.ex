defmodule AetherDrop.Communication.Room do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "rooms" do
    field :slug, :string
    field :is_persistent, :boolean, default: false
    field :last_active_at, :utc_datetime

    has_many :messages, AetherDrop.Communication.Message
    has_many :transfers, AetherDrop.Transfers.Transfer

    timestamps()
  end

  def changeset(room, attrs) do
    room
    |> cast(attrs, [:slug, :is_persistent, :last_active_at])
    |> validate_required([:slug])
    |> unique_constraint(:slug)
  end
end
