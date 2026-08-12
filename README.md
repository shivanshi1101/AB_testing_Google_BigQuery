# A/B Experimentation and Conversion Funnel Evaluation

**Tools:** SQL (Google BigQuery) · Power BI
**Data source:** [GA4 Obfuscated Sample E-commerce Dataset](https://console.cloud.google.com/marketplace/product/bigquery-public-datasets/ga4-obfuscated-sample-ecommerce) — `bigquery-public-data.ga4_obfuscated_sample_ecommerce`

## Project Overview

This project simulates a controlled A/B experiment on top of real Google Analytics 4 (GA4)
e-commerce event data from the Google Merchandise Store. It builds a full pipeline
from raw event data, through SQL transformation and statistical validation, to an
interactive Power BI dashboard mirroring how a data/analytics team would evaluate a
product experiment end-to-end.

**Funnel stages analyzed:**
`page_view → view_item → add_to_cart → begin_checkout → purchase`

## Methodology Note (read this first)

The GA4 public dataset reflects **real user behavior**, but it does not contain an actual
A/B test there is no "control" vs "variant" experience baked into the data. To build this
project:

1. Every user was **randomly and deterministically** assigned to a `control` or `variant`
   group using a hash of their `user_pseudo_id` (`FARM_FINGERPRINT`), so the same user always
   lands in the same group.
2. A **synthetic conversion lift** was applied to the `variant` group only: ~15% of variant
   users who reached checkout but did not purchase were flipped to "converted," simulating
   the effect of a real UX improvement.
3. All underlying behavioral data (page views, cart adds, checkout starts) is 100% real GA4
   data — only the group assignment and the lift are synthetic.

This is a standard, transparent technique for building experimentation portfolio projects
on top of observational data, and is disclosed here for full transparency.

## Workflow

The project runs on 3 SQL files, executed and saved as BigQuery views in this order
(note: file 2 must run before file 3, since file 3 depends on the view file 2 creates):

| Order | Description | File | Saved view name |
|---|---|---|---|
| 1 | Build the funnel: distinct users reaching each stage, per group, using random control/variant assignment (`FARM_FINGERPRINT` hash split) | `sql/01_funnel_stage_counts.sql` | `funnel_stage_counts` |
| 2 | Apply a synthetic conversion lift to the variant group (~15% of near-miss checkout users flipped to "converted") | `sql/02_user_funnel_synthetic.sql` | `user_funnel_synthetic` |
| 3 | Two-proportion z-test comparing control vs variant conversion rates | `sql/03_ab_test_stats.sql` | `ab_test_stats` |
| 4 | Power BI dashboard | `powerbi/` | — |

## BigQuery Views Used by Power BI

| View name | Source query | Purpose |
|---|---|---|
| `funnel_stage_counts` | `sql/01_funnel_stage_counts.sql` | Users reached per funnel stage, per group |
| `user_funnel_synthetic` | `sql/02_user_funnel_synthetic.sql` | User-level funnel + synthetic conversion flag |
| `ab_test_stats` | `sql/03_ab_test_stats.sql` | Conversion rates, lift, z-score (single summary row) |

## Results

| Metric | Control | Variant |
|---|---|---|
| Conversion rate | ~1.11% | ~1.61% |
| Lift | — | +0.50 pp (~45% relative) |
| Z-score | 3.06 | |
| P-value | ≈ 0.002 (significant at p < 0.05) | |

**Interpretation:** Variant showed a statistically significant lift in conversion rate over
Control, rejecting the null hypothesis that both experiences perform equally
(z = 3.06, p ≈ 0.002).

## Power BI Dashboard

Connects directly to the three BigQuery views above via Power BI's native BigQuery connector
(Import mode). Includes:

- **Funnel chart** - stage-by-stage drop-off, control vs variant
- **KPI cards** - control conversion rate, variant conversion rate, lift, z-score
- **Significance indicator** - DAX-driven label ("Statistically Significant" / "Not Significant")
- **Bar chart** - conversion rate comparison across groups

See `powerbi/dashboard_notes.md` for full build details and DAX measures.

## How to Reproduce

1. Create a Google Cloud project with BigQuery enabled (free tier is sufficient).
2. Run the SQL scripts in `sql/` **in order (01 → 03)** inside the BigQuery console.
   Each one must be saved as a view before running the next, since 03 depends on
   the view created by 02.
3. Save each query's output as a **view** in your own BigQuery dataset, using the
   view names in the table above.
4. In `sql/03_ab_test_stats.sql`, update the `FROM` path to point at your own
   project/dataset (it currently references `inductive-talon-503905-q0.ab_funnel_project`).
5. Open Power BI Desktop → Get Data → Google BigQuery → connect to your project → load
   the three saved views (choose **Transform Data**, not Load, to review column types first).
6. Build the dashboard visuals described in `powerbi/dashboard_notes.md`.

## Repository Structure

```
ab-funnel-project/
├── README.md
├── .gitignore
├── sql/
│   ├── 01_funnel_stage_counts.sql
│   ├── 02_user_funnel_synthetic.sql
│   └── 03_ab_test_stats.sql
├── powerbi/
│   ├── dashboard_notes.md
│   ├── ab_funnel_dashboard.pbix
│   └── screenshots/
│       ├── funnel_chart.png
│       ├── kpi_cards.png
│       └── full_dashboard.png
└── docs/
    └── methodology.md   (optional, expanded version of the note above)
```

## Disclaimer

This is a portfolio/learning project. The dataset is Google's public GA4 sample e-commerce
export; no proprietary or personal data is used. The A/B test itself is synthetic, as
disclosed above.
