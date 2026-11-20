# BigQuery SQL Scripts — California Hospital Utilization Analytics (2020–2024)

## 1. Overview

This directory contains four BigQuery Standard SQL scripts used to validate and analyze the California Department of Health Care Access and Information (HCAI) Hospital Utilization Trends dataset for 2020–2024.

The scripts cover:
- Dataset validation and data quality checks
- Statewide monthly utilization trends
- Month-over-month (MoM) and year-over-year (YoY) changes
- Annual utilization comparisons
- Facility-level utilization and reporting coverage
- An audit of records with `Count = 11`

These queries analyze the existing BigQuery table. They do not modify the source data or create permanent tables.

## 2. Files and Responsibilities

| File | Purpose |
|---|---|
| `01_data_quality_checks.sql` | Checks row counts, date validity, missing values, numeric conversion, negative counts, duplicate grain keys, and records with `Count = 11`. |
| `02_monthly_trends.sql` | Calculates statewide utilization totals and monthly averages, monthly values, MoM percentage changes, and the largest monthly declines and increases. |
| `03_annual_trends.sql` | Compares 2020 and 2024 totals and calculates annual totals and YoY percentage changes. |
| `04_facility_analysis.sql` | Calculates facility-level recorded utilization and evaluates reporting coverage by facility, system, and setting. |

## 3. Table Reference and Reporting Grain

The scripts reference the following table:

```text
project-64ca764a-0f3f-4a31-b12.health_analytics.hospital_utilization_v2
```

The reporting grain for these analyses is:

```text
Date + Facility Name + System + Setting
```

The duplicate-key query checks this combination and returns any keys with more than one record. Potential duplicates should be investigated rather than deleted automatically.

### Statewide and Facility-Level Separation

The source includes statewide aggregate records as well as individual facility records:
- **Statewide analysis:** Filter using `Facility Name = 'Statewide'`.
- **Facility-level analysis:** Exclude records where `Facility Name = 'Statewide'` and exclude missing facility names (`Facility Name IS NOT NULL AND Facility Name != 'Statewide'`).

These levels must **not** be summed together because doing so would double-count utilization. Facility-level totals represent recorded facility observations and should not be interpreted as independently verified statewide totals.

## 4. Data Quality and Interpretation

### Date Parsing
The source stores reporting months as text labels, such as `20-Jan`. The scripts convert these labels into dates using `SAFE.PARSE_DATE('%y-%b', Date)`. Invalid or missing dates are explicitly flagged in `01_data_quality_checks.sql` (`invalid_date_labels`) and filtered out before time-series and annual aggregations.

### Numeric Conversion
The scripts use `SAFE_CAST` to convert `Count` to `INT64` / `FLOAT64`. Missing values and non-null values that cannot be converted are checked separately in `01_data_quality_checks.sql`.

### Records with `Count = 11`
The scripts quantify records where `Count = 11` without changing or imputing their values. While these values may represent suppressed small counts, they should not be treated as confirmed suppression unless established by the applicable HCAI documentation, and should not automatically be replaced with zero or another estimated value.

### Reporting Gaps
The monthly change queries (`02_monthly_trends.sql`) only calculate a MoM percentage change when `DATE_DIFF(month, previous_month_date, MONTH) = 1` (the current month is exactly one calendar month after the preceding observation). The annual change query (`03_annual_trends.sql`) applies the equivalent rule (`year - previous_year = 1`) for consecutive calendar years. This prevents a missing period from being treated as an ordinary one-month or one-year comparison.

## 5. How to Run the Scripts in BigQuery

1. Open **BigQuery Studio** in Google Cloud Console.
2. Confirm that the source data is available in the table referenced above.
3. If your project or dataset differs, update the fully qualified table name in each script.
4. Use **GoogleSQL (BigQuery Standard SQL)**.
5. Run the scripts in this order:
   - `01_data_quality_checks.sql`
   - `02_monthly_trends.sql`
   - `03_annual_trends.sql`
   - `04_facility_analysis.sql`
6. Review the results and investigate unexpected data quality findings before interpreting the analysis.

Each numbered query is a separate statement. Run the individual statements and review their result sets.

## 6. Key Findings from the Project

The statewide annual analysis for 2020–2024 showed the following changes:

| Service setting | 2020 utilization | 2024 utilization | Change |
|---|---:|---:|---:|
| Ambulatory Surgery | 1,785,120 | 2,334,952 | +30.80% |
| Emergency Department | 10,023,851 | 13,307,457 | +32.76% |
| Inpatient | 3,444,532 | 3,738,290 | +8.53% |

These figures are statewide recorded utilization totals. They describe changes in recorded activity and do not, by themselves, establish the causes of those changes.

## 7. Limitations

- The analysis describes utilization, not clinical outcomes, quality of care, costs, or profitability.
- Changes in recorded utilization do not establish causation.
- Records with `Count = 11` require cautious interpretation until their meaning is confirmed from the applicable source documentation.
- Facility-level totals may be affected by reporting coverage, missing values, and differences between facilities.
- Reporting coverage is measured using distinct observed months; it does not establish why a facility has missing months.
- Monthly and annual percentage changes are not calculated when the immediately preceding calendar period is absent or the comparison denominator is zero.

## 8. Tools and Skills Demonstrated

- Google BigQuery
- GoogleSQL (Standard SQL)
- Data quality validation
- Aggregation and grouping
- Date parsing and date functions (`SAFE.PARSE_DATE`, `EXTRACT`, `DATE_DIFF`)
- Common table expressions (`WITH`)
- Window functions (`LAG`)
- Conditional aggregation (`COUNTIF`, `MAX(IF(...))`)
- Safe type conversion and division (`SAFE_CAST`, `SAFE_DIVIDE`)
- Trend analysis and percentage-change calculations
- Facility-level reporting coverage analysis

These scripts form the SQL analysis component of the **California Hospital Utilization Analytics (2020–2024)** portfolio project.
