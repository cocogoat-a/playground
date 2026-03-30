---
name: spreadsheet-cleanup
description: Clean low-signal spreadsheets and ad-platform exports by removing analytically useless rows and columns. Use when Codex needs to clean Google Sheets or local `.xlsx`, `.csv`, or `.tsv` files, especially Google Ads or Meta Ads exports, by trimming 0-cost/0-conversion rows, dropping blank or placeholder columns, removing duplicate or constant low-value fields, and preserving context needed for analysis.
---

# Spreadsheet Cleanup

## Overview

Use this skill to reduce spreadsheets to the data that still matters for analysis. Apply it to Google Ads and Meta Ads exports first, then reuse the same principles for generic spreadsheets that contain blank, duplicated, placeholder, or constant low-signal data.

## Workflow

1. Identify the spreadsheet shape.
- Inspect each sheet or tab independently.
- For Google Sheets, use Google MCP to read each tab before editing it.
- For local files, run `scripts/profile_cleanup_candidates.py` first to find low-signal rows and columns.
- Read `references/ads-export-patterns.md` when the file looks like an ad-platform export.

2. Normalize the table before making decisions.
- Treat the first non-empty row as the header row unless the sheet clearly contains a preamble.
- Compare headers case-insensitively, but preserve original header text in the cleaned output.
- Treat empty strings, whitespace, `--`, `[]`, `None`, `null`, and `N/A` as placeholder values.
- Parse numeric strings safely, including currency symbols, commas, parentheses, and percents.

3. Remove low-signal rows.
- If a sheet contains both a total cost/spend column and a direct conversions/results column, remove rows only when both values parse to zero.
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

5. Apply edits safely.
- For Google Sheets, use Google MCP for reads and writes.
- If direct row or column deletion is unavailable, rewrite the compact cleaned table rather than depending on structural delete operations.
- For local `.xlsx` files, prefer `openpyxl`; for `.csv` and `.tsv`, use standard delimited-file workflows.
- Preserve formatting when the spreadsheet already has meaningful presentation.
- Prefer non-destructive cleanup unless the user asked to overwrite the original.

## Detection Rules

### Cost and conversions columns

- Prefer direct spend columns such as `Cost`, `Spend`, or `Amount spent`.
- Prefer direct result columns such as `Conversions`, `Conv.`, `Conv. (Platform comparable)`, `Results`, or another direct result count.
- Do not treat `Avg. cost`, `Conv. rate`, `Cost / conv.`, `Conv. value`, or `Conv. value/Cost` as row-removal inputs.

### Constant-column policy

- Drop a constant column when it is placeholder-like or operational noise.
- Keep a constant column when removing it would make the remaining data ambiguous.
- If a constant column could matter, keep it unless another retained column already carries the same meaning.

## Local Helper

- Run `scripts/profile_cleanup_candidates.py <path>` to profile a local workbook or flat file.
- Use `--sheet <name>` to analyze one sheet in an `.xlsx` file.
- Use `--json` when a machine-readable report is easier for the current task.
- Install `openpyxl` before analyzing `.xlsx` files if it is not already available.

## References

- Read `references/ads-export-patterns.md` for concrete Google Ads and Meta Ads cleanup patterns, including conservative handling of demographic tabs.
