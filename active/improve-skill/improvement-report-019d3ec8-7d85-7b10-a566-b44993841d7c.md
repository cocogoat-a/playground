# Improve-Skill Report

**Session ID**: `019d3ec8-7d85-7b10-a566-b44993841d7c`
**Session Path**: `C:\Users\daniv\.codex\sessions\2026\03\30\rollout-2026-03-30T15-46-59-019d3ec8-7d85-7b10-a566-b44993841d7c.jsonl`
**Target Skill**: `spreadsheet-cleanup`
**Mode**: `apply`

## Reason

- The session showed that Google Sheets cleanup was being routed through Google Drive MCP instead of the live Sheets UI.
- The requested improvement was to make Playwright MCP the primary path so rows and columns can be deleted in bulk through filters, sorting, and direct row or column selection.

## Applied Changes

- Rewrote the Google Sheets workflow in `SKILL.md` to make Playwright MCP the default path.
- Added bulk-edit tactics for filters, sorts, row-header deletion, and column-letter deletion.
- Replaced the old Google MCP fallback guidance with UI-first fallbacks based on edit access, tab duplication, and local export.
- Tightened validation and guardrails around filtered deletions, right-to-left column removal, and post-delete verification.
- Updated `agents/openai.yaml` so the skill prompt now calls for Playwright-based Google Sheets bulk edits.

## Backup

- `C:\.codex\Playground\active\improve-skill\backups\spreadsheet-cleanup-20260330T125541Z`

## Residual Risk

- This skill now intentionally conflicts with the workspace preference that says Google Sheets tasks should use Google MCP. The skill itself now documents Playwright as the primary path because that was the explicit change requested in this session.
