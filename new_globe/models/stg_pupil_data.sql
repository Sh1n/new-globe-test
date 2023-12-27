-- This is the staged version of the pupil data. 
-- Used both for cleaning and for ingesting the files
-- in order not to read each time from the bucket
{{
    config(
        materialized='incremental',
        partition_by={
            "field": "date",
            "data_type": "date",
            "granularity": "day"
        }
    )
}}

WITH renamed AS (
    SELECT
        SnapshotDate AS date,
        PupilID as pupil_id,
        AcademyName AS academy_name,
        FirstName AS first_name,
        MiddleName AS middle_name,
        LastName AS last_name,
        Status AS status,
        GradeId AS grade_id,
        GradeName AS grade_name,
        Stream AS stream
    FROM {{ source('pupils', 'pupil_data') }}
    WHERE
        1 = 1

    {% if is_incremental() %}
        AND SnapshotDate > (SELECT MAX(date) FROM {{ this }})
    {% endif %}
),

cleaned AS (
    SELECT
        date,
        pupil_id,
        -- The decision to split on the AcademyName is for the sake of standardisation since certain
        -- records appear along a code after the academy name (Region code?)
        SPLIT(academy_name, '-')[0] AS academy_name,
        INITCAP(TRIM(REPLACE(first_name, '.', ''))) AS first_name,
        INITCAP(TRIM(REPLACE(middle_name, '.', ''))) AS middle_name,
        INITCAP(TRIM(REPLACE(last_name, '.', ''))) AS last_name,
        status,
        grade_id,
        grade_name,
        -- We assume we want to standardise this field
        UPPER(stream) AS stream
    FROM renamed
)

SELECT
    *
FROM cleaned

