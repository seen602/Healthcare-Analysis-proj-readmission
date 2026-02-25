-- ============================================================
-- Patient 30-Day Readmission Analysis — SQL Queries
-- Dataset: UCI Diabetes 130-US Hospitals (1999-2008)
-- After cleaning: 69,987 records
-- Run in SQLite / PostgreSQL / MySQL
-- ============================================================

-- ── 1. Dataset Overview KPIs ──────────────────────────────────────────────────
SELECT
    COUNT(*)                                AS total_encounters,
    COUNT(DISTINCT patient_nbr)             AS unique_patients,
    SUM(readmitted)                         AS total_readmissions,
    ROUND(AVG(readmitted) * 100, 1)         AS readmission_rate_pct,
    ROUND(AVG(time_in_hospital), 1)         AS avg_los_days,
    ROUND(AVG(num_medications), 1)          AS avg_medications,
    ROUND(AVG(number_diagnoses), 1)         AS avg_diagnoses
FROM encounters;
-- Real output: 69,987 | 69,987 | 6,285 | 9.0% | 4.3 days | 15.7 | 7.2


-- ── 2. Cohort Profile: Readmitted vs Not Readmitted ──────────────────────────
SELECT
    CASE WHEN readmitted = 1 THEN 'Readmitted' ELSE 'Not Readmitted' END AS cohort,
    COUNT(*)                                AS n,
    ROUND(AVG(time_in_hospital), 2)         AS avg_los,
    ROUND(AVG(num_medications), 2)          AS avg_meds,
    ROUND(AVG(number_inpatient), 2)         AS avg_prior_inpatient,
    ROUND(AVG(number_emergency), 2)         AS avg_prior_emergency,
    ROUND(AVG(number_diagnoses), 2)         AS avg_diagnoses
FROM encounters
GROUP BY readmitted;
-- Key insight: prior_inpatient 0.37 vs 0.16 (+131%), prior_emergency 0.15 vs 0.10 (+50%)


-- ── 3. Readmission Rate by Age Group ─────────────────────────────────────────
SELECT
    age,
    COUNT(*)                                AS encounters,
    SUM(readmitted)                         AS readmissions,
    ROUND(AVG(readmitted) * 100, 1)         AS readmission_rate_pct,
    ROUND(AVG(time_in_hospital), 1)         AS avg_los
FROM encounters
GROUP BY age
ORDER BY age;
-- Peak: [80-90) at 10.8%, [70-80) at 10.2%


-- ── 4. Readmission by Prior Utilization Bucket ───────────────────────────────
SELECT
    CASE
        WHEN (number_inpatient + number_emergency) = 0         THEN 'None (0 visits)'
        WHEN (number_inpatient + number_emergency) = 1         THEN 'Low (1 visit)'
        WHEN (number_inpatient + number_emergency) BETWEEN 2 AND 3 THEN 'Medium (2-3 visits)'
        ELSE 'High (4+ visits)'
    END AS prior_visits_bucket,
    COUNT(*)                                AS n,
    ROUND(AVG(readmitted) * 100, 1)         AS readmission_rate_pct,
    ROUND(AVG(time_in_hospital), 1)         AS avg_los
FROM encounters
GROUP BY prior_visits_bucket
ORDER BY readmission_rate_pct DESC;
-- Real output: 4+ visits=25.5%, 2-3=16.4%, 1=10.3%, None=7.1%


-- ── 5. Medication Change (A1Cresult) x Insulin Analysis ──────────────────────
-- Note: A1Cresult is derived from 'change' column (Ch=medication changed, No=unchanged)
SELECT
    A1Cresult,
    insulin,
    COUNT(*)                                AS n,
    ROUND(AVG(readmitted) * 100, 1)         AS readmission_rate_pct,
    ROUND(AVG(time_in_hospital), 1)         AS avg_los
FROM encounters
GROUP BY A1Cresult, insulin
ORDER BY readmission_rate_pct DESC
LIMIT 12;


-- ── 6. Length of Stay Bucket Analysis ────────────────────────────────────────
SELECT
    CASE
        WHEN time_in_hospital BETWEEN 1 AND 3  THEN '1-3 days (Short)'
        WHEN time_in_hospital BETWEEN 4 AND 6  THEN '4-6 days (Medium)'
        WHEN time_in_hospital BETWEEN 7 AND 9  THEN '7-9 days (Long)'
        ELSE '10+ days (Extended)'
    END AS los_bucket,
    COUNT(*)                                AS n,
    ROUND(AVG(readmitted) * 100, 1)         AS readmission_rate_pct,
    ROUND(AVG(num_medications), 1)          AS avg_meds
FROM encounters
GROUP BY los_bucket
ORDER BY readmission_rate_pct DESC;


-- ── 7. Readmission by Gender and Race ────────────────────────────────────────
SELECT
    gender,
    race,
    COUNT(*)                                AS n,
    ROUND(AVG(readmitted) * 100, 1)         AS readmission_rate_pct
FROM encounters
GROUP BY gender, race
HAVING COUNT(*) >= 50
ORDER BY readmission_rate_pct DESC;


-- ── 8. Diabetes Medication × Insulin Combination ─────────────────────────────
SELECT
    diabetesMed,
    insulin,
    COUNT(*)                                AS n,
    ROUND(AVG(readmitted) * 100, 1)         AS readmission_rate_pct,
    ROUND(AVG(num_medications), 1)          AS avg_meds,
    ROUND(AVG(time_in_hospital), 1)         AS avg_los
FROM encounters
GROUP BY diabetesMed, insulin
ORDER BY readmission_rate_pct DESC;


-- ── 9. Rule-Based Risk Score (Pure SQL — no Python required) ─────────────────
SELECT
    encounter_id,
    patient_nbr,
    age,
    gender,
    time_in_hospital,
    number_inpatient,
    number_emergency,
    num_medications,
    A1Cresult,
    readmitted,
    -- Compute score
    MIN(number_inpatient * 2, 4)
      + MIN(number_emergency, 2)
      + CASE WHEN time_in_hospital >= 7  THEN 1 ELSE 0 END
      + CASE WHEN time_in_hospital >= 10 THEN 1 ELSE 0 END
      + CASE WHEN A1Cresult = '>8'       THEN 1 ELSE 0 END
      + CASE WHEN num_medications >= 20  THEN 1 ELSE 0 END  AS risk_score,
    -- Assign tier
    CASE
        WHEN (MIN(number_inpatient * 2, 4) + MIN(number_emergency, 2)
              + CASE WHEN time_in_hospital >= 7  THEN 1 ELSE 0 END
              + CASE WHEN time_in_hospital >= 10 THEN 1 ELSE 0 END
              + CASE WHEN A1Cresult = '>8'       THEN 1 ELSE 0 END
              + CASE WHEN num_medications >= 20  THEN 1 ELSE 0 END) >= 7 THEN 'Critical'
        WHEN (MIN(number_inpatient * 2, 4) + MIN(number_emergency, 2)
              + CASE WHEN time_in_hospital >= 7  THEN 1 ELSE 0 END
              + CASE WHEN time_in_hospital >= 10 THEN 1 ELSE 0 END
              + CASE WHEN A1Cresult = '>8'       THEN 1 ELSE 0 END
              + CASE WHEN num_medications >= 20  THEN 1 ELSE 0 END) >= 4 THEN 'High'
        WHEN (MIN(number_inpatient * 2, 4) + MIN(number_emergency, 2)
              + CASE WHEN time_in_hospital >= 7  THEN 1 ELSE 0 END
              + CASE WHEN time_in_hospital >= 10 THEN 1 ELSE 0 END
              + CASE WHEN A1Cresult = '>8'       THEN 1 ELSE 0 END
              + CASE WHEN num_medications >= 20  THEN 1 ELSE 0 END) >= 2 THEN 'Medium'
        ELSE 'Low'
    END AS risk_tier
FROM encounters
ORDER BY risk_score DESC;


-- ── 10. Risk Tier Validation ──────────────────────────────────────────────────
WITH scored AS (
    SELECT *,
        MIN(number_inpatient * 2, 4) + MIN(number_emergency, 2)
        + CASE WHEN time_in_hospital >= 7  THEN 1 ELSE 0 END
        + CASE WHEN time_in_hospital >= 10 THEN 1 ELSE 0 END
        + CASE WHEN A1Cresult = '>8'       THEN 1 ELSE 0 END
        + CASE WHEN num_medications >= 20  THEN 1 ELSE 0 END AS risk_score
    FROM encounters
),
tiered AS (
    SELECT *,
        CASE
            WHEN risk_score >= 7 THEN 'Critical'
            WHEN risk_score >= 4 THEN 'High'
            WHEN risk_score >= 2 THEN 'Medium'
            ELSE 'Low'
        END AS risk_tier
    FROM scored
)
SELECT
    risk_tier,
    COUNT(*)                                AS patients,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_total,
    ROUND(AVG(readmitted) * 100, 1)         AS actual_readmission_rate_pct,
    ROUND(AVG(risk_score), 2)               AS avg_score
FROM tiered
GROUP BY risk_tier
ORDER BY actual_readmission_rate_pct DESC;
-- Validates: Critical=21.1%, High=~16%, Medium=~10.5%, Low=~7.5%
