defmodule Frontispiece.Kernel.Adapter do
  @moduledoc """
  Behaviour for LLM adapters. Each adapter wraps a different coding assistant
  (Claude, Codex, Coggy, Aider, local models) behind a uniform interface.

  The kernel doesn't care which LLM runs — it sends a practice context and
  gets back a response. Adapters handle auth, rate limits, format translation.
  """

  @type context :: %{
          practice: String.t(),
          episode: String.t(),
          wells: [map()],
          history: [map()]
        }

  @type response :: %{
          content: String.t(),
          model: String.t(),
          tokens_in: non_neg_integer(),
          tokens_out: non_neg_integer(),
          latency_ms: non_neg_integer(),
          raw: map()
        }

  @doc "Send a prompt with practice context, get a response."
  @callback run(prompt :: String.t(), context()) ::
              {:ok, response()} | {:error, term()}

  @doc "Check if the adapter is currently available (auth valid, service up)."
  @callback available?() :: boolean()

  @doc "Human-readable name for UI display."
  @callback display_name() :: String.t()

  @doc "Estimated cost per 1K tokens (input + output), in USD. 0.0 for free/local."
  @callback cost_per_1k() :: float()
end
