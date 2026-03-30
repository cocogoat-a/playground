# Improvement Report

Target skill: `C:\Users\daniv\.codex\skills\google-ads-quarterly-report-export`

Session-based findings applied:

- The workflow needs an explicit account-context verification step before export because this session initially started from the wrong MCC/account context.
- The workbook helper did not remove rows where both `Cost` and `Impr.` were zero, which forced a manual cleanup pass.
- The Drive/Sheets fallback needs stronger guidance for replacement runs because duplicate files with the same title and trashed copies made final verification unreliable.

Actions taken:

- Created backup at `C:\.codex\Playground\active\improve-skill\backups\google-ads-quarterly-report-export-20260326-160735`
- Updated `SKILL.md` with account verification, zero-stat cleanup, and Drive replacement verification guidance
- Updated `build_google_ads_quarterly_workbook.py` to drop rows where both impressions and cost are zero when those columns exist

Validation plan:

- Run the skill validator
- Run Python compilation against the helper script

Residual risk:

- Google Drive UI behavior can still vary by account and duplicate-file state, but the skill now documents the safer verification path
