---
title: "Fleet Triage"
context: "A server is at 93% disk. You paste the SSH session into Loom."
llm_used: "claude-opus-4"
wells:
  - kind: prompt
    label: "The triage prompt"
    content: |
      I just SSHed into gcp1 and found it at 93% disk (469MB free on a 9.7G volume).
      Here's `du -sh /var/log/*` and `apt list --installed`. Tell me what to clean
      and in what order, with exact commands. Prioritize: reclaim the most space
      with the least risk of breaking things.
  - kind: command
    label: "The SSH command"
    content: "ssh gcp1 'du -sh /var/log/* | sort -rh | head -20'"
    language: bash
  - kind: command
    label: "The cleanup sequence"
    content: |
      sudo journalctl --vacuum-size=50M
      sudo apt clean
      sudo rm -rf /var/cache/apt/archives/*.deb
      sudo find /var/log -name '*.gz' -mtime +7 -delete
    language: bash
---

You're in a session working on corpora when someone mentions gcp1 is struggling.
You SSH in, see the problem, copy the terminal output, and paste it into a fresh
Claude session with the triage prompt.

The move isn't "write a detailed handoff document about the disk situation."
The move is **paste the raw terminal output** and let the LLM decompose it.

The transcript contains `du` output, `df` output, `apt list`, and your own
observations. Claude sees all of it. You don't need to summarize — you need
to select and dispatch.

**The variation:** In this episode, the context is infrastructure. The paste
is terminal output. The dispatch is a cleanup command sequence. In the next
episode, the paste will be a build log and the dispatch will be a fix.
