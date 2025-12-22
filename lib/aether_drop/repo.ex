defmodule AetherDrop.Repo do
  use Ecto.Repo,
    otp_app: :aether_drop,
    adapter: Ecto.Adapters.Postgres
end
