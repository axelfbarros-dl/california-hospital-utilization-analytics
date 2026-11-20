-- California Hospital Utilization Analytics (2020–2024)
-- BigQuery Standard SQL
-- Data quality and validation checks

-- IMPORTANT:
-- Use Facility Name = 'Statewide' for statewide analysis.
-- Exclude statewide aggregate rows from facility-level analysis.

-- 01. DATASET VALIDATION
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT `Date`) AS distinct_date_labels,
  COUNT(DISTINCT `Setting`) AS distinct_settings,
  COUNTIF(`Facility Name` = 'Statewide') AS statewide_rows,
  COUNTIF(`Facility Name` IS NULL) AS missing_facility_names,
  COUNTIF(`Date` IS NOT NULL AND SAFE.PARSE_DATE('%y-%b', `Date`) IS NULL)
    AS invalid_date_labels
FROM `project-64ca764a-0f3f-4a31-b12.health_analytics.hospital_utilization_v2`;


-- 02. DATA QUALITY CHECKS
-- Invalid counts excludes NULL values so missing and invalid values
-- are reported separately.
SELECT
  COUNT(*) AS total_rows,
  COUNTIF(`Date` IS NULL) AS missing_dates,
  COUNTIF(`Setting` IS NULL) AS missing_settings,
  COUNTIF(`Count` IS NULL) AS missing_counts,
  COUNTIF(
    `Count` IS NOT NULL
    AND SAFE_CAST(`Count` AS INT64) IS NULL
  ) AS invalid_counts,
  COUNTIF(SAFE_CAST(`Count` AS INT64) < 0) AS negative_counts
FROM `project-64ca764a-0f3f-4a31-b12.health_analytics.hospital_utilization_v2`;


-- 03. DUPLICATE GRAIN KEY CHECK
-- Expected grain: Date + Facility Name + System + Setting.
-- Review any returned rows; do not delete records automatically.
SELECT
  `Date`,
  `Facility Name`,
  `System`,
  `Setting`,
  COUNT(*) AS row_count
FROM `project-64ca764a-0f3f-4a31-b12.health_analytics.hospital_utilization_v2`
GROUP BY
  `Date`,
  `Facility Name`,
  `System`,
  `Setting`
HAVING COUNT(*) > 1
ORDER BY row_count DESC, `Date`;


-- 04. RECORDS WITH COUNT = 11
-- These values may represent suppressed small counts.
-- Confirm the interpretation against source documentation.
-- Do not automatically replace or reinterpret these values.
SELECT
  `Setting`,
  COUNTIF(SAFE_CAST(`Count` AS INT64) = 11)
    AS records_with_count_11,
  COUNT(*) AS total_rows,
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(SAFE_CAST(`Count` AS INT64) = 11),
      COUNT(*)
    ) * 100,
    2
  ) AS pct_rows_with_count_11
FROM `project-64ca764a-0f3f-4a31-b12.health_analytics.hospital_utilization_v2`
WHERE `Facility Name` IS NOT NULL
  AND `Facility Name` != 'Statewide'
GROUP BY `Setting`
ORDER BY records_with_count_11 DESC;
