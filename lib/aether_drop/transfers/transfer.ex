defmodule AetherDrop.Transfers.Transfer do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "transfers" do
    field :filename, :string
    field :file_size_bytes, :integer
    field :status, Ecto.Enum, values: [:pending, :completed, :failed, :cancelled]
    field :is_relayed, :boolean, default: false

    belongs_to :room, AetherDrop.Communication.Room
    belongs_to :sender, AetherDrop.Identity.Device
    belongs_to :receiver, AetherDrop.Identity.Device

    timestamps()
  end

  def changeset(transfer, attrs) do
    transfer
    |> cast(attrs, [
      :filename,
      :file_size_bytes,
      :status,
      :is_relayed,
      :room_id,
      :sender_id,
      :receiver_id
    ])
    |> validate_required([:filename, :status, :room_id, :sender_id])
  end
end
