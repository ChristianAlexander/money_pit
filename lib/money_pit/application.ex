defmodule MoneyPit.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MoneyPitWeb.Telemetry,
      MoneyPit.Repo,
      {DNSCluster, query: Application.get_env(:money_pit, :dns_cluster_query) || :ignore},
      {Oban,
       AshOban.config(
         Application.fetch_env!(:money_pit, :ash_domains),
         Application.fetch_env!(:money_pit, Oban)
       )},
      {Phoenix.PubSub, name: MoneyPit.PubSub},
      # Start a worker by calling: MoneyPit.Worker.start_link(arg)
      # {MoneyPit.Worker, arg},
      # Start to serve requests, typically the last entry
      MoneyPitWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :money_pit]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MoneyPit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MoneyPitWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
