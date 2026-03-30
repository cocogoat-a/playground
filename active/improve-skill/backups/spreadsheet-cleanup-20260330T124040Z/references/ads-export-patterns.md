# Ads Export Patterns

Use these patterns as grounded examples when cleaning Google Ads or Meta Ads exports.

## Google Ads export patterns from the sample workbook

### `Time of Day`

- This tab contains direct `Cost` and `Conversions` columns.
- Many rows have `Cost = 0` and `Conversions = 0`; those rows are low-signal and removable.
- Keep rows with spend but no conversions because they still show wasted spend.
- Keep rows with conversions but zero recorded cost only if the source data actually contains that case.
- Keep `Day of the week`, `Hour of the day`, and `Campaign` even when one of those dimensions is repetitive.

### `Devices`

- This tab also contains direct `Cost` and `Conversions` columns.
- Columns such as `Ad group`, `Bid adj.`, and `Ad group bid adj.` are often placeholder-only (`--`, `None`) or constant across the kept rows and are usually removable.
- `Level` can be removable when every kept row is just `Campaign`.
- Keep `Device` and `Campaign` because they are primary analytical dimensions.
- Remove duplicate or constant `Currency code` columns when they do not add meaning.

### `Ad Group Performance`

- This tab may use `Cost` plus `Conv. (Platform comparable)` instead of a plain `Conversions` column.
- Columns like `Default max. CPC`, `Target CPA`, `Target ROAS`, and `Brand inclusions` are often placeholder-only or constant low-signal fields.
- Duplicate `Currency code` columns are removable when they carry the same constant value.
- Constant `Ad group status`, `Status`, or `Status reasons` fields are removable when they are identical across the retained rows and do not affect interpretation.
- Keep `Ad group`, `Campaign`, and any segmentation fields that still explain how rows differ.

### `Age` and `Gender`

- These tabs can arrive as partially flattened report exports.
- Blank spacer columns are removable.
- Do not force row cleanup unless you can reliably extract direct cost and conversion values from the embedded text payload.
- Prefer conservative cleanup: remove obvious blank or placeholder structure first, then stop if the remaining text block still contains the actual report.

## Generic heuristics for ads exports

- Treat `--`, `[]`, blank strings, repeated `None`, and repeated `null` as placeholder values.
- Prefer dropping columns that are operational rather than analytical.
- Keep the columns that define the slice being analyzed: campaign, ad set, ad group, ad name, date, device, location, gender, age, audience, placement, or time bucket.
- Remove repeated low-signal context when another retained column already preserves the meaning.

## Generic heuristics for non-ads spreadsheets

- Remove fully blank columns and rows first.
- Remove placeholder-only columns next.
- Remove duplicated columns if one copy is redundant.
- Remove constant columns only when the value does not help explain the data that remains.
- Keep identifiers, dates, categories, and segment labels even when they repeat.
