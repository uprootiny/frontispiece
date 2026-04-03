defmodule Frontispiece.LLM.Router do
  @moduledoc """
  Routes requests to LLM adapters. Supports explicit selection, fallback
  chains, and parallel fan-out for comparison runs.

  The router is the swap point — change which LLM handles a practice
  without touching any UI or kernel code.
  """

  alias Frontispiece.Kernel.Adapter
  alias Frontispiece.LLM.{Claude, Codex, Coggy, Local}
  require Logger

  @adapters %{
    "claude" => Claude,
    "codex" => Codex,
    "coggy" => Coggy,
    "local" => Local
  }

  @default_chain ["claude", "codex", "local", "coggy"]
  @run_timeout_ms 120_000

  @type adapter_result :: {:ok, Adapter.response()} | {:error, term()}

  @spec run(String.t(), String.t(), Adapter.context()) :: adapter_result()
  @doc "Run a prompt through a specific adapter by name."
  def run(adapter_name, prompt, context) when is_binary(adapter_name) do
    case Map.get(@adapters, adapter_name) do
      nil -> {:error, :unknown_adapter}
      mod -> safe_timed_run(mod, prompt, context)
    end
  end

  @spec run_with_fallback(String.t(), Adapter.context(), [String.t()]) :: adapter_result()
  @doc "Run through the fallback chain until one succeeds."
  def run_with_fallback(prompt, context, chain \\ @default_chain) do
    Enum.reduce_while(chain, {:error, :all_adapters_failed}, fn name, _acc ->
      case Map.get(@adapters, name) do
        nil ->
          {:cont, {:error, :all_adapters_failed}}

        mod ->
          if mod.available?() do
            case safe_timed_run(mod, prompt, context) do
              {:ok, response} -> {:halt, {:ok, Map.put(response, :adapter, name)}}
              {:error, _} -> {:cont, {:error, :all_adapters_failed}}
            end
          else
            {:cont, {:error, :all_adapters_failed}}
          end
      end
    end)
  end

  @spec run_parallel(String.t(), Adapter.context(), [String.t()]) :: %{
          String.t() => adapter_result()
        }
  @doc "Fan out to multiple adapters in parallel for side-by-side comparison."
  def run_parallel(prompt, context, adapter_names \\ Map.keys(@adapters)) do
    adapter_names
    |> Enum.filter(fn name ->
      case Map.get(@adapters, name) do
        nil -> false
        mod -> mod.available?()
      end
    end)
    |> Task.async_stream(
      fn name ->
        mod = Map.fetch!(@adapters, name)
        {name, safe_timed_run(mod, prompt, context)}
      end,
      max_concurrency: 4,
      timeout: @run_timeout_ms,
      on_timeout: :kill_task
    )
    |> Enum.reduce(%{}, fn
      {:ok, {name, result}}, acc ->
        Map.put(acc, name, result)

      {:exit, reason}, acc ->
        Logger.warning("Adapter task exited: #{inspect(reason)}")
        acc
    end)
  end

  @spec list_adapters() :: [map()]
  @doc "List all registered adapters with availability status."
  def list_adapters do
    Enum.map(@adapters, fn {name, mod} ->
      %{
        name: name,
        display_name: mod.display_name(),
        available: safe_available?(mod),
        cost_per_1k: mod.cost_per_1k()
      }
    end)
  end

  @spec adapter_names() :: [String.t()]
  @doc "List all registered adapter names."
  def adapter_names, do: Map.keys(@adapters)

  # Wraps adapter.run in timing + exception safety
  defp safe_timed_run(mod, prompt, context) do
    start = System.monotonic_time(:millisecond)

    case mod.run(prompt, context) do
      {:ok, response} ->
        elapsed = System.monotonic_time(:millisecond) - start
        {:ok, %{response | latency_ms: elapsed}}

      {:error, _} = error ->
        error
    end
  rescue
    exception ->
      Logger.error("Adapter #{inspect(mod)} raised: #{Exception.message(exception)}")
      {:error, {:adapter_exception, Exception.message(exception)}}
  end

  defp safe_available?(mod) do
    mod.available?()
  rescue
    _ -> false
  end
end
