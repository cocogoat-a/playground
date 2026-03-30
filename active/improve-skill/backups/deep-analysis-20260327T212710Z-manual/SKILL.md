---
name: deep-analysis
description: Multi-pass analysis and synthesis with 15 subagents across three waves. Use only when explicitly invoked as $deep-analysis or when the user explicitly asks for deep analysis, multi-pass critique, or iterative refinement from multiple agent angles. Use for research, strategy, evaluation, and judgment-heavy tasks that benefit from initial analysis, structured criticism, and a final improved result published to a designed Notion page.
---
# Deep Analysis

## Overview

Use this skill to run a fixed three-wave analysis workflow: 5 analysts, 5 critics, then 5 improvers. Treat the process as opinionated by default and change the wave sizes only if the user explicitly asks for a different setup.

## Defaults

- Spawn `5` analyst agents, `5` critic agents, and `5` improver agents.
- Use `agent_type: "default"`, `model: "gpt-5.4-mini"`, and `reasoning_effort: "xhigh"` for spawned agents by default.
- Create the final deliverable as a designed Notion page via Notion MCP.
- Put the usable final answer in the Notion page itself, not just the process artifacts. The page should show the polished final result prominently near the top.
- Use this skill only on explicitly-invoked requests. Do not apply it implicitly.

## Guardrails

- Use this skill for analysis, research, ranking, strategy, and recommendation tasks. Do not use it for parallel code edits unless the user explicitly asks for implementation fan-out.
- Verify unstable facts before spawning when the task depends on current events, prices, policies, schedules, product specs, or other time-sensitive information.
- Keep the shared context neutral. Do not leak a preferred answer into subagent prompts.
- Lock one strict output schema per wave before spawning so the outputs can be aggregated without guesswork.
- Preserve minority and conflicting critiques. Do not collapse the critic wave into only majority views.
- Keep Notion MCP restricted to the main orchestrator agent. Spawned analyst, critic, and improver agents must not use Notion MCP or create external artifacts.
- Wait for the full wave to finish before moving forward. Do not synthesize, critique, improve, or publish based on partial wave results unless the user explicitly allows degraded execution.
- User wants deep-analysis subagents to perform broader research from different adjacent angles, not small analysis passes. The workflow should be more comprehensive and exploratory, with looser schemas and less emphasis on strict comparable outputs or accuracy-first framing.
## Workflow

### 1. Parse the request

Extract:

- the exact problem to analyze
- the audience for the final answer
- the required output type
- the options, if any
- constraints, tradeoffs, and success criteria

If the prompt is too vague to compare outputs mechanically, sharpen it before spawning.

### 2. Lock the schemas

Use one fixed schema per wave.

Wave A analyst schema:

- `Summary`: 2-4 sentences
- `Key findings`: 3-5 bullets
- `Risks or weak points`: 2-4 bullets
- `Recommendation`: 1 concise paragraph
- `Confidence`: `1-10`

Wave B critic schema:

- Return `7-10` recommendations.
- Use one block per item:
  - `Title`
  - `Issue`
  - `Why it matters`
  - `Recommended improvement`
  - `Priority`: `High`, `Medium`, or `Low`

Wave C improver schema:

- `Revised answer`
- `What changed`
- `Recommendations not fully implemented`
- `Confidence`: `1-10`

Keep the schema identical within each wave. Change only the framing.

### 3. Spawn the 5 analyst agents

Use these framings in parallel:

1. Neutral
2. Risk-aware
3. Contrarian
4. First-principles
5. User-centered

Prompt template:

```text
{framing}

Analyze this problem independently. Do not assume what other agents will say.

Problem:
{problem}

Context:
{relevant facts, options, constraints, and audience}

Required output:
{wave A schema}

Be specific. State uncertainty explicitly. Keep the response concise and decision-useful.
Do not use Notion MCP. Return only the requested structured response in chat.
```

Wait on all 5 analyst agents and do not start synthesis until every analyst has returned a final result. If an analyst fails or times out, retry or replace that analyst first; do not proceed with a partial wave unless the user explicitly approves that tradeoff.

### 4. Combine the analyst outputs

Create one synthesized first-pass draft that includes:

- the shared conclusions
- the meaningful disagreements
- the recurring risks
- the current best recommendation
- unresolved questions or assumptions

Normalize obviously equivalent points, but preserve genuine divergence.

### 5. Spawn the 5 critic agents

Give every critic the original problem, the constraints, and the synthesized first-pass draft.

Use these angles in parallel:

1. Factual rigor
2. Missing counterarguments
3. Execution feasibility
4. Clarity and structure
5. Omitted edge cases

Prompt template:

```text
{critic angle}

Review this synthesized analysis critically. Do not rewrite it yet. Find weaknesses and propose improvements.

Problem:
{problem}

First-pass draft:
{combined analyst output}

Required output:
{wave B schema}

Return 7-10 items. Focus on concrete improvements, not generic praise or repetition.
Do not use Notion MCP. Return only the requested structured response in chat.
```

Wait on all 5 critic agents and do not merge recommendations until every critic has returned a final result. If a critic fails or times out, retry or replace that critic first; do not proceed with a partial wave unless the user explicitly approves that tradeoff.

### 6. Merge all critic recommendations

Build one full unique recommendation list.

Rules:

- Keep all unique recommendations. Do not cap the combined list at `10`.
- Merge only clearly equivalent recommendations.
- Preserve conflicting recommendations as separate items.
- Record provenance for every merged item:
  - `Recommendation ID`
  - `Recommendation`
  - `Source angle(s)`
  - `Support count`
  - `Priority mix`
- If the critics produce `18` unique items, keep `18`.
- Do not discard low-support ideas only because they are minority views.

This full unique recommendation list is the required input to the improver wave and must also appear in the final output artifact.

### 7. Spawn the 5 improver agents

Give every improver:

- the original problem
- the synthesized first-pass draft
- the full unique recommendation list

Use these framings in parallel:

1. Rigor-first
2. Clarity-first
3. Strategy-first
4. Actionability-first
5. Skeptic-proof

Prompt template:

```text
{improver framing}

Improve this draft using the full recommendation list below. Implement compatible improvements, note where recommendations conflict, and avoid dropping important minority critiques without explanation.

Problem:
{problem}

First-pass draft:
{combined analyst output}

Full recommendation list:
{all unique recommendations with provenance}

Required output:
{wave C schema}

Produce a refined answer, not a commentary about the process.
Do not use Notion MCP. Return only the requested structured response in chat.
```

Wait on all 5 improver agents and do not merge the final answer until every improver has returned a final result. If an improver fails or times out, retry or replace that improver first; do not proceed with a partial wave unless the user explicitly approves that tradeoff.

### 8. Merge the improver outputs

Produce one final answer by combining the strongest compatible improvements from the 5 improver outputs.

For every unique recommendation, assign one final status:

- `Implemented`
- `Partially implemented`
- `Not implemented`

Add a short rationale for that status. When two recommendations conflict, keep both in the table and explain the tradeoff instead of silently dropping one.

### 9. Publish the final artifact to Notion

Use Notion MCP only after all three waves are complete and the final merged answer is ready. If you need complex page content, first fetch `notion://docs/enhanced-markdown-spec`.

If the user provided a Notion destination, use it. Otherwise create a private standalone page.

The Notion page must be useful on its own to the end user:

- Put the polished `Final Improved Output` near the top, before long process sections.
- Do not publish a page that is mostly traces, artifacts, or methodology with the real deliverable buried below.
- If the task produces a user-facing deliverable, the Notion page should make that deliverable easy to copy, review, and use directly.
- The process sections should support the result, not overshadow it.

Structure the page as a designed deliverable with:

- `Final Improved Output`
- `Executive Summary`
- `Problem`
- `First-Pass Synthesis`
- `Full Unique Recommendations`
- `Recommendation Traceability`
- optional appendix with concise per-agent summaries

Use a traceability table with these columns:

- `Unique recommendation`
- `Source angle(s)`
- `Status`
- `How incorporated`

Prefer a clean, readable layout over a raw dump of agent transcripts.

## User-facing return

Return:

- one short paragraph summarizing the final result
- the Notion page URL
- the count of unique recommendations gathered
- the number implemented, partially implemented, and not implemented
- the single most important unresolved tradeoff, if one remains

Also make clear that the Notion page contains the final usable result itself, not only supporting artifacts.

## Fallbacks

- Document the most reliable workaround from the session as an explicit fallback so the next run does not have to rediscover it.
