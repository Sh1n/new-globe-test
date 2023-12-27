{{
    config(
        materialized='table',
    )
}}
-- The decision to split on the AcademyName is for the sake of standardisation since certain
-- records appear along a code after the academy name (Region code?)
WITH sourced AS (
    SELECT
        DISTINCT
        academy_name
    FROM {{ ref('stg_pupil_data') }}
    WHERE
        1 = 1
)

SELECT
    GENERATE_UUID() AS surrogate_key,
    academy_name
FROM sourced