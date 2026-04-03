defmodule FrontispieceWeb.PracticeLive do
  @moduledoc """
  Home screen: 5-level progressive architecture disclosure + practice cards.
  Each level builds on the previous. Users can enter at any depth.
  """
  use FrontispieceWeb, :live_view

  alias Frontispiece.Kernel.Sequencer

  @impl true
  def mount(_params, _session, socket) do
    practices = Sequencer.all_practices()

    level =
      case socket.assigns[:uri] do
        %{fragment: "level-" <> n} -> n
        _ -> "1"
      end

    {:ok, assign(socket, practices: practices, active_level: level, page_title: "Frontispiece")}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    level =
      case URI.parse(uri).fragment do
        "level-" <> n when n in ~w(1 2 3 4 5 tree) -> n
        _ -> socket.assigns[:active_level] || "1"
      end

    {:noreply, assign(socket, active_level: level)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-black text-white">
      <header class="sticky top-0 z-50 bg-black/90 backdrop-blur-sm border-b border-white/10 safe-top">
        <div class="px-4 py-3">
          <h1 class="text-lg font-mono font-semibold tracking-tight">frontispiece</h1>
          <p class="text-xs text-white/40 font-mono mt-0.5">
            practice-storytelling engine for coding assistants
          </p>
        </div>

        <nav
          id="level-nav"
          role="tablist"
          aria-label="Architecture levels"
          class="flex gap-1 px-4 pb-2 overflow-x-auto"
          phx-hook="LevelNav"
        >
          <button
            :for={
              {label, id} <- [
                {"Metaphor", "1"},
                {"Subsystems", "2"},
                {"Pipelines", "3"},
                {"Stack", "4"},
                {"Formal", "5"},
                {"Tree", "tree"}
              ]
            }
            role="tab"
            aria-selected={to_string(@active_level == id)}
            aria-controls={"level-#{id}"}
            phx-click="set_level"
            phx-value-level={id}
            class={"text-xs font-mono px-3 py-1.5 rounded-full transition-colors touch-manipulation shrink-0 " <>
              if(@active_level == id,
                do: "bg-white/20 text-white",
                else: "bg-white/5 text-white/40 hover:text-white/60"
              )}
          >
            {label}
          </button>
        </nav>
      </header>

      <main class="px-4 pt-6 pb-32 max-w-2xl mx-auto">
        <!-- L1: Metaphor — why this exists -->
        <section
          :if={@active_level == "1"}
          id="level-1"
          role="tabpanel"
          aria-labelledby="tab-1"
          class="space-y-6 animate-in"
        >
          <div class="space-y-4">
            <h2 class="text-xl font-semibold">What if prompts were practiced, not written?</h2>
            <p class="text-sm text-white/70 leading-relaxed">
              A musician doesn't read about scales. They play the same scale in twelve keys
              until their fingers know the shape. A surgeon doesn't memorize procedures from
              a textbook. They watch the same operation done twenty times, each time on a
              different body, until the <em class="text-white/80">judgment</em>
              is trained — not just the technique.
            </p>
            <p class="text-sm text-white/50 leading-relaxed italic">
              So why do we treat prompts like recipes? Copy this text, paste it, get your answer.
              That works once. But the next problem is shaped differently, and the recipe doesn't transfer.
            </p>
            <p class="text-sm text-white/70 leading-relaxed">
              Frontispiece is a practice room. Each practice is a
              <strong class="text-white/90">move</strong>
              — paste-parse-dispatch,
              the handoff, parallel agents. You see the same move land in 5 different contexts.
              The details change. The shape stays. By the third variation you stop reading and
              start recognizing. By the fifth, you reach for it without thinking.
            </p>
            <div class="rounded-xl bg-white/5 border border-white/10 p-4 space-y-2">
              <p class="font-mono text-sm text-white/60">practice = a move you can practice</p>
              <p class="font-mono text-sm text-white/60">episode = one context where it lands</p>
              <p class="font-mono text-sm text-white/60">
                well = the exact prompt you copy out and use right now
              </p>
            </div>
            <p class="text-xs text-white/40 leading-relaxed">
              Every well is a real prompt that solved a real problem. Tap to copy. Paste into
              your terminal. Modify for your context. The prompts work — but more importantly,
              the <em>shape</em>
              of the prompts transfers to problems we haven't written episodes for yet.
            </p>
          </div>

          <div class="pt-4 border-t border-white/5">
            <p class="text-xs text-white/30 font-mono mb-4">Practices available now:</p>
            <.practice_cards practices={@practices} />
          </div>
        </section>
        
    <!-- L2: Subsystems — what exists -->
        <section
          :if={@active_level == "2"}
          id="level-2"
          role="tabpanel"
          aria-labelledby="tab-2"
          class="space-y-6 animate-in"
        >
          <h2 class="text-xl font-semibold">What exists</h2>

          <div class="space-y-3">
            <.subsystem
              name="Kernel"
              desc="Practice/Episode/Well schemas, sequencing, engagement tracking, markdown rendering, content loading from disk. The thick middleware — all business logic lives here."
            />
            <.subsystem
              name="LLM Router"
              desc="Swappable adapters (Claude, Codex, Coggy, local). Fallback chains, parallel fan-out for comparison. 90s timeouts, exception safety, rate limiting."
            />
            <.subsystem
              name="LiveView Surface"
              desc="iPhone-first. Swipe between episodes, tap-to-copy wells, rerun prompts through different LLMs. Dark, dense, monospace. Server-rendered — no JS framework."
            />
            <.subsystem
              name="JSON API"
              desc="Same kernel, different projection. TUI connects here. Health checks, engagement tracking, adapter listing, prompt execution."
            />
            <.subsystem
              name="TUI"
              desc="Rust/Ratatui terminal client. j/k navigation, y to yank wells. Connects to the API — same data, different surface."
            />
            <.subsystem
              name="Content"
              desc="Practices authored as markdown with YAML frontmatter + TOML metadata. mix frontispiece.author scaffolds new ones. Seeds load from priv/content/ on startup."
            />
          </div>
        </section>
        
    <!-- L3: Pipelines — how data flows -->
        <section
          :if={@active_level == "3"}
          id="level-3"
          role="tabpanel"
          aria-labelledby="tab-3"
          class="space-y-6 animate-in"
        >
          <h2 class="text-xl font-semibold">How data flows</h2>

          <div class="rounded-xl bg-white/5 border border-white/10 p-4 font-mono text-xs text-white/60 space-y-3 overflow-x-auto">
            <p class="text-white/40">Authoring pipeline:</p>
            <pre class="whitespace-pre">markdown + frontmatter
    → ContentLoader.parse_markdown_with_frontmatter/1
    → Repo.transaction (batch insert)
    → Practice → Episode → [Well] + [Media]
    → SQLite</pre>

            <p class="text-white/40 pt-2">Reading pipeline:</p>
            <pre class="whitespace-pre">Sequencer.journey(practice_id)
    → episodes with wells + media preloaded
    → Markdown.render/1 (ETS-cached, XSS-sanitized)
    → LiveView assigns → HEEx template
    → server-rendered HTML over WebSocket</pre>

            <p class="text-white/40 pt-2">Rerun pipeline:</p>
            <pre class="whitespace-pre">user taps "rerun →" on a prompt well
    → EpisodeLive pushes Task
    → Router.run(adapter, prompt, context)
    → Adapter.run/2 (Req.post with timeout)
    → rerun_result message sent back to LV
    → result rendered inline</pre>

            <p class="text-white/40 pt-2">Engagement pipeline:</p>
            <pre class="whitespace-pre">view / copy / rerun / skip events
    → Engagement.track/1 (debounced: 2s window)
    → SQLite engagements table
    → top_copied/1, episode_stats/1, practice_stats/1
    → StatsLive dashboard</pre>
          </div>
        </section>
        
    <!-- L4: Stack — which APIs implement it -->
        <section
          :if={@active_level == "4"}
          id="level-4"
          role="tabpanel"
          aria-labelledby="tab-4"
          class="space-y-6 animate-in"
        >
          <h2 class="text-xl font-semibold">Implementation</h2>

          <div class="space-y-2 text-sm">
            <.stack_row label="Runtime" value="Elixir 1.18 + Erlang/OTP 27 + Phoenix 1.8" />
            <.stack_row label="UI" value="Phoenix LiveView 1.1 — server-rendered, WebSocket push" />
            <.stack_row
              label="CSS"
              value="Tailwind 3.4 + @tailwindcss/typography — mobile-first, dark"
            />
            <.stack_row label="Storage" value="SQLite via ecto_sqlite3 — single file, zero ops" />
            <.stack_row label="HTTP" value="Bandit (pure Elixir HTTP/2 server)" />
            <.stack_row
              label="LLM calls"
              value="Req with 90s timeout, retry: false, transport error handling"
            />
            <.stack_row
              label="Rate limit"
              value="GenServer + ETS token bucket, 10 req/min per IP on /api/run"
            />
            <.stack_row
              label="Markdown"
              value="Earmark → ETS cache (phash2 key) → regex XSS sanitizer"
            />
            <.stack_row
              label="Content"
              value="YAML frontmatter + minimal TOML parser (multiline, escapes)"
            />
            <.stack_row
              label="PWA"
              value="Service worker — cache-first assets, network-first API, offline shell"
            />
            <.stack_row
              label="TUI"
              value="Rust + Ratatui + reqwest — j/k nav, y yank, talks to /api"
            />
            <.stack_row
              label="Tests"
              value="51 tests (schema, markdown, content loader, API, LiveView)"
            />
            <.stack_row
              label="Lint"
              value="mix lint = format --check-formatted + credo --strict + test"
            />
          </div>
        </section>
        
    <!-- L5: Formal — invariants and abstractions -->
        <section
          :if={@active_level == "5"}
          id="level-5"
          role="tabpanel"
          aria-labelledby="tab-5"
          class="space-y-6 animate-in"
        >
          <h2 class="text-xl font-semibold">Invariants</h2>

          <div class="rounded-xl bg-white/5 border border-white/10 p-4 font-mono text-xs text-white/60 space-y-4 overflow-x-auto">
            <div>
              <p class="text-white/40">Content model:</p>
              <pre class="whitespace-pre">Practice ──1:N──▸ Episode ──1:N──▸ Well
                              ──1:N──▸ Media
                              ──1:N──▸ Engagement</pre>
            </div>

            <div>
              <p class="text-white/40">Adapter contract:</p>
              <pre class="whitespace-pre">∀ adapter ∈ [Claude, Codex, Coggy, Local]:
    adapter.run(prompt, ctx) → ok(response) | error(reason)
    adapter.available?()     → boolean
    adapter.cost_per_1k()    → float ≥ 0.0</pre>
            </div>

            <div>
              <p class="text-white/40">Engagement debounce:</p>
              <pre class="whitespace-pre">∀ (episode_id, event):
    track(e) at time t → skip if ∃ record where
    record.episode_id = e.episode_id ∧
    record.event = e.event ∧
    t - record.inserted_at &lt; 2000ms</pre>
            </div>

            <div>
              <p class="text-white/40">Rate limit (token bucket):</p>
              <pre class="whitespace-pre">∀ key:
    tokens(key, t) = min(max_tokens,
    tokens(key, t₀) + ⌊(t - t₀) / refill_interval⌋)
    check(key) → :ok        if tokens > 0, decrement
             → :rate_limited  otherwise</pre>
            </div>

            <div>
              <p class="text-white/40">Recovery invariant:</p>
              <pre class="whitespace-pre">crash_loss ≤ last_uncommitted_engagement
    (SQLite WAL mode, content is static on disk)</pre>
            </div>

            <div>
              <p class="text-white/40">Surface independence:</p>
              <pre class="whitespace-pre">∀ surface ∈ [LiveView, JSON API, TUI]:
    surface reads Kernel — Kernel never reads surface
    swap(surface) preserves all state and statistics</pre>
            </div>
          </div>
        </section>
        
    <!-- Composition tree — re-summarizes after exploration -->
        <section
          :if={@active_level == "tree"}
          id="level-tree"
          role="tabpanel"
          aria-labelledby="tab-tree"
          class="space-y-6 animate-in"
        >
          <h2 class="text-xl font-semibold">Composition</h2>

          <div class="rounded-xl bg-white/5 border border-white/10 p-4 font-mono text-xs text-white/60 overflow-x-auto">
            <pre class="whitespace-pre">frontispiece
    ├── kernel/                    <span class="text-white/30"># thick middleware</span>
    │   ├── Practice → Episode → Well, Media
    │   ├── Sequencer              <span class="text-white/30"># ordering + progress</span>
    │   ├── Engagement             <span class="text-white/30"># debounced tracking</span>
    │   ├── ContentLoader          <span class="text-white/30"># markdown → DB</span>
    │   ├── Markdown               <span class="text-white/30"># cached + sanitized</span>
    │   └── RateLimiter            <span class="text-white/30"># ETS token bucket</span>
    ├── llm/                       <span class="text-white/30"># swappable backends</span>
    │   ├── Adapter behaviour
    │   ├── Claude | Codex | Coggy | Local
    │   └── Router                 <span class="text-white/30"># select / fallback / fan-out</span>
    ├── surfaces/                  <span class="text-white/30"># ephemeral projections</span>
    │   ├── LiveView (iPhone-first)
    │   │   ├── PracticeLive       <span class="text-white/30"># this page</span>
    │   │   ├── JourneyLive        <span class="text-white/30"># swipe episodes</span>
    │   │   ├── EpisodeLive        <span class="text-white/30"># deep view + rerun</span>
    │   │   ├── CompareLive        <span class="text-white/30"># multi-LLM fan-out</span>
    │   │   └── StatsLive          <span class="text-white/30"># engagement dashboard</span>
    │   ├── JSON API               <span class="text-white/30"># /api/* for TUI + others</span>
    │   └── TUI (Rust/Ratatui)     <span class="text-white/30"># terminal surface</span>
    └── content/                   <span class="text-white/30"># authored as files</span>
    ├── paste-parse-dispatch/  <span class="text-white/30"># 3 episodes</span>
    ├── the-handoff/           <span class="text-white/30"># 2 episodes</span>
    ├── parallel-agents/       <span class="text-white/30"># 2 episodes</span>
    └── mix frontispiece.author <span class="text-white/30"># scaffold new ones</span></pre>
          </div>

          <div class="pt-4 border-t border-white/5">
            <p class="text-xs text-white/30 font-mono mb-4">Enter a practice:</p>
            <.practice_cards practices={@practices} />
          </div>
        </section>
      </main>
    </div>
    """
  end

  # -- Components --

  defp practice_cards(assigns) do
    ~H"""
    <div class="space-y-3">
      <a
        :for={practice <- @practices}
        href={"/p/#{practice.slug}"}
        class="block bg-white/5 rounded-xl p-4 active:bg-white/10 transition-colors
               touch-manipulation border border-white/5 hover:border-white/15"
      >
        <div class="flex items-start justify-between mb-1">
          <h3 class="text-sm font-semibold leading-tight">{practice.name}</h3>
          <span class="text-xs font-mono text-white/30 tabular-nums ml-2 shrink-0">
            {length(practice.episodes)} ep
          </span>
        </div>
        <p :if={practice.one_liner} class="text-xs text-white/50 leading-relaxed">
          {practice.one_liner}
        </p>
        <div class="flex gap-1 mt-2">
          <div
            :for={_ep <- practice.episodes}
            class="w-1.5 h-1.5 rounded-full bg-white/20"
          />
        </div>
      </a>
    </div>
    """
  end

  defp subsystem(assigns) do
    ~H"""
    <div class="rounded-lg bg-white/5 border border-white/5 p-3">
      <h3 class="text-sm font-mono font-semibold text-white/80 mb-1">{@name}</h3>
      <p class="text-xs text-white/50 leading-relaxed">{@desc}</p>
    </div>
    """
  end

  defp stack_row(assigns) do
    ~H"""
    <div class="flex gap-3 py-1.5 border-b border-white/5 last:border-0">
      <span class="text-xs font-mono text-white/40 w-20 shrink-0">{@label}</span>
      <span class="text-xs text-white/60">{@value}</span>
    </div>
    """
  end

  # -- Events --

  @impl true
  def handle_event("set_level", %{"level" => level}, socket)
      when level in ~w(1 2 3 4 5 tree) do
    {:noreply,
     socket
     |> assign(active_level: level)
     |> push_patch(to: "/#level-#{level}", replace: true)}
  end

  def handle_event("set_level", _, socket), do: {:noreply, socket}

  @impl true
  def handle_event("navigate", %{"slug" => slug}, socket) do
    {:noreply, push_navigate(socket, to: "/p/#{slug}")}
  end
end
