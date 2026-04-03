# Frontispiece

Practice-storytelling engine for coding assistants. Elixir/Phoenix LiveView.

## What this is
- iPhone-first web app showing coding assistant practices via repetitive-with-variations episodes
- Thick middleware (kernel) with swappable LLM adapters (Claude, Codex, Coggy, local)
- Three surfaces: mobile web (LiveView), desktop web (LiveView), TUI (Rust/Ratatui)
- Content authored as markdown + YAML frontmatter in `priv/content/`

## Stack
- Elixir 1.18 + Erlang/OTP 27 + Phoenix 1.8 + LiveView 1.1
- Ecto + SQLite3 (via exqlite)
- Tailwind CSS (mobile-first, dark mode)
- Rust TUI in `tui/` (talks to JSON API)

## Conventions
- Run `mix format` before committing
- Run `mix credo --strict` — no warnings allowed
- All public functions need `@spec` typespecs
- Kernel modules (`lib/frontispiece/kernel/`) own business logic — LiveViews are thin
- LLM adapters implement the `Frontispiece.Kernel.Adapter` behaviour
- Content goes in `priv/content/{practice-slug}/` as numbered markdown files
- Tests in `test/` mirror `lib/` structure

## Commands
- `mix setup` — deps, db, assets
- `mix phx.server` — dev server at localhost:4000
- `mix test` — run tests
- `mix format --check-formatted` — check formatting
- `mix credo --strict` — lint
- `cd tui && cargo build` — build TUI

## Do NOT
- Add Python or Node dependencies (assets tooling via mix wrappers only)
- Put business logic in LiveViews — they call kernel functions
- Commit without running `mix format`
