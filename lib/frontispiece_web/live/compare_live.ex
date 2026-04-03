defmodule FrontispieceWeb.CompareLive do
  @moduledoc """
  Side-by-side comparison: run the same prompt through multiple LLMs.
  On mobile: vertical stack with swipe between results.
  On desktop: true side-by-side columns.
  """
  use FrontispieceWeb, :live_view

  alias Frontispiece.Kernel.{Episode, Practice}
  alias Frontispiece.LLM.Router
  alias Frontispiece.Repo
  import Ecto.Query

  @impl true
  def mount(%{"practice_slug" => p_slug, "episode_slug" => e_slug}, _session, socket) do
    with %Practice{} = practice <- Repo.get_by(Practice, slug: p_slug),
         %Episode{} = episode <-
           Episode
           |> where(practice_id: ^practice.id, slug: ^e_slug)
           |> preload(:wells)
           |> Repo.one() do
      adapters = Router.list_adapters() |> Enum.filter(& &1.available)
      prompt_well = Enum.find(episode.wells, List.first(episode.wells), &(&1.kind == "prompt"))

      {:ok,
       assign(socket,
         practice: practice,
         episode: episode,
         prompt: (prompt_well && prompt_well.content) || "",
         adapters: adapters,
         results: %{},
         running: false,
         page_title: "Compare: #{episode.title}"
       )}
    else
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Not found")
         |> redirect(to: "/")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-black text-white">
      <header class="sticky top-0 z-50 bg-black/90 backdrop-blur-sm border-b border-white/10 safe-top">
        <div class="px-4 py-3 flex items-center gap-3">
          <a
            href={"/p/#{@practice.slug}/#{@episode.slug}"}
            class="text-white/50 hover:text-white text-lg"
          >
            ←
          </a>
          <h1 class="text-sm font-mono font-semibold">Compare LLMs</h1>
        </div>
      </header>

      <main class="px-4 pt-6 pb-24 max-w-5xl mx-auto space-y-6">
        <div class="rounded-xl bg-white/5 border border-white/10 p-4">
          <p class="text-xs font-mono text-white/40 mb-2">Prompt</p>
          <p class="text-sm font-mono text-white/80 whitespace-pre-wrap">{@prompt}</p>
        </div>

        <button
          phx-click="run_all"
          disabled={@running}
          class={"w-full py-3 rounded-xl font-mono text-sm transition-colors touch-manipulation " <>
            if(@running, do: "bg-white/5 text-white/30", else: "bg-white/10 text-white active:bg-white/20")}
        >
          {if @running, do: "Running...", else: "Run through all adapters"}
        </button>

        <div class="space-y-4 md:grid md:grid-cols-2 md:gap-4 md:space-y-0">
          <div
            :for={adapter <- @adapters}
            class="rounded-xl bg-white/5 border border-white/10 overflow-hidden"
          >
            <div class="px-3 py-2 bg-white/5 border-b border-white/5 flex items-center justify-between">
              <span class="text-xs font-mono font-semibold text-white/70">
                {adapter.display_name}
              </span>
              <span :if={@results[adapter.name]} class="text-[10px] font-mono text-white/30">
                {@results[adapter.name].latency_ms}ms
              </span>
            </div>

            <div class="px-3 py-3 min-h-[100px]">
              <div
                :if={@running && !@results[adapter.name]}
                class="flex items-center gap-2 text-sm text-white/30 font-mono"
              >
                <span class="animate-pulse">●</span> thinking...
              </div>
              <div
                :if={@results[adapter.name]}
                class="text-sm font-mono text-white/80 whitespace-pre-wrap"
              >
                {@results[adapter.name].content}
              </div>
              <div
                :if={!@running && !@results[adapter.name]}
                class="text-sm text-white/20 font-mono"
              >
                waiting
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end

  @impl true
  def handle_event("run_all", _, socket) do
    prompt = socket.assigns.prompt
    practice_slug = socket.assigns.practice.slug
    episode_slug = socket.assigns.episode.slug
    lv = self()

    {:ok, _pid} =
      Task.start(fn ->
        context = %{practice: practice_slug, episode: episode_slug, wells: [], history: []}
        results = Router.run_parallel(prompt, context)
        send(lv, {:compare_results, results})
      end)

    {:noreply, assign(socket, running: true, results: %{})}
  end

  @impl true
  def handle_info({:compare_results, results}, socket) do
    parsed =
      Map.new(results, fn
        {name, {:ok, resp}} ->
          {name, resp}

        {name, {:error, reason}} ->
          {name, %{content: "Error: #{inspect(reason)}", latency_ms: 0}}
      end)

    {:noreply, assign(socket, running: false, results: parsed)}
  end
end
