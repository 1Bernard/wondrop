defmodule AetherDropWeb.Presence do
  use Phoenix.Presence,
    otp_app: :aether_drop,
    pubsub_server: AetherDrop.PubSub
end
