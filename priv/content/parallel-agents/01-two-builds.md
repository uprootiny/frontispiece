---
title: "Two Independent Builds"
context: "corpora-bridge and nlp-engine need building. Neither depends on the other."
llm_used: "claude-opus-4"
wells:
  - kind: prompt
    label: "Dispatch agent 1"
    content: |
      cd ~/Nissan/corpora-bridge && swift build
      If it fails, fix the errors. If it succeeds, run `swift run corpora-bridge status`
      and report what you see. Do not touch any other project.
  - kind: prompt
    label: "Dispatch agent 2"
    content: |
      cd ~/Nissan/nlp-engine && swift build
      If it fails, fix the errors. If it succeeds, run `swift run nlp-harvest --dry-run`
      and report what you see. Do not touch any other project.
  - kind: prompt
    label: "The merge prompt"
    content: |
      Two agents just ran. Here are their results:

      [paste agent 1 output]
      [paste agent 2 output]

      Summarize: what built, what broke, what's the combined state?
      Are there any interactions between these two that I should know about?
---

The simplest case: two Swift packages that don't share code. Build them
at the same time instead of sequentially.

The key discipline is **scoping the dispatch.** Each agent gets one directory,
one build command, one verification step, and an explicit instruction not to
touch anything else. Without that constraint, agents drift into helpful
refactoring of neighboring code and create merge conflicts with each other.

The merge step is lightweight here — just combine two status reports. But
it's still necessary. Maybe nlp-engine's harvest depends on a CLI flag that
corpora-bridge just changed. The merge prompt catches cross-cutting concerns.
