---
name: google-ads-quarterly-report-export
description: Use when Codex needs to collect Google Ads reports from a live Google Ads account or MCC for quarter-based reporting, especially when the user wants current quarter and last quarter exports, native section exports instead of Report Builder, cleaned data, and one combined Google Sheet deliverable. This skill is for Google Ads UI navigation with Playwright MCP plus Google Sheets delivery.
---
# Google Ads Quarterly Report Export

Use this skill for reusable Google Ads reporting runs from a live account or MCC child account.

The default output is one cleaned Google Sheet containing both the current quarter and the last quarter in the same report tabs, labeled by a `Quarter` column.

Treat every request as a fresh reporting run. Do not reuse prior exports, prior spreadsheets, prior cleaned workbooks, or assumptions from earlier report runs.

Use browser automation for this skill because the required Google Ads exports are UI-only and login-dependent. Prefer Google MCP for Drive and Google Sheets delivery when practical.
Use Playwright MCP as the default browser automation path for this skill. Do not switch to a CLI browser workflow unless the user explicitly overrides that requirement.

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

## Subagent Defaults

Use spawned subagents only for the export branches in this skill. These settings apply only to spawned agents, not to the main orchestrator.

- `agent_type: "default"`
- `model: "gpt-5.4-mini"`
- `reasoning_effort: "high"`

Keep the main orchestrator on its normal model settings.

## Parallel Export Topology

Use quarter-split parallelism by default. Do not split work by report section.

Spawn exactly two browser-owner export agents in parallel:

- `Current Quarter Export Agent`
- `Last Quarter Export Agent`

Assign each export agent all of the following:

- one explicit quarter date range
- one isolated download/work directory
- the full section list for that quarter
- its own screenshots, console notes, network notes, and failure evidence

Use separate browser-owner agents or windows for parallel browser work. Do not fan out tabs inside one shared session.

Keep `agency-ops` session reuse as a hard requirement for every branch:

- preserve the existing authenticated browser state
- do not clear cookies or local storage
- do not restart into a clean browser context unless the user explicitly overrides that behavior

## Branch Handoff Contract

Require each export branch to return a structured handoff to the main orchestrator before workbook build:

- account name observed
- CID observed
- exact quarter range used
- per-section export status
- file paths produced
- screenshot paths and console/network notes for any failure, retry, omission, or fallback

Do not let a branch self-publish, self-upload, or continue inventing recovery steps after it has reported a blocking failure.

## Workflow

1. Resolve quarter ranges once at the start of the run.
2. Create one run manifest before any browser export work:
   - map `Current Quarter Export Agent` to the current-quarter date range
   - map `Last Quarter Export Agent` to the last-quarter date range
   - assign an isolated working directory to each branch
   - list the expected filenames for each branch before export starts
3. Open or attach to the live Google Ads session with Playwright MCP.
4. Reuse the existing authenticated browser state and keep the current session intact:
   - prefer the existing live Google Ads tab if it is already open
   - if Playwright MCP cannot reliably control the already-open page, attach to the live browser tab via CDP instead of starting a fresh browser context
   - do not clear cookies or local storage
   - treat unexpected sign-out or session reset as a failure to diagnose, not a reason to start fresh blindly
5. If operating from MCC, select the child account by exact name or CID.
6. Verify the active account context before any export:
   - confirm the visible account name and CID match the requested target
   - if the session started in the wrong MCC or child account, stop and switch before exporting anything
7. Resolve quarter ranges explicitly:
   - current quarter = quarter containing today's date, exported through today's date when the quarter has not ended yet
   - last quarter = the full immediately preceding quarter
   - never force a future end date in Google Ads just to reach the calendar quarter boundary
8. Spawn exactly two export agents in parallel, one for each quarter in the run manifest.
9. Require each export branch to:
   - attach to the live Google Ads session through the preserved authenticated state
   - verify visible account name, CID, and the visible date label before every export
   - export the full section list for its assigned quarter only
   - verify each expected raw file exists in its own working directory before moving to the next section
10. Wait for both branches to finish or for a failure condition that requires orchestration intervention.
11. If one branch loses authenticated Ads state, lands on `about:blank`, or lands on Google sign-in:
   - stop that branch immediately
   - capture a screenshot plus console and network notes before retry
   - retry that branch once in a controlled way
   - if the retry fails, preserve all successful artifacts, stop parallel recovery attempts, and continue the remaining export work serially with one browser owner
12. Clean and consolidate the raw exports into one workbook only after raw file presence is verified for both branches or after serial fallback completes.
13. Upload the cleaned workbook into one Google Sheet.
14. Verify the final Google Sheets file is the intended live deliverable in Drive before finishing.

Always prefer explicit quarter dates over relative language in final delivery notes.
Always collect data from the live account state at the time of the run.

## Google Ads Navigation Rules

Use native section pages and native export controls. Avoid Report Builder entirely.

When using Playwright MCP:

- Keep the existing session instead of starting a clean browser context.
- Save screenshots when a navigation, filter change, export, or download flow fails.
- Check browser console and network activity when the page behaves unexpectedly, especially when tables fail to render or export menus do not open.
- If a navigation or reopen lands on `about:blank` or Google sign-in, stop and escalate for re-authentication instead of repeatedly reopening Ads.
- When switching accounts in MCC, prefer the account picker or accounts table with exact account name/CID over brittle overview-card refs.
- If a visible control exists but the normal MCP click path is unreliable, retry with the exact snapshot element ref or a page-script DOM click before abandoning the section.
- Require every branch to confirm the visible Google Ads date label matches its assigned quarter range before every export.

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
- When the export control is missing or broken, script the visible table and its pagination through page script or CDP, then save the extracted rows under the standard quarter filename.
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
Use isolated branch working directories so the current-quarter and last-quarter agents cannot overwrite or mix files during parallel export.
After each export, verify the expected file exists in the current branch run directory before moving to the next section or quarter.

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

Keep Google Sheets import and final delivery in the main orchestrator thread unless the user explicitly asks for delegated delivery behavior.

If Google MCP is not practical for the final import step, use Playwright MCP with the existing authenticated Google session:

- create a new spreadsheet
- import the cleaned workbook
- rename the spreadsheet if the user provided a title or if a clear account-based title is available
- if rerunning or replacing the same report, avoid leaving duplicate Drive items with the same title unless the user explicitly wants versioned copies
- verify the newest modified file is the one you intend to deliver; do not trust upload-dialog location shortcuts when duplicate or trashed copies exist
- if workbook import is unreliable, generate TSVs from the workbook tabs and paste each tab into a fresh spreadsheet, then rename the document and sheet tabs explicitly
- if a sheet-by-sheet paste loop is interrupted, inspect the live spreadsheet state before adding more tabs or replaying the import steps

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
- Review the orchestration text against these scenarios after edits:
  - both quarter branches succeed
  - one branch fails once and succeeds on retry
  - one branch fails twice and degrades to serial execution
  - one section is unavailable in one quarter
  - both branches finish without file-name collisions or cross-contamination

## Notes

- Household income may be unavailable in some accounts or regions.
- Some Google Ads pages expose slightly different export menus; prefer native export first and use fallback extraction only when direct export is missing.
- If the user asks for a different report mix, keep the same workflow and only narrow the section list.

## Fallbacks

- If the MCC overview cards are unstable, switch accounts through the account picker or accounts table using the exact account name or CID.
- If the export menu shows both `Excel .csv` and `.csv`, choose the exact format deliberately and capture a screenshot before retrying unstable menu clicks.
- If Playwright MCP lands on the wrong page state but the user is already logged in elsewhere, inspect the existing browser pages and attach to the live Ads or Sheets tab before reopening the product from scratch.
- If the native demographic export menu is unavailable, open the detailed table and extract it through DOM or CDP pagination instead of skipping the section.
- If Google Sheets import does not land on a clean editable grid, pivot to a fresh spreadsheet and paste workbook-generated TSV tabs instead of repeatedly retrying the same broken import flow.
- If a quarter branch loses authenticated Ads state, retry that branch once with captured evidence, then stop parallel recovery and degrade the remaining work to one serial browser owner.
- Document the most reliable workaround from the session as an explicit fallback so the next run does not have to rediscover it.
## Workflow Simplifications

- Resolve quarter date ranges, working directory, and target account context once at the start of the run, then reuse them across sections.
- Resolve the live Ads page, live Sheets page, working directory, and expected export filenames once at the start of the run, then reuse that state across sections.
- Resolve the branch-to-quarter mapping and expected branch outputs once at the start of the run, then reuse that manifest throughout export, fallback, cleanup, and delivery.
- Resolve the target skill path, helper scripts, and required reference files once, then reuse that context instead of reopening the same assets repeatedly.
## Guardrails

- Keep current-quarter exports quarter-to-date when the quarter is still in progress.
- Do not try to recover a lost Google Ads session by blindly reopening Ads pages after Playwright drifts to `about:blank` or sign-in.
- Prefer stable MCC account lists over transient overview-card refs when selecting the child account.
- Use Playwright MCP as the default browser automation path for this skill.
- If a live logged-in Google Ads tab already exists, attach to that tab via MCP or CDP instead of restarting a new browser context.
- When a demographics export control is missing or broken, extract the detailed visible table through page script or CDP pagination and save it under the standard quarter filename.
- Do not let a partially completed Google Sheets import continue blindly after an interrupted paste loop; inspect the live sheet state first.
- Do not split browser work by report section when using subagents; split only by quarter.
- Do not let both quarter branches make independent recovery decisions after a blocking failure; route recovery through the main orchestrator.
- Do not run the workbook helper until the orchestrator has verified raw export coverage from both branches or completed the serial fallback path.
- Do not use Chrome MCP for this skill; use Playwright MCP only. The main agent must launch subagents for quarter exports, divide export work into explicit subtasks, and wait for all spawned export agents to finish or fail before any workbook build, fallback reuse decision, or Google Sheets delivery. Do not claim completion while any export subagent is still running.
## Safety

- Preserve the existing authenticated browser state and do not attempt cookie or profile reconstruction unless the user explicitly asks for that kind of recovery work.
