# Stochastic Multi-Agent Consensus Report

**Problem**: Improve a LinkedIn comment-generation prompt so the output sounds more human and less AI-shaped
**Agents**: 10
**Date**: 2026-03-14

## Consensus

The strongest consensus is that the current prompt is too visibly scaffolded. It asks for the right ingredients, but the model can feel those ingredients as separate boxes to tick, which produces comments that read polished, segmented, and synthetic.

### Top consensus recommendations

1. **Remove rigid visible templates** - supported by 10/10 agents  
   The A, B, C template framing is the biggest source of repeated cadence. It pushes the model into comments that feel assembled rather than spoken.

2. **Add a naturalness rejection test** - supported by 9/10 agents  
   The prompt needs a hard filter for comments that could fit under many posts, or comments where each clause obviously maps to a rule.

3. **Bias shorter and more spoken** - supported by 8/10 agents  
   Human LinkedIn comments from operators usually read faster, rougher, and less balanced than polished AI output. A tighter word range helps.

4. **Generate several options and keep the least polished one** - supported by 8/10 agents  
   Single-pass generation tends to optimize for neatness. Multi-candidate selection produces comments that feel more offhand and believable.

5. **Separate must-haves from style guidance** - supported by 7/10 agents  
   The model should know what is mandatory, but the sentence should not sound like it is walking through a mandatory list in order.

## Divergences

### 1. Keep or relax the explicit closer rule

- **Keep it explicit (6/10)**: The grounded closer helps replyability and keeps comments from ending flat.
- **Relax it slightly (4/10)**: The closer should stay, but it should be described as a feeling rather than a required slot.

**Synthesis**: Keep the closer, but tell the model not to make the seam visible.

### 2. Keep or remove the praise plus observation split

- **Keep both, but blend them (7/10)**: The praise and operator truth are still useful, just not as visibly separate fragments.
- **Collapse them into one move (3/10)**: One understated reaction may be enough when the detail already carries the insight.

**Synthesis**: Keep both constraints, but rewrite them so the comment can sound like one natural thought.

## Outliers

1. **Drop the emoji rule entirely** - 2/10  
   A small minority thought the emoji contributes to performative tone, but most agents felt it is acceptable if tightly controlled.

2. **Allow sentence fragments instead of a full sentence** - 2/10  
   This could increase realism, but it introduces more variability than the current task needs.

## Raw Rankings or Scores

| Recommendation | Support | Band |
|---|---:|---|
| Remove A, B, C template scaffolding | 10/10 | Consensus |
| Add naturalness and interchangeability rejection tests | 9/10 | Consensus |
| Tighten length and spoken cadence | 8/10 | Consensus |
| Draft multiple candidates and select the least polished | 8/10 | Consensus |
| Separate hard constraints from style cues | 7/10 | Consensus |
| Keep closer but hide the seam | 6/10 | Split |
| Keep praise and operator truth, but blend them | 7/10 | Consensus |
| Drop emoji rule | 2/10 | Outlier |
| Allow fragments instead of a sentence | 2/10 | Outlier |

## Individual Agent Summaries

1. **Neutral baseline**  
   The prompt has good specificity controls, but the sentence shape is too easy for the model to overfit. Confidence: 9/10.

2. **Risk-averse**  
   Too many visible slots create brittle, samey outputs and increase the chance of comma-stacked AI cadence. Confidence: 9/10.

3. **Growth-oriented**  
   Naturalness improves when the prompt drafts multiple candidates and chooses the least polished one instead of the neatest one. Confidence: 8/10.

4. **Contrarian**  
   The template section should be removed entirely because it is teaching a reusable pattern, not a human reaction. Confidence: 9/10.

5. **First-principles**  
   The core target should be simple: sound like a real agency owner typed the comment in 20 seconds. Confidence: 10/10.

6. **End-user empathy**  
   Readers notice when a comment could be copied under twenty posts. The prompt needs a swapability fail test. Confidence: 8/10.

7. **Resource-constrained**  
   Fewer instructions with sharper rejection criteria will outperform a long checklist of stylistic components. Confidence: 8/10.

8. **Long-term**  
   Repeated comments will feel synthetic unless cadence varies. The prompt should ask for different rhythms during candidate generation. Confidence: 8/10.

9. **Data-driven**  
   The current 10 to 35 word range is too loose. A narrower band produces more believable comments. Confidence: 8/10.

10. **Systems thinking**  
   The best prompt structure is layered: hard constraints, voice cues, rejection tests, then candidate selection. Confidence: 9/10.

## Method Notes

This was an approximate sequential fallback run of the stochastic-consensus method. True parallel subagents were not available in this environment, so the analysis used 10 framing variations in one session and then aggregated the shared conclusions.

## Recommended Prompt Changes

- Delete the A, B, C template section.
- Tell the model to sound like it was typed quickly by an operator, not composed by a copywriter.
- Add an interchangeability test: if the comment fits another post, reject it.
- Add a seam test: if every clause clearly corresponds to a rule, reject it.
- Narrow the target length and punctuation so the output stays short and spoken.
- Generate multiple candidates and select the one that feels most offhand, not most polished.
