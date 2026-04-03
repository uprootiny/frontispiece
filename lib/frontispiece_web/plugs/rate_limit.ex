defmodule FrontispieceWeb.Plugs.RateLimit do
  @moduledoc "Plug that rate limits requests using the token bucket RateLimiter."

  import Plug.Conn
  alias Frontispiece.Kernel.RateLimiter

  @behaviour Plug

  @impl true
  @spec init(keyword()) :: keyword()
  def init(opts), do: opts

  @impl true
  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, _opts) do
    key = client_key(conn)
    status = RateLimiter.status(key)

    conn =
      conn
      |> put_resp_header("x-ratelimit-remaining", to_string(status.remaining))
      |> put_resp_header("x-ratelimit-reset", to_string(status.reset_in_ms))

    case RateLimiter.check(key) do
      :ok ->
        conn

      {:error, :rate_limited} ->
        retry_after = max(div(status.reset_in_ms, 1000), 1)

        conn
        |> put_resp_header("retry-after", to_string(retry_after))
        |> put_resp_content_type("application/json")
        |> send_resp(429, Jason.encode!(%{error: "rate limited", retry_after: retry_after}))
        |> halt()
    end
  end

  defp client_key(conn) do
    conn.remote_ip |> :inet.ntoa() |> to_string()
  end
end
