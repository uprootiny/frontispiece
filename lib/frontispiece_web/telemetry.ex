defmodule FrontispieceWeb.Telemetry do
  @moduledoc "Telemetry supervisor for Frontispiece."

  use Supervisor
  import Telemetry.Metrics

  @spec start_link(term()) :: Supervisor.on_start()
  def start_link(arg), do: Supervisor.start_link(__MODULE__, arg, name: __MODULE__)

  @impl true
  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @spec metrics() :: [Telemetry.Metrics.t()]
  def metrics do
    [
      summary("phoenix.endpoint.start.system_time", unit: {:native, :millisecond}),
      summary("phoenix.endpoint.stop.duration", unit: {:native, :millisecond}),
      summary("phoenix.router_dispatch.stop.duration", unit: {:native, :millisecond}),
      summary("phoenix.live_view.mount.stop.duration", unit: {:native, :millisecond}),
      summary("phoenix.live_view.handle_event.stop.duration", unit: {:native, :millisecond})
    ]
  end

  defp periodic_measurements, do: []
end
