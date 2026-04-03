---
title: "Fleet State Handoff"
context: "You probed 5 servers. Document what you found for the next agent."
llm_used: "claude-opus-4"
wells:
  - kind: prompt
    label: "The fleet handoff prompt"
    content: |
      I just probed 5 fleet servers. Here is everything I found:

      [paste fleet status, disk usage, running services, broken things]

      Write a fleet handoff document with:
      1. Per-host status table (host, disk%, load, services up/down, blockers)
      2. Cross-host issues (cert mismatches, agent duplication, budget overdraws)
      3. Priority triage: what to fix first and why
      4. Exact SSH commands to resume each fix

      The next session will SSH in and execute. Be precise.
  - kind: snippet
    label: "Fleet handoff structure"
    content: |
      ## Fleet Status

      | Host | Disk | Load | Services | Blocker |
      |------|------|------|----------|---------|
      | hyle | 75%  | 1.0  | 15/18 up | agent dedup |
      | finml| 89%  | 4.9  | 3/3 up  | disk, CPU lockup |
      | hub2 | 67%  | 0.3  | 8/8 up  | — |

      ## Cross-Host Issues
      - Agent duplication: claude@X and claude-X are same agent (8 phantoms)
      - Cert mismatch: corpora.hyperstitious.org serving wrong cert

      ## Priority
      1. Kill finml Java process (311% CPU, PID 160203)
      2. Clean finml disk (89% → target 70%)
      3. Fix agent dedup in serve.py on hyle

      ## Resume Commands
      ```bash
      ssh finml 'sudo kill 160203'
      ssh finml 'rm -rf ~/xmasnumerai ~/dec16'
      ssh hyle 'vim /path/to/serve.py'  # normalize agent names
      ```
    language: markdown
---

A handoff for infrastructure, not code. The challenge: when you've probed
multiple servers, the findings scatter across terminal windows. The handoff
has to **consolidate** into a single actionable document.

**The variation from episode 1:** Code handoffs are about project state.
Fleet handoffs are about system state. The structure is different — you need
per-host tables, cross-host patterns, and exact SSH commands rather than
build commands.

The most important field in a fleet handoff is the **priority triage**.
The next session will ask "what do I fix first?" — if the handoff doesn't
answer that question explicitly, they'll waste 20 minutes re-triaging.
