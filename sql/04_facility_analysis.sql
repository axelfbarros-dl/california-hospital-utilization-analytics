-- California Hospital Utilization Analytics (2020–2024)
-- BigQuery Standard SQL
-- Facility-level analysis excludes statewide aggregate records.
-- These results describe recorded facility observations,
-- not independently calculated statewide totals.

-- 01. FACILITY-LEVEL TOTALS BY SETTING
SELECT
  `Facility Name`,
  `System`,
  `Setting`,
  SUM(SAFE_CAST(`Count` AS INT64)) AS total_recorded_utilization,
  COUNT(
    DISTINCT SAFE.PARSE_DATE('%y-%b', `Date`)
  ) AS months_reported
FROM `project-64ca764a-0f3f-4a31-b12.health_analytics.hospital_utilization_v2`
WHERE `Facility Name` IS NOT NULL
  AND `Facility Name` != 'Statewide'
GROUP BY
  `Facility Name`,
  `System`,
  `Setting`
ORDER BY total_recorded_utilization DESC;


-- 02. FACILITY REPORTING COVERAGE
WITH facility_months AS (
  SELECT DISTINCT
    `Facility Name`,
    `System`,
    `Setting`,
    SAFE.PARSE_DATE('%y-%b', `Date`) AS month
  FROM `project-64ca764a-0f3f-4a31-b12.health_analytics.hospital_utilization_v2`
  WHERE `Facility Name` IS NOT NULL
    AND `Facility Name` != 'Statewide'
)
SELECT
  `Facility Name`,
  `System`,
  `Setting`,
  COUNT(DISTINCT month) AS months_reported,
  MIN(month) AS first_month,
  MAX(month) AS last_month
FROM facility_months
WHERE month IS NOT NULL
GROUP BY
  `Facility Name`,
  `System`,
  `Setting`
ORDER BY months_reported DESC, `Facility Name`;
