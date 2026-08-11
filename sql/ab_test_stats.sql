WITH stats AS (
  SELECT
    ab_group,
    COUNT(*) AS n,
    SUM(synthetic_purchase) AS conversions,
    SUM(synthetic_purchase) / COUNT(*) AS rate
  FROM
    `inductive-talon-503905-q0.ab_funnel_project.user_funnel_synthetic`
  GROUP BY
    ab_group
),

pivoted AS (
  SELECT
    MAX(CASE WHEN ab_group = 'control' THEN n END) AS n_control,
    MAX(CASE WHEN ab_group = 'control' THEN conversions END) AS conv_control,
    MAX(CASE WHEN ab_group = 'control' THEN rate END) AS rate_control,
    MAX(CASE WHEN ab_group = 'variant' THEN n END) AS n_variant,
    MAX(CASE WHEN ab_group = 'variant' THEN conversions END) AS conv_variant,
    MAX(CASE WHEN ab_group = 'variant' THEN rate END) AS rate_variant
  FROM
    stats
)

SELECT
  rate_control,
  rate_variant,
  rate_variant - rate_control AS lift,
  (conv_control + conv_variant) / (n_control + n_variant) AS pooled_rate,
  SQRT(
    ((conv_control + conv_variant) / (n_control + n_variant))
    * (1 - (conv_control + conv_variant) / (n_control + n_variant))
    * (1.0 / n_control + 1.0 / n_variant)
  ) AS standard_error,
  (rate_variant - rate_control) /
  SQRT(
    ((conv_control + conv_variant) / (n_control + n_variant))
    * (1 - (conv_control + conv_variant) / (n_control + n_variant))
    * (1.0 / n_control + 1.0 / n_variant)
  ) AS z_score
FROM
  pivoted;
