-- California Hospital Utilization Analytics (2020–2024)
-- BigQuery Standard SQL
-- Statewide monthly utilization and month-over-month analysis.
-- All queries use Facility Name = 'Statewide'.

-- 01. STATEWIDE TOTALS AND AVERAGE MONTHLY UTILIZATION
SELECT
  `Setting`,
  SUM(SAFE_CAST(`Count` AS INT64)) AS total_utilization,
  ROUND(
    AVG(SAFE_CAST(`Count` AS FLOAT64)),
    2
  ) AS average_monthly_utilization,
  COUNT(DISTINCT SAFE.PARSE_DATE('%y-%b', `Date`))
    AS months_reported
FROM `project-64ca764a-0f3f-4a31-b12.health_analytics.hospital_utilization_v2`
WHERE `Facility Name` = 'Statewide'
GROUP BY `Setting`
ORDER BY total_utilization DESC;


-- 02. STATEWIDE MONTHLY UTILIZATION
SELECT
  SAFE.PARSE_DATE('%y-%b', `Date`) AS month,
  `Setting`,
  SAFE_CAST(`Count` AS INT64) AS monthly_utilization
FROM `project-64ca764a-0f3f-4a31-b12.health_analytics.hospital_utilization_v2`
WHERE `Facility Name` = 'Statewide'
ORDER BY month, `Setting`;


-- 03. MONTH-OVER-MONTH CHANGE (%)
-- Calculate a MoM change only when the previous observation
-- is from the immediately preceding calendar month.
WITH monthly AS (
  SELECT
    SAFE.PARSE_DATE('%y-%b', `Date`) AS month,
    `Setting`,
    SAFE_CAST(`Count` AS INT64) AS monthly_utilization
  FROM `project-64ca764a-0f3f-4a31-b12.health_analytics.hospital_utilization_v2`
  WHERE `Facility Name` = 'Statewide'
),
comparison AS (
  SELECT
    month,
    `Setting`,
    monthly_utilization,
    LAG(month) OVER (
      PARTITION BY `Setting`
      ORDER BY month
    ) AS previous_month_date,
    LAG(monthly_utilization) OVER (
      PARTITION BY `Setting`
      ORDER BY month
    ) AS previous_month_utilization
  FROM monthly
)
SELECT
  month,
  `Setting`,
  monthly_utilization,
  previous_month_utilization,
  CASE
    WHEN DATE_DIFF(month, previous_month_date, MONTH) = 1
    THEN ROUND(
      SAFE_DIVIDE(
        monthly_utilization - previous_month_utilization,
        previous_month_utilization
      ) * 100,
      2
    )
    ELSE NULL
  END AS monthly_change_pct
FROM comparison
ORDER BY month, `Setting`;


-- 04. TEN LARGEST MONTH-OVER-MONTH DECLINES
WITH monthly AS (
  SELECT
    SAFE.PARSE_DATE('%y-%b', `Date`) AS month,
    `Setting`,
    SAFE_CAST(`Count` AS INT64) AS monthly_utilization
  FROM `project-64ca764a-0f3f-4a31-b12.health_analytics.hospital_utilization_v2`
  WHERE `Facility Name` = 'Statewide'
),
comparison AS (
  SELECT
    month,
    `Setting`,
    monthly_utilization,
    LAG(month) OVER (
      PARTITION BY `Setting`
      ORDER BY month
    ) AS previous_month_date,
    LAG(monthly_utilization) OVER (
      PARTITION BY `Setting`
      ORDER BY month
    ) AS previous_month_utilization
  FROM monthly
),
changes AS (
  SELECT
    month,
    `Setting`,
    monthly_utilization,
    previous_month_utilization,
    CASE
      WHEN DATE_DIFF(month, previous_month_date, MONTH) = 1
      THEN ROUND(
        SAFE_DIVIDE(
          monthly_utilization - previous_month_utilization,
          previous_month_utilization
        ) * 100,
        2
      )
      ELSE NULL
    END AS change_pct
  FROM comparison
)
SELECT *
FROM changes
WHERE change_pct IS NOT NULL
ORDER BY change_pct ASC
LIMIT 10;


-- 05. TEN LARGEST MONTH-OVER-MONTH INCREASES
WITH monthly AS (
  SELECT
    SAFE.PARSE_DATE('%y-%b', `Date`) AS month,
    `Setting`,
    SAFE_CAST(`Count` AS INT64) AS monthly_utilization
  FROM `project-64ca764a-0f3f-4a31-b12.health_analytics.hospital_utilization_v2`
  WHERE `Facility Name` = 'Statewide'
),
comparison AS (
  SELECT
    month,
    `Setting`,
    monthly_utilization,
    LAG(month) OVER (
      PARTITION BY `Setting`
      ORDER BY month
    ) AS previous_month_date,
    LAG(monthly_utilization) OVER (
      PARTITION BY `Setting`
      ORDER BY month
    ) AS previous_month_utilization
  FROM monthly
),
changes AS (
  SELECT
    month,
    `Setting`,
    monthly_utilization,
    previous_month_utilization,
    CASE
      WHEN DATE_DIFF(month, previous_month_date, MONTH) = 1
      THEN ROUND(
        SAFE_DIVIDE(
          monthly_utilization - previous_month_utilization,
          previous_month_utilization
        ) * 100,
        2
      )
      ELSE NULL
    END AS change_pct
  FROM comparison
)
SELECT *
FROM changes
WHERE change_pct IS NOT NULL
ORDER BY change_pct DESC
LIMIT 10;
