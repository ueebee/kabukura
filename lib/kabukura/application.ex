defmodule Kabukura.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      KabukuraWeb.Telemetry,
      Kabukura.Repo,
      {DNSCluster, query: Application.get_env(:kabukura, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Kabukura.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Kabukura.Finch},
      # Start a worker by calling: Kabukura.Worker.start_link(arg)
      # {Kabukura.Worker, arg},
      # Start to serve requests, typically the last entry
      KabukuraWeb.Endpoint,
      Kabukura.DataSources.JQuants.TokenStore
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Kabukura.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    KabukuraWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
