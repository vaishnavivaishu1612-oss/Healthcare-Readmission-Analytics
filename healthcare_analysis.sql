-- 1. Preview the data
SELECT *
FROM diabetic_data
LIMIT 10;


-- 2. Total number of records
SELECT COUNT(*) AS total_counts
FROM diabetic_data;


-- 3. View table structure
DESCRIBE diabetic_data;


-- 4. Patients by readmission status
SELECT
    readmitted,
    COUNT(*) AS total_counts
FROM diabetic_data
GROUP BY readmitted;


-- 5. Patients by age group
SELECT
    age,
    COUNT(*) AS total_patients
FROM diabetic_data
GROUP BY age
ORDER BY total_patients DESC;


-- 6. Average hospital stay
SELECT
    ROUND(AVG(time_in_hospital), 2) AS avg_stay
FROM diabetic_data;


-- 7. Patients by gender
SELECT
    gender,
    COUNT(*) AS total_gender
FROM diabetic_data
GROUP BY gender;


-- 8. Thirty-day readmission rate by age group
SELECT
    age,
    COUNT(*) AS total_patients,

    SUM(
        CASE
            WHEN readmitted = '<30' THEN 1
            ELSE 0
        END
    ) AS readmitted_within_30_days,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN readmitted = '<30' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS readmission_rate_percentage

FROM diabetic_data
GROUP BY age
ORDER BY readmission_rate_percentage DESC;


-- 9. Age groups with above-average hospital stays
SELECT
    age,
    ROUND(AVG(time_in_hospital), 2) AS average_stay
FROM diabetic_data
GROUP BY age
HAVING AVG(time_in_hospital) >
(
    SELECT AVG(time_in_hospital)
    FROM diabetic_data
)
ORDER BY average_stay DESC;


-- 10. Create readable readmission categories
SELECT
    encounter_id,
    patient_nbr,
    age,
    time_in_hospital,
    readmitted,

    CASE
        WHEN readmitted = '<30' THEN 'Early Readmission'
        WHEN readmitted = '>30' THEN 'Late Readmission'
        WHEN readmitted = 'NO' THEN 'No Readmission'
        ELSE 'Unknown'
    END AS readmission_category

FROM diabetic_data
LIMIT 20;


-- 11. Age groups with a readmission rate above the hospital average
WITH age_readmission AS (
    SELECT
        age,
        COUNT(*) AS total_patients,

        SUM(
            CASE
                WHEN readmitted = '<30' THEN 1
                ELSE 0
            END
        ) AS early_readmissions

    FROM diabetic_data
    GROUP BY age
),

age_rates AS (
    SELECT
        age,
        total_patients,
        early_readmissions,

        ROUND(
            100.0 * early_readmissions / total_patients,
            2
        ) AS age_readmission_rate

    FROM age_readmission
)

SELECT *
FROM age_rates
WHERE age_readmission_rate >
(
    SELECT
        100.0 * SUM(
            CASE
                WHEN readmitted = '<30' THEN 1
                ELSE 0
            END
        ) / COUNT(*)
    FROM diabetic_data
)
ORDER BY age_readmission_rate DESC;


-- 12. Rank age groups by readmission rate
WITH age_rates AS (
    SELECT
        age,
        COUNT(*) AS total_patients,

        SUM(
            CASE
                WHEN readmitted = '<30' THEN 1
                ELSE 0
            END
        ) AS early_readmissions,

        ROUND(
            100.0 * SUM(
                CASE
                    WHEN readmitted = '<30' THEN 1
                    ELSE 0
                END
            ) / COUNT(*),
            2
        ) AS readmission_rate

    FROM diabetic_data
    GROUP BY age
)

SELECT
    age,
    total_patients,
    early_readmissions,
    readmission_rate,

    DENSE_RANK() OVER (
        ORDER BY readmission_rate DESC
    ) AS risk_rank

FROM age_rates
ORDER BY risk_rank;


-- 13. Classify patient risk
SELECT
    patient_nbr,
    age,
    time_in_hospital,
    num_medications,

    CASE
        WHEN time_in_hospital >= 10
             AND num_medications >= 20
            THEN 'High Risk'

        WHEN time_in_hospital >= 5
             AND num_medications >= 10
            THEN 'Medium Risk'

        ELSE 'Low Risk'
    END AS risk_category

FROM diabetic_data
LIMIT 20;


-- 14. Count patients in each risk group
SELECT
    CASE
        WHEN time_in_hospital >= 10
             AND num_medications >= 20
            THEN 'High Risk'

        WHEN time_in_hospital >= 5
             AND num_medications >= 10
            THEN 'Medium Risk'

        ELSE 'Low Risk'
    END AS risk_category,

    COUNT(*) AS total_patients

FROM diabetic_data
GROUP BY risk_category
ORDER BY total_patients DESC;


-- 15. Top 10 encounters with the longest hospital stays
SELECT
    patient_nbr,
    age,
    time_in_hospital,
    num_medications
FROM diabetic_data
ORDER BY time_in_hospital DESC, num_medications DESC
LIMIT 10;


-- 16. Rank encounters by hospital-stay length
SELECT
    patient_nbr,
    age,
    time_in_hospital,

    DENSE_RANK() OVER (
        ORDER BY time_in_hospital DESC
    ) AS stay_rank

FROM diabetic_data;
CREATE VIEW vw_age_group_summary AS
SELECT
    age,

    COUNT(*) AS total_patients,

    SUM(
        CASE
            WHEN readmitted = '<30' THEN 1
            ELSE 0
        END
    ) AS early_readmissions,

    ROUND(
        100 * SUM(
            CASE
                WHEN readmitted = '<30' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS readmission_rate,

    ROUND(AVG(time_in_hospital),2) AS avg_hospital_stay,

    ROUND(AVG(num_medications),2) AS avg_medications

FROM diabetic_data
GROUP BY age;

SELECT *
FROM vw_age_group_summary;
SELECT *

FROM vw_age_group_summary
ORDER BY readmission_rate DESC
LIMIT 5;

SELECT *
FROM vw_age_group_summary
ORDER BY avg_hospital_stay DESC
LIMIT 5;