defmodule Frontispiece.LLM.Codex do
  @moduledoc "OpenAI Codex / GPT adapter."
  @behaviour Frontispiece.Kernel.Adapter

  @request_timeout_ms 90_000

  @impl true
  @spec run(String.t(), Frontispiece.Kernel.Adapter.context()) ::
          {:ok, Frontispiece.Kernel.Adapter.response()} | {:error, term()}
  def run(prompt, context) do
    body = %{
      model: model(),
      messages: build_messages(context, prompt),
      max_tokens: 4096
    }

    case Req.post(endpoint(),
           json: body,
           headers: headers(),
           receive_timeout: @request_timeout_ms,
           retry: false
         ) do
      {:ok,
       %{status: 200, body: %{"choices" => [%{"message" => %{"content" => text}} | _]} = raw}} ->
        {:ok,
         %{
           content: text,
           model: raw["model"],
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
  def available?, do: api_key() != nil

  @impl true
  @spec display_name() :: String.t()
  def display_name, do: "Codex"

  @impl true
  @spec cost_per_1k() :: float()
  def cost_per_1k, do: 0.01

  defp endpoint, do: "https://api.openai.com/v1/chat/completions"
  defp model, do: System.get_env("OPENAI_MODEL") || "gpt-4o"
  defp api_key, do: System.get_env("OPENAI_API_KEY")

  defp headers do
    [
      {"authorization", "Bearer #{api_key()}"},
      {"content-type", "application/json"}
    ]
  end

  defp build_messages(context, prompt) do
    system = %{
      role: "system",
      content: "Demonstrating '#{context.practice}' in context '#{context.episode}'."
    }

    prior = Enum.map(context.history, &%{role: &1.role, content: &1.content})
    [system | prior] ++ [%{role: "user", content: prompt}]
  end
end
