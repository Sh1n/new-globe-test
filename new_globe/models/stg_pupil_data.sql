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
        -- We do use ANY_VALUE to remove duplicates in case of duplicated source files
        -- Since each pupil can attend one academy at time, we do group on <Date, Pupil>
        SnapshotDate AS date,
        PupilID as pupil_id,
        ANY_VALUE(AcademyName) AS academy_name,
        ANY_VALUE(FirstName) AS first_name,
        ANY_VALUE(MiddleName) AS middle_name,
        ANY_VALUE(LastName) AS last_name,
        ANY_VALUE(Status) AS status,
        ANY_VALUE(GradeId) AS grade_id,
        ANY_VALUE(GradeName) AS grade_name,
        ANY_VALUE(Stream) AS stream
    FROM {{ source('pupils', 'pupil_data') }}
    WHERE
        1 = 1
    {% if is_incremental() %}
        AND SnapshotDate > (SELECT MAX(date) FROM {{ this }})
    {% endif %}
    GROUP BY
        1, 2
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

