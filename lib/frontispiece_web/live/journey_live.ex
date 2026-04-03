defmodule FrontispieceWeb.JourneyLive do
  @moduledoc """
  Full practice walkthrough — swipe through episodes horizontally.
  iPhone: native-feeling horizontal swipe with snap points.
  Desktop: arrow keys or click nav.
  """
  use FrontispieceWeb, :live_view

  alias Frontispiece.Kernel.{Practice, Sequencer, Engagement, Markdown}
  alias Frontispiece.Repo

  @impl true
  def mount(%{"slug" => slug}, session, socket) do
    case Repo.get_by(Practice, slug: slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Practice not found")
         |> redirect(to: "/")}

      practice ->
        annotated = Sequencer.journey(practice.id)
        episodes = Enum.map(annotated, & &1.episode)
        current = List.first(episodes)
        session_id = session["session_id"] || Engagement.generate_session_id()

        {:ok,
         assign(socket,
           practice: practice,
           episodes: episodes,
           current_index: 0,
           current: current,
           session_id: session_id,
           page_title: practice.name
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-black text-white" phx-window-keydown="keydown">
      <header class="sticky top-0 z-50 bg-black/90 backdrop-blur-sm border-b border-white/10 safe-top">
        <div class="px-4 py-3 flex items-center gap-3">
          <a href="/" class="text-white/50 hover:text-white text-lg">←</a>
          <div class="flex-1 min-w-0">
            <h1 class="text-sm font-mono font-semibold truncate">{@practice.name}</h1>
          </div>
          <span class="text-xs font-mono text-white/40 tabular-nums">
            {@current_index + 1}/{length(@episodes)}
          </span>
        </div>

        <div class="h-0.5 bg-white/5">
          <div
            class="h-full bg-white/40 transition-all duration-300"
            style={"width: #{(@current_index + 1) / max(length(@episodes), 1) * 100}%"}
          />
        </div>
      </header>

      <main
        class="px-4 pt-6 pb-32 max-w-2xl mx-auto"
        phx-hook="SwipeNav"
        id="episode-content"
      >
        <div :if={@current} class="space-y-6">
          <div>
            <h2 class="text-xl font-semibold mb-2">{@current.title}</h2>
            <span class="inline-block px-2.5 py-0.5 rounded-full bg-white/10 text-xs font-mono text-white/60">
              {@current.context}
            </span>
          </div>

          <div :for={media <- @current.media || []} class="rounded-xl overflow-hidden bg-white/5">
            <.media_embed media={media} />
          </div>

          <div class="prose prose-invert prose-sm max-w-none leading-relaxed">
            {raw(Markdown.render(@current.narration))}
          </div>

          <div :for={well <- @current.wells || []} class="space-y-2">
            <.well well={well} />
          </div>
        </div>
      </main>

      <nav class="fixed bottom-0 inset-x-0 bg-black/90 backdrop-blur-sm border-t border-white/10 safe-bottom">
        <div class="px-4 py-3 flex items-center justify-between max-w-2xl mx-auto">
          <button
            phx-click="prev"
            class={"text-sm font-mono px-4 py-2 rounded-lg transition-colors touch-manipulation " <>
              if(@current_index > 0, do: "bg-white/10 text-white active:bg-white/20", else: "text-white/20")}
            disabled={@current_index == 0}
          >
            ← prev
          </button>

          <button
            phx-click="toggle_adapter_picker"
            class="text-xs font-mono px-3 py-1.5 rounded-full bg-white/5 text-white/50
                   hover:bg-white/10 transition-colors touch-manipulation"
          >
            {(@current && @current.llm_used) || "claude"}
          </button>

          <button
            phx-click="next"
            class={"text-sm font-mono px-4 py-2 rounded-lg transition-colors touch-manipulation " <>
              if(@current_index < length(@episodes) - 1, do: "bg-white/10 text-white active:bg-white/20", else: "text-white/20")}
            disabled={@current_index >= length(@episodes) - 1}
          >
            next →
          </button>
        </div>
      </nav>
    </div>
    """
  end

  defp well(assigns) do
    ~H"""
    <div class="rounded-xl bg-white/5 border border-white/10 overflow-hidden">
      <div class="flex items-center justify-between px-3 py-2 bg-white/5 border-b border-white/5">
        <span class="text-xs font-mono text-white/50">{@well.label}</span>
        <button
          phx-click="copy_well"
          phx-value-id={@well.id}
          class="text-xs font-mono px-2 py-1 rounded bg-white/10 text-white/70
                 active:bg-white/25 transition-colors touch-manipulation"
        >
          copy
        </button>
      </div>
      <pre class="px-3 py-3 text-sm font-mono text-white/80 overflow-x-auto whitespace-pre-wrap break-words"><code>{@well.content}</code></pre>
    </div>
    """
  end

  defp media_embed(%{media: %{kind: "asciinema"}} = assigns) do
    ~H"""
    <div class="p-2">
      <div
        id={"cast-#{@media.id}"}
        phx-hook="AsciinemaPlayer"
        data-src={@media.path}
        class="w-full"
      />
    </div>
    """
  end

  defp media_embed(%{media: %{kind: kind}} = assigns) when kind in ["screenshot", "gif"] do
    ~H"""
    <img src={@media.path} alt={@media.alt_text || ""} class="w-full" loading="lazy" />
    <p :if={@media.caption} class="px-3 py-2 text-xs text-white/40 font-mono">
      {@media.caption}
    </p>
    """
  end

  defp media_embed(assigns) do
    ~H"""
    <div class="p-4 text-sm text-white/40 font-mono">
      [{@media.kind}: {@media.path}]
    </div>
    """
  end

  @impl true
  def handle_event("next", _, socket), do: navigate(socket, socket.assigns.current_index + 1)

  @impl true
  def handle_event("prev", _, socket), do: navigate(socket, socket.assigns.current_index - 1)

  @impl true
  def handle_event("swipe", %{"direction" => "left"}, socket),
    do: navigate(socket, socket.assigns.current_index + 1)

  @impl true
  def handle_event("swipe", %{"direction" => "right"}, socket),
    do: navigate(socket, socket.assigns.current_index - 1)

  @impl true
  def handle_event("keydown", %{"key" => key}, socket) when key in ["ArrowRight", "j", "l"],
    do: navigate(socket, socket.assigns.current_index + 1)

  @impl true
  def handle_event("keydown", %{"key" => key}, socket) when key in ["ArrowLeft", "h", "k"],
    do: navigate(socket, socket.assigns.current_index - 1)

  @impl true
  def handle_event("keydown", _, socket), do: {:noreply, socket}

  @impl true
  def handle_event("copy_well", %{"id" => well_id}, socket) do
    Engagement.track(%{
      event: "copy",
      episode_id: socket.assigns.current.id,
      session_id: socket.assigns.session_id,
      metadata: %{well_id: well_id}
    })

    {:noreply, push_event(socket, "copy-to-clipboard", %{well_id: well_id})}
  end

  @impl true
  def handle_event("toggle_adapter_picker", _, socket), do: {:noreply, socket}

  defp navigate(socket, index) do
    episodes = socket.assigns.episodes
    index = max(0, min(index, length(episodes) - 1))
    current = Enum.at(episodes, index)

    if current do
      Engagement.track(%{
        event: "view",
        episode_id: current.id,
        session_id: socket.assigns.session_id
      })
    end

    {:noreply, assign(socket, current_index: index, current: current)}
  end
end
