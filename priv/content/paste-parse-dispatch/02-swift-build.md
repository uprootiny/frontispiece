---
title: "Swift Build Failure"
context: "A SwiftUI app fails to build. You paste the compiler output."
llm_used: "claude-opus-4"
wells:
  - kind: prompt
    label: "The build-fix prompt"
    content: |
      This SwiftUI app fails with the errors below. The app uses @Observable
      (Swift 5.9+), Ecto-style stores, and SPM. Fix each error. Show me the
      corrected code blocks, not the full files.
  - kind: command
    label: "The build command"
    content: "cd ~/Nissan/deskfloor && swift build 2>&1 | head -50"
    language: bash
---

Same move, different material. This time the paste isn't terminal output from
a server — it's compiler errors from `swift build`.

You paste the full error output. The LLM sees the line numbers, the error
messages, the surrounding code context that the compiler helpfully includes.
You don't need to explain the architecture. The errors *are* the context.

**The twist:** Compiler errors are more structured than terminal output.
They have file paths, line numbers, error codes. The parse step is almost
automatic. What matters is the selection: which errors are root causes
and which are cascading failures from the first error?

The dispatch is different too: instead of "run these commands," it's
"replace these code blocks." But the shape of the practice is identical.
