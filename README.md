# Frontispiece

A practice-storytelling engine that shows how to use coding assistants
through repetitive-with-variations demonstrations.

Each **episode** is the same move performed in a different context:
a terminal recording, a screenshot, a copyable prompt well, a brief narration.
The repetition is the point — you learn the shape by seeing it land differently
each time.

## Architecture

```
┌─────────────────────────────────────────────────┐
│  UI Surfaces (ephemeral, swappable)             │
│  ┌─────────┐  ┌──────────┐  ┌───────┐          │
│  │ Mobile  │  │ Desktop  │  │  TUI  │          │
│  │ (touch) │  │ (panels) │  │ (ssh) │          │
│  └────┬────┘  └────┬─────┘  └───┬───┘          │
│       └─────────────┼───────────┘               │
│                     ▼                           │
├─────────────────────────────────────────────────┤
│  Phoenix LiveView                               │
│  Responsive layouts, touch affordances,         │
│  progressive disclosure, swipe gestures,        │
│  copyable wells, inline media                   │
├─────────────────────────────────────────────────┤
│  Kernel (thick middleware, the real app)         │
│  ┌──────────┐ ┌──────────┐ ┌──────────────┐    │
│  │ Practice │ │   LLM    │ │    State     │    │
│  │  Engine  │ │  Router  │ │   & Stats    │    │
│  └──────────┘ └──────────┘ └──────────────┘    │
│  ┌──────────┐ ┌──────────┐ ┌──────────────┐    │
│  │  Asset   │ │ Episode  │ │  Engagement  │    │
│  │ Pipeline │ │ Sequencer│ │   Tracker    │    │
│  └──────────┘ └──────────┘ └──────────────┘    │
├─────────────────────────────────────────────────┤
│  LLM Adapters (swappable kernel backends)       │
│  Claude │ Codex │ Coggy │ Aider │ Local │ ...  │
└─────────────────────────────────────────────────┘
```

## Key ideas

- **iPhone-first.** Every screen works with one thumb. Touch targets,
  swipe between episodes, pull-to-refresh, haptic-weight scroll.
  No pinch-to-zoom-a-desktop-site.

- **Thick middleware.** The kernel owns state, routing, sequencing,
  statistics. UIs are projections. Swap the UI without losing anything.

- **Swappable LLM kernel.** Each adapter implements a behaviour.
  Rerun the same episode through Claude, then Codex, then a local model.
  Compare results side by side. The practice stays the same; the voice changes.

- **Engagement by repetition.** The same practice shown 5-8 times in
  different contexts. Each variation adds one twist. The user internalizes
  the shape, not the specifics.

## Surfaces

| Surface | Stack | Affordances |
|---------|-------|-------------|
| Mobile web | Phoenix LiveView, responsive | Swipe, tap, pull, share sheet, copy wells |
| Desktop web | Phoenix LiveView, multi-panel | Side-by-side compare, drag, keyboard nav |
| TUI | Ratatui over SSH / local | Arrow keys, copy, pipe-friendly output |

## Content model

An **Episode** is one demonstration of a practice:

```
Episode
  ├── practice: "paste-parse-dispatch" | "handoff" | "parallel-agents" | ...
  ├── context: "fleet triage" | "swift app build" | "nlp pipeline" | ...
  ├── narration: Markdown (brief, connects to next episode)
  ├── media: [Screenshot | GIF | AsciinemaRecording | TerminalPlayback]
  ├── wells: [CopyableWell]  — the exact prompt, command, or config
  ├── llm_used: "claude-opus-4" | "codex" | "coggy" | ...
  ├── variation_of: Episode? (links to the "base" version)
  └── metrics: {views, copies, reruns, time_spent}
```

A **Practice** is a named pattern with 5-8 episodes:

```
Practice
  ├── name: "Paste, Parse, Dispatch"
  ├── slug: "paste-parse-dispatch"
  ├── one_liner: "Paste a transcript. Auto-decompose. Select pieces. Dispatch."
  ├── episodes: [Episode]  (ordered by complexity)
  └── takeaway: Markdown (what you should have internalized)
```

A **Well** is a copyable text block:

```
Well
  ├── kind: :prompt | :command | :config | :snippet
  ├── content: String
  ├── label: String  — "The dispatch prompt" / "The SSH command"
  └── copy_count: Integer
```

## Tech stack

- **Elixir + Phoenix LiveView** — server-rendered interactivity, no JS framework
- **Ecto + SQLite** — local state, statistics, episode progress
- **GenServer** — LLM adapter pool, background reruns, engagement tracking
- **Tailwind CSS** — responsive, mobile-first utility classes
- **asciinema** — terminal recordings embedded inline
- **Ratatui** (Rust) — TUI surface, connects to same kernel via API

## Directory layout

```
frontispiece/
├── lib/
│   ├── frontispiece/
│   │   ├── kernel/           # The thick middleware
│   │   │   ├── practice.ex        # Practice schema + logic
│   │   │   ├── episode.ex         # Episode schema + sequencing
│   │   │   ├── well.ex            # Copyable text wells
│   │   │   ├── engagement.ex      # View/copy/rerun tracking
│   │   │   └── sequencer.ex       # Episode ordering + variation logic
│   │   ├── llm/              # Swappable LLM adapters
│   │   │   ├── adapter.ex         # Behaviour definition
│   │   │   ├── claude.ex          # Claude adapter
│   │   │   ├── codex.ex           # Codex adapter
│   │   │   ├── coggy.ex           # Coggy adapter
│   │   │   ├── aider.ex           # Aider adapter
│   │   │   └── router.ex          # Adapter selection + fallback
│   │   ├── assets/           # Media pipeline
│   │   │   ├── pipeline.ex        # Screenshot/GIF/asciinema processing
│   │   │   └── storage.ex         # Local file storage + CDN upload
│   │   ├── stats/            # Learning + statistics
│   │   │   ├── tracker.ex         # Event ingestion
│   │   │   ├── aggregator.ex      # Per-practice, per-episode rollups
│   │   │   └── comparator.ex      # Cross-LLM result comparison
│   │   └── repo.ex           # Ecto repo (SQLite)
│   ├── frontispiece_web/
│   │   ├── live/             # LiveView pages
│   │   │   ├── practice_live.ex   # Practice overview (list of episodes)
│   │   │   ├── episode_live.ex    # Single episode view (media + wells + narration)
│   │   │   ├── compare_live.ex    # Side-by-side LLM comparison
│   │   │   ├── journey_live.ex    # Full practice walkthrough (swipe through)
│   │   │   └── stats_live.ex      # Engagement dashboard
│   │   ├── components/       # Reusable UI components
│   │   │   ├── well.ex            # Copyable text well (tap to copy, flash confirm)
│   │   │   ├── media_player.ex    # GIF/asciinema/screenshot viewer
│   │   │   ├── episode_card.ex    # Episode preview card
│   │   │   ├── swipe_container.ex # Touch swipe navigation
│   │   │   └── narration.ex       # Markdown narration block
│   │   ├── layouts/
│   │   │   ├── root.html.heex     # Shell (meta, PWA manifest, viewport)
│   │   │   └── app.html.heex      # App chrome (nav, safe areas)
│   │   └── router.ex
│   └── frontispiece.ex
├── priv/
│   ├── repo/migrations/
│   ├── static/
│   │   ├── media/            # Screenshots, GIFs, asciinema casts
│   │   └── icons/            # PWA icons, touch icons
│   └── content/              # Episode content as markdown + frontmatter
│       ├── paste-parse-dispatch/
│       │   ├── 01-fleet-triage.md
│       │   ├── 01-fleet-triage.cast    # asciinema recording
│       │   ├── 01-fleet-triage.png     # screenshot
│       │   ├── 02-swift-build.md
│       │   ├── 03-nlp-debug.md
│       │   └── practice.toml           # Practice metadata
│       ├── the-handoff/
│       │   ├── 01-session-end.md
│       │   ├── 02-cold-start.md
│       │   └── practice.toml
│       └── parallel-agents/
│           ├── 01-two-builds.md
│           ├── 02-research-and-code.md
│           └── practice.toml
├── tui/                      # Rust TUI surface
│   ├── Cargo.toml
│   └── src/
│       ├── main.rs
│       ├── client.rs         # HTTP client to kernel API
│       ├── episode_view.rs
│       ├── well_widget.rs
│       └── swipe.rs          # Vim-style j/k + arrow navigation
├── config/
│   ├── config.exs
│   ├── dev.exs
│   ├── prod.exs
│   └── runtime.exs           # LLM API keys from env
├── mix.exs
├── flake.nix                 # Nix dev shell: elixir + rust + asciinema
└── README.md
```

## First practices to build

1. **Paste, Parse, Dispatch** — The Loom pattern from Deskfloor.
   Paste a session transcript → auto-decompose into sections →
   select pieces → dispatch as context to a new agent session.

2. **The Handoff** — Writing a handoff doc at session end so the
   next session (human or agent) starts with full context.

3. **Parallel Agents** — Spinning up concurrent subagents for
   independent concerns and merging their results.

## Running

```bash
# Dev (requires nix)
nix develop
mix setup
mix phx.server
# → http://localhost:4000 (open on iPhone via local network)

# TUI
cd tui && cargo run
```

## License

MIT
