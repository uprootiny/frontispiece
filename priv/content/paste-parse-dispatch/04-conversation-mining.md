---
title: "Conversation Mining"
context: "You have 200 conversation turns across 6 sessions. Extract the good parts."
llm_used: "claude-opus-4"
wells:
  - kind: prompt
    label: "The extraction prompt"
    content: |
      Here are the last 50 turns from my Claude Code sessions. Extract:
      1. Every decision that was made (and why)
      2. Every command or code block that solved a problem
      3. Every approach that was tried and abandoned (and why it failed)
      4. Every reusable prompt pattern

      Format as four sections. Be specific — include the exact commands and code, not summaries.
  - kind: prompt
    label: "The topic map prompt"
    content: |
      Given these conversation turns, build a topic frequency map.
      For each topic: how many turns mention it, which sessions,
      and what was the arc (introduced → explored → resolved / abandoned).
      Show the top 15 topics sorted by frequency.
  - kind: command
    label: "Export your Claude history"
    content: "cat ~/.claude/history.jsonl | jq -r '.message' | head -100"
    language: bash
---

The richest variant. You're not pasting one session's output — you're pasting
**a corpus** and asking the LLM to find structure in it.

This is where paste-parse-dispatch becomes a research tool. The paste is
bulk history. The parse is topic extraction. The dispatch is a follow-up
session focused on the most interesting thread the LLM found.

**Why this works:** You can't read 200 conversation turns and spot patterns.
The LLM can. But it needs the raw material — not your summary of what you
think was important, but the actual turns. Your summary has survivorship bias.
The raw turns have everything, including the abandoned approaches that might
be worth revisiting.
