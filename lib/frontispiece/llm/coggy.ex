defmodule Frontispiece.LLM.Coggy do
  @moduledoc """
  Coggy adapter — talks to the Coggy cognitive engine on hyle:8421.
  Routes through Coggy's LLM bridge which dispatches to OpenRouter models.
  """
  @behaviour Frontispiece.Kernel.Adapter

  @request_timeout_ms 60_000
  @health_timeout_ms 3_000

  @impl true
  @spec run(String.t(), Frontispiece.Kernel.Adapter.context()) ::
          {:ok, Frontispiece.Kernel.Adapter.response()} | {:error, term()}
  def run(prompt, context) do
    body = %{
      text: prompt,
      context: "#{context.practice}/#{context.episode}",
      source: "frontispiece"
    }

    case Req.post("#{endpoint()}/api/bridge/compile",
           json: body,
           receive_timeout: @request_timeout_ms,
           retry: false
         ) do
      {:ok, %{status: 200, body: %{"result" => text} = raw}} ->
        {:ok,
         %{
           content: text,
           model: raw["model"] || "coggy-bridge",
           tokens_in: 0,
           tokens_out: 0,
           latency_ms: raw["elapsed_ms"] || 0,
           raw: raw
         }}

      {:ok, %{status: status, body: resp_body}} ->
        {:error, {:api_error, status, resp_body}}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, {:transport, reason}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  @spec available?() :: boolean()
  def available? do
    case Req.get("#{endpoint()}/api/metrics",
           receive_timeout: @health_timeout_ms,
           retry: false
         ) do
      {:ok, %{status: 200}} -> true
      _ -> false
    end
  rescue
    Req.TransportError -> false
  end

  @impl true
  @spec display_name() :: String.t()
  def display_name, do: "Coggy"

  @impl true
  @spec cost_per_1k() :: float()
  def cost_per_1k, do: 0.0

  defp endpoint, do: System.get_env("COGGY_URL") || "http://173.212.203.211:8421"
end
