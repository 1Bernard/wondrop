defmodule AetherDrop.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AetherDropWeb.Telemetry,
      AetherDrop.Repo,
      {DNSCluster, query: Application.get_env(:aether_drop, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AetherDrop.PubSub},
      AetherDropWeb.Presence,
      # Start a worker by calling: AetherDrop.Worker.start_link(arg)
      # {AetherDrop.Worker, arg},
      # Start to serve requests, typically the last entry
      AetherDropWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AetherDrop.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AetherDropWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
