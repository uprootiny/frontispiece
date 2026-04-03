defmodule FrontispieceWeb.EpisodeLive do
  @moduledoc """
  Single episode deep view — media, narration, wells, rerun controls.
  This is where you can rerun a well through a different LLM and see
  the comparison inline.
  """
  use FrontispieceWeb, :live_view

  alias Frontispiece.Kernel.{Episode, Practice, Engagement, Markdown}
  alias Frontispiece.LLM.Router
  alias Frontispiece.Repo
  import Ecto.Query

  @impl true
  def mount(%{"practice_slug" => p_slug, "episode_slug" => e_slug}, session, socket) do
    with %Practice{} = practice <- Repo.get_by(Practice, slug: p_slug),
         %Episode{} = episode <-
           Episode
           |> where(practice_id: ^practice.id, slug: ^e_slug)
           |> preload([:wells, :media])
           |> Repo.one() do
      session_id = session["session_id"] || Engagement.generate_session_id()
      Engagement.track(%{event: "view", episode_id: episode.id, session_id: session_id})
      adapters = Router.list_adapters()

      {:ok,
       assign(socket,
         practice: practice,
         episode: episode,
         adapters: adapters,
         selected_adapter: "claude",
         rerun_result: nil,
         rerunning: false,
         session_id: session_id,
         page_title: episode.title
       )}
    else
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Episode not found")
         |> redirect(to: "/")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-black text-white">
      <header class="sticky top-0 z-50 bg-black/90 backdrop-blur-sm border-b border-white/10 safe-top">
        <div class="px-4 py-3 flex items-center gap-3">
          <a href={"/p/#{@practice.slug}"} class="text-white/50 hover:text-white text-lg">←</a>
          <div class="flex-1 min-w-0">
            <h1 class="text-sm font-mono font-semibold truncate">{@episode.title}</h1>
            <p class="text-xs text-white/40 font-mono truncate">{@practice.name}</p>
          </div>
        </div>
      </header>

      <main class="px-4 pt-6 pb-32 max-w-2xl mx-auto space-y-6">
        <span class="inline-block px-2.5 py-0.5 rounded-full bg-white/10 text-xs font-mono text-white/60">
          {@episode.context}
        </span>

        <div class="prose prose-invert prose-sm max-w-none">
          {raw(Markdown.render(@episode.narration))}
        </div>

        <div :for={well <- @episode.wells} class="space-y-3">
          <div class="rounded-xl bg-white/5 border border-white/10 overflow-hidden">
            <div class="flex items-center justify-between px-3 py-2 bg-white/5 border-b border-white/5">
              <div class="flex items-center gap-2">
                <span class="text-xs font-mono text-white/50">{well.label}</span>
                <span class="text-[10px] font-mono px-1.5 py-0.5 rounded bg-white/5 text-white/30">
                  {well.kind}
                </span>
              </div>
              <div class="flex items-center gap-1.5">
                <button
                  phx-click="copy_well"
                  phx-value-content={well.content}
                  phx-value-well-id={well.id}
                  class="text-xs font-mono px-2 py-1 rounded bg-white/10 text-white/70
                         active:bg-white/25 touch-manipulation"
                >
                  copy
                </button>
                <button
                  :if={well.kind == "prompt"}
                  phx-click="rerun"
                  phx-value-content={well.content}
                  class="text-xs font-mono px-2 py-1 rounded bg-blue-500/20 text-blue-300
                         active:bg-blue-500/30 touch-manipulation"
                >
                  rerun →
                </button>
              </div>
            </div>
            <pre class="px-3 py-3 text-sm font-mono text-white/80 overflow-x-auto whitespace-pre-wrap break-words"><code>{well.content}</code></pre>
          </div>
        </div>

        <div :if={@rerunning || @rerun_result} class="space-y-3">
          <div class="flex items-center gap-2 overflow-x-auto pb-1 -mx-1 px-1">
            <button
              :for={adapter <- @adapters}
              phx-click="select_adapter"
              phx-value-name={adapter.name}
              class={"text-xs font-mono px-3 py-1.5 rounded-full touch-manipulation transition-colors shrink-0 " <>
                if(adapter.name == @selected_adapter,
                  do: "bg-white/20 text-white",
                  else:
                    if(adapter.available,
                      do: "bg-white/5 text-white/50",
                      else: "bg-white/5 text-white/20 line-through"
                    )
                )}
              disabled={not adapter.available}
            >
              {adapter.display_name}
            </button>
          </div>

          <div :if={@rerunning} class="rounded-xl bg-white/5 p-4">
            <div class="flex items-center gap-2 text-sm text-white/50 font-mono">
              <span class="animate-pulse">●</span> Running through {@selected_adapter}...
            </div>
          </div>

          <div
            :if={@rerun_result}
            class="rounded-xl bg-white/5 border border-white/10 overflow-hidden"
          >
            <div class="px-3 py-2 bg-white/5 border-b border-white/5 flex items-center justify-between">
              <span class="text-xs font-mono text-white/50">
                {@rerun_result.model} · {@rerun_result.latency_ms}ms
              </span>
              <button
                phx-click="copy_result"
                class="text-xs font-mono px-2 py-1 rounded bg-white/10 text-white/70
                       active:bg-white/25 touch-manipulation"
              >
                copy
              </button>
            </div>
            <div class="px-3 py-3 text-sm font-mono text-white/80 whitespace-pre-wrap">
              {@rerun_result.content}
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end

  @impl true
  def handle_event("copy_well", %{"content" => content, "well-id" => well_id}, socket) do
    Engagement.track(%{
      event: "copy",
      episode_id: socket.assigns.episode.id,
      session_id: socket.assigns.session_id,
      metadata: %{well_id: well_id}
    })

    {:noreply, push_event(socket, "copy-text", %{text: content})}
  end

  @impl true
  def handle_event("select_adapter", %{"name" => name}, socket) do
    if name in Router.adapter_names() do
      {:noreply, assign(socket, selected_adapter: name)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("rerun", %{"content" => prompt}, socket) do
    ep = socket.assigns.episode
    adapter = socket.assigns.selected_adapter

    Engagement.track(%{
      event: "rerun",
      episode_id: ep.id,
      session_id: socket.assigns.session_id,
      adapter_used: adapter
    })

    lv = self()
    practice_slug = socket.assigns.practice.slug
    episode_slug = ep.slug

    {:ok, _pid} =
      Task.start(fn ->
        context = %{
          practice: practice_slug,
          episode: episode_slug,
          wells: [],
          history: []
        }

        result = Router.run(adapter, prompt, context)
        send(lv, {:rerun_result, result})
      end)

    {:noreply, assign(socket, rerunning: true, rerun_result: nil)}
  end

  @impl true
  def handle_event("copy_result", _, socket) do
    if socket.assigns.rerun_result do
      {:noreply, push_event(socket, "copy-text", %{text: socket.assigns.rerun_result.content})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:rerun_result, {:ok, response}}, socket) do
    {:noreply, assign(socket, rerunning: false, rerun_result: response)}
  end

  @impl true
  def handle_info({:rerun_result, {:error, reason}}, socket) do
    {:noreply,
     assign(socket,
       rerunning: false,
       rerun_result: %{content: "Error: #{inspect(reason)}", model: "error", latency_ms: 0}
     )}
  end
end
