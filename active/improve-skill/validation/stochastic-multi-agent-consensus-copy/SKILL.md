---
name: stochastic-multi-agent-consensus
description: Use when the user explicitly asks for multiple independent agent opinions, consensus, polling, voting, or "what do N agents think". Spawn several Codex subagents with the same problem and slight framing variations, collect structured responses, and aggregate consensus, divergences, and outliers for decision-making, option ranking, strategic analysis, binary choices, or scored evaluations.
---
# Stochastic Multi-Agent Consensus

## Overview

Run several parallel Codex subagents on the same question, keep the output schema fixed, vary the framing slightly, then aggregate the results mechanically. Use this to reduce single-run bias, expose real disagreements, and surface creative outliers.

## Guardrails

- Use this skill only when the user explicitly asks for multiple agents, consensus, polling, voting, or parallel independent opinions.
- Use this skill for analysis, judgment, ranking, or recommendation tasks. Do not use it for parallel code edits unless the user explicitly asks for implementation fan-out.
- Keep the shared context neutral. Do not leak your preferred answer or draft conclusion into the subagent prompts.
- Require at least 3 agents. Default to 5. Use 7 to 9 only when the problem is ambiguous, high-stakes, or the user explicitly asks for a larger poll.
- Verify unstable facts before spawning if the question depends on current events, prices, policies, schedules, or other time-sensitive data.
- Keep the output schema fixed before spawning subagents so aggregation stays mechanical.
## Workflow

### 1. Parse the request

Extract:

- The exact problem or decision to analyze
- Agent count `N`
- Output type: ranking, recommendation, scorecard, or binary decision
- The option list, if the user already supplied one
- Constraints, success criteria, and required tradeoffs

If the prompt is too vague to compare responses mechanically, ask the user to sharpen it before spawning agents.

### 2. Lock the output schema

Define one structured schema that every subagent must follow. Keep the schema strict enough that you can compare outputs without guesswork.

Examples:

- Ranking: `Rank these 4 options from best to worst as a numbered list. Include a one-line reason for each rank.`
- Recommendation: `Return your top 3 recommendations. For each, give a name, one-sentence rationale, and confidence 1-10.`
- Binary: `Answer YES or NO, then give your top 3 reasons and confidence 1-10.`
- Scorecard: `Score each option 1-10 on speed, risk, and upside. Output one line per option.`

Keep the schema identical across all agents. Only the framing changes.

### 3. Create framing variations

Use slight framing differences to induce stochastic diversity without changing the task itself. Cycle through these patterns as needed:

1. Neutral: analyze objectively
2. Risk-averse: weigh downside heavily
3. Growth-oriented: optimize for upside
4. Contrarian: challenge the default view
5. First-principles: ignore convention
6. User-centered: optimize for the end user
7. Resource-constrained: assume tight time and budget
8. Long-term: optimize for the multi-year outcome
9. Measurable-only: favor what can be verified
10. Systems view: emphasize second-order effects

If `N` is greater than 10, repeat the cycle. If the task is very sensitive to framing, keep the variations lighter and closer to neutral.

### 4. Spawn Codex subagents in parallel

Use the current Codex subagent feature, not older task-fan-out patterns.
These model settings apply only to spawned subagents. Do not treat them as an instruction to downgrade or change the main agent.

Default configuration:

- `agent_type: "default"`
- `model: "gpt-5.4-mini"`
- `reasoning_effort: "xhigh"`

Escalate only when justified:

- Use `gpt-5.4-mini` and `reasoning_effort: "xhigh"` for spawned subagents only when the user explicitly asks for the larger model or the task is unusually difficult.
- Use `agent_type: "explorer"` only when every agent is answering the same bounded read-only codebase question.
- Avoid `agent_type: "worker"` for this skill unless the user explicitly wants parallel implementation branches.

Context strategy:

- Prefer passing a clean prompt plus only the relevant artifacts or constraints.
- Use `fork_context: true` only when the agents genuinely need the exact current thread context and that context does not already contain your conclusions.

Prompt template:

```text
{framing variation}

Analyze this problem independently. Do not assume what other agents will say.

Problem:
{problem}

Context:
{only the relevant facts, options, and constraints}

Required output:
{fixed output schema}

Be specific. State uncertainty explicitly. Keep the response concise and decision-useful.
```

Track each spawned agent ID alongside its framing variation so you can attribute outliers later.

### 5. Collect results and aggregate mechanically

After spawning all agents, wait on the agent set and aggregate only completed, usable responses. If one or more agents fail, exclude them and report the effective `N`.

Aggregation rules:

- Ranking tasks: use Borda-style scoring. If there are `M` options, award `M` points for first place, `M-1` for second, and so on.
- Recommendation tasks: normalize similar ideas, count support, and merge only clearly equivalent recommendations.
- Scorecard tasks: compute mean, median, and spread for each option. Flag high-variance options.
- Binary tasks: count YES vs NO and summarize the strongest arguments on each side.

Classify findings with thresholds based on the number of usable responses:

- Consensus: at least 70 percent of responding agents support the same conclusion
- Divergence: no option reaches 70 percent, or the distribution is meaningfully split
- Outlier: a unique idea supported by only one agent, or by at most 20 percent when `N` is larger

If all agents agree, call out unanimity explicitly. If no view dominates, treat the split itself as the finding.

### 6. Write the report

Write the full report to `active/consensus/consensus_report.md` unless the workspace has a stronger project-specific storage convention. Create `active/consensus/` if it does not exist. Overwrite prior reports unless the user asked to preserve history.

Use this structure:

```markdown
# Stochastic Multi-Agent Consensus Report

**Problem**: {problem}
**Agents requested**: {requested_n}
**Agents used**: {effective_n}
**Date**: {date}

## Consensus
{Items with strong agreement}

## Divergences
{Meaningful splits or high-variance judgments}

## Outliers
{Unique ideas worth inspection, tagged with framing variation}

## Aggregation Table
{Scores, counts, or tallies}

## Individual Agent Summaries
{One concise summary per agent with framing noted}
```

### 7. Deliver the user-facing result

Return:

- One short paragraph summarizing the overall finding
- The top 3 consensus items, if they exist
- The most important divergence that still needs human judgment
- The most interesting outlier worth considering
- The report path

## Configuration

Use these defaults unless the user says otherwise:

- Agents: `5`
- Default model: `gpt-5.4-mini`
- Default reasoning: `xhigh`

Heuristics:

- Binary yes/no calls usually need only 3 to 5 agents.
- Ranking many options usually benefits from 5 to 7 agents.
- Increase `N` only when broader variance sampling matters more than additional per-agent depth.

## Edge Cases

- If the user asks for fewer than 3 agents, warn that the result is weak and use 3 unless they insist.
- If the options are underspecified, ask for a sharper option list before polling.
- If agent outputs do not follow the schema, salvage only what can be compared confidently and note the deviation.
- If all usable responses are low-confidence or highly divergent, say so plainly instead of forcing a false consensus.

## Fallbacks

- Document the most reliable workaround from the session as an explicit fallback so the next run does not have to rediscover it.

## Validation

- Treat non-zero exits and tracebacks as workflow stops, summarize the failure, and retry only through a documented fallback.

## Workflow Simplifications

- Resolve the target skill path, helper scripts, and required reference files once, then reuse that context instead of reopening the same assets repeatedly.
