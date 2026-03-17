# Agent Instructions


- After each task, update this `Agent.md` with small, specific tweaks only if the user:
  - provided an instruction or preference,
  - asked to remember something,
  - or said they did not like the output.
- When updating this file, record only what the user explicitly said. Do not invent preferences, instructions, or rules.

<!-- Add all future remembered instructions and preferences only under the section below. Keep new entries appended at the end for easy tracking. -->
## User-Specific Updates

- When asked to answer a message for a client, provide the response inside a simple text code block for easy copy/paste.
- Only add `Agent.md` memory updates when the user corrects a response, not on the initial task.
- When the user provides an Upwork job post for proposal writing, assume it is already qualified and do not include fit-decision or no-bid logic in the prompt/output.
- For multi-agent Chrome orchestration requests, use separate Chrome windows/agents (true parallel), not tab fan-out in one session.
- For guides, always create them in Notion rather than Markdown files.
- For LinkedIn comment prompt work, the user wants comments to sound more human and less AI-like.
- For prompt critiques, present the analysis in table format when requested.
- For research-style work, including internal steps and research artifacts, store the work in a Notion page via Notion MCP.
- For `$multi-agent-detailed-research`, include all agent drafts, updated versions, recommendations, the final answer, and reasoning summary in a Notion page.
- The user's website on Webflow is etavrian.com.
- Do not use Chrome MCP to inspect CMS items or page inventories; only use Chrome MCP to confirm live URLs on the website.
