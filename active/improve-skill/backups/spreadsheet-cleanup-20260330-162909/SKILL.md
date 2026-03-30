---
name: spreadsheet-cleanup
description: Clean low-signal spreadsheets and ad-platform exports by removing analytically useless rows and columns. Use when Codex needs to clean Google Sheets or local `.xlsx`, `.csv`, or `.tsv` files, especially Google Ads or Meta Ads exports, by trimming 0-cost/0-conversion rows, dropping blank or placeholder columns, removing duplicate or constant low-value fields, and preserving context needed for analysis. For Google Sheets, prefer Playwright-driven bulk UI edits over connector-based cell rewrites.
---
# Spreadsheet Cleanup

## Overview

Use this skill to reduce spreadsheets to the data that still matters for analysis. Apply it to Google Ads and Meta Ads exports first, then reuse the same principles for generic spreadsheets that contain blank, duplicated, placeholder, or constant low-signal data.

For Google Sheets, default to Playwright MCP in the live Sheets UI. The primary path is bulk cleanup through filters, sorts, row-header selection, and column-letter selection so entire row and column blocks can be removed in place instead of rewriting cells through Google Drive MCP.

## Workflow

1. Identify the spreadsheet shape.
- Inspect each sheet or tab independently.
- For Google Sheets, open the spreadsheet in Playwright MCP, switch through each tab, and inspect the live table before editing it.
- Confirm the header row, frozen rows, totals rows, and the candidate cost/spend and conversions/results columns from the visible sheet, not from memory.
- Prefer UI-native filters, sorts, and range selection over cell-by-cell edits.
- For local files, run `scripts/profile_cleanup_candidates.py` first to find low-signal rows and columns.
- Read `references/ads-export-patterns.md` when the file looks like an ad-platform export.

2. Normalize the table before making decisions.
- Treat the first non-empty row as the header row unless the sheet clearly contains a preamble.
- Compare headers case-insensitively, but preserve original header text in the cleaned output.
- Treat empty strings, whitespace, `--`, `[]`, `None`, `null`, and `N/A` as placeholder values.
- Parse numeric strings safely, including currency symbols, commas, parentheses, and percents.

3. Remove low-signal rows.
- If a sheet contains both a total cost/spend column and a direct conversions/results column, remove rows only when both values parse to zero.
- In Google Sheets, use filters or temporary sorts to cluster zero/zero rows together before deleting them.
- Delete matching rows in bulk from the row headers. Prefer contiguous row-range deletion or filtered visible-row deletion over repeated single-row actions.
- Reset or clear filters after each destructive pass so the next selection is based on the full remaining dataset.
- Keep rows with spend but no conversions.
- Keep rows with conversions but zero recorded cost.
- Ignore rate, value, and ratio columns when deciding row removal.
- Only apply the zero/zero rule when both metrics are detected reliably.

4. Remove low-signal columns.
- Remove columns that are fully blank after row cleanup.
- Remove columns that contain only placeholder values.
- Remove duplicate columns when one is redundant.
- Remove single-value columns only when they add little analytical value.
- Remove constant operational columns such as fixed bidding fields, duplicate currency fields, repeated status fields, or repeated structural labels like `Level` when they do not change interpretation.
- Keep context columns such as campaign names, ad set names, ad group names, dates, time buckets, demographic buckets, devices, and locations even if many values repeat.
- Be conservative with flattened text-report tabs such as demographic exports when metrics are embedded inside one text field.
- In Google Sheets, inspect the full kept column before deleting it, then remove adjacent low-signal columns together when possible.
- When multiple candidate columns are separated, delete from right to left so earlier column letters do not shift under the cursor.

5. Apply edits safely.
- For Google Sheets, use Playwright MCP as the default read and write path.
- Use the Sheets UI to duplicate a tab first when the cleanup should stay non-destructive.
- Prefer filter views, column sorting, row-header selection, and column-letter selection so structural edits happen in bulk.
- If direct row or column deletion is blocked by protected ranges, grouped rows, or merged cells, stop and choose a safer UI path such as duplicating the tab and cleaning the duplicate.
- For local `.xlsx` files, prefer `openpyxl`; for `.csv` and `.tsv`, use standard delimited-file workflows.
- Preserve formatting when the spreadsheet already has meaningful presentation.
- Prefer non-destructive cleanup unless the user asked to overwrite the original.

## Google Sheets UI Tactics

- Use Playwright MCP to keep the cleanup inside the live Google Sheets UI whenever the sheet is editable.
- Start from the actual sheet URL and keep the session attached to the existing browser state so permissions and login state are preserved.
- If the sheet has a header row, turn on a filter for that table before sorting or deleting.
- Sort or filter on the direct spend and conversions columns to isolate zero/zero rows into a visible block.
- Select row ranges from the left row numbers and delete the full rows in one action.
- Select low-signal columns from the top column letters and delete the full columns in one action.
- When columns are adjacent, select and delete them together. When they are not adjacent, delete from right to left.
- After each bulk delete, verify the remaining header row and the first and last kept rows before moving to the next tab.

## Detection Rules

### Cost and conversions columns

- Prefer direct spend columns such as `Cost`, `Spend`, or `Amount spent`.
- Prefer direct result columns such as `Conversions`, `Conv.`, `Conv. (Platform comparable)`, `Results`, or another direct result count.
- Do not treat `Avg. cost`, `Conv. rate`, `Cost / conv.`, `Conv. value`, or `Conv. value/Cost` as row-removal inputs.

### Constant-column policy

- Drop a constant column when it is placeholder-like or operational noise.
- Keep a constant column when removing it would make the remaining data ambiguous.
- If a constant column could matter, keep it unless another retained column already carries the same meaning.
- Do not preserve a column just because the header sounds important. If the inspected cells are all placeholders such as `--`, the column is low-signal and should be removed.
- Treat bidding and configuration columns such as `Default max. CPC`, `Target CPA`, and `Target ROAS` as removable when the inspected cells are entirely blank or placeholder-only.

## Local Helper

- Run `scripts/profile_cleanup_candidates.py <path>` to profile a local workbook or flat file.
- Use `--sheet <name>` to analyze one sheet in an `.xlsx` file.
- Use `--json` when a machine-readable report is easier for the current task.
- Install `openpyxl` before analyzing `.xlsx` files if it is not already available.

## References

- Read `references/ads-export-patterns.md` for concrete Google Ads and Meta Ads cleanup patterns, including conservative handling of demographic tabs.

## Fallbacks

- If the browser session is view-only, request edit access or export a local copy through the UI and clean that file offline instead of attempting connector-based rewrites.
- If sorting or filtering is blocked by merged cells, grouped rows, or protected ranges, duplicate the tab first and clean the duplicate rather than forcing in-place edits.
- If bulk deletion would be ambiguous because the filter is hiding rows you have not re-checked, clear the filter and verify the exact row set again before deleting.

## Validation

- Before keeping or removing a disputed column, re-read the exact column range from the source sheet and decide from the actual cell values rather than from memory or prior assumptions.
- After every bulk row delete, verify that a non-zero spend row and a non-zero conversions row still exist when they existed before the cleanup.
- After every bulk column delete, confirm that the key analytical dimensions and metric headers are still present and in the expected order.
- Clear temporary filters or sorts before final handoff unless the filtered state is intentionally part of the deliverable.
- When a user challenges a cleanup decision, verify the full inspected sample for that row or column first, then answer with the evidence.
- Treat non-zero exits and tracebacks as workflow stops, summarize the failure, and retry only through a documented fallback.

## Guardrails

- For Google Sheets cleanup, do not default to Google Drive MCP reads and writes when the sheet is editable in the browser. The primary path is Playwright-driven bulk UI editing.
- Do not perform repeated single-row or single-column deletions when the same result can be achieved through one filtered or contiguous bulk delete.
- Do not delete rows from a filtered view until the spend and conversions criteria have been checked against the visible rows.
- Delete separated columns from right to left to avoid accidental header drift during the pass.
- Do not defend a keep/remove decision after the fact unless the relevant range has been re-checked directly.
- Placeholder-only columns are removable low-signal columns even when their headers look analytically meaningful.
- If a judgment call is ambiguous, say so and verify the cells before editing or explaining the decision.
