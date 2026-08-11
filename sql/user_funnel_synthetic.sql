WITH user_groups AS (
  SELECT
    user_pseudo_id,
    CASE
      WHEN MOD(ABS(FARM_FINGERPRINT(user_pseudo_id)), 2) = 0 THEN 'control'
      ELSE 'variant'
    END AS ab_group
  FROM (
    SELECT DISTINCT user_pseudo_id
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201107'
  )
),

user_funnel AS (
  SELECT
    e.user_pseudo_id,
    g.ab_group,
    MAX(CASE WHEN e.event_name = 'begin_checkout' THEN 1 ELSE 0 END) AS reached_checkout,
    MAX(CASE WHEN e.event_name = 'purchase' THEN 1 ELSE 0 END) AS real_purchase
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` e
  JOIN
    user_groups g
  ON
    e.user_pseudo_id = g.user_pseudo_id
  WHERE
    e._TABLE_SUFFIX BETWEEN '20201101' AND '20201107'
    AND e.event_name IN ('page_view', 'view_item', 'add_to_cart', 'begin_checkout', 'purchase')
  GROUP BY
    e.user_pseudo_id, g.ab_group
)

SELECT
  user_pseudo_id,
  ab_group,
  reached_checkout,
  real_purchase,
  CASE
    WHEN real_purchase = 1 THEN 1
    WHEN ab_group = 'variant'
         AND reached_checkout = 1
         AND MOD(ABS(FARM_FINGERPRINT(CONCAT(user_pseudo_id, 'lift'))), 100) < 15
    THEN 1
    ELSE 0
  END AS synthetic_purchase
FROM
  user_funnel;
