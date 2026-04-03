defmodule FrontispieceWeb.StatsLive do
  @moduledoc """
  Engagement dashboard — which episodes get copied, which get skipped,
  which adapters are used most. The learning surface.
  """
  use FrontispieceWeb, :live_view

  alias Frontispiece.Kernel.{Engagement, Sequencer}
  alias Frontispiece.LLM.Router

  @impl true
  def mount(_params, _session, socket) do
    practices = Sequencer.all_practices()
    top_copied = Engagement.top_copied(20)
    adapters = Router.list_adapters()

    {:ok,
     assign(socket,
       practices: practices,
       top_copied: top_copied,
       adapters: adapters,
       page_title: "Stats"
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-black text-white">
      <header class="sticky top-0 z-50 bg-black/90 backdrop-blur-sm border-b border-white/10 safe-top">
        <div class="px-4 py-3 flex items-center gap-3">
          <a href="/" class="text-white/50 hover:text-white text-lg">←</a>
          <h1 class="text-sm font-mono font-semibold">Stats</h1>
        </div>
      </header>

      <main class="px-4 pt-6 pb-24 max-w-2xl mx-auto space-y-8">
        <!-- Adapter availability -->
        <section>
          <h2 class="text-xs font-mono text-white/40 uppercase tracking-wider mb-3">Adapters</h2>
          <div class="space-y-2">
            <div
              :for={a <- @adapters}
              class="flex items-center justify-between py-2 px-3 rounded-lg bg-white/5"
            >
              <div class="flex items-center gap-2">
                <span class={"w-2 h-2 rounded-full " <> if(a.available, do: "bg-green-400", else: "bg-white/20")} />
                <span class="text-sm font-mono">{a.display_name}</span>
              </div>
              <span class="text-xs font-mono text-white/30">
                ${:erlang.float_to_binary(a.cost_per_1k, decimals: 3)}/1k
              </span>
            </div>
          </div>
        </section>
        
    <!-- Practices overview -->
        <section>
          <h2 class="text-xs font-mono text-white/40 uppercase tracking-wider mb-3">Practices</h2>
          <div class="space-y-2">
            <div
              :for={p <- @practices}
              class="flex items-center justify-between py-2 px-3 rounded-lg bg-white/5"
            >
              <span class="text-sm font-mono">{p.name}</span>
              <span class="text-xs font-mono text-white/30 tabular-nums">
                {length(p.episodes)} episodes
              </span>
            </div>
          </div>
        </section>
        
    <!-- Top copied -->
        <section>
          <h2 class="text-xs font-mono text-white/40 uppercase tracking-wider mb-3">Most Copied</h2>
          <div :if={@top_copied == []} class="text-sm text-white/20 font-mono py-4">
            No copies yet — start exploring practices
          </div>
          <div
            :for={item <- @top_copied}
            class="flex items-center justify-between py-2 px-3 rounded-lg bg-white/5 mb-2"
          >
            <span class="text-sm font-mono text-white/70">{item.episode_title}</span>
            <span class="text-xs font-mono tabular-nums text-white/40">{item.copies} copies</span>
          </div>
        </section>
      </main>
    </div>
    """
  end
end
