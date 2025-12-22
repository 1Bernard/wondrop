defmodule AetherDrop.Identity.Device do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "devices" do
    field :name, :string, default: "Anonymous Device"
    field :fingerprint, :string
    field :last_seen_at, :utc_datetime
    field :preferences, :map, default: %{}

    has_many :messages, AetherDrop.Communication.Message
    has_many :sent_transfers, AetherDrop.Transfers.Transfer, foreign_key: :sender_id
    has_many :received_transfers, AetherDrop.Transfers.Transfer, foreign_key: :receiver_id

    timestamps()
  end

  def changeset(device, attrs) do
    device
    |> cast(attrs, [:name, :fingerprint, :last_seen_at, :preferences])
    |> validate_required([:fingerprint])
    |> unique_constraint(:fingerprint)
  end
end
