{{
    config(
        materialized='table',
    )
}}
-- Data Cleaning:
    -- 1. Replace strange characters
    -- 2. remove spaces
    -- 3. make the union of first name, middle name, last name
    -- 4. rebuild the naming structure

-- We assume that:
    -- The full name is the concatenation of the distinct words in the names
    -- The words composing the full name might be also 1 character long (like B, J, K, S, X)
    -- The special character like . cannot be part of a name
    -- The first name is the first word in the full name
    -- The last name is the last word in the full name
    -- The middle name is the full name but the first and last words
    -- The full name is composed by at least 2 words

WITH cleaned AS (
    SELECT 
        DISTINCT
        PupilID AS pupil_id,
        INITCAP(TRIM(REPLACE(FirstName, '.', ''))) AS first_name,
        INITCAP(TRIM(REPLACE(MiddleName, '.', ''))) AS middle_name,
        INITCAP(TRIM(REPLACE(LastName, '.', ''))) AS last_name
    FROM {{ source('pupils', 'pupil_data') }}
    WHERE 1 = 1
),

rebuilt_names AS (
    SELECT
        cleaned.pupil_id,
        ARRAY(
            SELECT DISTINCT s 
            FROM UNNEST(
            -- ARRAY_CONCAT returns 0 rows if any of the arguments are null, coalescing to solve 
            ARRAY_CONCAT(
                COALESCE(SPLIT(first_name, ' '), []),
                COALESCE(SPLIT(middle_name, ' '), []), 
                COALESCE(SPLIT(last_name, ' '), [])
            )
            ) s
        ) AS rebuilt_full_name
    FROM cleaned
)

SELECT
    GENERATE_UUID() AS surrogate_key,
    pupil_id,
    rebuilt_full_name[0] AS first_name,
    ARRAY_TO_STRING(
        ARRAY(
            SELECT part
            FROM UNNEST(rebuilt_full_name) part WITH OFFSET index 
            WHERE index BETWEEN 1 AND ARRAY_LENGTH(rebuilt_full_name) - 2
        ), ' ') AS middle_name,
    rebuilt_full_name[ARRAY_LENGTH(rebuilt_full_name) - 1] AS last_name,
FROM rebuilt_names
