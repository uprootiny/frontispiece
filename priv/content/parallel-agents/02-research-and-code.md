---
title: "Research While Building"
context: "One agent researches BM25 math. Another implements the Topic module."
llm_used: "claude-opus-4"
wells:
  - kind: prompt
    label: "Research agent"
    content: |
      Research BM25 scoring for topic extraction. I need:
      1. The exact Okapi BM25 formula with k1 and b parameters
      2. How IDF should be computed (log formula)
      3. Common pitfalls: what happens if you sum vs average across documents?
      4. How to handle bigrams: PMI vs NPMI, when to use each
      Return formulas, not code. I'll implement separately.
  - kind: prompt
    label: "Implementation agent"
    content: |
      In ~/Nissan/corpora-bridge/Sources/Topics.swift, implement a TopicScorer
      struct with these methods:
      - bm25(term:, in document:, corpus:) -> Double
      - idf(term:, corpus:) -> Double
      - npmi(bigram:, corpus:) -> Double

      Use placeholder formulas for now. Mark each with // TODO: verify formula.
      I'll fill in the correct math from a separate research source.
---

A subtler pattern: one agent does pure research (no code changes), another
writes code with placeholder math. Neither blocks the other.

**The twist from episode 1:** These agents *do* interact — the research
feeds the implementation. But they don't interact *during* execution. The
merge step is where research meets code: you take the formulas from agent 1
and fill in the TODOs from agent 2.

This is faster than serial execution because the research agent doesn't
need to wait for the code structure, and the code agent doesn't need to
wait for the math. The interface between them is well-defined: function
signatures with TODO placeholders.
