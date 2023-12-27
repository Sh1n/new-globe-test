{{
    config(
        materialized='table',
    )
}}

WITH sourced AS (
    SELECT
        grade_id,
        grade_name,
        ROW_NUMBER() OVER (PARTITION BY grade_id ORDER BY date DESC) as rn
    FROM {{ ref('stg_pupil_data') }}
    WHERE
        1 = 1
)

SELECT
    GENERATE_UUID() AS surrogate_key,
    grade_id,
    grade_name
FROM sourced
WHERE rn = 1