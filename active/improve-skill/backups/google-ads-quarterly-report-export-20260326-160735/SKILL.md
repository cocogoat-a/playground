---
name: google-ads-quarterly-report-export
description: Use when Codex needs to collect Google Ads reports from a live Google Ads account or MCC for quarter-based reporting, especially when the user wants current quarter and last quarter exports, native section exports instead of Report Builder, cleaned data, and one combined Google Sheet deliverable. This skill is for Google Ads UI navigation with Chrome MCP plus Google Sheets delivery.
---

# Google Ads Quarterly Report Export

Use this skill for reusable Google Ads reporting runs from a live account or MCC child account.

The default output is one cleaned Google Sheet containing both the current quarter and the last quarter in the same report tabs, labeled by a `Quarter` column.

Treat every request as a fresh reporting run. Do not reuse prior exports, prior spreadsheets, prior cleaned workbooks, or assumptions from earlier report runs.

## Inputs

Accept these inputs from the user request when available:

- Target account name or CID
- Optional output title override
- Optional report-section override

Default assumptions:

- Google Ads is already authenticated
- Google Sheets is already authenticated
- The target account can be selected uniquely by account name or CID
- Delivery target is Google Sheets only

## Default Report Scope

Collect these sections unless the user explicitly narrows scope:

- Ad Group Performance
- Devices
- Locations
- Time of Day and Day of Week
- Age
- Gender
- Household Income

Important defaults:

- Use detailed ad group stats, not campaign performance
- Export both current quarter and last quarter every time
- Never use Report Builder

## Workflow

1. Open the live Google Ads session in Chrome MCP.
2. If operating from MCC, select the child account by exact name or CID.
3. Resolve quarter ranges explicitly:
   - current quarter = quarter containing today's date
   - last quarter = immediately preceding quarter
4. Export the full report set for current quarter.
5. Export the full report set for last quarter.
6. Clean and consolidate the raw exports into one workbook.
7. Upload the cleaned workbook into one Google Sheet.

Always prefer explicit quarter dates over relative language in final delivery notes.
Always collect data from the live account state at the time of the run.

## Google Ads Navigation Rules

Use native section pages and native export controls. Avoid Report Builder entirely.

When a section exposes a richer table behind a collapsed chart or compact summary view:

- Use `View table` first when needed.
- Use `More -> View detailed report` when that path exists.
- Export from the detailed view rather than the compact summary.

Prefer section-native export menus before any fallback extraction.

## Section Rules

### Ad Group Performance

- Navigate to the `Ad groups` section, not `Campaigns`.
- Export detailed ad group stats for each quarter.
- If the default ad group page is summary-like, use the detailed-report path before exporting.

### Devices

- Navigate to `When and where ads showed -> Devices`.
- Export the detailed table for each quarter.

### Locations

- Navigate to the location reporting view used for native location exports.
- Export the detailed table for each quarter.

### Time of Day and Day of Week

- Navigate to the ad schedule or `When ads showed` view that exposes day/hour reporting.
- Export the day-and-hour report for each quarter.

### Demographics

- Navigate to demographics reporting in the audience/demographics area.
- Collect `Age`, `Gender`, and `Household Income` when available.
- If a demographic tab does not expose direct export controls, use fallback extraction from the visible detailed table.
- If a demographic type is unavailable in the account or region, skip it and note the omission in the final output.

## Export Naming Convention

Save raw quarter exports into a working directory using these identifiers:

- `current_quarter_ad_group_performance.csv`
- `current_quarter_devices.csv`
- `current_quarter_locations.csv`
- `current_quarter_time_of_day.csv`
- `current_quarter_age.csv`
- `current_quarter_gender.csv`
- `current_quarter_household_income.csv`
- `last_quarter_ad_group_performance.csv`
- `last_quarter_devices.csv`
- `last_quarter_locations.csv`
- `last_quarter_time_of_day.csv`
- `last_quarter_age.csv`
- `last_quarter_gender.csv`
- `last_quarter_household_income.csv`

If a quarter/report file is missing because the source tab was unavailable, continue and note it.
Before exporting, clear or replace any old working directory content for that run so no previous files can leak into the new output.

## Cleanup Rules

Before upload, clean every exported dataset:

- Remove title rows
- Remove date-range rows
- Remove totals rows
- Remove filler rows and empty rows
- Remove empty columns
- Normalize Google Ads split UI values when needed
- Add a `Quarter` column to every cleaned table

Only use files created during the current run. Do not merge with older local exports or append into an older workbook.

Use the helper script at [build_google_ads_quarterly_workbook.py](C:\Users\daniv\.codex\skills\google-ads-quarterly-report-export\scripts\build_google_ads_quarterly_workbook.py) to build the workbook deterministically.

## Workbook Shape

Create one workbook per run with these tabs when data exists:

- `Summary`
- `Ad Group Performance`
- `Devices`
- `Locations`
- `Time of Day`
- `Age`
- `Gender`
- `Household Income`

Stack current quarter and last quarter in the same tab for each report type.

Each non-summary tab must include a `Quarter` column so the two periods remain distinguishable after upload.

The `Summary` tab should include:

- account name
- CID if available
- run date
- current-quarter date range
- last-quarter date range
- notes on any skipped or unavailable sections

## Google Sheets Delivery

Prefer Google MCP for Google Sheets and Drive operations.

If Google MCP is not practical for the final import step, use Chrome MCP with Google Sheets:

- create a new spreadsheet
- import the cleaned workbook
- rename the spreadsheet if the user provided a title or if a clear account-based title is available

After import, prefer opening the `Summary` tab before finishing.
Do not update an older report spreadsheet unless the user explicitly asks for that behavior.

## Validation

Validate the skill folder after edits:

```powershell
python C:\Users\daniv\.codex\skills\.system\skill-creator\scripts\quick_validate.py C:\Users\daniv\.codex\skills\google-ads-quarterly-report-export
```

Validate the workbook helper on realistic raw exports before relying on it.

## Notes

- Household income may be unavailable in some accounts or regions.
- Some Google Ads pages expose slightly different export menus; prefer native export first and use fallback extraction only when direct export is missing.
- If the user asks for a different report mix, keep the same workflow and only narrow the section list.
