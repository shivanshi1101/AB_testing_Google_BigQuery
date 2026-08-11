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

funnel_events AS (
  SELECT
    e.user_pseudo_id,
    g.ab_group,
    e.event_name
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` e
  JOIN
    user_groups g
  ON
    e.user_pseudo_id = g.user_pseudo_id
  WHERE
    e._TABLE_SUFFIX BETWEEN '20201101' AND '20201107'
    AND e.event_name IN ('page_view', 'view_item', 'add_to_cart', 'begin_checkout', 'purchase')
)

SELECT
  ab_group,
  event_name,
  CASE
    WHEN event_name = 'page_view' THEN 1
    WHEN event_name = 'view_item' THEN 2
    WHEN event_name = 'add_to_cart' THEN 3
    WHEN event_name = 'begin_checkout' THEN 4
    WHEN event_name = 'purchase' THEN 5
  END AS stage_order,
  COUNT(DISTINCT user_pseudo_id) AS users_reached
FROM
  funnel_events
GROUP BY
  ab_group,
  event_name,
  stage_order;
