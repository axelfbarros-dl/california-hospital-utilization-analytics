-- California Hospital Utilization Analytics (2020–2024)
-- BigQuery Standard SQL
-- Statewide annual utilization and year-over-year analysis.

-- 01. ANNUAL TOTALS: 2020 VS 2024
WITH monthly AS (
  SELECT
    SAFE.PARSE_DATE('%y-%b', `Date`) AS month,
    `Setting`,
    SAFE_CAST(`Count` AS INT64) AS monthly_utilization
  FROM `project-64ca764a-0f3f-4a31-b12.health_analytics.hospital_utilization_v2`
  WHERE `Facility Name` = 'Statewide'
),
yearly AS (
  SELECT
    EXTRACT(YEAR FROM month) AS year,
    `Setting`,
    SUM(monthly_utilization) AS annual_total
  FROM monthly
  WHERE month IS NOT NULL
  GROUP BY year, `Setting`
),
comparison AS (
  SELECT
    `Setting`,
    MAX(IF(year = 2020, annual_total, NULL)) AS total_2020,
    MAX(IF(year = 2024, annual_total, NULL)) AS total_2024
  FROM yearly
  GROUP BY `Setting`
)
SELECT
  `Setting`,
  total_2020,
  total_2024,
  ROUND(
    SAFE_DIVIDE(total_2024 - total_2020, total_2020) * 100,
    2
  ) AS change_pct_2020_2024
FROM comparison
ORDER BY change_pct_2020_2024 DESC;


-- 02. YEAR-OVER-YEAR CHANGE (%)
-- Calculate a YoY change only when the previous observation
-- is from the immediately preceding calendar year.
WITH monthly AS (
  SELECT
    SAFE.PARSE_DATE('%y-%b', `Date`) AS month,
    `Setting`,
    SAFE_CAST(`Count` AS INT64) AS monthly_utilization
  FROM `project-64ca764a-0f3f-4a31-b12.health_analytics.hospital_utilization_v2`
  WHERE `Facility Name` = 'Statewide'
),
yearly AS (
  SELECT
    EXTRACT(YEAR FROM month) AS year,
    `Setting`,
    SUM(monthly_utilization) AS annual_total
  FROM monthly
  WHERE month IS NOT NULL
  GROUP BY year, `Setting`
),
comparison AS (
  SELECT
    year,
    `Setting`,
    annual_total,
    LAG(year) OVER (
      PARTITION BY `Setting`
      ORDER BY year
    ) AS previous_year,
    LAG(annual_total) OVER (
      PARTITION BY `Setting`
      ORDER BY year
    ) AS previous_year_total
  FROM yearly
)
SELECT
  year,
  `Setting`,
  annual_total,
  previous_year_total,
  CASE
    WHEN year - previous_year = 1
    THEN ROUND(
      SAFE_DIVIDE(
        annual_total - previous_year_total,
        previous_year_total
      ) * 100,
      2
    )
    ELSE NULL
  END AS year_over_year_change_pct
FROM comparison
ORDER BY `Setting`, year;
