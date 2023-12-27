{{
    config(
        materialized='table',
    )
}}

WITH sourced AS (
    SELECT
        GradeId AS grade_id,
        GradeName AS grade_name,
        ROW_NUMBER() OVER (PARTITION BY GradeId ORDER BY SnapshotDate DESC) as rn
    FROM {{ source('pupils', 'pupil_data') }}
    WHERE
        1 = 1
)

SELECT
    GENERATE_UUID() AS surrogate_key,
    grade_id,
    grade_name
FROM sourced
WHERE rn = 1