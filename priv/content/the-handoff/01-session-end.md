---
title: "Ending a Build Session"
context: "You've been building Swift apps for 3 hours. Time to hand off."
llm_used: "claude-opus-4"
wells:
  - kind: prompt
    label: "The handoff prompt"
    content: |
      Write a handoff document for the next agent session. Include:
      1. Current state of each project touched (builds? committed? blockers?)
      2. Decisions made and why
      3. What's broken and the exact error
      4. Exact commands to resume where I left off
      Format as markdown. Be honest about what's untested.
  - kind: snippet
    label: "Handoff structure"
    content: |
      ## State
      - corpora-bridge: builds, committed, 200 entries ingested
      - deskfloor: builds, uncommitted changes in Views/
      - nlp-engine: builds, untested at runtime

      ## Decisions
      - @Observable over TCA (less ceremony for this scope)
      - SQLite over Core Data (simpler, CLI-compatible)

      ## Broken
      - PasteAnalysisView: 500+ lines, needs decomposition
      - Launcher panel: hotkey registers but panel doesn't always show

      ## Resume
      ```bash
      cd ~/Nissan/deskfloor && swift build   # verify still compiles
      swift run Deskfloor                     # launch, press Ctrl+Space
      ```
    language: markdown
---

The session is over. You've been context-switching between three Swift projects
for hours. You have uncommitted changes, half-fixed bugs, and design decisions
in your head that aren't written down anywhere.

The handoff prompt forces you to externalize all of it. Not as a journal entry
("today I worked on...") but as **operational context** for a cold start.

The key insight: handoffs are written for someone who has *zero* context.
That someone might be you in two days, or a different Claude session tomorrow.
Either way, they need: state, decisions, breakage, resume commands.
