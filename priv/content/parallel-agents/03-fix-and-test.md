---
title: "Fix and Test in Parallel"
context: "One agent fixes the bug. Another writes the test. They meet at PR time."
llm_used: "claude-opus-4"
wells:
  - kind: prompt
    label: "Fix agent"
    content: |
      The Engagement.track/1 function doesn't debounce rapid duplicate events.
      Two identical "view" events within 100ms both get inserted.

      Fix it: before inserting, check if the same (episode_id, event) was
      recorded in the last 2 seconds. If so, return :debounced instead of inserting.

      Only modify lib/frontispiece/kernel/engagement.ex. Do not touch tests.
  - kind: prompt
    label: "Test agent"
    content: |
      Write tests for Engagement.track/1 debounce behavior:
      1. First call inserts successfully
      2. Immediate second call with same episode_id + event returns :debounced
      3. Call with different event type is NOT debounced
      4. Call after 2+ seconds is NOT debounced (use Process.sleep in test)

      Only write test/frontispiece/engagement_test.exs. Do not modify lib/ code.
  - kind: prompt
    label: "Merge verification"
    content: |
      Two agents worked in parallel:
      - Agent 1 modified lib/frontispiece/kernel/engagement.ex (added debounce)
      - Agent 2 created test/frontispiece/engagement_test.exs (tests debounce)

      Verify:
      1. Do the tests pass against the implementation? Run `mix test test/frontispiece/engagement_test.exs`
      2. Are there any interface mismatches (function signatures, return values)?
      3. Does the implementation match what the tests expect?
---

The most sophisticated variant: the agents work on **complementary sides of
the same interface**. One writes the implementation, the other writes the tests.
Neither sees the other's work until merge.

**Why this is harder than episode 1:** Independent builds can't conflict — they're
in different directories. But fix-and-test agents share an interface contract.
If the fix agent returns `{:ok, :debounced}` but the test agent expects `:debounced`,
the merge fails.

The discipline is **specifying the interface in both prompts**. The fix prompt says
"return :debounced". The test prompt says "returns :debounced". Same words, same
contract. The merge verification prompt catches any drift.
