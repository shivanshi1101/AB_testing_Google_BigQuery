# Power BI Dashboard: Build Notes

## Data source connection
- Connector: **Google BigQuery** (Power BI native connector)
- Import mode (not DirectQuery)
- Tables loaded (choose **Transform Data**, not Load, to review column types first):
  - `funnel_stage_counts` - users reached per funnel stage, per group
  - `user_funnel_synthetic` - user-level funnel + synthetic conversion flag
  - `ab_test_stats` - conversion rates, lift, z-score (single summary row)

## Suggested visuals

1. **Funnel chart** - stage-by-stage user counts, split by `ab_group`
   (built from `funnel_stage_counts`)
   - Group: `event_name`
   - Values: `users_reached`
   - Add an `ab_group` **slicer** alongside it to toggle Control / Variant

2. **KPI cards** (from `ab_test_stats`):
   - `rate_control` → titled "Control Conversion Rate"
   - `rate_variant` → titled "Variant Conversion Rate"
   - `lift` → titled "Conversion Lift"
   - `z_score` → titled "Z-Score"

3. **Significance indicator** - DAX measure (see below), shown as a Card

4. **Bar chart** - conversion rate by group
   - `ab_test_stats` is a single summary row (one row with `rate_control` and
     `rate_variant` as separate columns), so it **cannot** be split into a bar
     chart by `ab_group` directly — dropping `rate_control` onto a chart axis'd
     by `ab_group` just repeats the same static value across every category.
   - To build this as an actual bar chart: go to Power Query → select
     `ab_test_stats` → select the `rate_control` and `rate_variant` columns →
     **Transform → Unpivot Columns**. This reshapes the two columns into two
     rows (`Attribute` - group name, `Value` = rate), which can then be used
     as a normal bar chart axis/value pair.
   - Simpler alternative: skip the bar chart and rely on the 4 KPI cards above
     - this is what the dashboard build actually used.

## Card formatting (raw decimals display incorrectly by default)

`rate_control`, `rate_variant`, and `lift` are stored as raw decimals
(e.g. `0.0111` = 1.11%). Left at default formatting, Power BI rounds these to
2 decimal places as plain numbers, which collapses distinct values into
near-identical displayed digits (e.g. both control and variant showing as
"0.01"–"0.02", and Lift showing as "0.01" when its real value is 0.005).

**Z-Score does not have this problem** - its real value (~3.06) is already in
a range where 2 decimal places is meaningful, so no format change is needed
for that card.

**To fix the 3 rate/lift cards:**
1. Click the card → Format pane (paintbrush icon)
2. Scroll to **Callout value** → expand it
3. Set **Display units** to `None`
4. Set **Value decimal places** to `2`
5. Change the number format from General/Decimal to **Percentage** — this
   multiplies the value by 100 before rounding, so `0.0111` correctly displays
   as `1.11%` instead of `0.01`. (If not available directly in the Callout
   value section, right-click the field in the Fields well → Format → Percentage.)

Expected result after formatting:
| Card | Displays as |
|---|---|
| Control Conversion Rate | 1.11% |
| Variant Conversion Rate | 1.61% |
| Conversion Lift | 0.50% |
| Z-Score | 3.06 |

## DAX measures

```dax
Significance Label = 
IF(ABS(SELECTEDVALUE('ab_test_stats'[z_score])) > 1.96, "Statistically Significant", "Not Significant")
```

Place this measure in its own Card visual alongside the 4 KPI cards.

## Layout notes
- Add a title text box at the top: "A/B Experimentation & Conversion Funnel Evaluation"
- Add a smaller text box referencing the synthetic methodology disclosure
  (see `docs/methodology.md`), so anyone viewing the dashboard understands the
  group assignment and lift are simulated on top of real GA4 data.
- Keep control/variant color coding consistent across all visuals
  (e.g. grey = control, purple/blue = variant).
- Export a full-dashboard screenshot to `powerbi/screenshots/full_dashboard.png`
  and embed it in the main README for GitHub visibility.
