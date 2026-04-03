defmodule FrontispieceWeb.API.RunController do
  @moduledoc "JSON API for running prompts through LLM adapters."

  use FrontispieceWeb, :controller

  alias Frontispiece.LLM.Router

  action_fallback FrontispieceWeb.API.FallbackController

  @max_prompt_length 32_000

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t() | {:error, term()}
  def create(conn, %{"adapter" => adapter, "prompt" => prompt} = params)
      when is_binary(adapter) and is_binary(prompt) do
    cond do
      adapter not in Router.adapter_names() ->
        conn |> put_status(400) |> json(%{error: "unknown adapter: #{adapter}"})

      String.length(prompt) > @max_prompt_length ->
        conn
        |> put_status(400)
        |> json(%{error: "prompt too long (max #{@max_prompt_length} chars)"})

      String.trim(prompt) == "" ->
        conn |> put_status(400) |> json(%{error: "prompt cannot be empty"})

      true ->
        context = %{
          practice: to_string(params["practice"] || ""),
          episode: to_string(params["episode"] || ""),
          wells: [],
          history: []
        }

        case Router.run(adapter, prompt, context) do
          {:ok, response} ->
            json(conn, %{
              content: response.content,
              model: response.model,
              tokens_in: response.tokens_in,
              tokens_out: response.tokens_out,
              latency_ms: response.latency_ms
            })

          {:error, reason} ->
            conn |> put_status(502) |> json(%{error: inspect(reason)})
        end
    end
  end

  def create(conn, _params) do
    conn |> put_status(400) |> json(%{error: "missing required fields: adapter, prompt"})
  end
end
