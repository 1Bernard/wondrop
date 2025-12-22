defmodule AetherDrop.Communication.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field :content, :string
    field :kind, Ecto.Enum, values: [:chat, :clipboard, :system]

    belongs_to :room, AetherDrop.Communication.Room
    belongs_to :device, AetherDrop.Identity.Device

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :kind, :room_id, :device_id])
    |> validate_required([:kind, :room_id])
  end
end
