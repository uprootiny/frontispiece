defmodule Frontispiece.Kernel.RateLimiter do
  @moduledoc """
  Token bucket rate limiter backed by ETS. Limits requests per key
  (typically client IP). GenServer handles periodic cleanup of stale buckets.
  """

  use GenServer
  require Logger

  @table :frontispiece_rate_limits
  @max_tokens 10
  @refill_interval_ms 6_000
  @cleanup_interval_ms 60_000
  @stale_after_ms 300_000

  @type status :: %{remaining: non_neg_integer(), reset_in_ms: non_neg_integer()}

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec check(String.t()) :: :ok | {:error, :rate_limited}
  @doc "Consume one token. Returns :ok or {:error, :rate_limited}."
  def check(key) do
    now = System.monotonic_time(:millisecond)
    bucket = get_or_create_bucket(key, now)

    {tokens, last_refill} = refill(bucket, now)

    if tokens > 0 do
      :ets.insert(@table, {key, tokens - 1, last_refill, now})
      :ok
    else
      :ets.insert(@table, {key, 0, last_refill, now})
      {:error, :rate_limited}
    end
  end

  @spec status(String.t()) :: status()
  @doc "Check remaining tokens and time until next refill."
  def status(key) do
    now = System.monotonic_time(:millisecond)
    bucket = get_or_create_bucket(key, now)
    {tokens, last_refill} = refill(bucket, now)
    next_refill = last_refill + @refill_interval_ms - now

    %{
      remaining: tokens,
      reset_in_ms: max(next_refill, 0)
    }
  end

  # GenServer callbacks

  @impl true
  def init(_opts) do
    :ets.new(@table, [
      :set,
      :public,
      :named_table,
      read_concurrency: true,
      write_concurrency: true
    ])

    schedule_cleanup()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    now = System.monotonic_time(:millisecond)
    cutoff = now - @stale_after_ms

    # Delete buckets not accessed recently
    :ets.foldl(
      fn {key, _tokens, _last_refill, last_access}, acc ->
        if last_access < cutoff, do: :ets.delete(@table, key)
        acc
      end,
      nil,
      @table
    )

    schedule_cleanup()
    {:noreply, state}
  end

  # Private

  defp get_or_create_bucket(key, now) do
    case :ets.lookup(@table, key) do
      [{^key, tokens, last_refill, _last_access}] ->
        {tokens, last_refill}

      [] ->
        :ets.insert(@table, {key, @max_tokens, now, now})
        {@max_tokens, now}
    end
  end

  defp refill({tokens, last_refill}, now) do
    elapsed = now - last_refill
    new_tokens_count = div(elapsed, @refill_interval_ms)

    if new_tokens_count > 0 do
      refilled = min(tokens + new_tokens_count, @max_tokens)
      new_last_refill = last_refill + new_tokens_count * @refill_interval_ms
      {refilled, new_last_refill}
    else
      {tokens, last_refill}
    end
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval_ms)
  end
end
