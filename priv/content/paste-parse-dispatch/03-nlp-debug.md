---
title: "NLP Algorithm Debug"
context: "Topic extraction produces garbage. You paste the output and the algorithm."
llm_used: "claude-opus-4"
wells:
  - kind: prompt
    label: "The algorithm review prompt"
    content: |
      Here is my BM25 topic extraction implementation in Swift and its output
      on 120 conversation turns. The top terms are filler words like "especially"
      and "please." Tell me what's wrong with the math and show the corrected
      implementation.
  - kind: snippet
    label: "The broken scoring"
    content: |
      // BM25 scoring — this version sums TF-IDF across documents,
      // which defeats the purpose of IDF
      let score = documents.reduce(0.0) { acc, doc in
          acc + tfidf(term, in: doc) * idf(term)
      }
    language: swift
  - kind: snippet
    label: "The fix"
    content: |
      // BM25 scoring — average per-document score preserves IDF signal
      let scores = documents.map { tfidf(term, in: $0) * idf(term) }
      let score = scores.reduce(0.0, +) / Double(max(scores.count, 1))
    language: swift
---

Now the paste isn't infrastructure and it isn't compiler errors — it's
**algorithm output that looks plausible but is wrong.**

This is the hardest variant. Terminal errors are obvious. Compiler errors
point to exact lines. But an NLP algorithm that produces "reasonable-looking"
but subtly wrong results requires the LLM to understand the math.

You paste: the algorithm code, the output it produces, and what you expected.
The LLM identifies the bug (summing vs. averaging defeats IDF). You get back
the corrected implementation.

**The repetition lands here:** three episodes, three completely different
domains (infrastructure, build systems, algorithms), but the same shape:
paste raw context → auto-parse → select the relevant pieces → dispatch
a focused question → get actionable output.

The practice is the shape. The content changes. You're learning to recognize
when paste-parse-dispatch is the right move.
