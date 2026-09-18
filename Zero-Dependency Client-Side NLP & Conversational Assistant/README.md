<div align="center">

  <h3>AI & Data Science (NLP, ML, Analytics, Data Engineering)</h3>

  <h1><b>Zero-Dependency Client-Side NLP & Conversational Assistant</b></h1>

  <h3>Deterministic NLP, No LLM</h3>

</div>

Developed [a lightweight, client-side NLP engine](https://im-engr474-sep26sys.netlify.app) designed for offline-first browser execution. The conversational assistant is embedded in [iM-Engr](https://im-engr474-sep26sys.netlify.app), where it answers questions about my work, including engineering, data, design, and writing, without making a single call to an AI API.

## Why build this *without* an LLM in 2026

Everyone's shipping an OpenAI/Claude wrapper as their "AI portfolio bot." That's a fine option, but it comes with tradeoffs most people don't mention:

- **Cost** — every question is an API call, forever, at your expense.
- **Latency** — a round trip to a model provider on every keystroke of curiosity.
- **Hallucination risk** — an LLM will confidently invent details about *my own resume* if the prompt is loose enough.
- **Opacity** — you can't fully explain why it said what it said.
- **Dependency** — if the provider has an outage, or changes pricing, your portfolio's core feature breaks.

I wanted the opposite: something **fast, free to run, fully explainable, and impossible to hallucinate**, because the one thing a hiring manager should never doubt is whether the facts about me are *actually true*. So instead of wiring up an API, I built a small, deterministic retrieval engine from scratch — normalization, typo correction, weighted intent scoring, and context-aware follow-ups — entirely in vanilla JavaScript, entirely client-side.

It's not trying to be a general-purpose chatbot. It's trying to be the most reliable, zero-cost, zero-latency version of "ask me anything about my work" that exists.

<sub>[⬅ Back to Main Page](https://github.com/cryp-moh-graphy/ai-ds-portfolio/blob/main/README.md)</sub>
