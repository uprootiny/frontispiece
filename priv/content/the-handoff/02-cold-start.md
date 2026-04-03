---
title: "Cold-Starting From a Handoff"
context: "New session. You have a handoff doc from yesterday. Use it."
llm_used: "claude-opus-4"
wells:
  - kind: prompt
    label: "The cold-start prompt"
    content: |
      Read the handoff document below. Run the resume commands to verify
      current state. Then tell me: what's the single highest-value thing
      to work on next, given what's broken and what's close to done?

      [paste handoff document here]
  - kind: command
    label: "Verify state first"
    content: |
      cd ~/Nissan/deskfloor && swift build
      cd ~/Nissan/corpora-bridge && swift build
      cd ~/Nissan/nlp-engine && swift build
      git -C ~/Nissan/deskfloor status
    language: bash
---

The other side of the handoff. You're the next session. You have a document
that tells you the state, the decisions, the breakage, and the resume commands.

The move is **not** to start reading code. The move is to:
1. Run the resume commands (do things still compile?)
2. Verify the stated breakage (is the launcher still flaky?)
3. Ask for prioritization (what's highest value right now?)

The handoff document is a hypothesis about the current state. The resume
commands test that hypothesis. If something changed since the handoff was
written — a dependency updated, a file got deleted — you'll know immediately.

**The variation from episode 1:** Writing a handoff is the end of a session.
Using a handoff is the start of a session. Same document, different moment,
different skills. Writing requires honest self-assessment. Reading requires
trust-but-verify.
