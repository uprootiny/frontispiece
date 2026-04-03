defmodule Frontispiece.LLM.Claude do
  @moduledoc "Claude adapter — Anthropic Messages API."
  @behaviour Frontispiece.Kernel.Adapter

  @request_timeout_ms 90_000

  @impl true
  @spec run(String.t(), Frontispiece.Kernel.Adapter.context()) ::
          {:ok, Frontispiece.Kernel.Adapter.response()} | {:error, term()}
  def run(prompt, context) do
    body = %{
      model: model(),
      max_tokens: 4096,
      system: system_prompt(context),
      messages: build_messages(context.history, prompt)
    }

    case Req.post(endpoint(),
           json: body,
           headers: headers(),
           receive_timeout: @request_timeout_ms,
           retry: false
         ) do
      {:ok, %{status: 200, body: %{"content" => [%{"text" => text} | _]} = raw}} ->
        {:ok,
         %{
           content: text,
           model: raw["model"],
           tokens_in: get_in(raw, ["usage", "input_tokens"]) || 0,
           tokens_out: get_in(raw, ["usage", "output_tokens"]) || 0,
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
  def available?, do: api_key() != nil

  @impl true
  @spec display_name() :: String.t()
  def display_name, do: "Claude"

  @impl true
  @spec cost_per_1k() :: float()
  def cost_per_1k, do: 0.015

  defp endpoint, do: "https://api.anthropic.com/v1/messages"
  defp model, do: System.get_env("CLAUDE_MODEL") || "claude-sonnet-4-20250514"
  defp api_key, do: System.get_env("ANTHROPIC_API_KEY")

  defp headers do
    [
      {"x-api-key", api_key()},
      {"anthropic-version", "2023-06-01"},
      {"content-type", "application/json"}
    ]
  end

  defp system_prompt(context) do
    "You are demonstrating the practice '#{context.practice}' " <>
      "in the context of '#{context.episode}'. " <>
      "Be concrete, show exact commands and code, stay focused on the single move being demonstrated."
  end

  defp build_messages(history, prompt) do
    prior = Enum.map(history, fn h -> %{role: h.role, content: h.content} end)
    prior ++ [%{role: "user", content: prompt}]
  end
end
