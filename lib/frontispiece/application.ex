defmodule Frontispiece.Application do
  @moduledoc "OTP Application for Frontispiece."

  use Application

  @impl true
  @spec start(term(), term()) :: {:ok, pid()} | {:error, term()}
  def start(_type, _args) do
    children = [
      Frontispiece.Repo,
      Frontispiece.Kernel.RateLimiter,
      FrontispieceWeb.Telemetry,
      {Phoenix.PubSub, name: Frontispiece.PubSub},
      FrontispieceWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Frontispiece.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  @spec config_change(keyword(), keyword(), [atom()]) :: :ok
  def config_change(changed, _new, removed) do
    FrontispieceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
