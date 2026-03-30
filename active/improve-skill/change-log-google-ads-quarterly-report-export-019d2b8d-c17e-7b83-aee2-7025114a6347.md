# Change Log: google-ads-quarterly-report-export

**Session ID**: 019d2b8d-c17e-7b83-aee2-7025114a6347

## Changes

- Merged `Fallbacks` guidance into SKILL.md
- Merged `Workflow Simplifications` guidance into SKILL.md
- Merged `Guardrails` guidance into SKILL.md
- Manual follow-up patch removed Chrome/DevTools/CDP recovery language from the export flow and kept the skill Playwright-MCP-only.
- Manual follow-up patch added explicit orchestrator subtasks and wait semantics so the main agent must wait for quarter export subagents before workbook build, Sheets delivery, or completion messaging.
- Manual follow-up patch added a no-reuse guardrail for prior raw exports after live Playwright failures unless the user explicitly asks for reuse.

## Backup

- `C:\.codex\Playground\active\improve-skill\backups\google-ads-quarterly-report-export-20260326T192349Z`
