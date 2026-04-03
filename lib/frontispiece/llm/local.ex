defmodule Frontispiece.LLM.Local do
  @moduledoc """
  Local model adapter — talks to any OpenAI-compatible local server
  (llama.cpp, ollama, LM Studio, vLLM). Zero cost, full privacy.
  """
  @behaviour Frontispiece.Kernel.Adapter

  @request_timeout_ms 120_000
  @health_timeout_ms 2_000

  @impl true
  @spec run(String.t(), Frontispiece.Kernel.Adapter.context()) ::
          {:ok, Frontispiece.Kernel.Adapter.response()} | {:error, term()}
  def run(prompt, context) do
    body = %{
      model: model(),
      messages: [
        %{
          role: "system",
          content: "Practice: #{context.practice}, Episode: #{context.episode}"
        },
        %{role: "user", content: prompt}
      ],
      max_tokens: 4096
    }

    case Req.post("#{endpoint()}/v1/chat/completions",
           json: body,
           receive_timeout: @request_timeout_ms,
           retry: false
         ) do
      {:ok,
       %{status: 200, body: %{"choices" => [%{"message" => %{"content" => text}} | _]} = raw}} ->
        {:ok,
         %{
           content: text,
           model: raw["model"] || "local",
           tokens_in: get_in(raw, ["usage", "prompt_tokens"]) || 0,
           tokens_out: get_in(raw, ["usage", "completion_tokens"]) || 0,
           latency_ms: 0,
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
    case Req.get("#{endpoint()}/v1/models",
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
  def display_name, do: "Local"

  @impl true
  @spec cost_per_1k() :: float()
  def cost_per_1k, do: 0.0

  defp endpoint, do: System.get_env("LOCAL_LLM_URL") || "http://localhost:8080"
  defp model, do: System.get_env("LOCAL_LLM_MODEL") || "default"
end
