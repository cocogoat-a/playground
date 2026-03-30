---
name: google-ads-quarterly-report-export
description: Use when Codex needs to collect Google Ads reports from a live Google Ads account or MCC for quarter-based reporting, especially when the user wants current quarter and last quarter exports, native section exports instead of Report Builder, cleaned data, and one combined Google Sheet deliverable. This skill is for Google Ads UI navigation with Playwright CLI plus Google Sheets delivery.
---
# Google Ads Quarterly Report Export

Use this skill for reusable Google Ads reporting runs from a live account or MCC child account.

The default output is one cleaned Google Sheet containing both the current quarter and the last quarter in the same report tabs, labeled by a `Quarter` column.

Treat every request as a fresh reporting run. Do not reuse prior exports, prior spreadsheets, prior cleaned workbooks, or assumptions from earlier report runs.

Use browser automation for this skill because the required Google Ads exports are UI-only and login-dependent. Prefer Google MCP for Drive and Google Sheets delivery when practical.

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

1. Open the live Google Ads session with `playwright-cli`.
2. Reuse the existing authenticated browser state and keep the current session intact:
   - use the `agency-ops` Playwright session
   - do not clear cookies or local storage
   - treat unexpected sign-out or session reset as a failure to diagnose, not a reason to start fresh blindly
3. If operating from MCC, select the child account by exact name or CID.
4. Verify the active account context before any export:
   - confirm the visible account name and CID match the requested target
   - if the session started in the wrong MCC or child account, stop and switch before exporting anything
5. Resolve quarter ranges explicitly:
   - current quarter = quarter containing today's date, exported through today's date when the quarter has not ended yet
   - last quarter = the full immediately preceding quarter
   - never force a future end date in Google Ads just to reach the calendar quarter boundary
6. Export the full report set for current quarter.
7. Export the full report set for last quarter.
8. Clean and consolidate the raw exports into one workbook.
9. Upload the cleaned workbook into one Google Sheet.
10. Verify the final Google Sheets file is the intended live deliverable in Drive before finishing.

Always prefer explicit quarter dates over relative language in final delivery notes.
Always collect data from the live account state at the time of the run.

## Google Ads Navigation Rules

Use native section pages and native export controls. Avoid Report Builder entirely.

When using `playwright-cli`:

- Keep the existing session instead of starting a clean browser context.
- Save screenshots when a navigation, filter change, export, or download flow fails.
- Check browser console and network activity when the page behaves unexpectedly, especially when tables fail to render or export menus do not open.
- If a navigation or reopen lands on `about:blank` or Google sign-in, stop and escalate for re-authentication instead of repeatedly reopening Ads.
- When switching accounts in MCC, prefer the account picker or accounts table with exact account name/CID over brittle overview-card refs.

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
After each export, verify the expected file exists in the current run directory before moving to the next section or quarter.

## Cleanup Rules

Before upload, clean every exported dataset:

- Remove title rows
- Remove date-range rows
- Remove totals rows
- Remove filler rows and empty rows
- Remove empty columns
- Remove rows where both `Cost` and `Impr.` or `Impressions` are zero
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

If Google MCP is not practical for the final import step, use `playwright-cli` with the existing authenticated Google session:

- create a new spreadsheet
- import the cleaned workbook
- rename the spreadsheet if the user provided a title or if a clear account-based title is available
- if rerunning or replacing the same report, avoid leaving duplicate Drive items with the same title unless the user explicitly wants versioned copies
- verify the newest modified file is the one you intend to deliver; do not trust upload-dialog location shortcuts when duplicate or trashed copies exist

After import, prefer opening the `Summary` tab before finishing.
Do not update an older report spreadsheet unless the user explicitly asks for that behavior.

## Validation

Validate the skill folder after edits:

```powershell
python C:\Users\daniv\.codex\skills\.system\skill-creator\scripts\quick_validate.py C:\Users\daniv\.codex\skills\google-ads-quarterly-report-export
```

Validate the workbook helper on realistic raw exports before relying on it.
- Treat non-zero exits and tracebacks as workflow stops, summarize the failure, and retry only through a documented fallback.
- Confirm the visible Google Ads date label matches the intended range before each export.
- Confirm each expected raw export file was created during the current run before starting cleanup or upload.

## Notes

- Household income may be unavailable in some accounts or regions.
- Some Google Ads pages expose slightly different export menus; prefer native export first and use fallback extraction only when direct export is missing.
- If the user asks for a different report mix, keep the same workflow and only narrow the section list.

## Fallbacks

- If the MCC overview cards are unstable, switch accounts through the account picker or accounts table using the exact account name or CID.
- If the export menu shows both `Excel .csv` and `.csv`, choose the exact format deliberately and capture a screenshot before retrying unstable menu clicks.

## Workflow Simplifications

- Resolve quarter date ranges, working directory, and target account context once at the start of the run, then reuse them across sections.

## Guardrails

- Keep current-quarter exports quarter-to-date when the quarter is still in progress.
- Do not try to recover a lost Google Ads session by blindly reopening Ads pages after Playwright drifts to `about:blank` or sign-in.
- Prefer stable MCC account lists over transient overview-card refs when selecting the child account.

## Safety

- Preserve the existing authenticated browser state and do not attempt cookie or profile reconstruction unless the user explicitly asks for that kind of recovery work.
