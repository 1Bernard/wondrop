defmodule AetherDrop.Repo.Migrations.CreateInitialSchema do
  use Ecto.Migration

  def change do
    # DEVICES
    create table(:devices, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :fingerprint, :string, null: false
      add :last_seen_at, :utc_datetime
      add :preferences, :map, default: "{}"

      timestamps()
    end

    create unique_index(:devices, [:fingerprint])

    # ROOMS
    create table(:rooms, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :slug, :string, null: false
      add :is_persistent, :boolean, default: false
      add :last_active_at, :utc_datetime

      timestamps()
    end

    create unique_index(:rooms, [:slug])

    # MESSAGES
    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content, :text
      add :kind, :string, null: false

      add :room_id, references(:rooms, on_delete: :delete_all, type: :binary_id)
      add :device_id, references(:devices, on_delete: :nilify_all, type: :binary_id)

      timestamps()
    end

    create index(:messages, [:room_id])

    # TRANSFERS
    create table(:transfers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string
      add :file_size_bytes, :bigint
      add :status, :string
      add :is_relayed, :boolean, default: false

      add :room_id, references(:rooms, on_delete: :delete_all, type: :binary_id)
      add :sender_id, references(:devices, on_delete: :nilify_all, type: :binary_id)
      add :receiver_id, references(:devices, on_delete: :nilify_all, type: :binary_id)

      timestamps()
    end

    create index(:transfers, [:room_id])
  end
end
