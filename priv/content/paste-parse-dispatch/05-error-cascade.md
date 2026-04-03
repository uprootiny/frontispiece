---
title: "Error Cascade"
context: "CI is red. 47 errors. Most are cascading from 2 root causes."
llm_used: "claude-opus-4"
wells:
  - kind: prompt
    label: "The root cause prompt"
    content: |
      Here is the full CI output (47 errors). Most of these are cascading failures.
      Identify the root causes — the 2-3 errors that, if fixed, would resolve
      the rest. For each root cause:
      1. The exact error and file/line
      2. Why it cascades (what depends on it)
      3. The fix (show the code change)

      Do NOT list all 47 errors. Only the roots.
  - kind: command
    label: "Grab CI output"
    content: "gh run view --log-failed 2>&1 | tail -200"
    language: bash
---

The hardest version of paste-parse-dispatch. When a CI run fails with
dozens of errors, most developers either:
- Read from the top and fix one at a time (slow, most are cascading)
- Grep for "error" and scan randomly (misses the dependency structure)

The move is: **paste the entire log, ask for root causes only.**

The LLM sees the dependency graph between errors that you'd have to trace
manually. A missing import in file A causes type errors in files B, C, D
that import A. Fix A, and B/C/D resolve automatically.

**The twist from episodes 1-3:** The LLM isn't just parsing — it's doing
dependency analysis. It needs to understand which errors *cause* other errors.
This is where LLMs genuinely outperform grep.
