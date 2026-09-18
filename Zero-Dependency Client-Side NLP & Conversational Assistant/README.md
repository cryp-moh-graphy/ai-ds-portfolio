<div align="center">

  <h3>AI & Data Science (NLP, ML, Analytics, Data Engineering)</h3>

  <h1><b>Zero-Dependency Client-Side NLP & Conversational Assistant</b></h1>

</div>

Developed a lightweight, client-side NLP engine designed for offline-first browser execution. The conversational assistant is embedded in **[iM-Engr](https://im-engr474-sep26sys.netlify.app)**, where it answers questions about my work across engineering, data, design, and writing without making a single call to an AI API.

## Why build this without an LLM in 2026

For a portfolio assistant, I wanted factual accuracy and predictable behavior to take priority over open-ended generation. An LLM-based implementation would be straightforward, but it would also introduce external API costs, network latency, model-provider dependency, and the possibility of generated responses containing details that were never part of my portfolio.

I chose a different approach: a **deterministic retrieval engine** built from scratch in vanilla JavaScript and running entirely in the browser.

The system combines Unicode-aware normalization, scoped fuzzy typo correction, weighted intent scoring, confidence thresholds, and context-aware follow-ups to map questions to responses from an authored knowledge base. Because responses are selected from predefined content rather than generated at runtime, the assistant cannot invent new project or biographical facts.

The result is a **zero-backend, zero-API, zero-dependency** conversational interface that runs locally in the browser, with predictable outputs and no recurring inference cost.

It's not intended to be a general-purpose chatbot or a replacement for an LLM. It's a deliberately constrained system built around a specific requirement: **answer questions about my work quickly, transparently, and without generating facts that aren't in the underlying knowledge base.**

<sub>[⬅ Back to Main Page](https://github.com/cryp-moh-graphy/ai-ds-portfolio/blob/main/README.md)</sub>
